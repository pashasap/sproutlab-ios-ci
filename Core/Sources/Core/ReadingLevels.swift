extension Curriculum {
    static let readingTitleKeys = ["trail.level.reading-fr-r1.title", "trail.level.reading-fr-r2.title",
                                   "trail.level.reading-fr-r3.title", "trail.level.reading-fr-r6.title",
                                   "trail.level.reading-fr-r8.title"]

    /// The five French reading levels, each added by data; r8 sits directly after r6.
    static let readingLevels: [LevelDefinition] = [readingR1Level, readingR2Level, readingR3Level,
                                                   readingFR6Level, readingFR8Level]
}
