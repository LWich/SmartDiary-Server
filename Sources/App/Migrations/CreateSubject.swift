import Fluent

struct CreateSubject: AsyncMigration {
    func prepare(on database: Database) async throws {
        try await database.schema(Subject.schema)
            .field("id", .string, .identifier(auto: false))
            .field("title", .string, .required)
            .field("credits", .float, .required)
            .field("formula_text", .string, .required)
            .field("group_id", .string, .references(Group.schema, .id, onDelete: .cascade))
            .create()
    }

    func revert(on database: Database) async throws {
        try await database.schema(Subject.schema).delete()
    }
}
