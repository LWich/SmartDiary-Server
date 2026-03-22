import Fluent
import Redis
import Vapor

struct AssistantController {
    func groupStudents(req: Request) async throws -> [GroupStudentDTO] {
        let user = try req.auth.require(User.self)
        guard user.role == .assistant else {
            throw Abort(.forbidden, reason: "Assistant role required")
        }
        guard let gid = user.$group.id else {
            throw Abort(.badRequest, reason: "Assistant has no group")
        }
        let students = try await User.query(on: req.db)
            .filter(\.$group.$id == gid)
            .filter(\.$role == UserRole.student)
            .sort(\.$displayName)
            .all()
        return students.map {
            GroupStudentDTO(id: $0.id!, displayName: $0.displayName, email: $0.email)
        }
    }

    func studentSubjects(req: Request) async throws -> [StudentSubjectBriefDTO] {
        let assistant = try req.auth.require(User.self)
        guard assistant.role == .assistant else {
            throw Abort(.forbidden, reason: "Assistant role required")
        }
        guard let studentId = req.parameters.get("studentId"),
              let student = try await User.find(studentId, on: req.db),
              student.role == .student
        else {
            throw Abort(.notFound)
        }
        guard assistant.$group.id == student.$group.id else {
            throw Abort(.forbidden)
        }
        guard let gid = student.$group.id else {
            throw Abort(.badRequest)
        }
        let subjects = try await Subject.query(on: req.db)
            .filter(\.$group.$id == gid)
            .sort(\.$title)
            .all()
        return subjects.map {
            StudentSubjectBriefDTO(id: $0.id!, title: $0.title, credits: $0.credits)
        }
    }

    func grading(req: Request) async throws -> AssistantSubjectGradingDTO {
        let assistant = try req.auth.require(User.self)
        guard assistant.role == .assistant else {
            throw Abort(.forbidden, reason: "Assistant role required")
        }
        guard let studentId = req.parameters.get("studentId"),
              let subjectId = req.parameters.get("subjectId"),
              let student = try await User.find(studentId, on: req.db),
              let subject = try await Subject.find(subjectId, on: req.db)
        else {
            throw Abort(.notFound)
        }
        guard student.role == .student else {
            throw Abort(.notFound)
        }
        guard assistant.$group.id == student.$group.id, subject.$group.id == assistant.$group.id else {
            throw Abort(.forbidden)
        }
        let elements = try await GradeElement.query(on: req.db)
            .filter(\.$subject.$id == subjectId)
            .sort(\.$sortOrder)
            .all()
        let elementIds = elements.compactMap(\.id)
        let grades = try await StudentGrade.query(on: req.db)
            .filter(\.$student.$id == studentId)
            .filter(\.$gradeElement.$id ~~ elementIds)
            .all()
        let dtos = elements.map { el -> GradeElementDTO in
            let elid = el.id!
            let g = grades.first { $0.$gradeElement.id == elid }
            return GradeElementDTO(
                id: elid,
                title: el.title,
                weight: el.weight,
                mark: g?.mark ?? 0,
                comment: g?.comment
            )
        }
        return AssistantSubjectGradingDTO(
            studentId: studentId,
            subjectId: subjectId,
            title: subject.title,
            formulaText: subject.formulaText,
            elements: dtos
        )
    }

    func saveGrades(req: Request) async throws -> HTTPStatus {
        let assistant = try req.auth.require(User.self)
        guard assistant.role == .assistant else {
            throw Abort(.forbidden, reason: "Assistant role required")
        }
        guard let studentId = req.parameters.get("studentId"),
              let subjectId = req.parameters.get("subjectId"),
              let student = try await User.find(studentId, on: req.db),
              let subject = try await Subject.find(subjectId, on: req.db)
        else {
            throw Abort(.notFound)
        }
        guard student.role == .student else {
            throw Abort(.notFound)
        }
        guard assistant.$group.id == student.$group.id, subject.$group.id == assistant.$group.id else {
            throw Abort(.forbidden)
        }
        let body = try req.content.decode(GradeBatchUpdateRequest.self)
        let elements = try await GradeElement.query(on: req.db)
            .filter(\.$subject.$id == subjectId)
            .all()
        let elementById = Dictionary(uniqueKeysWithValues: elements.compactMap { el -> (String, GradeElement)? in
            guard let id = el.id else { return nil }
            return (id, el)
        })
        try await req.db.transaction { db in
            for patch in body.elements {
                guard elementById[patch.elementId] != nil else {
                    throw Abort(.badRequest, reason: "Unknown element \(patch.elementId)")
                }
                if let existing = try await StudentGrade.query(on: db)
                    .filter(\.$student.$id == studentId)
                    .filter(\.$gradeElement.$id == patch.elementId)
                    .first()
                {
                    existing.mark = patch.mark
                    existing.comment = patch.comment
                    try await existing.save(on: db)
                } else {
                    let row = StudentGrade(
                        studentID: studentId,
                        gradeElementID: patch.elementId,
                        mark: patch.mark,
                        comment: patch.comment
                    )
                    try await row.save(on: db)
                }
            }
            let updatedGrades = try await StudentGrade.query(on: db)
                .filter(\.$student.$id == studentId)
                .filter(\.$gradeElement.$id ~~ elements.compactMap(\.id))
                .all()
            let finalMark = GradeCalculation.finalMark(elements: elements, grades: updatedGrades)
            if let enrollment = try await Enrollment.query(on: db)
                .filter(\.$student.$id == studentId)
                .filter(\.$subject.$id == subjectId)
                .first()
            {
                enrollment.finalMark = finalMark
                try await enrollment.save(on: db)
            } else {
                let e = Enrollment(studentID: studentId, subjectID: subjectId, finalMark: finalMark)
                try await e.save(on: db)
            }
        }
        if let gid = assistant.$group.id {
            try await RankingController.invalidateCache(req: req, groupId: gid)
        }
        return .noContent
    }
}
