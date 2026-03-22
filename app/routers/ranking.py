from typing import Annotated

from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession

from app.database import get_session
from app.deps import get_current_user
from app.models import Enrollment, Subject, User, UserRole
from app.redis_client import get_cached_json, set_cached_json
from app.schemas import RankingBoardDTO, RankingEntryDTO

router = APIRouter(tags=["ranking"])

CACHE_TTL = 60


@router.get("/ranking/board", response_model=RankingBoardDTO)
async def board(
    user: Annotated[User, Depends(get_current_user)],
    session: Annotated[AsyncSession, Depends(get_session)],
) -> RankingBoardDTO:
    if not user.group_id:
        raise HTTPException(status_code=status.HTTP_400_BAD_REQUEST, detail="No group")
    key = f"ranking:board:{user.group_id}"
    cached = await get_cached_json(key)
    if cached is not None:
        return RankingBoardDTO.model_validate(cached)
    st_row = await session.execute(
        select(User).where(User.group_id == user.group_id, User.role == UserRole.student)
    )
    students = list(st_row.scalars().all())
    sub_row = await session.execute(select(Subject).where(Subject.group_id == user.group_id))
    subjects = list(sub_row.scalars().all())
    entries: list[tuple[User, float]] = []
    for s in students:
        weighted = 0.0
        for sub in subjects:
            en_row = await session.execute(
                select(Enrollment).where(
                    Enrollment.student_id == s.id,
                    Enrollment.subject_id == sub.id,
                )
            )
            en = en_row.scalar_one_or_none()
            if en:
                weighted += sub.credits * en.final_mark
        entries.append((s, weighted))
    entries.sort(key=lambda x: x[1], reverse=True)
    dtos: list[RankingEntryDTO] = []
    for idx, (stu, sm) in enumerate(entries):
        dtos.append(
            RankingEntryDTO(
                id=f"r-{stu.id}",
                student_id=stu.id,
                display_name=stu.display_name,
                weighted_sum=sm,
                rank=idx + 1,
            )
        )
    board_dto = RankingBoardDTO(entries=dtos)
    await set_cached_json(key, board_dto.model_dump(), CACHE_TTL)
    return board_dto
