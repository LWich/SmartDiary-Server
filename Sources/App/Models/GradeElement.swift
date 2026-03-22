import Fluent
import Vapor

final class GradeElement: Model, Content, @unchecked Sendable {
    static let schema = "grade_elements"

    @ID(custom: "id", generatedBy: .user)
    var id: String?

    @Field(key: "title")
    var title: String

    @Field(key: "weight")
    var weight: Float

    @Field(key: "sort_order")
    var sortOrder: Int

    @Parent(key: "subject_id")
    var subject: Subject

    @Children(for: \.$gradeElement)
    var studentGrades: [StudentGrade]

    init() {}

    init(id: String, title: String, weight: Float, sortOrder: Int, subjectID: Subject.IDValue) {
        self.id = id
        self.title = title
        self.weight = weight
        self.sortOrder = sortOrder
        self.$subject.id = subjectID
    }
}
