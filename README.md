# SmartDairy Server

REST API на [Vapor 4](https://vapor.codes) с PostgreSQL (Fluent), JWT (Bearer) и кэшем рейтинга в Redis. Форматы JSON — **snake_case**, как в iOS-клиенте (`JSONEncoder`/`JSONDecoder` с `convertToSnakeCase`).

## Запуск

1. Поднять PostgreSQL и Redis:

   ```bash
   docker compose up -d
   ```

2. Скопировать переменные окружения (при необходимости отредактировать):

   ```bash
   cp .env.example .env
   ```

3. Собрать и запустить:

   ```bash
   swift run SmartDairyServer
   ```

По умолчанию сервер слушает `http://127.0.0.1:8080` (см. `HOST` / `PORT` в `.env`).

## Тестовые учётные записи

| Роль      | Email                     | Пароль            |
|-----------|---------------------------|-------------------|
| Студент   | `student@smartdairy.test` | `SmartDairy2025!` |
| Ассистент | `assistant@smartdairy.test` | `SmartDairy2025!` |

В сиде также есть студенты `s1`, `s2` (для демонстрации рейтинга); у них тот же пароль.

## Эндпоинты (совместимость с iOS)

- `POST /api/v1/auth/login`
- `POST /api/v1/auth/logout` (Bearer)
- `GET /api/v1/users/me` (Bearer)
- `GET /api/v1/student/diary/summary` (Bearer, роль student)
- `GET /api/v1/student/subjects/:subjectId/detail` (Bearer, student)
- `GET /api/v1/ranking/board` (Bearer)
- `GET /api/v1/assistant/group/students` (Bearer, assistant)
- `GET /api/v1/assistant/students/:studentId/subjects` (Bearer, assistant)
- `GET /api/v1/assistant/students/:studentId/subjects/:subjectId/grading` (Bearer, assistant)
- `PUT /api/v1/assistant/students/:studentId/subjects/:subjectId/grades` (Bearer, assistant)

Итоговая оценка по предмету хранится в таблице `enrollments` и пересчитывается при сохранении оценок ассистентом как \(\sum_i w_i \cdot m_i\) по элементам контроля.

## Справочник формул

Текстовые формулы из учебных планов лежат в ресурсе `Sources/App/Resources/grading_formulas.json` (можно использовать как справочник; расчёт в API — по весам и баллам в БД).
