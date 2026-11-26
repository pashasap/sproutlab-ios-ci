let auditStops: [(id: String, root: String)] = [
    (id: "welcome", root: "sproutlab.audit.welcome"),
    (id: "explorer-trail", root: "sproutlab.audit.explorer-trail"),
    (id: "round-summary", root: "sproutlab.audit.round-summary"),
    (id: "terrarium", root: "sproutlab.audit.terrarium"),
    (id: "creature-gallery", root: "sproutlab.audit.creature-gallery"),
    (id: "journal", root: "sproutlab.audit.journal"),
    (id: "diagnostics", root: "sproutlab.audit.diagnostics"),
    (id: "math-m1-count", root: "sproutlab.audit.math-m1-count"),
    (id: "math-m2-ten", root: "sproutlab.audit.math-m2-ten"),
    (id: "math-counting", root: "sproutlab.audit.math-counting"),
    (id: "math-make-ten", root: "sproutlab.audit.math-make-ten"),
    (id: "math-addition", root: "sproutlab.audit.math-addition"),
    (id: "math-subtraction", root: "sproutlab.audit.math-subtraction"),
    (id: "math-pattern", root: "sproutlab.audit.math-pattern"),
    (id: "math-comparison", root: "sproutlab.audit.math-comparison"),
    (id: "reading-tap-grapheme", root: "sproutlab.audit.reading-tap-grapheme"),
    (id: "reading-sequence-sounds", root: "sproutlab.audit.reading-sequence-sounds"),
    (id: "reading-blend-new", root: "sproutlab.audit.reading-blend-new"),
    (id: "reading-decode-reveal", root: "sproutlab.audit.reading-decode-reveal"),
    (id: "reading-change-grapheme", root: "sproutlab.audit.reading-change-grapheme"),
    (id: "reading-build-word", root: "sproutlab.audit.reading-build-word"),
    (id: "reading-select-digraph", root: "sproutlab.audit.reading-select-digraph"),
    (id: "reading-blend-word", root: "sproutlab.audit.reading-blend-word"),
    (id: "reading-repair-split", root: "sproutlab.audit.reading-repair-split"),
    (id: "reading-en-sounds", root: "sproutlab.audit.reading-en-sounds"),
    (id: "reading-en-words", root: "sproutlab.audit.reading-en-words"),
    (id: "reading-en-digraphs", root: "sproutlab.audit.reading-en-digraphs"),
    (id: "robot-c1", root: "sproutlab.audit.robot-c1"),
    (id: "robot-c2", root: "sproutlab.audit.robot-c2"),
    (id: "robot-c3", root: "sproutlab.audit.robot-c3"),
    (id: "robot-c4", root: "sproutlab.audit.robot-c4"),
    (id: "music-a4", root: "sproutlab.audit.music-a4"),
    (id: "reading-fr-r6", root: "sproutlab.audit.reading-fr-r6"),
    (id: "reading-en-r6", root: "sproutlab.audit.reading-en-r6"),
    (id: "reading-fr-r8", root: "sproutlab.audit.reading-fr-r8"),
    (id: "reading-en-r8", root: "sproutlab.audit.reading-en-r8"),
]

extension AuditStopsUITests {
    @MainActor func test_001_welcome() { visit("welcome", root: "sproutlab.audit.welcome") }
    @MainActor func test_002_explorer_trail() { visit("explorer-trail", root: "sproutlab.audit.explorer-trail") }
    @MainActor func test_003_round_summary() { visit("round-summary", root: "sproutlab.audit.round-summary") }
    @MainActor func test_004_terrarium() { visit("terrarium", root: "sproutlab.audit.terrarium") }
    @MainActor func test_005_creature_gallery() { visit("creature-gallery", root: "sproutlab.audit.creature-gallery") }
    @MainActor func test_006_journal() { visit("journal", root: "sproutlab.audit.journal") }
    @MainActor func test_007_diagnostics() { visit("diagnostics", root: "sproutlab.audit.diagnostics") }
    @MainActor func test_008_math_m1_count() { visit("math-m1-count", root: "sproutlab.audit.math-m1-count") }
    @MainActor func test_009_math_m2_ten() { visit("math-m2-ten", root: "sproutlab.audit.math-m2-ten") }
    @MainActor func test_010_math_counting() { visit("math-counting", root: "sproutlab.audit.math-counting") }
    @MainActor func test_011_math_make_ten() { visit("math-make-ten", root: "sproutlab.audit.math-make-ten") }
    @MainActor func test_012_math_addition() { visit("math-addition", root: "sproutlab.audit.math-addition") }
    @MainActor func test_013_math_subtraction() { visit("math-subtraction", root: "sproutlab.audit.math-subtraction") }
    @MainActor func test_014_math_pattern() { visit("math-pattern", root: "sproutlab.audit.math-pattern") }
    @MainActor func test_015_math_comparison() { visit("math-comparison", root: "sproutlab.audit.math-comparison") }
    @MainActor func test_016_reading_tap_grapheme() { visit("reading-tap-grapheme", root: "sproutlab.audit.reading-tap-grapheme") }
    @MainActor func test_017_reading_sequence_sounds() { visit("reading-sequence-sounds", root: "sproutlab.audit.reading-sequence-sounds") }
    @MainActor func test_018_reading_blend_new() { visit("reading-blend-new", root: "sproutlab.audit.reading-blend-new") }
    @MainActor func test_019_reading_decode_reveal() { visit("reading-decode-reveal", root: "sproutlab.audit.reading-decode-reveal") }
    @MainActor func test_020_reading_change_grapheme() { visit("reading-change-grapheme", root: "sproutlab.audit.reading-change-grapheme") }
    @MainActor func test_021_reading_build_word() { visit("reading-build-word", root: "sproutlab.audit.reading-build-word") }
    @MainActor func test_022_reading_select_digraph() { visit("reading-select-digraph", root: "sproutlab.audit.reading-select-digraph") }
    @MainActor func test_023_reading_blend_word() { visit("reading-blend-word", root: "sproutlab.audit.reading-blend-word") }
    @MainActor func test_024_reading_repair_split() { visit("reading-repair-split", root: "sproutlab.audit.reading-repair-split") }
    @MainActor func test_025_reading_en_sounds() { visit("reading-en-sounds", root: "sproutlab.audit.reading-en-sounds") }
    @MainActor func test_026_reading_en_words() { visit("reading-en-words", root: "sproutlab.audit.reading-en-words") }
    @MainActor func test_027_reading_en_digraphs() { visit("reading-en-digraphs", root: "sproutlab.audit.reading-en-digraphs") }
    @MainActor func test_028_robot_c1() { visit("robot-c1", root: "sproutlab.audit.robot-c1") }
    @MainActor func test_029_robot_c2() { visit("robot-c2", root: "sproutlab.audit.robot-c2") }
    @MainActor func test_030_robot_c3() { visit("robot-c3", root: "sproutlab.audit.robot-c3") }
    @MainActor func test_031_robot_c4() { visit("robot-c4", root: "sproutlab.audit.robot-c4") }
    @MainActor func test_032_music_a4() { visit("music-a4", root: "sproutlab.audit.music-a4") }
    @MainActor func test_033_reading_fr_r6() { visit("reading-fr-r6", root: "sproutlab.audit.reading-fr-r6") }
    @MainActor func test_034_reading_en_r6() { visit("reading-en-r6", root: "sproutlab.audit.reading-en-r6") }
    @MainActor func test_035_reading_fr_r8() { visit("reading-fr-r8", root: "sproutlab.audit.reading-fr-r8") }
    @MainActor func test_036_reading_en_r8() { visit("reading-en-r8", root: "sproutlab.audit.reading-en-r8") }
}
