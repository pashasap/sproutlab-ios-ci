let auditStops: [(id: String, root: String)] = [
    (id: "math-counting", root: "sproutlab.audit.math-counting"),
]

extension AuditStopsUITests {
    @MainActor func test_001_math_counting() { visit("math-counting", root: "sproutlab.audit.math-counting") }
}
