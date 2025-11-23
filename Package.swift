// swift-tools-version: 5.9
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "LuckyTrans",
    platforms: [
        .macOS(.v13)
    ],
    products: [
        .library(
            name: "LuckyTrans",
            targets: ["LuckyTrans"]
        ),
    ],
    dependencies: [
        // 可以添加第三方依赖，如 MASShortcut 用于快捷键管理
    ],
    targets: [
        .target(
            name: "LuckyTrans",
            dependencies: []
        ),
        .testTarget(
            name: "LuckyTransTests",
            dependencies: ["LuckyTrans"]
        ),
    ]
)

