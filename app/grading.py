from app.models import GradeElement, StudentGrade


def final_mark(elements: list[GradeElement], grades: list[StudentGrade]) -> float:
    by_el: dict[str, float] = {}
    for g in grades:
        by_el[g.grade_element_id] = g.mark
    total = 0.0
    for el in elements:
        m = by_el.get(el.id, 0.0)
        total += el.weight * m
    return total
