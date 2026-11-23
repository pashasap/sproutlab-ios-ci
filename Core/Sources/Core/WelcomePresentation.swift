import Foundation

/// The single play control on the Welcome screen.
public struct WelcomePlayControl: Equatable {
    public let visibleLabel: String
    public let spokenLabel: String
    public let minimumWidth: Double
    public let minimumHeight: Double
}

/// Pure presentation value for the Welcome screen.
public struct WelcomePresentation: Equatable {
    public let titleText: String
    public let tagline: String
    public let playControls: [WelcomePlayControl]

    public init(language: Language) {
        titleText = TextTable.string("welcome.title", language)
        tagline = TextTable.string("welcome.tagline", language)
        playControls = [WelcomePlayControl(
            visibleLabel: TextTable.string("welcome.play", language),
            spokenLabel: TextTable.string("a11y.play", language),
            minimumWidth: 56,
            minimumHeight: 56)]
    }
}
