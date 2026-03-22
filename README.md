# SmartDairy Server

REST API для приложения «дневник» на **FastAPI** + **PostgreSQL** (SQLAlchemy 2 async) + **Redis** (кэш рейтинга). Формат JSON — **snake_case**, как в iOS-клиенте.

## Требования

- Python 3.11+
- Docker (для Postgres и Redis) — или свои инстансы

## Запуск

1. Поднять БД и Redis:

   ```bash
   docker compose up -d
   ```

2. Виртуальное окружение и зависимости:

   ```bash
   python3 -m venv .venv
   source .venv/bin/activate   # Windows: .venv\Scripts\activate
   pip install -r requirements.txt
   ```

3. Переменные окружения (при необходимости скопировать и отредактировать):

   ```bash
   cp .env.example .env
   ```

4. Сервер:

   ```bash
   uvicorn app.main:app --host 0.0.0.0 --port 8080 --reload
   ```

Документация OpenAPI: `http://127.0.0.1:8080/docs`.

## Тестовые учётные записи

| Роль      | Email                       | Пароль            |
|-----------|-----------------------------|-------------------|
| Студент   | `student@smartdairy.test`   | `SmartDairy2025!` |
| Ассистент | `assistant@smartdairy.test` | `SmartDairy2025!` |

Дополнительно в сиде: студенты `s1`, `s2` (тот же пароль).

## Эндпоинты (`/api/v1/...`)

- `POST /auth/login`
- `POST /auth/logout` (Bearer)
- `GET /users/me` (Bearer)
- `GET /student/diary/summary` (Bearer, student)
- `GET /student/subjects/{subject_id}/detail` (Bearer, student)
- `GET /ranking/board` (Bearer)
- `GET /assistant/group/students` (Bearer, assistant)
- `GET /assistant/students/{student_id}/subjects` (Bearer, assistant)
- `GET /assistant/students/{student_id}/subjects/{subject_id}/grading` (Bearer, assistant)
- `PUT /assistant/students/{student_id}/subjects/{subject_id}/grades` (Bearer, assistant)

Справочник текстовых формул: `app/Resources/grading_formulas.json`.

## Публичный / LAN IP

Слушайте `0.0.0.0` (по умолчанию в `HOST`) и подключайте клиент к `http://<IP-адрес_машины>:8080`. Для устройства в той же Wi‑Fi сети используйте локальный IP Mac, не `127.0.0.1`.
