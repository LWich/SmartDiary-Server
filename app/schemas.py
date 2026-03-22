from pydantic import BaseModel, ConfigDict


class AuthLoginRequest(BaseModel):
    model_config = ConfigDict(extra="forbid")
    email: str
    password: str


class UserProfileDTO(BaseModel):
    model_config = ConfigDict(from_attributes=True)
    id: str
    email: str
    display_name: str
    role: str
    group_id: str | None
    group_title: str | None


class AuthLoginResponse(BaseModel):
    access_token: str
    token_type: str
    user: UserProfileDTO


class DisciplineSummaryDTO(BaseModel):
    id: str
    title: str
    credits: float
    final_mark: float


class DiarySummaryDTO(BaseModel):
    faculty: str
    grade: str
    disciplines: list[DisciplineSummaryDTO]


class GradeElementDTO(BaseModel):
    id: str
    title: str
    weight: float
    mark: float
    comment: str | None


class SubjectDetailDTO(BaseModel):
    subject_id: str
    title: str
    formula_text: str
    final_mark: float
    elements: list[GradeElementDTO]


class RankingEntryDTO(BaseModel):
    id: str
    student_id: str
    display_name: str
    weighted_sum: float
    rank: int


class RankingBoardDTO(BaseModel):
    entries: list[RankingEntryDTO]


class GroupStudentDTO(BaseModel):
    id: str
    display_name: str
    email: str


class StudentSubjectBriefDTO(BaseModel):
    id: str
    title: str
    credits: float


class AssistantSubjectGradingDTO(BaseModel):
    student_id: str
    subject_id: str
    title: str
    formula_text: str
    elements: list[GradeElementDTO]


class GradeElementPatchDTO(BaseModel):
    element_id: str
    mark: float
    comment: str | None = None


class GradeBatchUpdateRequest(BaseModel):
    elements: list[GradeElementPatchDTO]
