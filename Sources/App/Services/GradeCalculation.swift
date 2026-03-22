import Fluent
import Vapor

enum GradeCalculation {
    static func finalMark(elements: [GradeElement], grades: [StudentGrade]) -> Float {
        var byElement: [String: Float] = [:]
        for g in grades {
            let eid = g.$gradeElement.id
            byElement[eid] = g.mark
        }
        var sum: Float = 0
        for el in elements {
            let mark = byElement[el.id!] ?? 0
            sum += el.weight * mark
        }
        return sum
    }
}
