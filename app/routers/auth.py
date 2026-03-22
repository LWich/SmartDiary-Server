from typing import Annotated

from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy.orm import selectinload

from app.database import get_session
from app.deps import get_current_user
from app.models import User
from app.schemas import AuthLoginRequest, AuthLoginResponse, UserProfileDTO
from app.security import create_access_token, verify_password

router = APIRouter(tags=["auth"])


def _profile(user: User) -> UserProfileDTO:
    g = user.group
    return UserProfileDTO(
        id=user.id,
        email=user.email,
        display_name=user.display_name,
        role=user.role.value,
        group_id=user.group_id,
        group_title=g.title if g else None,
    )


@router.post("/auth/login", response_model=AuthLoginResponse)
async def login(
    body: AuthLoginRequest,
    session: Annotated[AsyncSession, Depends(get_session)],
) -> AuthLoginResponse:
    email = body.email.lower().strip()
    result = await session.execute(select(User).where(User.email == email).options(selectinload(User.group)))
    user = result.scalar_one_or_none()
    if user is None or not verify_password(body.password, user.password_hash):
        raise HTTPException(status_code=status.HTTP_401_UNAUTHORIZED, detail="Invalid credentials")
    token = create_access_token(user.id)
    return AuthLoginResponse(access_token=token, token_type="bearer", user=_profile(user))


@router.post("/auth/logout", status_code=status.HTTP_204_NO_CONTENT)
async def logout(
    _user: Annotated[User, Depends(get_current_user)],
) -> None:
    return None


@router.get("/users/me", response_model=UserProfileDTO)
async def me(
    user: Annotated[User, Depends(get_current_user)],
    session: Annotated[AsyncSession, Depends(get_session)],
) -> UserProfileDTO:
    result = await session.execute(select(User).where(User.id == user.id).options(selectinload(User.group)))
    u = result.scalar_one()
    return _profile(u)
