import Fluent
import JWT
import Vapor

struct JWTUserAuthenticator: AsyncBearerAuthenticator {
    func authenticate(bearer: BearerAuthorization, for request: Request) async throws {
        let payload: AccessTokenPayload
        do {
            payload = try request.jwt.verify(bearer.token, as: AccessTokenPayload.self)
        } catch {
            return
        }
        guard let user = try await User.query(on: request.db)
            .filter(\.$id == payload.uid)
            .first()
        else {
            return
        }
        request.auth.login(user)
    }
}
