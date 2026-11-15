import Foundation

public struct KitSortBin: Sendable, Equatable {
    public let iconKey: String
    public internal(set) var tokens: [String]
}

/// Sorting: pick an unsorted token, tap a bin to put it there, tap a sorted token to take it back.
public struct KitSorting: KitComponent {
    struct Step: Sendable, Equatable {
        let token: String
        let bin: Int
        let unsortedIndex: Int
        let sorted: Bool
    }

    public private(set) var bins: [KitSortBin]
    public private(set) var unsorted: [String]
    public private(set) var selectedToken: String?
    public private(set) var announcements: [KitAnnouncement] = []
    private var history: [Step] = []

    public init(tokens: [String], binIcons: [String]) throws {
        guard (2...3).contains(binIcons.count) else { throw KitError.binCount(binIcons.count) }
        let allowed = Set(ChromeCatalog.allSymbolNames)
        let drawn = allowed.union(ChromeCatalog.terrariumSymbolNames)
        for key in binIcons where !drawn.contains(key) && !drawn.contains(TextTable.string(key, .en)) {
            throw KitError.unknownIcon(key)
        }
        bins = binIcons.map { KitSortBin(iconKey: $0, tokens: []) }
        unsorted = tokens
    }

    /// Spoken label of a bin, independent of the selection; never empty.
    public func binLabel(at index: Int, language: Language) -> String {
        let template = TextTable.string("kit.bin.label", language)
        var what = ""
        if bins.indices.contains(index) {
            let key = bins[index].iconKey
            let labelKey = key + ".label"
            if TextTable.entries[labelKey] != nil || TextTable.iconLabel(labelKey) != nil {
                what = TextTable.string(labelKey, language)
            } else if let entry = TextTable.iconLabel(forSymbol: key) {
                what = language == .fr ? entry.fr : entry.en
            }
        }
        if what.isEmpty {
            return TextTable.string("kit.bin.fallback", language) + " \(index + 1)"
        }
        return template.replacingOccurrences(of: "{what}", with: what)
    }

    public var complete: Bool { unsorted.isEmpty }

    public mutating func select(_ token: String) {
        guard unsorted.contains(token), selectedToken != token else { return }
        selectedToken = token
        announcements.append(KitAnnouncement(key: "kit.say.selected", subject: token))
    }

    public mutating func tap(_ bin: Int) {
        guard bins.indices.contains(bin), let token = selectedToken,
              let index = unsorted.firstIndex(of: token) else { return }
        unsorted.remove(at: index)
        bins[bin].tokens.append(token)
        selectedToken = nil
        history.append(Step(token: token, bin: bin, unsortedIndex: index, sorted: true))
        announcements.append(KitAnnouncement(key: complete ? "kit.say.complete" : "kit.say.sorted", subject: token))
    }

    public mutating func tapSorted(_ token: String) {
        guard let bin = bins.firstIndex(where: { $0.tokens.contains(token) }) else { return }
        bins[bin].tokens.removeAll { $0 == token }
        unsorted.append(token)
        history.append(Step(token: token, bin: bin, unsortedIndex: unsorted.count - 1, sorted: false))
        announcements.append(KitAnnouncement(key: "kit.say.returned", subject: token))
    }

    public mutating func undo() {
        guard let step = history.popLast() else { return }
        if step.sorted {
            bins[step.bin].tokens.removeAll { $0 == step.token }
            unsorted.insert(step.token, at: min(step.unsortedIndex, unsorted.count))
        } else {
            unsorted.removeAll { $0 == step.token }
            bins[step.bin].tokens.append(step.token)
        }
        selectedToken = nil
        announcements.append(KitAnnouncement(key: "kit.say.undone", subject: step.token))
    }

    public mutating func apply(_ command: KitCommand) {
        switch command {
        case .select(let token): select(token)
        case .tapBin(let bin): tap(bin)
        case .tapSorted(let token): tapSorted(token)
        case .undo: undo()
        default: break
        }
    }

    public var accessibilityActions: [KitAccessibilityAction] {
        var list = unsorted.map { KitAccessibilityAction(labelKey: "kit.action.select", command: .select($0), subject: $0) }
        if selectedToken != nil {
            list += bins.indices.map { KitAccessibilityAction(labelKey: "kit.action.bin", command: .tapBin($0)) }
        }
        list += bins.flatMap(\.tokens).map {
            KitAccessibilityAction(labelKey: "kit.action.sorted", command: .tapSorted($0), subject: $0)
        }
        list.append(KitAccessibilityAction(labelKey: "kit.action.undo", command: .undo))
        return list
    }

    public var tapTargets: [KitTapTarget] {
        var list = bins.indices.map { KitTapTarget(identifier: KitIdentifier.make("bin", $0), command: .tapBin($0)) }
        for (index, token) in unsorted.enumerated() {
            list.append(KitTapTarget(identifier: KitIdentifier.make("unsorted", index), command: .select(token), subject: token))
        }
        for (index, token) in bins.flatMap(\.tokens).enumerated() {
            list.append(KitTapTarget(identifier: KitIdentifier.make("sorted", index), command: .tapSorted(token), subject: token))
        }
        list.append(KitTapTarget(identifier: KitIdentifier.make("undo"), command: .undo))
        return list
    }
}
