import Fluent

struct CreateUser: AsyncMigration {
    func prepare(on database: Database) async throws {
        try await database.schema(User.schema)
            .field("id", .string, .identifier(auto: false))
            .field("email", .string, .required)
            .field("password_hash", .string, .required)
            .field("display_name", .string, .required)
            .field("role", .string, .required)
            .field("group_id", .string, .references(Group.schema, .id, onDelete: .setNull))
            .unique(on: "email")
            .create()
    }

    func revert(on database: Database) async throws {
        try await database.schema(User.schema).delete()
    }
}
