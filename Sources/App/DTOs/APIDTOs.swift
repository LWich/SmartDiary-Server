import Vapor

struct AuthLoginRequest: Content {
    let email: String
    let password: String
}

struct AuthLoginResponse: Content {
    let accessToken: String
    let tokenType: String
    let user: UserProfileDTO
}

struct UserProfileDTO: Content {
    let id: String
    let email: String
    let displayName: String
    let role: String
    let groupId: String?
    let groupTitle: String?
}

struct DiarySummaryDTO: Content {
    let faculty: String
    let grade: String
    let disciplines: [DisciplineSummaryDTO]
}

struct DisciplineSummaryDTO: Content {
    let id: String
    let title: String
    let credits: Float
    let finalMark: Float
}

struct SubjectDetailDTO: Content {
    let subjectId: String
    let title: String
    let formulaText: String
    let finalMark: Float
    let elements: [GradeElementDTO]
}

struct GradeElementDTO: Content {
    let id: String
    let title: String
    let weight: Float
    let mark: Float
    let comment: String?
}

struct RankingBoardDTO: Content {
    let entries: [RankingEntryDTO]
}

struct RankingEntryDTO: Content {
    let id: String
    let studentId: String
    let displayName: String
    let weightedSum: Float
    let rank: Int
}

struct GroupStudentDTO: Content {
    let id: String
    let displayName: String
    let email: String
}

struct StudentSubjectBriefDTO: Content {
    let id: String
    let title: String
    let credits: Float
}

struct AssistantSubjectGradingDTO: Content {
    let studentId: String
    let subjectId: String
    let title: String
    let formulaText: String
    let elements: [GradeElementDTO]
}

struct GradeBatchUpdateRequest: Content {
    let elements: [GradeElementPatchDTO]
}

struct GradeElementPatchDTO: Content {
    let elementId: String
    let mark: Float
    let comment: String?
}

struct APIErrorResponse: Content {
    let error: String
    let message: String?
}
