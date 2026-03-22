import Fluent
import Vapor

public func routes(_ app: Application) throws {
    let auth = AuthController()
    let student = StudentController()
    let assistant = AssistantController()
    let ranking = RankingController()

    let v1 = app.grouped("api", "v1")

    let authRoutes = v1.grouped("auth")
    authRoutes.post("login", use: auth.login)
    let tokenProtected = v1.grouped(JWTUserAuthenticator())
        .grouped(User.guardMiddleware())
    tokenProtected.post("auth", "logout", use: auth.logout)

    tokenProtected.get("users", "me", use: auth.me)

    tokenProtected.get("student", "diary", "summary", use: student.diarySummary)
    tokenProtected.get("student", "subjects", ":subjectId", "detail", use: student.subjectDetail)

    tokenProtected.get("ranking", "board", use: ranking.board)

    tokenProtected.get("assistant", "group", "students", use: assistant.groupStudents)
    tokenProtected.get("assistant", "students", ":studentId", "subjects", use: assistant.studentSubjects)
    tokenProtected.get(
        "assistant", "students", ":studentId", "subjects", ":subjectId", "grading",
        use: assistant.grading
    )
    tokenProtected.put(
        "assistant", "students", ":studentId", "subjects", ":subjectId", "grades",
        use: assistant.saveGrades
    )
}
