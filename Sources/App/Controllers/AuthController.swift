import Fluent
import JWT
import Vapor

struct AuthController {
    func login(req: Request) async throws -> AuthLoginResponse {
        let body = try req.content.decode(AuthLoginRequest.self)
        let email = body.email.lowercased()
        guard let user = try await User.query(on: req.db).filter(\.$email == email).first() else {
            throw Abort(.unauthorized, reason: "Invalid credentials")
        }
        guard (try? Bcrypt.verify(body.password, created: user.passwordHash)) == true else {
            throw Abort(.unauthorized, reason: "Invalid credentials")
        }
        let payload = AccessTokenPayload(
            exp: ExpirationClaim(value: Date().addingTimeInterval(60 * 60 * 24 * 7)),
            uid: user.id!
        )
        let token = try req.jwt.sign(payload)
        try await user.$group.load(on: req.db)
        let profile = UserProfileDTO(
            id: user.id!,
            email: user.email,
            displayName: user.displayName,
            role: user.role.rawValue,
            groupId: user.$group.id,
            groupTitle: user.group?.title
        )
        return AuthLoginResponse(accessToken: token, tokenType: "bearer", user: profile)
    }

    func logout(req: Request) async throws -> HTTPStatus {
        HTTPStatus.noContent
    }

    func me(req: Request) async throws -> UserProfileDTO {
        let user = try req.auth.require(User.self)
        try await user.$group.load(on: req.db)
        return UserProfileDTO(
            id: user.id!,
            email: user.email,
            displayName: user.displayName,
            role: user.role.rawValue,
            groupId: user.$group.id,
            groupTitle: user.group?.title
        )
    }
}
