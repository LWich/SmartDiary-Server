import JWT
import Vapor

struct AccessTokenPayload: JWTPayload {
    var exp: ExpirationClaim
    var uid: String

    func verify(using signer: JWTSigner) throws {
        try exp.verifyNotExpired()
    }
}
