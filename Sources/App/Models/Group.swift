import Fluent
import Vapor

final class Group: Model, Content, @unchecked Sendable {
    static let schema = "groups"

    @ID(custom: "id", generatedBy: .user)
    var id: String?

    @Field(key: "title")
    var title: String

    @Field(key: "faculty")
    var faculty: String

    @Field(key: "grade")
    var grade: String

    @Children(for: \.$group)
    var users: [User]

    @Children(for: \.$group)
    var subjects: [Subject]

    init() {}

    init(id: String, title: String, faculty: String, grade: String) {
        self.id = id
        self.title = title
        self.faculty = faculty
        self.grade = grade
    }
}
