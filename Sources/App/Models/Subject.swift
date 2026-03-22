import Fluent
import Vapor

final class Subject: Model, Content, @unchecked Sendable {
    static let schema = "subjects"

    @ID(custom: "id", generatedBy: .user)
    var id: String?

    @Field(key: "title")
    var title: String

    @Field(key: "credits")
    var credits: Float

    @Field(key: "formula_text")
    var formulaText: String

    @Parent(key: "group_id")
    var group: Group

    @Children(for: \.$subject)
    var gradeElements: [GradeElement]

    init() {}

    init(id: String, title: String, credits: Float, formulaText: String, groupID: Group.IDValue) {
        self.id = id
        self.title = title
        self.credits = credits
        self.formulaText = formulaText
        self.$group.id = groupID
    }
}
