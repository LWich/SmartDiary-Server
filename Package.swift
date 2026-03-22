// swift-tools-version:5.10
import PackageDescription

let package = Package(
    name: "SmartDairyServer",
    platforms: [
        .macOS(.v13)
    ],
    products: [
        .executable(name: "SmartDairyServer", targets: ["Run"])
    ],
    dependencies: [
        .package(url: "https://github.com/vapor/vapor.git", from: "4.92.0"),
        .package(url: "https://github.com/vapor/fluent.git", from: "4.9.0"),
        .package(url: "https://github.com/vapor/fluent-postgres-driver.git", from: "2.8.0"),
        .package(url: "https://github.com/vapor/redis.git", from: "4.10.0"),
        .package(url: "https://github.com/vapor/jwt.git", from: "4.2.0")
    ],
    targets: [
        .target(
            name: "App",
            dependencies: [
                .product(name: "Vapor", package: "vapor"),
                .product(name: "Fluent", package: "fluent"),
                .product(name: "FluentPostgresDriver", package: "fluent-postgres-driver"),
                .product(name: "Redis", package: "redis"),
                .product(name: "JWT", package: "jwt")
            ],
            path: "Sources/App",
            resources: [
                .copy("Resources/grading_formulas.json")
            ]
        ),
        .executableTarget(
            name: "Run",
            dependencies: [
                .target(name: "App")
            ],
            path: "Sources/Run"
        )
    ]
)
