from pydantic_settings import BaseSettings, SettingsConfigDict


class Settings(BaseSettings):
    model_config = SettingsConfigDict(env_file=".env", env_file_encoding="utf-8", extra="ignore")

    database_host: str = "localhost"
    database_port: int = 5432
    database_username: str = "smartdairy"
    database_password: str = "smartdairy"
    database_name: str = "smartdairy"

    redis_host: str = "localhost"
    redis_port: int = 6379

    jwt_secret: str = "dev-only-secret-change-me-in-production-min-32-chars!!"
    jwt_algorithm: str = "HS256"
    jwt_expire_days: int = 7

    host: str = "0.0.0.0"
    port: int = 8080

    @property
    def database_url(self) -> str:
        return (
            f"postgresql+asyncpg://{self.database_username}:{self.database_password}"
            f"@{self.database_host}:{self.database_port}/{self.database_name}"
        )

    @property
    def redis_url(self) -> str:
        return f"redis://{self.redis_host}:{self.redis_port}/0"


settings = Settings()
