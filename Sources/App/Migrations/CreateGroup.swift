import Fluent

struct CreateGroup: AsyncMigration {
    func prepare(on database: Database) async throws {
        try await database.schema(Group.schema)
            .field("id", .string, .identifier(auto: false))
            .field("title", .string, .required)
            .field("faculty", .string, .required)
            .field("grade", .string, .required)
            .create()
    }

    func revert(on database: Database) async throws {
        try await database.schema(Group.schema).delete()
    }
}
