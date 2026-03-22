from contextlib import asynccontextmanager

from fastapi import FastAPI

from app.config import settings
from app.database import async_session_maker, engine
from app.models import Base
from app.redis_client import close_redis, init_redis
from app.routers import assistant, auth, ranking, student
from app.seed import seed_if_empty


@asynccontextmanager
async def lifespan(_app: FastAPI):
    async with engine.begin() as conn:
        await conn.run_sync(Base.metadata.create_all)
    await init_redis()
    async with async_session_maker() as session:
        await seed_if_empty(session)
        await session.commit()
    yield
    await close_redis()
    await engine.dispose()


app = FastAPI(title="SmartDairy API", lifespan=lifespan)

app.include_router(auth.router, prefix="/api/v1")
app.include_router(student.router, prefix="/api/v1")
app.include_router(assistant.router, prefix="/api/v1")
app.include_router(ranking.router, prefix="/api/v1")
