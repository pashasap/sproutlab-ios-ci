import Foundation

// CI-only shim: under xtool/SwiftPM the App target gets a generated `Bundle.module`.
// In the XcodeGen application target resources are copied into the main bundle instead.
extension Bundle {
    static var module: Bundle { .main }
}
