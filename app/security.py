from datetime import UTC, datetime, timedelta

from jose import JWTError, jwt
from passlib.context import CryptContext

from app.config import settings

pwd_context = CryptContext(schemes=["bcrypt"], deprecated="auto")


def verify_password(plain: str, hashed: str) -> bool:
    return pwd_context.verify(plain, hashed)


def hash_password(password: str) -> str:
    return pwd_context.hash(password)


def create_access_token(user_id: str) -> str:
    expire = datetime.now(UTC) + timedelta(days=settings.jwt_expire_days)
    payload = {"uid": user_id, "exp": int(expire.timestamp())}
    return jwt.encode(payload, settings.jwt_secret, algorithm=settings.jwt_algorithm)


def decode_token(token: str) -> str:
    try:
        payload = jwt.decode(token, settings.jwt_secret, algorithms=[settings.jwt_algorithm])
        uid = payload.get("uid")
        if not uid or not isinstance(uid, str):
            raise JWTError("missing uid")
        return uid
    except JWTError as e:
        raise ValueError(str(e)) from e
