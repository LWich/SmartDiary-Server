from typing import Annotated

from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy.orm import selectinload

from app.database import get_session
from app.deps import get_current_user
from app.grading import final_mark
from app.models import Enrollment, GradeElement, StudentGrade, Subject, User, UserRole
from app.schemas import DiarySummaryDTO, DisciplineSummaryDTO, GradeElementDTO, SubjectDetailDTO

router = APIRouter(tags=["student"])


@router.get("/student/diary/summary", response_model=DiarySummaryDTO)
async def diary_summary(
    user: Annotated[User, Depends(get_current_user)],
    session: Annotated[AsyncSession, Depends(get_session)],
) -> DiarySummaryDTO:
    if user.role != UserRole.student:
        raise HTTPException(status_code=status.HTTP_403_FORBIDDEN, detail="Student role required")
    if not user.group_id:
        raise HTTPException(status_code=status.HTTP_400_BAD_REQUEST, detail="User has no group")
    result = await session.execute(select(User).where(User.id == user.id).options(selectinload(User.group)))
    u = result.scalar_one()
    group = u.group
    if group is None:
        raise HTTPException(status_code=status.HTTP_500_INTERNAL_SERVER_ERROR)
    subj_result = await session.execute(
        select(Subject).where(Subject.group_id == user.group_id).order_by(Subject.title)
    )
    subjects = subj_result.scalars().all()
    disciplines: list[DisciplineSummaryDTO] = []
    for sub in subjects:
        en_row = await session.execute(
            select(Enrollment).where(
                Enrollment.student_id == user.id,
                Enrollment.subject_id == sub.id,
            )
        )
        en = en_row.scalar_one_or_none()
        fm = float(en.final_mark) if en else 0.0
        disciplines.append(
            DisciplineSummaryDTO(
                id=sub.id,
                title=sub.title,
                credits=sub.credits,
                final_mark=fm,
            )
        )
    return DiarySummaryDTO(faculty=group.faculty, grade=group.grade, disciplines=disciplines)


@router.get("/student/subjects/{subject_id}/detail", response_model=SubjectDetailDTO)
async def subject_detail(
    subject_id: str,
    user: Annotated[User, Depends(get_current_user)],
    session: Annotated[AsyncSession, Depends(get_session)],
) -> SubjectDetailDTO:
    if user.role != UserRole.student:
        raise HTTPException(status_code=status.HTTP_403_FORBIDDEN, detail="Student role required")
    sub_row = await session.execute(select(Subject).where(Subject.id == subject_id))
    subject = sub_row.scalar_one_or_none()
    if subject is None:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND)
    if user.group_id != subject.group_id:
        raise HTTPException(status_code=status.HTTP_403_FORBIDDEN)
    el_row = await session.execute(
        select(GradeElement).where(GradeElement.subject_id == subject_id).order_by(GradeElement.sort_order)
    )
    elements = list(el_row.scalars().all())
    eids = [e.id for e in elements]
    if not eids:
        grades = []
    else:
        g_row = await session.execute(
            select(StudentGrade).where(
                StudentGrade.student_id == user.id,
                StudentGrade.grade_element_id.in_(eids),
            )
        )
        grades = list(g_row.scalars().all())
    by_el = {g.grade_element_id: g for g in grades}
    dtos = [
        GradeElementDTO(
            id=el.id,
            title=el.title,
            weight=el.weight,
            mark=by_el[el.id].mark if el.id in by_el else 0.0,
            comment=by_el[el.id].comment if el.id in by_el else None,
        )
        for el in elements
    ]
    fm = final_mark(elements, grades)
    return SubjectDetailDTO(
        subject_id=subject.id,
        title=subject.title,
        formula_text=subject.formula_text,
        final_mark=fm,
        elements=dtos,
    )
