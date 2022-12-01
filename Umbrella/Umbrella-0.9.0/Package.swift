// swift-tools-version:5.0

import PackageDescription

let package = Package(
  name: "Umbrella",
  platforms: [
    .macOS(.v10_11), .iOS(.v8), .tvOS(.v9), .watchOS(.v2)
  ],
  products: [
    .library(name: "Umbrella", targets: ["Umbrella"]),
    .library(name: "UmbrellaAmplitude", targets: ["UmbrellaAmplitude"]),
    .library(name: "UmbrellaAnswers", targets: ["UmbrellaAnswers"]),
    .library(name: "UmbrellaAppboy", targets: ["UmbrellaAppboy"]),
    .library(name: "UmbrellaAppsFlyer", targets: ["UmbrellaAppsFlyer"]),
    .library(name: "UmbrellaFirebase", targets: ["UmbrellaFirebase"]),
    .library(name: "UmbrellaFlurry", targets: ["UmbrellaFlurry"]),
    .library(name: "UmbrellaLocalytics", targets: ["UmbrellaLocalytics"]),
    .library(name: "UmbrellaMixpanel", targets: ["UmbrellaMixpanel"]),
  ],
  targets: [
    .target(name: "Umbrella"),
    .target(name: "UmbrellaAmplitude", dependencies: ["Umbrella"]),
    .target(name: "UmbrellaAnswers", dependencies: ["Umbrella"]),
    .target(name: "UmbrellaAppboy", dependencies: ["Umbrella"]),
    .target(name: "UmbrellaAppsFlyer", dependencies: ["Umbrella"]),
    .target(name: "UmbrellaFirebase", dependencies: ["Umbrella"]),
    .target(name: "UmbrellaFlurry", dependencies: ["Umbrella"]),
    .target(name: "UmbrellaLocalytics", dependencies: ["Umbrella"]),
    .target(name: "UmbrellaMixpanel", dependencies: ["Umbrella"]),
    .testTarget(name: "UmbrellaTests", dependencies: ["Umbrella"]),
    .testTarget(name: "UmbrellaAmplitudeTests", dependencies: ["UmbrellaAmplitude"]),
    .testTarget(name: "UmbrellaAnswersTests", dependencies: ["UmbrellaAnswers"]),
    .testTarget(name: "UmbrellaAppboyTests", dependencies: ["UmbrellaAppboy"]),
    .testTarget(name: "UmbrellaAppsFlyerTests", dependencies: ["UmbrellaAppsFlyer"]),
    .testTarget(name: "UmbrellaFirebaseTests", dependencies: ["UmbrellaFirebase"]),
    .testTarget(name: "UmbrellaFlurryTests", dependencies: ["UmbrellaFlurry"]),
    .testTarget(name: "UmbrellaLocalyticsTests", dependencies: ["UmbrellaLocalytics"]),
    .testTarget(name: "UmbrellaMixpanelTests", dependencies: ["UmbrellaMixpanel"]),
  ],
  swiftLanguageVersions: [.v5]
)
