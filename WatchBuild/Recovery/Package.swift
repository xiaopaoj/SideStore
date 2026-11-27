// swift-tools-version: 6.0
import PackageDescription
let package = Package(name: "FWOSRecovery", products: [.library(name: "FWOSRecovery", targets: ["FWOSRecovery"])], targets: [.target(name: "FWOSRecovery"), .testTarget(name: "FWOSRecoveryTests", dependencies: ["FWOSRecovery"])])
