import json
from typing import Any

import redis.asyncio as redis

from app.config import settings

_client: redis.Redis | None = None


async def init_redis() -> None:
    global _client
    _client = redis.from_url(settings.redis_url, decode_responses=True)


async def close_redis() -> None:
    global _client
    if _client is not None:
        await _client.aclose()
        _client = None


def _require() -> redis.Redis:
    if _client is None:
        raise RuntimeError("Redis not initialized")
    return _client


async def invalidate_ranking_cache(group_id: str) -> None:
    await _require().delete(f"ranking:board:{group_id}")


async def get_cached_json(key: str) -> Any | None:
    raw = await _require().get(key)
    if raw is None:
        return None
    return json.loads(raw)


async def set_cached_json(key: str, value: Any, ttl_seconds: int) -> None:
    await _require().setex(key, ttl_seconds, json.dumps(value, ensure_ascii=False))
