import XCTest

/// v22 acceptance audit. Every PNG is written straight to the host disk (/tmp/slshots) as it is taken.
/// No test taps the ear (the CI simulator may have no TTS voices). Rounds answer from the stimulus value first,
/// then try the remaining choices (unlimited retries, no penalty), so no answer key is needed.
/// The host watches the log for "REQUEST <what>" and touches /tmp/slctl/<what>-ok when done
/// (dark, light, xl, seed = mark reading R1 and R2 completed in the saved progress so R2/R3 open).
final class SproutLabUITests: XCTestCase {
    override func setUpWithError() throws { continueAfterFailure = true }

    static let levelIds = ["math-bonds-10", "math-add-sub-20", "math-patterns-20",
                           "reading-fr-r1", "reading-fr-r2", "reading-fr-r3"]

    // MARK: - iPhone

    @MainActor
    func testA_Phone() throws {
        XCUIDevice.shared.orientation = .portrait
        var app = XCUIApplication()
        app.launch()
        XCTAssertTrue(playButton(app).waitForExistence(timeout: 60), "welcome")
        chrome(app, "P01"); frames(app, "P01")
        shot("P01-welcome-fr-light")

        tapSafe(playButton(app))
        _ = level(app, "math-bonds-10").waitForExistence(timeout: 10)
        tiles(app, "P02"); frames(app, "P02")
        shot("P02-trail-fr-light")
        app.swipeUp(); sleep(1); tiles(app, "P03"); shot("P03-trail-fr-scrolled")
        app.swipeDown(); sleep(1)

        // Math round 1: counting and make 10, every question shot.
        tapSafe(level(app, "math-bonds-10"))
        playRound(app, tag: "M1")
        chrome(app, "M1S"); frames(app, "M1S")
        shot("M1-summary")

        // Star button -> terrarium, dial, pan, resident, journal.
        terrariumTour(app, tag: "G", full: true)
        leaveSummary(app)

        // Math rounds 2 and 3.
        tapLevel(app, "math-add-sub-20")
        playRound(app, tag: "M2")
        shot("M2-summary"); leaveSummary(app)
        tapLevel(app, "math-patterns-20")
        playRound(app, tag: "M3")
        shot("M3-summary"); leaveSummary(app)
        tiles(app, "P04"); shot("P04-trail-after-math")

        // Reading R1 (open from the start).
        app.swipeUp(); sleep(1)
        tiles(app, "P05"); shot("P05-trail-reading-lane")
        tapLevel(app, "reading-fr-r1")
        playRound(app, tag: "R1")
        if summaryVisible(app, wait: 1) { shot("R1-summary"); leaveSummary(app) }

        // Unlock R2 and R3 through the saved file (host), then play them.
        app.terminate()
        request("seed")
        app = XCUIApplication(); app.launch()
        _ = playButton(app).waitForExistence(timeout: 30)
        tapSafe(playButton(app)); _ = level(app, "math-bonds-10").waitForExistence(timeout: 10)
        app.swipeUp(); sleep(1)
        tiles(app, "P06"); shot("P06-trail-after-seed")
        for (id, tag) in [("reading-fr-r2", "R2"), ("reading-fr-r3", "R3")] {
            tapLevel(app, id)
            playRound(app, tag: tag)
            if summaryVisible(app, wait: 1) { shot("\(tag)-summary"); leaveSummary(app) }
        }

        // Sound control and diagnostics.
        app.swipeDown(); sleep(1)
        let music = el(app, "sproutlab.music")
        note("music before label='\(music.label)'")
        tapSafe(music); sleep(1)
        note("music after label='\(music.label)' selected=\(music.isSelected)")
        shot("U01-music-on")
        tapSafe(music); sleep(1)
        titleTarget(app).press(forDuration: 3.5); sleep(1)
        note("after hold: diagnostics=\(app.staticTexts["Diagnostics"].exists) trail=\(level(app, "math-bonds-10").exists)")
        frames(app, "D01")
        shot("D01-diagnostics")
        let gallery = app.buttons.matching(NSPredicate(format: "label IN %@", ["Galerie", "Gallery"])).firstMatch
        if gallery.waitForExistence(timeout: 2) {
            tapSafe(gallery); sleep(2)
            shot("D02-gallery-1")
            app.swipeUp(); sleep(1); shot("D03-gallery-2")
            tapSafe(closeButton(app)); sleep(1)
        } else { note("gallery button ABSENT") }
        if closeButton(app).exists { tapSafe(closeButton(app)); sleep(1) } else { dismissSheet(app) }
        tapSafe(titleTarget(app)); sleep(1)
        note("tap home: home=\(playButton(app).waitForExistence(timeout: 5))")
        shot("P07-home-after-title-tap")

        // English: trail and one question of each math kind.
        let en = app.buttons["Anglais"]
        if en.waitForExistence(timeout: 2) { tapSafe(en); sleep(1) } else { note("EN segment ABSENT") }
        tapSafe(playButton(app)); _ = level(app, "math-bonds-10").waitForExistence(timeout: 10)
        shot("E01-trail-en")
        for id in ["math-bonds-10", "math-add-sub-20", "math-patterns-20"] {
            tapLevel(app, id)
            note("E \(id) prompt='\(promptText(app))' stimulus=\(stimulusValue(app))")
            shot("E-\(id)-q1")
            back(app)
        }
        let fr = app.buttons["French"]
        if fr.waitForExistence(timeout: 2) { tapSafe(fr); sleep(1) }

        // Landscape: trail, question, terrarium.
        XCUIDevice.shared.orientation = .landscapeLeft; sleep(2)
        chrome(app, "L01"); frames(app, "L01"); shot("L01-trail-landscape")
        tapLevel(app, "math-add-sub-20")
        chrome(app, "L02"); frames(app, "L02"); shot("L02-question-landscape")
        app.swipeUp(); sleep(1); shot("L03-question-landscape-scrolled")
        back(app)
        tapSafe(el(app, "sproutlab.terrarium.open")); sleep(2)
        frames(app, "L04"); shot("L04-terrarium-landscape")
        closeTerrarium(app)
        XCUIDevice.shared.orientation = .portrait; sleep(2)

        // Larger Text (accessibility XL): relaunch.
        app.terminate()
        request("xl")
        let large = XCUIApplication()
        large.launchArguments += ["-UIPreferredContentSizeCategoryName", "UICTContentSizeCategoryAccessibilityXL"]
        large.launch()
        _ = playButton(large).waitForExistence(timeout: 30)
        chrome(large, "X01"); frames(large, "X01"); shot("X01-welcome-xl")
        tapSafe(playButton(large)); _ = level(large, "math-bonds-10").waitForExistence(timeout: 10)
        tiles(large, "X02"); frames(large, "X02"); shot("X02-trail-xl")
        large.swipeUp(); sleep(1); shot("X03-trail-xl-scrolled")
        large.swipeUp(); sleep(1); shot("X04-trail-xl-scrolled-2")
        large.swipeDown(); large.swipeDown(); sleep(1)
        tapLevel(large, "math-bonds-10")
        frames(large, "X05"); shot("X05-question-xl")
        large.swipeUp(); sleep(1); shot("X06-question-xl-scrolled")
        back(large)
        tapLevel(large, "reading-fr-r1")
        frames(large, "X07"); shot("X07-reading-xl")
        back(large)

        // Dark (live switch by the host).
        request("dark")
        shot("K01-trail-dark")
        tapLevel(large, "math-patterns-20")
        shot("K02-question-dark-xl")
        back(large)
        tapLevel(large, "reading-fr-r2")
        shot("K03-reading-dark-xl")
        back(large)
        terrariumTour(large, tag: "K", full: false)
        note("DONE")
    }

    // MARK: - iPad

    @MainActor
    func testB_Pad() throws {
        XCUIDevice.shared.orientation = .portrait
        let app = XCUIApplication()
        app.launch()
        XCTAssertTrue(playButton(app).waitForExistence(timeout: 60), "welcome")
        chrome(app, "I01"); titles(app, "I01"); shot("I01-welcome-ipad")
        tapSafe(playButton(app)); _ = level(app, "math-bonds-10").waitForExistence(timeout: 10)
        tiles(app, "I02"); frames(app, "I02"); shot("I02-trail-ipad")
        tapLevel(app, "math-bonds-10")
        playRound(app, tag: "IM1")
        shot("I03-summary-ipad")
        terrariumTour(app, tag: "IG", full: true)
        leaveSummary(app)
        XCUIDevice.shared.orientation = .landscapeLeft; sleep(2)
        chrome(app, "I04"); frames(app, "I04"); shot("I04-trail-ipad-landscape")
        tapLevel(app, "math-add-sub-20")
        frames(app, "I05"); shot("I05-question-ipad-landscape")
        back(app)
        tapLevel(app, "reading-fr-r1")
        playRound(app, tag: "IR1", maxQuestions: 2)
        back(app)
        tapSafe(el(app, "sproutlab.terrarium.open")); sleep(2)
        frames(app, "I06"); shot("I06-terrarium-ipad-landscape")
        closeTerrarium(app)
        request("dark")
        shot("I07-trail-ipad-landscape-dark")
        tapLevel(app, "math-patterns-20")
        shot("I08-question-ipad-dark")
        back(app)
        XCUIDevice.shared.orientation = .portrait; sleep(2)
        titleTarget(app).press(forDuration: 3.5); sleep(1)
        shot("I09-diagnostics-ipad")
        note("DONE")
    }

    // MARK: - Terrarium tour

    @MainActor
    private func terrariumTour(_ app: XCUIApplication, tag: String, full: Bool) {
        let open = el(app, "sproutlab.terrarium.open")
        note("\(tag) star button label='\(open.label)' frame=\(open.frame)")
        tapSafe(open); sleep(2)
        let garden = el(app, "sproutlab.terrarium")
        note("\(tag) terrarium=\(garden.exists) panL=\(el(app, "sproutlab.pan.left").exists) journal=\(el(app, "sproutlab.journal").exists)")
        frames(app, "\(tag)01")
        shot("\(tag)01-terrarium")
        let dial = app.buttons.matching(NSPredicate(format: "label BEGINSWITH %@ OR label BEGINSWITH %@",
                                                    "Cadran", "Sun and moon")).firstMatch
        if dial.exists {
            for i in 2...(full ? 5 : 3) { tapSafe(dial); sleep(1); shot("\(tag)0\(i)-dial-\(i - 1)") }
        } else { note("\(tag) dial ABSENT") }
        if full {
            let right = el(app, "sproutlab.pan.right")
            if right.exists { tapSafe(right); sleep(1); shot("\(tag)06-pan-right") }
            let creatures = app.descendants(matching: .any).matching(NSPredicate(format: "identifier BEGINSWITH %@", "sproutlab.creature.")).allElementsBoundByIndex
            note("\(tag) creatures: " + creatures.map { "\($0.identifier)@\($0.frame) '\($0.label)'" }.joined(separator: " ; "))
            if let c = creatures.first(where: { onScreen($0) }) { tapSafe(c); sleep(1); shot("\(tag)07-resident-tap") }
            let welcome = app.descendants(matching: .any).matching(NSPredicate(format: "identifier BEGINSWITH %@", "sproutlab.welcome.")).firstMatch
            if welcome.exists { tapSafe(welcome); sleep(1); shot("\(tag)08-welcome-tap") } else { note("\(tag) no welcome control") }
        }
        let journal = el(app, "sproutlab.journal")
        if journal.exists {
            tapSafe(journal); sleep(2)
            frames(app, "\(tag)09"); shot("\(tag)09-journal")
            if full { app.swipeUp(); sleep(1); shot("\(tag)10-journal-scrolled") }
            let jclose = el(app, "sproutlab.journal.close")
            if !tapSafe(jclose) { note("\(tag) journal close not tappable") }
            sleep(1)
        } else { note("\(tag) journal ABSENT") }
        closeTerrarium(app)
        note("\(tag) after close: terrarium=\(el(app, "sproutlab.terrarium").exists) star='\(el(app, "sproutlab.terrarium.open").label)'")
    }

    @MainActor
    private func closeTerrarium(_ app: XCUIApplication) {
        let close = el(app, "sproutlab.terrarium.close")
        if !(close.exists && tapSafe(close)) { note("terrarium close not tappable; swiping the sheet down"); dismissSheet(app) }
        sleep(1)
        if el(app, "sproutlab.terrarium.view").exists { dismissSheet(app) }
    }

    // MARK: - Round driver

    @MainActor
    private func playRound(_ app: XCUIApplication, tag: String, maxQuestions: Int = 5) {
        var asked = 0
        var wrongShot = false
        var lastQ = ""
        for _ in 0..<12 {
            if summaryVisible(app, wait: 0) { break }
            guard el(app, "sproutlab.back").waitForExistence(timeout: 4) else { note("\(tag) no question"); break }
            let q = progressLabel(app)
            if q != lastQ { asked += 1; lastQ = q }
            if asked > maxQuestions { note("\(tag) stop after \(maxQuestions) questions"); return }
            let kits = kitTargets(app)
            note("\(tag) \(q) prompt='\(promptText(app))' stimulus=\(stimulusValue(app)) choices=\(choiceValues(app)) kit=\(kits.map { "\($0.identifier)'\($0.label)'" })")
            frames(app, "\(tag)-\(q)")
            shot("\(tag)-\(q.filter { $0.isNumber })")
            var advanced = false
            if kits.isEmpty {
                let choices = choiceValues(app)
                let first = choices.firstIndex(of: expected(stimulusValue(app))) ?? 0
                for i in [first] + (0..<choices.count).filter({ $0 != first }) {
                    tapSafe(el(app, "sproutlab.choice.\(i)"))
                    usleep(700_000)
                    if summaryVisible(app, wait: 0) || progressLabel(app) != q { advanced = true; break }
                    note("\(tag) \(q) choice \(i) wrong; feedback='\(feedback(app))'")
                    if !wrongShot { shot("\(tag)-wrong-cue"); wrongShot = true }
                }
            } else {
                advanced = solveKit(app, tag: tag, q: q)
            }
            if !advanced {
                note("\(tag) \(q) NOT ADVANCED; abandoning round")
                shot("\(tag)-\(q.filter { $0.isNumber })-stuck")
                back(app)
                return
            }
        }
        note("\(tag) summary=\(summaryVisible(app, wait: 3)) star='\(el(app, "sproutlab.terrarium.open").label)'")
    }

    /// Kit items: ordering is solved from its known rotation; picture reveal and tile sets by trying each target;
    /// slot boards and sorting get one demonstration tap pair and a screenshot.
    @MainActor
    private func solveKit(_ app: XCUIApplication, tag: String, q: String) -> Bool {
        func moved() -> Bool { summaryVisible(app, wait: 0) || progressLabel(app) != q }
        let ids = kitTargets(app).map { $0.identifier }
        let n = ids.filter { $0.hasPrefix("sproutlab.kit.order.") }.count
        if n >= 2 {
            var taps = [n - 1]
            if n >= 3 { taps += Array((0...(n - 3)).reversed()) }
            for i in taps { tapSafe(el(app, "sproutlab.kit.order.\(i)")); usleep(500_000) }
            shot("\(tag)-\(q.filter { $0.isNumber })-ordered")
            if moved() { return true }
            note("\(tag) \(q) ordering not accepted after taps \(taps)")
            return false
        }
        if ids.contains("sproutlab.kit.begin") || ids.contains(where: { $0.hasPrefix("sproutlab.kit.answer.") }) {
            for k in 0..<5 {
                if el(app, "sproutlab.kit.reset").exists { tapSafe(el(app, "sproutlab.kit.reset")); usleep(400_000) }
                if el(app, "sproutlab.kit.begin").exists { tapSafe(el(app, "sproutlab.kit.begin")); usleep(500_000) }
                if k == 0 { shot("\(tag)-\(q.filter { $0.isNumber })-answering") }
                let a = el(app, "sproutlab.kit.answer.\(k)")
                guard a.exists else { break }
                tapSafe(a); usleep(900_000)
                if k == 0 { shot("\(tag)-\(q.filter { $0.isNumber })-revealed") }
                if moved() { return true }
            }
            return moved()
        }
        let tileCount = ids.filter { $0.hasPrefix("sproutlab.kit.tile.") }.count
        if tileCount > 0 {
            for i in 0..<tileCount {
                let t = el(app, "sproutlab.kit.tile.\(i)")
                if t.exists { tapSafe(t); usleep(700_000) }
                if i == 0 { shot("\(tag)-\(q.filter { $0.isNumber })-tile-tap") }
                if moved() { return true }
            }
            return moved()
        }
        // Slot board or sorting: demonstrate one placement and stop.
        if el(app, "sproutlab.kit.palette.0").exists && el(app, "sproutlab.kit.slot.0").exists {
            tapSafe(el(app, "sproutlab.kit.palette.0")); usleep(400_000)
            shot("\(tag)-\(q.filter { $0.isNumber })-picked")
            tapSafe(el(app, "sproutlab.kit.slot.0")); usleep(500_000)
            shot("\(tag)-\(q.filter { $0.isNumber })-placed")
        } else if el(app, "sproutlab.kit.unsorted.0").exists && el(app, "sproutlab.kit.bin.0").exists {
            tapSafe(el(app, "sproutlab.kit.unsorted.0")); usleep(400_000)
            shot("\(tag)-\(q.filter { $0.isNumber })-picked")
            tapSafe(el(app, "sproutlab.kit.bin.0")); usleep(500_000)
            shot("\(tag)-\(q.filter { $0.isNumber })-binned")
        }
        note("\(tag) \(q) kit after demo: " + kitTargets(app).map { "\($0.identifier)'\($0.label)'" }.joined(separator: " ; "))
        return moved()
    }

    private func expected(_ stim: String) -> String {
        let nums = stim.split(whereSeparator: { !$0.isNumber }).map(String.init)
        if stim.contains("crossed") || stim.contains("barr") { return nums.first ?? "?" }
        if (stim.contains("filled") && stim.contains("empty")) || (stim.contains("rempli") && stim.contains("vide")) {
            return nums.count > 1 ? nums[1] : "?"
        }
        if (stim.contains(" and ") || stim.contains(" et ")) && nums.count > 1 {
            return String((Int(nums[0]) ?? 0) + (Int(nums[1]) ?? 0))
        }
        return nums.first ?? "?"
    }

    /// Taps an element by coordinate when its centre lies inside the window; otherwise logs UNREACHABLE.
    /// Never asks for hittability: on an off-screen element that call itself fails the test.
    @MainActor @discardableResult
    private func tapSafe(_ e: XCUIElement) -> Bool {
        guard e.exists else { note("UNREACHABLE (absent) \(e.description.prefix(120))"); return false }
        let f = e.frame
        if onScreen(e) {
            XCUIApplication().coordinate(withNormalizedOffset: .zero).withOffset(CGVector(dx: f.midX, dy: f.midY)).tap()
            return true
        }
        note("UNREACHABLE (off-screen) \(e.identifier) '\(e.label)' frame=\(f) window=\(XCUIApplication().windows.firstMatch.frame)")
        return false
    }

    @MainActor
    private func onScreen(_ e: XCUIElement) -> Bool {
        guard e.exists else { return false }
        let f = e.frame
        let w = XCUIApplication().windows.firstMatch.frame
        return w.insetBy(dx: 2, dy: 2).contains(CGPoint(x: f.midX, y: f.midY))
    }

    // MARK: - Host handshake

    private func request(_ what: String) {
        let ok = URL(fileURLWithPath: "/tmp/slctl/\(what)-ok")
        note("REQUEST \(what)")
        for _ in 0..<30 where !FileManager.default.fileExists(atPath: ok.path) { usleep(500_000) }
        note("REQUEST \(what) acknowledged=\(FileManager.default.fileExists(atPath: ok.path))")
        sleep(1)
    }

    // MARK: - Helpers

    @MainActor
    private func kitTargets(_ app: XCUIApplication) -> [XCUIElement] {
        app.descendants(matching: .any).matching(NSPredicate(format: "identifier BEGINSWITH %@", "sproutlab.kit.")).allElementsBoundByIndex
    }

    @MainActor
    private func titleTarget(_ app: XCUIApplication) -> XCUIElement {
        let all = app.descendants(matching: .any).matching(identifier: "sproutlab.title").allElementsBoundByIndex
        if all.isEmpty { return el(app, "sproutlab.icon") }
        return all.min(by: { $0.frame.width < $1.frame.width })!
    }

    @MainActor
    private func titles(_ app: XCUIApplication, _ tag: String) {
        let all = app.descendants(matching: .any).matching(identifier: "sproutlab.title").allElementsBoundByIndex
        note("titles \(tag): title x\(all.count) " + all.map { "\($0.elementType.rawValue)@\($0.frame) '\($0.label)'" }.joined(separator: " , "))
    }

    @MainActor
    private func frames(_ app: XCUIApplication, _ tag: String) {
        let lines = app.debugDescription.split(separator: "\n")
            .filter { $0.contains("Button") || $0.contains("StaticText") || $0.contains("Window") || $0.contains("Image") || $0.contains("identifier") }
            .map { $0.trimmingCharacters(in: .whitespaces) }
        note("frames \(tag): " + lines.joined(separator: " || "))
    }

    @MainActor
    private func tiles(_ app: XCUIApplication, _ tag: String) {
        note("tiles \(tag): " + Self.levelIds.map { let t = level(app, $0); return t.exists ? "\($0)=\(t.frame) enabled=\(t.isEnabled) '\(t.label)'" : "\($0)=ABSENT" }.joined(separator: " ; "))
    }

    @MainActor
    private func closeButton(_ app: XCUIApplication) -> XCUIElement {
        app.buttons.matching(NSPredicate(format: "label IN %@", ["Fermer", "Close"])).firstMatch
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
        let b = summaryButton(app)
        if b.exists { tapSafe(b); sleep(1) } else { note("summary back ABSENT") }
    }

    @MainActor
    private func back(_ app: XCUIApplication) {
        let b = el(app, "sproutlab.back")
        if b.exists { tapSafe(b); sleep(1) } else { note("round back ABSENT") }
    }

    /// Scrolls the trail until the level tile is hittable, then taps it and waits for the round.
    @MainActor
    private func tapLevel(_ app: XCUIApplication, _ id: String) {
        let t = level(app, id)
        if !t.waitForExistence(timeout: 5) { note("level \(id) ABSENT"); return }
        var tries = 0
        while !onScreen(t) && tries < 4 { app.swipeUp(); usleep(500_000); tries += 1 }
        tries = 0
        while !onScreen(t) && tries < 4 { app.swipeDown(); usleep(500_000); tries += 1 }
        note("level \(id) enabled=\(t.isEnabled) '\(t.label)'")
        tapSafe(t)
        if !el(app, "sproutlab.back").waitForExistence(timeout: 5) { note("level \(id) did not open a round") }
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
    private func summaryButton(_ app: XCUIApplication) -> XCUIElement {
        app.buttons.matching(NSPredicate(format: "label IN %@", ["Back to the trail", "Retour au sentier"])).firstMatch
    }

    @MainActor
    private func summaryVisible(_ app: XCUIApplication, wait: TimeInterval) -> Bool {
        let s = summaryButton(app)
        return wait > 0 ? s.waitForExistence(timeout: wait) : s.exists
    }

    @MainActor
    private func chrome(_ app: XCUIApplication, _ tag: String) {
        var parts: [String] = []
        for id in ["sproutlab.title", "sproutlab.icon", "sproutlab.language", "sproutlab.music", "sproutlab.terrarium.open",
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

    /// All visible static texts except the progress line, joined: the prompt as the child sees it.
    @MainActor
    private func promptText(_ app: XCUIApplication) -> String {
        app.staticTexts.allElementsBoundByIndex.map { $0.label }.filter { !$0.hasPrefix("Question ") }.joined(separator: " | ")
    }

    @MainActor
    private func feedback(_ app: XCUIApplication) -> String {
        promptText(app)
    }

    @MainActor
    private func stimulusValue(_ app: XCUIApplication) -> String {
        let s = el(app, "sproutlab.stimulus")
        return s.exists ? ((s.value as? String) ?? "<no value>") : "<missing>"
    }

    @MainActor
    private func choiceValues(_ app: XCUIApplication) -> [String] {
        (0..<3).compactMap { let c = el(app, "sproutlab.choice.\($0)"); return c.exists ? ((c.value as? String) ?? c.label) : nil }
    }

    private func note(_ line: String) {
        print("AUDIT \(String(format: "%.1f", Date().timeIntervalSince1970.truncatingRemainder(dividingBy: 10000))) \(line)")
        fflush(stdout)
    }

    @MainActor
    private func shot(_ name: String) {
        let png = XCUIScreen.main.screenshot().pngRepresentation
        let dir = URL(fileURLWithPath: "/tmp/slshots")
        try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        try? png.write(to: dir.appendingPathComponent("\(name).png"))
        note("shot \(name)")
    }
}
