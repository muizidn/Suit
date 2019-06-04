// swift-tools-version:5.0
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
  name: "Suit",
  platforms: [
    .macOS(.v10_13)
  ],
  products: [
    .library(
      name: "Suit",
      targets: ["Suit"]),
    .library(
      name: "SuitTestUtils",
      targets: ["SuitTestUtils"])
    ],
  
    dependencies: [
      .package(url: "https://github.com/pmacro/Yoga", .branch("master"))
    ],
  
  targets: [
    .target(
      name: "Suit",
      dependencies: ["Yoga"],
      path: "Sources"
    ),
    .target(
      name: "SuitTestUtils",
      dependencies: ["Suit"],
      path: "TestUtils"
    ),
    .testTarget(
      name: "SuitTests",
      dependencies: ["Suit", "SuitTestUtils", "Yoga"],
      path: "Tests")
    ]
)

let suitTarget = package.targets.first(where: { $0.name == "Suit" })

#if os(Linux)
package.dependencies += [
  .package(url: "https://github.com/pmacro/Cairo", .branch("master")),
  .package(url: "https://github.com/pmacro/Freetype", .branch("master")),
  .package(url: "https://github.com/pmacro/Pango", .branch("master")),
  .package(url: "https://github.com/pmacro/Glib", .branch("master")),
  .package(url: "https://github.com/pmacro/Fontconfig", .branch("master")),
  .package(url: "https://github.com/pmacro/X11", .branch("master")),
  .package(url: "https://github.com/pmacro/CClipboard", .branch("master")),
  .package(url: "https://github.com/pmacro/GD", .branch("master")),
]

suitTarget!.dependencies.append("CClipboard")
#elseif os(macOS)
suitTarget!.exclude = ["Linux"]

#endif
