import Fluent
import Redis
import Vapor

struct RankingController {
    private static let cacheSeconds = 60

    static func cacheKey(groupId: String) -> RedisKey {
        RedisKey("ranking:board:\(groupId)")
    }

    static func invalidateCache(req: Request, groupId: String) async throws {
        _ = try await req.redis.delete(Self.cacheKey(groupId: groupId)).get()
    }

    func board(req: Request) async throws -> RankingBoardDTO {
        let user = try req.auth.require(User.self)
        guard let groupId = user.$group.id else {
            throw Abort(.badRequest, reason: "No group")
        }
        let key = Self.cacheKey(groupId: groupId)
        let jsonDecoder: JSONDecoder = {
            let d = JSONDecoder()
            d.keyDecodingStrategy = .convertFromSnakeCase
            return d
        }()
        if let cached = try await req.redis.get(key, asJSON: RankingBoardDTO.self, jsonDecoder: jsonDecoder) {
            return cached
        }
        let students = try await User.query(on: req.db)
            .filter(\.$group.$id == groupId)
            .filter(\.$role == UserRole.student)
            .all()
        let subjects = try await Subject.query(on: req.db)
            .filter(\.$group.$id == groupId)
            .all()
        var entries: [(user: User, sum: Float)] = []
        for s in students {
            let sid = s.id!
            var weighted: Float = 0
            for sub in subjects {
                guard let subId = sub.id else { continue }
                if let en = try await Enrollment.query(on: req.db)
                    .filter(\.$student.$id == sid)
                    .filter(\.$subject.$id == subId)
                    .first()
                {
                    weighted += sub.credits * en.finalMark
                }
            }
            entries.append((s, weighted))
        }
        entries.sort { $0.sum > $1.sum }
        var dtos: [RankingEntryDTO] = []
        for (idx, item) in entries.enumerated() {
            dtos.append(
                RankingEntryDTO(
                    id: "r-\(item.user.id!)",
                    studentId: item.user.id!,
                    displayName: item.user.displayName,
                    weightedSum: item.sum,
                    rank: idx + 1
                )
            )
        }
        let board = RankingBoardDTO(entries: dtos)
        let jsonEncoder: JSONEncoder = {
            let e = JSONEncoder()
            e.keyEncodingStrategy = .convertToSnakeCase
            return e
        }()
        try await req.redis.setex(
            key,
            toJSON: board,
            expirationInSeconds: Self.cacheSeconds,
            jsonEncoder: jsonEncoder
        )
        return board
    }
}
