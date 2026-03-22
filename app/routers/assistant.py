from typing import Annotated

from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession

from app.database import get_session
from app.deps import get_current_user
from app.redis_client import invalidate_ranking_cache
from app.grading import final_mark
from app.models import (
    Enrollment,
    GradeElement,
    StudentGrade,
    Subject,
    User,
    UserRole,
)
from app.schemas import (
    AssistantSubjectGradingDTO,
    GradeBatchUpdateRequest,
    GradeElementDTO,
    GroupStudentDTO,
    StudentSubjectBriefDTO,
)

router = APIRouter(tags=["assistant"])


@router.get("/assistant/group/students", response_model=list[GroupStudentDTO])
async def group_students(
    user: Annotated[User, Depends(get_current_user)],
    session: Annotated[AsyncSession, Depends(get_session)],
) -> list[GroupStudentDTO]:
    if user.role != UserRole.assistant:
        raise HTTPException(status_code=status.HTTP_403_FORBIDDEN, detail="Assistant role required")
    if not user.group_id:
        raise HTTPException(status_code=status.HTTP_400_BAD_REQUEST, detail="Assistant has no group")
    row = await session.execute(
        select(User)
        .where(User.group_id == user.group_id, User.role == UserRole.student)
        .order_by(User.display_name)
    )
    students = row.scalars().all()
    return [GroupStudentDTO(id=s.id, display_name=s.display_name, email=s.email) for s in students]


@router.get("/assistant/students/{student_id}/subjects", response_model=list[StudentSubjectBriefDTO])
async def student_subjects(
    student_id: str,
    assistant: Annotated[User, Depends(get_current_user)],
    session: Annotated[AsyncSession, Depends(get_session)],
) -> list[StudentSubjectBriefDTO]:
    if assistant.role != UserRole.assistant:
        raise HTTPException(status_code=status.HTTP_403_FORBIDDEN, detail="Assistant role required")
    s_row = await session.execute(select(User).where(User.id == student_id))
    student = s_row.scalar_one_or_none()
    if student is None or student.role != UserRole.student:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND)
    if assistant.group_id != student.group_id:
        raise HTTPException(status_code=status.HTTP_403_FORBIDDEN)
    if not student.group_id:
        raise HTTPException(status_code=status.HTTP_400_BAD_REQUEST)
    sub_row = await session.execute(
        select(Subject).where(Subject.group_id == student.group_id).order_by(Subject.title)
    )
    subs = sub_row.scalars().all()
    return [StudentSubjectBriefDTO(id=s.id, title=s.title, credits=s.credits) for s in subs]


@router.get("/assistant/students/{student_id}/subjects/{subject_id}/grading", response_model=AssistantSubjectGradingDTO)
async def grading(
    student_id: str,
    subject_id: str,
    assistant: Annotated[User, Depends(get_current_user)],
    session: Annotated[AsyncSession, Depends(get_session)],
) -> AssistantSubjectGradingDTO:
    if assistant.role != UserRole.assistant:
        raise HTTPException(status_code=status.HTTP_403_FORBIDDEN, detail="Assistant role required")
    st_row = await session.execute(select(User).where(User.id == student_id))
    student = st_row.scalar_one_or_none()
    su_row = await session.execute(select(Subject).where(Subject.id == subject_id))
    subject = su_row.scalar_one_or_none()
    if student is None or subject is None or student.role != UserRole.student:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND)
    if assistant.group_id != student.group_id or subject.group_id != assistant.group_id:
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
                StudentGrade.student_id == student_id,
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
    return AssistantSubjectGradingDTO(
        student_id=student_id,
        subject_id=subject_id,
        title=subject.title,
        formula_text=subject.formula_text,
        elements=dtos,
    )


@router.put("/assistant/students/{student_id}/subjects/{subject_id}/grades", status_code=status.HTTP_204_NO_CONTENT)
async def save_grades(
    student_id: str,
    subject_id: str,
    body: GradeBatchUpdateRequest,
    assistant: Annotated[User, Depends(get_current_user)],
    session: Annotated[AsyncSession, Depends(get_session)],
) -> None:
    if assistant.role != UserRole.assistant:
        raise HTTPException(status_code=status.HTTP_403_FORBIDDEN, detail="Assistant role required")
    st_row = await session.execute(select(User).where(User.id == student_id))
    student = st_row.scalar_one_or_none()
    su_row = await session.execute(select(Subject).where(Subject.id == subject_id))
    subject = su_row.scalar_one_or_none()
    if student is None or subject is None or student.role != UserRole.student:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND)
    if assistant.group_id != student.group_id or subject.group_id != assistant.group_id:
        raise HTTPException(status_code=status.HTTP_403_FORBIDDEN)
    el_row = await session.execute(select(GradeElement).where(GradeElement.subject_id == subject_id))
    elements = list(el_row.scalars().all())
    element_by_id = {e.id: e for e in elements}
    for patch in body.elements:
        if patch.element_id not in element_by_id:
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail=f"Unknown element {patch.element_id}",
            )
        ex_row = await session.execute(
            select(StudentGrade).where(
                StudentGrade.student_id == student_id,
                StudentGrade.grade_element_id == patch.element_id,
            )
        )
        existing = ex_row.scalar_one_or_none()
        if existing:
            existing.mark = patch.mark
            existing.comment = patch.comment
        else:
            session.add(
                StudentGrade(
                    student_id=student_id,
                    grade_element_id=patch.element_id,
                    mark=patch.mark,
                    comment=patch.comment,
                )
            )
    await session.flush()
    eids = [e.id for e in elements]
    g_row = await session.execute(
        select(StudentGrade).where(
            StudentGrade.student_id == student_id,
            StudentGrade.grade_element_id.in_(eids),
        )
    )
    updated_grades = list(g_row.scalars().all())
    fm = final_mark(elements, updated_grades)
    en_row = await session.execute(
        select(Enrollment).where(
            Enrollment.student_id == student_id,
            Enrollment.subject_id == subject_id,
        )
    )
    en = en_row.scalar_one_or_none()
    if en:
        en.final_mark = fm
    else:
        session.add(Enrollment(student_id=student_id, subject_id=subject_id, final_mark=fm))
    await session.commit()

    if assistant.group_id:
        await invalidate_ranking_cache(assistant.group_id)

    return None
