import Fluent
import FluentPostgresDriver
import JWT
import Redis
import Vapor

public func configure(_ app: Application) async throws {
    let encoder = JSONEncoder()
    encoder.keyEncodingStrategy = .convertToSnakeCase
    encoder.dateEncodingStrategy = .iso8601
    let decoder = JSONDecoder()
    decoder.keyDecodingStrategy = .convertFromSnakeCase
    decoder.dateDecodingStrategy = .iso8601

    ContentConfiguration.global.use(encoder: encoder, for: .json)
    ContentConfiguration.global.use(decoder: decoder, for: .json)

    let dbHost = Environment.get("DATABASE_HOST") ?? "localhost"
    let dbPort = Environment.get("DATABASE_PORT").flatMap(Int.init(_:)) ?? 5432
    let dbUser = Environment.get("DATABASE_USERNAME") ?? "smartdairy"
    let dbPass = Environment.get("DATABASE_PASSWORD") ?? "smartdairy"
    let dbName = Environment.get("DATABASE_NAME") ?? "smartdairy"
    let pgURL = "postgres://\(dbUser):\(dbPass)@\(dbHost):\(dbPort)/\(dbName)"
    try app.databases.use(.postgres(url: pgURL), as: .psql)

    let redisHost = Environment.get("REDIS_HOST") ?? "localhost"
    let redisPort = Environment.get("REDIS_PORT").flatMap(Int.init(_:)) ?? 6379
    app.redis.configuration = try RedisConfiguration(hostname: redisHost, port: redisPort)

    let jwtSecret = Environment.get("JWT_SECRET") ?? "dev-only-secret-change-me-in-production-min-32-chars!!"
    app.jwt.signers.use(.hs256(key: jwtSecret))

    app.migrations.add(CreateGroup())
    app.migrations.add(CreateUser())
    app.migrations.add(CreateSubject())
    app.migrations.add(CreateGradeElement())
    app.migrations.add(CreateEnrollment())
    app.migrations.add(CreateStudentGrade())
    app.migrations.add(SeedDatabase())

    try await app.autoMigrate()

    try routes(app)
}
