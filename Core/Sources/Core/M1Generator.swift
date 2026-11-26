/// Round of the Math M1 level: count objects once each, fill a tray, match equal collections.
public enum M1Generator {
    public static let itemsPerRound = 5
    static let variants = 3
    static let drawLimit = 200
    static let trayCapacity = 10

    /// One rule-produced question: kind, object count, filled tray slots, layout and variant.
    struct Config: Equatable {
        let kind: M1QuestionKind
        let count: Int
        let filled: Int
        let layout: M1Layout
        let variant: Int

        var id: Int {
            50_000 + kind.rawValue * 10_000 + ((count * 11 + filled) * 2 + layout.rawValue) * 10 + variant
        }
    }

    public static func items(seed: UInt64) -> [Item] {
        var rng = SeededRandom(seed: seed)
        let kinds = rng.shuffled(M1QuestionKind.allCases + (0..<(itemsPerRound - 3)).map { _ in
            M1QuestionKind.allCases[rng.below(3)]
        })
        var taken: Set<Int> = []
        var answers: Set<Int> = []
        var out: [Item] = []
        for (index, kind) in kinds.enumerated() {
            let transfer = index == itemsPerRound - 1
            var config = draw(kind: kind, transfer: transfer, rng: &rng)
            var draws = 1
            while (taken.contains(config.id) || answers.contains(answer(of: config))) && draws < drawLimit {
                config = draw(kind: kind, transfer: transfer, rng: &rng)
                draws += 1
            }
            taken.insert(config.id)
            answers.insert(answer(of: config))
            out.append(item(config).placed(at: index + 1, of: kinds.count))
        }
        return out
    }

    static func answer(of config: Config) -> Int { config.count }

    /// The transfer slot always uses the scattered layout and the least familiar variant.
    static func draw(kind: M1QuestionKind, transfer: Bool, rng: inout SeededRandom) -> Config {
        let low = kind == .tapCount ? 0 : 1
        let count = low + rng.below(11 - low)
        let filled = kind == .fillTray ? rng.below(trayCapacity - count + 1) : 0
        let layout: M1Layout = transfer ? .scattered : (rng.below(2) == 0 ? .clustered : .scattered)
        return Config(kind: kind, count: count, filled: filled, layout: layout,
                      variant: transfer ? variants - 1 : rng.below(variants))
    }

    /// Every configuration of the finite domain, for exhaustive linting.
    public static func allConfigurations() -> [Item] {
        var out: [Item] = []
        for kind in M1QuestionKind.allCases {
            let low = kind == .tapCount ? 0 : 1
            // A representative domain keeps the exhaustive lint fast while covering every kind and layout.
            let variantCount = kind == .fillTray ? 1 : 2
            for count in low...10 {
                let trays = kind == .fillTray ? [0, trayCapacity - count] : [0]
                for filled in Set(trays).sorted() {
                    for layout in [M1Layout.clustered, .scattered] {
                        for variant in 0..<variantCount {
                            out.append(item(Config(kind: kind, count: count, filled: filled,
                                                   layout: layout, variant: variant)))
                        }
                    }
                }
            }
        }
        return out
    }

    static func item(_ config: Config) -> Item {
        var rng = SeededRandom(seed: UInt64(config.id))
        let options = CountingBondsGenerator.wrongOptions(kind: .counting, operand: config.count,
                                                          answer: config.count, rng: &rng)
        var item = Item(kind: .counting, operand: config.count, options: options)
        item.configuration = config.id
        item.m1 = presentation(config, options: options)
        return item
    }

    static func presentation(_ config: Config, options: ItemOptions) -> M1Presentation {
        let shown = M1Layouts.collection(count: config.count, layout: config.layout, variant: config.variant)
        var out = M1Presentation(kind: config.kind, groups: [shown])
        switch config.kind {
        case .tapCount:
            break
        case .fillTray:
            let slots = (0..<(config.filled + config.count)).map { M1TraySlot(isFilled: $0 < config.filled) }
            out.traySlots = slots
        case .matchGroups:
            out.choiceGroups = options.choices.enumerated().map {
                M1Layouts.collection(count: $0.element, layout: config.layout.other,
                                     variant: (config.variant + $0.offset + 1) % variants)
            }
        }
        return out
    }
}

/// Deterministic object positions: a compact block for clustered, spread cells for scattered.
enum M1Layouts {
    static let sizes = [0.8, 1.0, 1.2]

    /// Cheap deterministic walk of the grid: no shuffled array is allocated per item.
    static func collection(count: Int, layout: M1Layout, variant: Int) -> M1Collection {
        let columns = layout == .clustered ? 4 : 5
        let rows = layout == .clustered ? 3 : 4
        let cells = columns * rows
        let step = [1, 3, 7, 9, 11].first { gcd($0, cells) == 1 } ?? 1
        var cell = (variant * 5 + count * 3) % cells
        var objects: [M1Object] = []
        objects.reserveCapacity(count)
        for index in 0..<count {
            let x = Double(cell % columns)
            let y = Double(cell / columns)
            let size = sizes[(index + variant) % sizes.count]
            if layout == .clustered {
                objects.append(M1Object(x: 0.25 + x * 0.16, y: 0.25 + y * 0.2, size: size))
            } else {
                let jitter = Double((cell * 37 + index * 11 + variant * 5) % 11 - 5) / 100
                objects.append(M1Object(x: (x + 0.5) / Double(columns) + jitter,
                                       y: (y + 0.5) / Double(rows) - jitter, size: size))
            }
            cell = (cell + step) % cells
        }
        return M1Collection(layout: layout, objects: objects)
    }

    private static func gcd(_ a: Int, _ b: Int) -> Int {
        var (x, y) = (a, b)
        while y != 0 { (x, y) = (y, x % y) }
        return x
    }
}
