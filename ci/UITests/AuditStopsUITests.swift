import CryptoKit
import Foundation
import UIKit
import XCTest

/// One test method per audit stop lives in `Stops.swift` (generated). A stop that hangs the app costs its own test:
/// XCTest's time allowance (`run_ui.sh`) kills that test, records a spindump and restarts the runner for the next one.
final class AuditStopsUITests: XCTestCase {
    override func setUpWithError() throws { continueAfterFailure = true }

    @MainActor
    func visit(_ id: String, root: String) {
        let out = URL(fileURLWithPath: "/tmp/audit-stops")
        try? FileManager.default.createDirectory(at: out, withIntermediateDirectories: true)
        XCUIDevice.shared.orientation = .portrait
        let app = XCUIApplication()
        app.launchArguments = ["-auditStop", id]
        app.launch()
        let element = app.descendants(matching: .any).matching(identifier: root).firstMatch
        let seen = element.waitForExistence(timeout: 10)
        if seen { usleep(1_200_000) }
        var tree = "error"
        var treeBytes = Data()
        do {
            let snapshot = try app.snapshot()
            let data = try JSONSerialization.data(withJSONObject: node(snapshot), options: [.sortedKeys])
            try data.write(to: out.appendingPathComponent(id + ".json"))
            treeBytes = data
            tree = "written"
        } catch {
            tree = "error \(error.localizedDescription)"
        }
        let png = XCUIScreen.main.screenshot().pngRepresentation
        try? png.write(to: out.appendingPathComponent(id + ".png"))
        // The capture record: the digests of the exact bytes above, written on the simulator. Every new write is
        // `try?`: a capture problem never fails, retries or slows the stop test.
        let hex = { (bytes: Data) in SHA256.hash(data: bytes).map { String(format: "%02x", $0) }.joined() }
        let window = app.windows.firstMatch.frame
        let capture: [String: Any] = [
            "stop_id": id,
            "root_present": seen,
            "actions_before_capture": 0,
            "window_pt": [Double(window.width), Double(window.height)],
            "scale": Double(UIScreen.main.scale),
            "tree": ["file": id + ".json", "sha256": hex(treeBytes)],
            "screen": ["file": id + ".png", "sha256": hex(png)],
        ]
        if let captureJSON = try? JSONSerialization.data(withJSONObject: capture, options: [.sortedKeys]) {
            try? captureJSON.write(to: out.appendingPathComponent(id + ".capture.json"))
        }
        print("AUDIT stop \(id) root=\(seen ? "present" : "absent") tree=\(tree) png=\(png.count)")
        app.terminate()
    }

    private func node(_ s: XCUIElementSnapshot) -> [String: Any] {
        [
            "type": Int(s.elementType.rawValue),
            "identifier": s.identifier,
            "label": s.label,
            "value": (s.value as? String) ?? "",
            "enabled": s.isEnabled,
            "frame": [Double(s.frame.minX), Double(s.frame.minY), Double(s.frame.width), Double(s.frame.height)],
            "children": s.children.map { node($0) },
        ]
    }
}
