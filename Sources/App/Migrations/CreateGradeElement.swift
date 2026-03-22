import Fluent

struct CreateGradeElement: AsyncMigration {
    func prepare(on database: Database) async throws {
        try await database.schema(GradeElement.schema)
            .field("id", .string, .identifier(auto: false))
            .field("title", .string, .required)
            .field("weight", .float, .required)
            .field("sort_order", .int, .required)
            .field("subject_id", .string, .references(Subject.schema, .id, onDelete: .cascade))
            .create()
    }

    func revert(on database: Database) async throws {
        try await database.schema(GradeElement.schema).delete()
    }
}
