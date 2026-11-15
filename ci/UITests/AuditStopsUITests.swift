import XCTest

final class AuditStopsUITests: XCTestCase {
    override func setUpWithError() throws { continueAfterFailure = true }

    @MainActor
    func testStops() throws {
        let out = URL(fileURLWithPath: "/tmp/audit-stops")
        try? FileManager.default.createDirectory(at: out, withIntermediateDirectories: true)
        XCUIDevice.shared.orientation = .portrait
        for stop in auditStops {
            let app = XCUIApplication()
            app.launchArguments = ["-auditStop", stop.id]
            app.launch()
            let root = app.descendants(matching: .any).matching(identifier: stop.root).firstMatch
            let seen = root.waitForExistence(timeout: 10)
            if seen { usleep(1_200_000) }
            var tree = "error"
            do {
                let snapshot = try app.snapshot()
                let data = try JSONSerialization.data(withJSONObject: node(snapshot), options: [.sortedKeys])
                try data.write(to: out.appendingPathComponent(stop.id + ".json"))
                tree = "written"
            } catch {
                tree = "error \(error.localizedDescription)"
            }
            let png = XCUIScreen.main.screenshot().pngRepresentation
            try? png.write(to: out.appendingPathComponent(stop.id + ".png"))
            print("AUDIT stop \(stop.id) root=\(seen ? "present" : "absent") tree=\(tree) png=\(png.count)")
            app.terminate()
        }
        print("AUDIT DONE \(auditStops.count)")
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
