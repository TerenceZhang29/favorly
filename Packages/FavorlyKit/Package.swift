// swift-tools-version: 6.0

import PackageDescription

let package = Package(
    name: "FavorlyKit",
    platforms: [
        .iOS(.v17),
        .macOS(.v14),
    ],
    products: [
        .library(name: "FavorlyCore", targets: ["FavorlyCore"]),
        .library(name: "FavorlyData", targets: ["FavorlyData"]),
        .library(name: "FavorlyFeatures", targets: ["FavorlyFeatures"]),
        .library(name: "FavorlyRemote", targets: ["FavorlyRemote"]),
    ],
    dependencies: [
        // Exact, because Package.resolved is not committed. See docs/PROGRESS.md before changing it.
        .package(url: "https://github.com/supabase/supabase-swift", exact: "2.55.5"),
    ],
    targets: [
        .target(name: "FavorlyCore"),
        .target(name: "FavorlyData", dependencies: ["FavorlyCore"]),
        .target(name: "FavorlyFeatures", dependencies: ["FavorlyCore"]),
        .target(
            name: "FavorlyRemote",
            dependencies: ["FavorlyCore", .product(name: "Supabase", package: "supabase-swift")]
        ),
        .testTarget(name: "FavorlyCoreTests", dependencies: ["FavorlyCore"]),
        .testTarget(name: "FavorlyDataTests", dependencies: ["FavorlyData"]),
        .testTarget(name: "FavorlyFeaturesTests", dependencies: ["FavorlyFeatures", "FavorlyData"]),
        .testTarget(name: "FavorlyRemoteTests", dependencies: ["FavorlyRemote", "FavorlyData"]),
    ]
)
