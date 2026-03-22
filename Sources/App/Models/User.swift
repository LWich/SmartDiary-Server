import Fluent
import Vapor

enum UserRole: String, Codable, Sendable {
    case student
    case assistant
}

final class User: Model, Content, @unchecked Sendable {
    static let schema = "users"

    @ID(custom: "id", generatedBy: .user)
    var id: String?

    @Field(key: "email")
    var email: String

    @Field(key: "password_hash")
    var passwordHash: String

    @Field(key: "display_name")
    var displayName: String

    @Field(key: "role")
    var role: UserRole

    @OptionalParent(key: "group_id")
    var group: Group?

    @Timestamp(key: "created_at", on: .create)
    var createdAt: Date?

    @Timestamp(key: "updated_at", on: .update)
    var updatedAt: Date?

    init() {}

    init(
        id: String,
        email: String,
        passwordHash: String,
        displayName: String,
        role: UserRole,
        groupID: Group.IDValue?
    ) {
        self.id = id
        self.email = email
        self.passwordHash = passwordHash
        self.displayName = displayName
        self.role = role
        self.$group.id = groupID
    }
}

extension User: Authenticatable {}
