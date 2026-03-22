from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession

from app.grading import final_mark
from app.models import (
    Enrollment,
    GradeElement,
    Group,
    StudentGrade,
    Subject,
    User,
    UserRole,
)
from app.security import hash_password


def _seed_elements(subject_id: str, items: list[tuple[str, str, float, int]]) -> list[GradeElement]:
    return [
        GradeElement(id=i, title=t, weight=w, sort_order=o, subject_id=subject_id) for i, t, w, o in items
    ]


async def seed_if_empty(session: AsyncSession) -> None:
    r = await session.execute(select(User).limit(1))
    if r.scalar_one_or_none() is not None:
        return

    pwd = hash_password("SmartDairy2025!")
    group = Group(
        id="grp-bse-251",
        title="БПИ251",
        faculty="Бакалавриат — Программная инженерия",
        grade="1 курс — 2 семестр",
    )
    session.add(group)
    users = [
        User(
            id="u-student-1",
            email="student@smartdairy.test",
            password_hash=pwd,
            display_name="Студент Петров",
            role=UserRole.student,
            group_id=group.id,
        ),
        User(
            id="u-assist-1",
            email="assistant@smartdairy.test",
            password_hash=pwd,
            display_name="Ассистент Иванов",
            role=UserRole.assistant,
            group_id=group.id,
        ),
        User(
            id="s1",
            email="ivanova@smartdairy.test",
            password_hash=pwd,
            display_name="Иванова А.",
            role=UserRole.student,
            group_id=group.id,
        ),
        User(
            id="s2",
            email="petrov2@smartdairy.test",
            password_hash=pwd,
            display_name="Петров П.",
            role=UserRole.student,
            group_id=group.id,
        ),
    ]
    for u in users:
        session.add(u)

    gid = group.id
    eco = Subject(
        id="subj-eco",
        title="Экономика",
        credits=4.0,
        formula_text=(
            "0.13 * Тесты онлайн-курса + 0.29 * КР №1 (микро) + 0.29 * КР №2 (макро) + 0.29 * Семинары"
        ),
        group_id=gid,
    )
    dm = Subject(
        id="subj-dm",
        title="Дискретная математика",
        credits=4.0,
        formula_text="0.09 * ДЗ 2 + 0.105 * КР 1 + 0.105 * КР 2 + 0.7 * Э 2",
        group_id=gid,
    )
    hist = Subject(
        id="subj-hist",
        title="История России",
        credits=1.0,
        formula_text="0.21 * СмартЛМС + 0.29 * Семинар 1 + 0.29 * Семинар 2 + 0.21 * Экзамен",
        group_id=gid,
    )
    arch = Subject(
        id="subj-arch",
        title="Архитектура ЭВМ и язык ассемблера",
        credits=6.0,
        formula_text=(
            "Final = 0.08*ДЗ_1 + 0.08*ДЗ_2 + 0.08*ДЗ_3 + 0.08*ДЗ_4 + 0.08*ДЗ_5 + 0.15*КР_1 + 0.15*КР_2 + 0.3*ЭКЗ"
        ),
        group_id=gid,
    )
    alg = Subject(
        id="subj-alg",
        title="Алгебра",
        credits=4.0,
        formula_text=(
            "О1=0,27·Кр + 0,12·ИДЗ(среднее мод1–2) + 0,16·Сем + 0,45·Экз (2-й модуль, упрощённо в элементы контроля)"
        ),
        group_id=gid,
    )
    matan = Subject(
        id="subj-matan",
        title="Математический анализ",
        credits=4.0,
        formula_text=(
            "0,1·ДЗ + 0,1·Quiz + 0,1·Доп.листочки + 0,2·КР + 0,3·Устная часть экзамена + "
            "0,2·Письменная часть экзамена + 0,05·Активность на семинарах"
        ),
        group_id=gid,
    )
    for s in (eco, dm, hist, arch, alg, matan):
        session.add(s)

    eco_els = _seed_elements(
        eco.id,
        [
            ("eco-t", "Тесты онлайн-курса", 0.13, 0),
            ("eco-k1", "КР №1 (микро)", 0.29, 1),
            ("eco-k2", "КР №2 (макро)", 0.29, 2),
            ("eco-sem", "Семинары", 0.29, 3),
        ],
    )
    dm_els = _seed_elements(
        dm.id,
        [
            ("dm-dz", "ДЗ 2", 0.09, 0),
            ("dm-k1", "КР 1", 0.105, 1),
            ("dm-k2", "КР 2", 0.105, 2),
            ("dm-e", "Э 2", 0.7, 3),
        ],
    )
    hist_els = _seed_elements(
        hist.id,
        [
            ("hist-lms", "СмартЛМС", 0.21, 0),
            ("hist-s1", "Семинарские занятия (1)", 0.29, 1),
            ("hist-s2", "Семинарские занятия (2)", 0.29, 2),
            ("hist-ex", "Экзамен", 0.21, 3),
        ],
    )
    arch_els = _seed_elements(
        arch.id,
        [
            ("a1", "ДЗ_1", 0.08, 0),
            ("a2", "ДЗ_2", 0.08, 1),
            ("a3", "ДЗ_3", 0.08, 2),
            ("a4", "ДЗ_4", 0.08, 3),
            ("a5", "ДЗ_5", 0.08, 4),
            ("a6", "КР_1", 0.15, 5),
            ("a7", "КР_2", 0.15, 6),
            ("a8", "ЭКЗ", 0.3, 7),
        ],
    )
    alg_els = _seed_elements(
        alg.id,
        [
            ("alg-kr", "Контрольная (модуль)", 0.27, 0),
            ("alg-idz", "ИДЗ (среднее)", 0.12, 1),
            ("alg-sem", "Семинар", 0.16, 2),
            ("alg-ex", "Экзамен", 0.45, 3),
        ],
    )
    matan_els = _seed_elements(
        matan.id,
        [
            ("e1", "ДЗ", 0.1, 0),
            ("e2", "Quiz", 0.1, 1),
            ("e3", "Доп.листочки", 0.1, 2),
            ("e4", "КР", 0.2, 3),
            ("e5", "Устная часть экзамена", 0.3, 4),
            ("e6", "Письменная часть экзамена", 0.2, 5),
            ("e7", "Активность на семинарах", 0.05, 6),
        ],
    )
    for el in eco_els + dm_els + hist_els + arch_els + alg_els + matan_els:
        session.add(el)

    await session.flush()

    subjects = [eco, dm, hist, arch, alg, matan]
    marks_map: dict[str, list[float]] = {
        "subj-eco": [7.0, 8.0, 7.5, 7.2],
        "subj-dm": [6.0, 0.0, 0.0, 0.0],
        "subj-hist": [7.0, 8.0, 6.0, 6.5],
        "subj-arch": [5.2, 7.08, 2.2, 9.12, 10.0, 3.51, 8.23, 4.82],
        "subj-alg": [5.0, 6.0, 6.5, 7.0],
        "subj-matan": [8.0, 7.5, 6.0, 5.5, 6.0, 5.0, 8.0],
    }

    student_id = "u-student-1"
    await session.flush()
    for sub in subjects:
        sid = sub.id
        row_marks = marks_map.get(sid)
        el_row = await session.execute(
            select(GradeElement).where(GradeElement.subject_id == sid).order_by(GradeElement.sort_order)
        )
        elements = list(el_row.scalars().all())
        if not row_marks or len(row_marks) != len(elements):
            continue
        grades: list[StudentGrade] = []
        for el, m in zip(elements, row_marks):
            g = StudentGrade(student_id=student_id, grade_element_id=el.id, mark=m, comment=None)
            session.add(g)
            grades.append(g)
        await session.flush()
        fm = final_mark(elements, grades)
        session.add(Enrollment(student_id=student_id, subject_id=sid, final_mark=fm))

    for sid, fm in [
        ("subj-eco", 8.1),
        ("subj-dm", 9.0),
        ("subj-hist", 9.2),
        ("subj-arch", 9.5),
        ("subj-alg", 9.0),
        ("subj-matan", 9.3),
    ]:
        session.add(Enrollment(student_id="s1", subject_id=sid, final_mark=fm))
    for sid, fm in [
        ("subj-eco", 7.5),
        ("subj-dm", 8.5),
        ("subj-hist", 8.0),
        ("subj-arch", 8.0),
        ("subj-alg", 8.5),
        ("subj-matan", 8.5),
    ]:
        session.add(Enrollment(student_id="s2", subject_id=sid, final_mark=fm))
