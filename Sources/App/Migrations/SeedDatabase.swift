import Fluent
import Vapor

struct SeedDatabase: AsyncMigration {
    func prepare(on database: Database) async throws {
        let group = Group(
            id: "grp-bse-251",
            title: "БПИ251",
            faculty: "Бакалавриат — Программная инженерия",
            grade: "1 курс — 2 семестр"
        )
        try await group.save(on: database)

        let studentHash = try Bcrypt.hash("SmartDairy2025!")
        let assistantHash = try Bcrypt.hash("SmartDairy2025!")

        let student = User(
            id: "u-student-1",
            email: "student@smartdairy.test",
            passwordHash: studentHash,
            displayName: "Студент Петров",
            role: .student,
            groupID: group.id!
        )
        let assistant = User(
            id: "u-assist-1",
            email: "assistant@smartdairy.test",
            passwordHash: assistantHash,
            displayName: "Ассистент Иванов",
            role: .assistant,
            groupID: group.id!
        )
        let ivanova = User(
            id: "s1",
            email: "ivanova@smartdairy.test",
            passwordHash: studentHash,
            displayName: "Иванова А.",
            role: .student,
            groupID: group.id!
        )
        let petrov2 = User(
            id: "s2",
            email: "petrov2@smartdairy.test",
            passwordHash: studentHash,
            displayName: "Петров П.",
            role: .student,
            groupID: group.id!
        )
        try await student.save(on: database)
        try await assistant.save(on: database)
        try await ivanova.save(on: database)
        try await petrov2.save(on: database)

        let gid = group.id!

        let eco = Subject(
            id: "subj-eco",
            title: "Экономика",
            credits: 4,
            formulaText:
                "0.13 * Тесты онлайн-курса + 0.29 * КР №1 (микро) + 0.29 * КР №2 (макро) + 0.29 * Семинары",
            groupID: gid
        )
        let dm = Subject(
            id: "subj-dm",
            title: "Дискретная математика",
            credits: 4,
            formulaText: "0.09 * ДЗ 2 + 0.105 * КР 1 + 0.105 * КР 2 + 0.7 * Э 2",
            groupID: gid
        )
        let hist = Subject(
            id: "subj-hist",
            title: "История России",
            credits: 1,
            formulaText:
                "0.21 * СмартЛМС + 0.29 * Семинар 1 + 0.29 * Семинар 2 + 0.21 * Экзамен",
            groupID: gid
        )
        let arch = Subject(
            id: "subj-arch",
            title: "Архитектура ЭВМ и язык ассемблера",
            credits: 6,
            formulaText:
                "Final = 0.08*ДЗ_1 + 0.08*ДЗ_2 + 0.08*ДЗ_3 + 0.08*ДЗ_4 + 0.08*ДЗ_5 + 0.15*КР_1 + 0.15*КР_2 + 0.3*ЭКЗ",
            groupID: gid
        )
        let alg = Subject(
            id: "subj-alg",
            title: "Алгебра",
            credits: 4,
            formulaText:
                "О1=0,27·Кр + 0,12·ИДЗ(среднее мод1–2) + 0,16·Сем + 0,45·Экз (2-й модуль, упрощённо в элементы контроля)",
            groupID: gid
        )
        let matan = Subject(
            id: "subj-matan",
            title: "Математический анализ",
            credits: 4,
            formulaText:
                "0,1·ДЗ + 0,1·Quiz + 0,1·Доп.листочки + 0,2·КР + 0,3·Устная часть экзамена + 0,2·Письменная часть экзамена + 0,05·Активность на семинарах",
            groupID: gid
        )
        try await eco.save(on: database)
        try await dm.save(on: database)
        try await hist.save(on: database)
        try await arch.save(on: database)
        try await alg.save(on: database)
        try await matan.save(on: database)

        let ecoEls: [(String, String, Float, Int)] = [
            ("eco-t", "Тесты онлайн-курса", 0.13, 0),
            ("eco-k1", "КР №1 (микро)", 0.29, 1),
            ("eco-k2", "КР №2 (макро)", 0.29, 2),
            ("eco-sem", "Семинары", 0.29, 3)
        ]
        try await seedElements(on: database, subjectId: eco.id!, items: ecoEls)

        let dmEls: [(String, String, Float, Int)] = [
            ("dm-dz", "ДЗ 2", 0.09, 0),
            ("dm-k1", "КР 1", 0.105, 1),
            ("dm-k2", "КР 2", 0.105, 2),
            ("dm-e", "Э 2", 0.7, 3)
        ]
        try await seedElements(on: database, subjectId: dm.id!, items: dmEls)

        let histEls: [(String, String, Float, Int)] = [
            ("hist-lms", "СмартЛМС", 0.21, 0),
            ("hist-s1", "Семинарские занятия (1)", 0.29, 1),
            ("hist-s2", "Семинарские занятия (2)", 0.29, 2),
            ("hist-ex", "Экзамен", 0.21, 3)
        ]
        try await seedElements(on: database, subjectId: hist.id!, items: histEls)

        let archEls: [(String, String, Float, Int)] = [
            ("a1", "ДЗ_1", 0.08, 0),
            ("a2", "ДЗ_2", 0.08, 1),
            ("a3", "ДЗ_3", 0.08, 2),
            ("a4", "ДЗ_4", 0.08, 3),
            ("a5", "ДЗ_5", 0.08, 4),
            ("a6", "КР_1", 0.15, 5),
            ("a7", "КР_2", 0.15, 6),
            ("a8", "ЭКЗ", 0.3, 7)
        ]
        try await seedElements(on: database, subjectId: arch.id!, items: archEls)

        let algEls: [(String, String, Float, Int)] = [
            ("alg-kr", "Контрольная (модуль)", 0.27, 0),
            ("alg-idz", "ИДЗ (среднее)", 0.12, 1),
            ("alg-sem", "Семинар", 0.16, 2),
            ("alg-ex", "Экзамен", 0.45, 3)
        ]
        try await seedElements(on: database, subjectId: alg.id!, items: algEls)

        let matanEls: [(String, String, Float, Int)] = [
            ("e1", "ДЗ", 0.1, 0),
            ("e2", "Quiz", 0.1, 1),
            ("e3", "Доп.листочки", 0.1, 2),
            ("e4", "КР", 0.2, 3),
            ("e5", "Устная часть экзамена", 0.3, 4),
            ("e6", "Письменная часть экзамена", 0.2, 5),
            ("e7", "Активность на семинарах", 0.05, 6)
        ]
        try await seedElements(on: database, subjectId: matan.id!, items: matanEls)

        let subjects = [eco, dm, hist, arch, alg, matan]

        try await seedStudentFull(
            on: database,
            studentId: student.id!,
            subjects: subjects,
            marks: [
                "subj-eco": [7.0, 8.0, 7.5, 7.2],
                "subj-dm": [6.0, 0, 0, 0],
                "subj-hist": [7.0, 8.0, 6.0, 6.5],
                "subj-arch": [5.2, 7.08, 2.2, 9.12, 10, 3.51, 8.23, 4.82],
                "subj-alg": [5.0, 6.0, 6.5, 7.0],
                "subj-matan": [8, 7.5, 6, 5.5, 6, 5, 8]
            ]
        )

        try await enrollmentOnly(
            on: database,
            studentId: ivanova.id!,
            values: [
                ("subj-eco", 8.1),
                ("subj-dm", 9.0),
                ("subj-hist", 9.2),
                ("subj-arch", 9.5),
                ("subj-alg", 9.0),
                ("subj-matan", 9.3)
            ]
        )
        try await enrollmentOnly(
            on: database,
            studentId: petrov2.id!,
            values: [
                ("subj-eco", 7.5),
                ("subj-dm", 8.5),
                ("subj-hist", 8.0),
                ("subj-arch", 8.0),
                ("subj-alg", 8.5),
                ("subj-matan", 8.5)
            ]
        )
    }

    func revert(on database: Database) async throws {}

    private func seedElements(
        on database: Database,
        subjectId: String,
        items: [(String, String, Float, Int)]
    ) async throws {
        for (id, title, weight, order) in items {
            let ge = GradeElement(id: id, title: title, weight: weight, sortOrder: order, subjectID: subjectId)
            try await ge.save(on: database)
        }
    }

    private func seedStudentFull(
        on database: Database,
        studentId: String,
        subjects: [Subject],
        marks: [String: [Float]]
    ) async throws {
        for subject in subjects {
            let sid = subject.id!
            let elements = try await GradeElement.query(on: database)
                .filter(\.$subject.$id == sid)
                .sort(\.$sortOrder)
                .all()
            guard let rowMarks = marks[sid], rowMarks.count == elements.count else {
                continue
            }
            var grades: [StudentGrade] = []
            for (el, m) in zip(elements, rowMarks) {
                let g = StudentGrade(studentID: studentId, gradeElementID: el.id!, mark: m, comment: nil)
                try await g.save(on: database)
                grades.append(g)
            }
            let final = GradeCalculation.finalMark(elements: elements, grades: grades)
            let en = Enrollment(studentID: studentId, subjectID: sid, finalMark: final)
            try await en.save(on: database)
        }
    }

    private func enrollmentOnly(
        on database: Database,
        studentId: String,
        values: [(String, Float)]
    ) async throws {
        for (subId, final) in values {
            let en = Enrollment(studentID: studentId, subjectID: subId, finalMark: final)
            try await en.save(on: database)
        }
    }
}
