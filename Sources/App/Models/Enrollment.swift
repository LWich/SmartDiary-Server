import Fluent
import Vapor

final class Enrollment: Model, Content, @unchecked Sendable {
    static let schema = "enrollments"

    @ID()
    var id: UUID?

    @Parent(key: "student_id")
    var student: User

    @Parent(key: "subject_id")
    var subject: Subject

    @Field(key: "final_mark")
    var finalMark: Float

    init() {}

    init(id: UUID? = nil, studentID: User.IDValue, subjectID: Subject.IDValue, finalMark: Float) {
        self.id = id
        self.$student.id = studentID
        self.$subject.id = subjectID
        self.finalMark = finalMark
    }
}
