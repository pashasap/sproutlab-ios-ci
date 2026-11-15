/// Pure layout decisions; they depend only on the width they are given, never on the device type.
public enum LayoutPolicy {
    public static let sideBySideMinimumWidth: Double = 600
    public static let maximumTrailColumns = 3

    public static func usesSideBySide(width: Double) -> Bool {
        width >= sideBySideMinimumWidth
    }

    /// Trail lanes: one column on narrow widths or a compact size class, one column per lane beside each other on wide.
    public static func trailColumns(width: Double, isCompactSizeClass: Bool, laneCount: Int) -> Int {
        guard !isCompactSizeClass, usesSideBySide(width: width) else { return 1 }
        return max(1, min(laneCount, maximumTrailColumns))
    }
}

/// What a screen renders: the bar is always pinned; the content scrolls only when it does not fit below the bar.
public struct ScreenLayout: Equatable {
    public let topBarPinned: Bool
    public let contentScrolls: Bool
}

extension LayoutPolicy {
    /// Height reserved for the top bar, in points.
    public static let topBarHeight: Double = 72

    public static func screenLayout(availableHeight: Double, contentHeight: Double) -> ScreenLayout {
        ScreenLayout(topBarPinned: true,
                     contentScrolls: contentHeight > availableHeight - topBarHeight)
    }
}

public enum Touch {
    /// Minimum side of every interactive control, in points.
    public static let minimumPoints: Double = 56
}
