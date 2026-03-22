import Fluent

struct CreateEnrollment: AsyncMigration {
    func prepare(on database: Database) async throws {
        try await database.schema(Enrollment.schema)
            .id()
            .field("student_id", .string, .references(User.schema, .id, onDelete: .cascade))
            .field("subject_id", .string, .references(Subject.schema, .id, onDelete: .cascade))
            .field("final_mark", .float, .required)
            .unique(on: "student_id", "subject_id")
            .create()
    }

    func revert(on database: Database) async throws {
        try await database.schema(Enrollment.schema).delete()
    }
}
