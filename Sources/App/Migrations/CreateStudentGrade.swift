import Fluent

struct CreateStudentGrade: AsyncMigration {
    func prepare(on database: Database) async throws {
        try await database.schema(StudentGrade.schema)
            .id()
            .field("student_id", .string, .references(User.schema, .id, onDelete: .cascade))
            .field("grade_element_id", .string, .references(GradeElement.schema, .id, onDelete: .cascade))
            .field("mark", .float, .required)
            .field("comment", .string)
            .unique(on: "student_id", "grade_element_id")
            .create()
    }

    func revert(on database: Database) async throws {
        try await database.schema(StudentGrade.schema).delete()
    }
}
