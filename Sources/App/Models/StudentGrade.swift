import Fluent
import Vapor

final class StudentGrade: Model, Content, @unchecked Sendable {
    static let schema = "student_grades"

    @ID()
    var id: UUID?

    @Parent(key: "student_id")
    var student: User

    @Parent(key: "grade_element_id")
    var gradeElement: GradeElement

    @Field(key: "mark")
    var mark: Float

    @OptionalField(key: "comment")
    var comment: String?

    init() {}

    init(
        id: UUID? = nil,
        studentID: User.IDValue,
        gradeElementID: GradeElement.IDValue,
        mark: Float,
        comment: String?
    ) {
        self.id = id
        self.$student.id = studentID
        self.$gradeElement.id = gradeElementID
        self.mark = mark
        self.comment = comment
    }
}
