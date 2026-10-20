// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "WineScannerLocal",
    platforms: [.iOS("18.2"), .macOS("15.0")],
    products: [.library(name: "WineScannerLocal", targets: ["WineScannerLocal"])],
    targets: [.target(
        name: "WineScannerLocal",
        // These source-identical integer resampling loops also process internal
        // large canvases. Keep UI Debug instrumentation, but compile the native
        // inference library as in the verified -O standalone consumer.
        swiftSettings: [.unsafeFlags(["-O"], .when(platforms: [.iOS], configuration: .debug))]
    )]
)
