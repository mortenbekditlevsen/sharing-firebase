// swift-tools-version: 6.0

import PackageDescription

let package = Package(
  name: "sharing-firebase",
  platforms: [
    .iOS(.v13),
    .macOS(.v10_15),
    .tvOS(.v13),
    .watchOS(.v7),
  ],
  products: [
    .library(
      name: "SharingFirebase",
      targets: ["SharingFirebase"]
    ),
    .library(
      name: "FirebaseStorageLive",
      targets: ["FirebaseStorageLive"]
    ),
  ],
  dependencies: [
    .package(url: "https://github.com/pointfreeco/swift-identified-collections", from: "1.1.1"),
    .package(url: "https://github.com/firebase/firebase-ios-sdk.git", from: "10.28.1"),
    .package(url: "https://github.com/pointfreeco/swift-dependencies", from: "1.6.4"),
    .package(url: "https://github.com/pointfreeco/swift-sharing", from: "2.3.0"),
  ],
  targets: [
    .target(
      name: "SharingFirebase",
      dependencies: [
        .product(name: "Sharing", package: "swift-sharing"),
      ]
    ),
    .target(
      name: "FirebaseStorageLive",
      dependencies: [
        "SharingFirebase",
        .product(name: "Sharing", package: "swift-sharing"),
        .product(name: "FirebaseFirestore", package: "firebase-ios-sdk"), 
        .product(name: "FirebaseDatabase", package: "firebase-ios-sdk"),
      ]
    ),
    .testTarget(
      name: "SharingFirebaseTests",
      dependencies: [
        "SharingFirebase",
        .product(name: "DependenciesTestSupport", package: "swift-dependencies"),
      ]
    ),
  ],
  swiftLanguageModes: [.v6]
)

#if !os(Windows)
  // Add the documentation compiler plugin if possible
  package.dependencies.append(
    .package(url: "https://github.com/apple/swift-docc-plugin", from: "1.0.0")
  )
#endif
