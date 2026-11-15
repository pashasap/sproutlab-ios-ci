import XCTest

/// V12 acceptance audit (iPhone). Every PNG is written straight to the host disk (/tmp/v12shots) as it is taken.
/// No test taps the ear (the CI simulator may have no TTS voices). Rounds answer from the stimulus value first,
/// then try the remaining choices (unlimited retries, no penalty), so no answer key is needed.
/// Steps run in priority order: a job cutoff that stops the test still leaves the most important pixels.
final class SproutLabUITests: XCTestCase {
    override func setUpWithError() throws { continueAfterFailure = true }

    @MainActor
    func testA_Phone() throws {
        XCUIDevice.shared.orientation = .portrait
        var app = XCUIApplication()
        app.launch()
        XCTAssertTrue(playButton(app).waitForExistence(timeout: 60), "welcome")
        switchToEnglish(app)
        chrome(app, "A01"); titles(app, "A01"); frames(app, "A01")
        shot("A01-home-light")

        // Trail: three levels, states and identities.
        playButton(app).tap()
        _ = level(app, "math-bonds-10").waitForExistence(timeout: 10)
        tiles(app, "A02"); frames(app, "A02")
        shot("A02-trail-light")

        // Round 1: bonds to 10, summary, star button, terrarium, kill on the summary.
        level(app, "math-bonds-10").tap()
        playRound(app, tag: "R1", shotEach: false)
        chrome(app, "A09"); frames(app, "A09")
        let before = starLabel(app)
        note("R1 summary star button label='\(before)' frame=\(el(app, "sproutlab.terrarium.open").frame)")
        shot("A09-summary-light")
        el(app, "sproutlab.terrarium.open").tap(); sleep(1)
        note("after star tap: terrarium=\(el(app, "sproutlab.terrarium").exists) panL=\(el(app, "sproutlab.pan.left").exists)")
        frames(app, "A10")
        shot("A10-star-button-opens")
        dismissSheet(app)
        note("after dismiss: summary=\(summaryVisible(app, wait: 1)) star='\(starLabel(app))'")
        shot("A11-summary-after-sheet")
        app.terminate()                                   // v5 defect (a): kill while on the summary
        app = XCUIApplication(); app.launch()
        _ = playButton(app).waitForExistence(timeout: 30)
        note("RELAUNCH star before kill='\(before)' after='\(starLabel(app))'")
        chrome(app, "A12")
        shot("A12-home-after-kill")
        playButton(app).tap(); _ = level(app, "math-bonds-10").waitForExistence(timeout: 10)
        tiles(app, "A13")
        shot("A13-trail-after-kill")

        // Landscape (v5 defect b): trail, home; frames prove clipping (negative y).
        XCUIDevice.shared.orientation = .landscapeLeft; sleep(2)
        chrome(app, "L01"); frames(app, "L01")
        shot("L01-trail-landscape")
        titleTarget(app, preferText: true).tap(); _ = playButton(app).waitForExistence(timeout: 5)
        chrome(app, "L02"); titles(app, "L02"); hierarchy(app, "L02")
        shot("L02-home-landscape")
        playButton(app).tap(); _ = level(app, "math-add-sub-20").waitForExistence(timeout: 5)
        level(app, "math-add-sub-20").tap()
        _ = el(app, "sproutlab.back").waitForExistence(timeout: 5)
        chrome(app, "L03"); frames(app, "L03")
        shot("L03-question-landscape")
        XCUIDevice.shared.orientation = .portrait; sleep(2)

        // Round 2: add and take away within 20 (continues the landscape-started round).
        playRound(app, tag: "R2", shotEach: true)
        shot("R2-summary")
        leaveSummary(app)

        // Round 3: patterns and comparison within 20.
        _ = level(app, "math-patterns-20").waitForExistence(timeout: 5)
        tiles(app, "A30")
        shot("A30-trail-after-r2")
        level(app, "math-patterns-20").tap()
        playRound(app, tag: "R3", shotEach: true)
        shot("R3-summary")
        leaveSummary(app)
        tiles(app, "A31")
        shot("A31-trail-after-r3")

        // Diagnostics hold and the creature gallery.
        titleTarget(app, preferText: false).press(forDuration: 3.5); sleep(1)
        note("after hold: diagnostics=\(diagnosticsOpen(app)) trail=\(level(app, "math-bonds-10").exists)")
        shot("A40-diagnostics")
        let gallery = app.buttons["Gallery"]
        if gallery.waitForExistence(timeout: 2) {
            gallery.tap(); sleep(2)
            frames(app, "A41")
            shot("A41-gallery-1")
            app.swipeUp(); sleep(1); shot("A42-gallery-2")
            app.swipeUp(); sleep(1); shot("A43-gallery-3")
            app.swipeUp(); sleep(1); shot("A44-gallery-4")
            app.buttons["Close"].firstMatch.tap(); sleep(1)
        } else { note("gallery button ABSENT") }
        closeDiagnostics(app)
        titleTarget(app, preferText: false).tap()
        note("tap home: home=\(playButton(app).waitForExistence(timeout: 5)) diagnostics=\(diagnosticsOpen(app))")

        // Larger Text accessibility XL (v5 defect c): relaunch.
        app.terminate()
        request("xl")
        let large = XCUIApplication()
        large.launchArguments += ["-UIPreferredContentSizeCategoryName", "UICTContentSizeCategoryAccessibilityXL"]
        large.launch()
        _ = playButton(large).waitForExistence(timeout: 30)
        chrome(large, "C01"); titles(large, "C01"); hierarchy(large, "C01")
        shot("C01-home-xl")
        playButton(large).tap(); _ = level(large, "math-bonds-10").waitForExistence(timeout: 5)
        tiles(large, "C02"); frames(large, "C02")
        shot("C02-trail-xl")
        large.swipeUp(); sleep(1); shot("C03-trail-xl-scrolled")
        large.swipeDown(); sleep(1)
        level(large, "math-add-sub-20").tap()
        _ = el(large, "sproutlab.back").waitForExistence(timeout: 5)
        chrome(large, "C04"); frames(large, "C04")
        shot("C04-question-xl")
        el(large, "sproutlab.back").tap(); sleep(1)

        // Dark (live appearance switch by the host).
        request("dark")
        shot("B01-trail-dark")
        level(large, "math-patterns-20").tap()
        _ = el(large, "sproutlab.back").waitForExistence(timeout: 5)
        shot("B02-question-dark-xl")
        el(large, "sproutlab.back").tap(); sleep(1)
        el(large, "sproutlab.terrarium.open").tap(); sleep(1)
        shot("B03-star-sheet-dark")
        note("DONE")
    }

    // MARK: - Round driver

    @MainActor
    private func playRound(_ app: XCUIApplication, tag: String, shotEach: Bool) {
        var lastQ = ""
        var wrongShot = false
        for _ in 0..<20 {
            if summaryVisible(app, wait: 0) { break }
            guard el(app, "sproutlab.back").waitForExistence(timeout: 4) else { note("\(tag) no question"); break }
            let q = progressLabel(app)
            let stim = stimulusValue(app)
            let choices = choiceValues(app)
            note("\(tag) \(q) prompt='\(promptLabel(app))' stimulus=\(stim) choices=\(choices)")
            if shotEach && q != lastQ { shot("\(tag)-\(q.replacingOccurrences(of: " ", with: ""))") }
            lastQ = q
            let first = choices.firstIndex(of: expected(stim)) ?? 0
            var order = [first] + (0..<3).filter { $0 != first }
            var advanced = false
            while !order.isEmpty {
                let i = order.removeFirst()
                el(app, "sproutlab.choice.\(i)").tap()
                usleep(600_000)
                if summaryVisible(app, wait: 0) || progressLabel(app) != q { advanced = true; break }
                note("\(tag) \(q) choice \(i) (\(choices[i])) wrong; feedback='\(feedback(app))'")
                if shotEach && !wrongShot { shot("\(tag)-wrong-cue"); wrongShot = true }
            }
            if !advanced { note("\(tag) \(q) no choice advanced") }
        }
        note("\(tag) summary=\(summaryVisible(app, wait: 3)) star='\(starLabel(app))'")
    }

    private func expected(_ stim: String) -> String {
        let nums = stim.split(whereSeparator: { !$0.isNumber }).map(String.init)
        if stim.contains("crossed") { return nums.first ?? "?" }
        if stim.contains("filled") && stim.contains("empty") { return nums.count > 1 ? nums[1] : "?" }
        if stim.contains(" and ") && nums.count > 1 { return String((Int(nums[0]) ?? 0) + (Int(nums[1]) ?? 0)) }
        return nums.first ?? "?"
    }

    // MARK: - Host handshake (appearance, content size)

    private func request(_ what: String) {
        let ok = URL(fileURLWithPath: "/tmp/v12ctl/\(what)-ok")
        note("REQUEST \(what)")
        for _ in 0..<20 where !FileManager.default.fileExists(atPath: ok.path) { usleep(500_000) }
        note("REQUEST \(what) acknowledged=\(FileManager.default.fileExists(atPath: ok.path))")
        sleep(1)
    }

    // MARK: - Helpers

    @MainActor
    private func titleTarget(_ app: XCUIApplication, preferText: Bool) -> XCUIElement {
        let all = app.descendants(matching: .any).matching(identifier: "sproutlab.title").allElementsBoundByIndex
        if all.isEmpty { return el(app, "sproutlab.icon") }
        if preferText { return all.max(by: { $0.frame.width < $1.frame.width })! }
        return all.min(by: { $0.frame.width < $1.frame.width })!
    }

    @MainActor
    private func titles(_ app: XCUIApplication, _ tag: String) {
        let all = app.descendants(matching: .any).matching(identifier: "sproutlab.title").allElementsBoundByIndex
        note("titles \(tag): title x\(all.count) " + all.map { "\($0.elementType.rawValue)@\($0.frame) '\($0.label)'" }.joined(separator: " , "))
    }

    /// Accessibility hierarchy dump (VoiceOver reading order evidence).
    @MainActor
    private func hierarchy(_ app: XCUIApplication, _ tag: String) {
        note("hierarchy \(tag): " + app.debugDescription.split(separator: "\n").map { $0.trimmingCharacters(in: .whitespaces) }.joined(separator: " || "))
    }

    @MainActor
    private func frames(_ app: XCUIApplication, _ tag: String) {
        let lines = app.debugDescription.split(separator: "\n")
            .filter { $0.contains("Button") || $0.contains("StaticText") || $0.contains("Window") || $0.contains("Image") || $0.contains("Other, identifier") }
            .map { $0.trimmingCharacters(in: .whitespaces) }
        note("frames \(tag): " + lines.joined(separator: " || "))
    }

    @MainActor
    private func tiles(_ app: XCUIApplication, _ tag: String) {
        let ids = ["math-bonds-10", "math-add-sub-20", "math-patterns-20"]
        note("tiles \(tag): " + ids.map { let t = level(app, $0); return t.exists ? "\($0)=\(t.frame) enabled=\(t.isEnabled) '\(t.label)'" : "\($0)=ABSENT" }.joined(separator: " ; "))
    }

    @MainActor
    private func diagnosticsOpen(_ app: XCUIApplication) -> Bool { app.staticTexts["Diagnostics"].exists }

    @MainActor
    private func closeDiagnostics(_ app: XCUIApplication) {
        let close = app.buttons["Close"].firstMatch
        if close.exists { close.tap(); sleep(1); return }
        if diagnosticsOpen(app) { dismissSheet(app) }
    }

    @MainActor
    private func dismissSheet(_ app: XCUIApplication) {
        let w = app.windows.firstMatch
        w.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.2))
            .press(forDuration: 0.05, thenDragTo: w.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.98)))
        sleep(1)
    }

    @MainActor
    private func leaveSummary(_ app: XCUIApplication) {
        let b = app.buttons["Back to the trail"].firstMatch
        if b.exists { b.tap(); sleep(1) } else { note("summary back ABSENT") }
    }

    @MainActor
    private func el(_ app: XCUIApplication, _ id: String) -> XCUIElement {
        app.descendants(matching: .any).matching(identifier: id).firstMatch
    }

    @MainActor
    private func level(_ app: XCUIApplication, _ id: String) -> XCUIElement { el(app, "sproutlab.level.\(id)") }

    @MainActor
    private func playButton(_ app: XCUIApplication) -> XCUIElement {
        app.buttons.matching(NSPredicate(format: "label == %@ OR label == %@", "Play", "Jouer")).firstMatch
    }

    @MainActor
    private func summaryVisible(_ app: XCUIApplication, wait: TimeInterval) -> Bool {
        let s = app.staticTexts.matching(NSPredicate(format: "label IN %@",
            ["Great job, you did it!", "Bravo, tu as réussi !", "Three stars for you!", "Trois étoiles pour toi !"])).firstMatch
        return wait > 0 ? s.waitForExistence(timeout: wait) : s.exists
    }

    @MainActor
    private func switchToEnglish(_ app: XCUIApplication) {
        let en = app.buttons["Anglais"]
        if en.waitForExistence(timeout: 1.5) { en.tap(); usleep(500_000) }
        note("EN now: \(app.buttons["English"].exists) selected=\(app.buttons["English"].isSelected)")
    }

    @MainActor
    private func chrome(_ app: XCUIApplication, _ tag: String) {
        var parts: [String] = []
        for id in ["sproutlab.title", "sproutlab.language", "sproutlab.music", "sproutlab.terrarium.open",
                   "sproutlab.back", "sproutlab.listen", "sproutlab.stimulus"] {
            let e = el(app, id)
            parts.append(e.exists ? "\(id)=\(e.frame) '\(e.label)'" : "\(id)=ABSENT")
        }
        parts.append("window=\(app.windows.firstMatch.frame)")
        note("chrome \(tag): " + parts.joined(separator: "; "))
    }

    @MainActor
    private func progressLabel(_ app: XCUIApplication) -> String {
        let q = app.staticTexts.matching(NSPredicate(format: "label BEGINSWITH %@", "Question ")).firstMatch
        return q.exists ? q.label : "-"
    }

    @MainActor
    private func promptLabel(_ app: XCUIApplication) -> String {
        let p = app.staticTexts.matching(NSPredicate(format: "label ENDSWITH %@", "?")).firstMatch
        return p.exists ? p.label : "-"
    }

    @MainActor
    private func feedback(_ app: XCUIApplication) -> String {
        let p = app.staticTexts.matching(NSPredicate(format: "label CONTAINS %@", "try again")).firstMatch
        return p.exists ? p.label : "-"
    }

    @MainActor
    private func stimulusValue(_ app: XCUIApplication) -> String {
        let s = el(app, "sproutlab.stimulus")
        return s.exists ? ((s.value as? String) ?? "<no value>") : "<missing>"
    }

    @MainActor
    private func choiceValues(_ app: XCUIApplication) -> [String] {
        (0..<3).map { let c = el(app, "sproutlab.choice.\($0)"); return (c.value as? String) ?? c.label }
    }

    @MainActor
    private func starLabel(_ app: XCUIApplication) -> String {
        let s = el(app, "sproutlab.terrarium.open")
        return s.exists ? s.label : "-"
    }

    private func note(_ line: String) {
        print("AUDIT \(String(format: "%.1f", Date().timeIntervalSince1970.truncatingRemainder(dividingBy: 10000))) \(line)")
        fflush(stdout)
    }

    @MainActor
    private func shot(_ name: String) {
        let png = XCUIScreen.main.screenshot().pngRepresentation
        let dir = URL(fileURLWithPath: "/tmp/v12shots")
        try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        try? png.write(to: dir.appendingPathComponent("\(name).png"))
        note("shot \(name)")
    }
}
