import Fluent
import Vapor

struct StudentController {
    func diarySummary(req: Request) async throws -> DiarySummaryDTO {
        let user = try req.auth.require(User.self)
        guard user.role == UserRole.student else {
            throw Abort(.forbidden, reason: "Student role required")
        }
        guard let groupId = user.$group.id else {
            throw Abort(.badRequest, reason: "User has no group")
        }
        try await user.$group.load(on: req.db)
        guard let group = user.group else {
            throw Abort(.internalServerError)
        }
        let subjects = try await Subject.query(on: req.db)
            .filter(\.$group.$id == groupId)
            .sort(\.$title)
            .all()
        var disciplines: [DisciplineSummaryDTO] = []
        for subject in subjects {
            let enrollment = try await Enrollment.query(on: req.db)
                .filter(\.$student.$id == user.id!)
                .filter(\.$subject.$id == subject.id!)
                .first()
            let finalMark = enrollment?.finalMark ?? 0
            disciplines.append(
                DisciplineSummaryDTO(
                    id: subject.id!,
                    title: subject.title,
                    credits: subject.credits,
                    finalMark: finalMark
                )
            )
        }
        return DiarySummaryDTO(
            faculty: group.faculty,
            grade: group.grade,
            disciplines: disciplines
        )
    }

    func subjectDetail(req: Request) async throws -> SubjectDetailDTO {
        let user = try req.auth.require(User.self)
        guard user.role == UserRole.student else {
            throw Abort(.forbidden, reason: "Student role required")
        }
        guard let subjectId = req.parameters.get("subjectId") else {
            throw Abort(.badRequest)
        }
        guard let subject = try await Subject.find(subjectId, on: req.db) else {
            throw Abort(.notFound)
        }
        guard let groupId = user.$group.id, subject.$group.id == groupId else {
            throw Abort(.forbidden)
        }
        let elements = try await GradeElement.query(on: req.db)
            .filter(\.$subject.$id == subjectId)
            .sort(\.$sortOrder)
            .all()
        let elementIds = elements.compactMap(\.id)
        let grades = try await StudentGrade.query(on: req.db)
            .filter(\.$student.$id == user.id!)
            .filter(\.$gradeElement.$id ~~ elementIds)
            .all()
        let dtos = elements.map { el -> GradeElementDTO in
            let elid = el.id!
            let g = grades.first { $0.$gradeElement.id == elid }
            return GradeElementDTO(
                id: el.id!,
                title: el.title,
                weight: el.weight,
                mark: g?.mark ?? 0,
                comment: g?.comment
            )
        }
        let finalMark = GradeCalculation.finalMark(elements: elements, grades: grades)
        return SubjectDetailDTO(
            subjectId: subject.id!,
            title: subject.title,
            formulaText: subject.formulaText,
            finalMark: finalMark,
            elements: dtos
        )
    }
}
