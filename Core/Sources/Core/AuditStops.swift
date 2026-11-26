/// One app state the factory looks at once per version.
public struct AuditStop: Sendable {
    public let id: String
    /// The accessibility identifier of the view that is on screen once the stop is open.
    public let root: String
    public let title: String
    /// One sentence a person can check on a screenshot or on the spoken labels of the controls.
    public let expectation: String
    /// Feature-map ids (F-nn) this stop is evidence for.
    public let flows: [String]
    /// Feedback ids of defects this stop is evidence for.
    public let defects: [String]
}

public enum AuditStops {
    public static let all: [AuditStop] = [
        AuditStop(id: "welcome", root: "sproutlab.audit.welcome", title: "Welcome", expectation: "The welcome screen shows the SproutLab title and one large play control with a spoken label.", flows: ["F-01"], defects: []),
        AuditStop(id: "explorer-trail", root: "sproutlab.audit.explorer-trail", title: "Explorer Trail", expectation: "The Explorer Trail shows a headed Math lane and a headed French reading lane with their level tiles.", flows: ["F-11"], defects: []),
        AuditStop(id: "round-summary", root: "sproutlab.audit.round-summary", title: "Round summary", expectation: "The round summary shows the three stars just earned and one control that returns to the trail.", flows: ["F-04"], defects: []),
        AuditStop(id: "terrarium", root: "sproutlab.audit.terrarium", title: "Terrarium", expectation: "The terrarium shows the garden residents with the day and night dial (Cadran), a close button 'Fermer le terrarium' and a nature journal button 'Mon carnet de nature'.", flows: ["F-16"], defects: []),
        AuditStop(id: "creature-gallery", root: "sproutlab.audit.creature-gallery", title: "Creature gallery", expectation: "The creature gallery draws every resident recipe at three sizes with the shared renderer.", flows: ["F-14"], defects: []),
        AuditStop(id: "journal", root: "sproutlab.audit.journal", title: "Journal", expectation: "The journal lists each met resident with a control that plays its call.", flows: [], defects: []),
        AuditStop(id: "diagnostics", root: "sproutlab.audit.diagnostics", title: "Diagnostics", expectation: "The diagnostics panel shows its measurements and a way to open the creature gallery.", flows: ["F-09"], defects: []),
        AuditStop(id: "math-m1-count", root: "sproutlab.audit.math-m1-count", title: "Math M1 count", expectation: "An M1 question shows a scattered collection of objects to count once each with three numeral choices.", flows: ["F-02"], defects: []),
        AuditStop(id: "math-m2-ten", root: "sproutlab.audit.math-m2-ten", title: "Math M2 ten frame", expectation: "A partly filled ten-frame shows some filled cells and some empty cells with three answer choices.", flows: ["F-02"], defects: []),
        AuditStop(id: "math-counting", root: "sproutlab.audit.math-counting", title: "Math counting question", expectation: "A counting question shows grouped dots with three answer choices and a back arrow.", flows: ["F-02"], defects: []),
        AuditStop(id: "math-make-ten", root: "sproutlab.audit.math-make-ten", title: "Math make-ten question", expectation: "A make-ten question shows a ten-frame of filled and empty places with three answer choices.", flows: ["F-02"], defects: []),
        AuditStop(id: "math-addition", root: "sproutlab.audit.math-addition", title: "Math addition question", expectation: "An addition question shows the two amounts being joined with three answer choices.", flows: ["F-12"], defects: []),
        AuditStop(id: "math-subtraction", root: "sproutlab.audit.math-subtraction", title: "Math subtraction question", expectation: "A subtraction question shows the dots taken away with a contrasting cross mark and three answer choices.", flows: ["F-12"], defects: []),
        AuditStop(id: "math-pattern", root: "sproutlab.audit.math-pattern", title: "Math pattern question", expectation: "A pattern question shows the number track with an outlined empty slot and three answer choices.", flows: ["F-13"], defects: []),
        AuditStop(id: "math-comparison", root: "sproutlab.audit.math-comparison", title: "Math comparison question", expectation: "A comparison question shows two quantities and asks for the larger or the smaller with three answer choices.", flows: ["F-13"], defects: []),
        AuditStop(id: "reading-tap-grapheme", root: "sproutlab.audit.reading-tap-grapheme", title: "Reading tap the letter", expectation: "A tap-the-letter question shows a syllable with three letter choices and a Tap to Hear control.", flows: [], defects: []),
        AuditStop(id: "reading-sequence-sounds", root: "sproutlab.audit.reading-sequence-sounds", title: "Reading put the sounds in order", expectation: "The ordering kit shows the sound tiles in a row that each have a spoken label with their place.", flows: [], defects: []),
        AuditStop(id: "reading-blend-new", root: "sproutlab.audit.reading-blend-new", title: "Reading sort the sounds", expectation: "In the sorting kit each bin's spoken label names what goes in it and is not a navigation name.", flows: [], defects: ["F-ac987c"]),
        AuditStop(id: "reading-decode-reveal", root: "sproutlab.audit.reading-decode-reveal", title: "Reading decode and reveal", expectation: "The picture-reveal kit hides its picture until the right word is submitted.", flows: [], defects: []),
        AuditStop(id: "reading-change-grapheme", root: "sproutlab.audit.reading-change-grapheme", title: "Reading change one letter", expectation: "A change-one-letter question shows the word and three choices that each differ by one letter.", flows: [], defects: []),
        AuditStop(id: "reading-build-word", root: "sproutlab.audit.reading-build-word", title: "Reading build the word", expectation: "The slot board shows empty slots and letter tiles that place into them in order.", flows: [], defects: []),
        AuditStop(id: "reading-select-digraph", root: "sproutlab.audit.reading-select-digraph", title: "Reading select the digraph", expectation: "The tile set shows the letters of a word and lets the child select the two that make one sound.", flows: [], defects: []),
        AuditStop(id: "reading-blend-word", root: "sproutlab.audit.reading-blend-word", title: "Reading blend the word", expectation: "The slot board for blending shows the sound slots of a word with their tiles to place.", flows: [], defects: []),
        AuditStop(id: "reading-repair-split", root: "sproutlab.audit.reading-repair-split", title: "Reading repair the split", expectation: "The tile set shows a word split in the wrong place and lets the child move the tiles to repair it.", flows: [], defects: []),
        AuditStop(id: "reading-en-sounds", root: "sproutlab.audit.reading-en-sounds", title: "English reading sounds", expectation: "An EN1 question shows the letters of a sound or short word with three answer choices.", flows: [], defects: []),
        AuditStop(id: "reading-en-words", root: "sproutlab.audit.reading-en-words", title: "English reading words", expectation: "An EN2 question shows a written word pair and asks which letter changed, with three answer choices.", flows: [], defects: []),
        AuditStop(id: "reading-en-digraphs", root: "sproutlab.audit.reading-en-digraphs", title: "English reading digraphs", expectation: "An EN3 question shows a word with the digraph written out and three answer choices.", flows: [], defects: []),
        AuditStop(id: "robot-c1", root: "sproutlab.audit.robot-c1", title: "Little Robot C1", expectation: "The C1 grid shows the robot, a row of arrow cards and a step control, with a prediction choice after a step.", flows: ["F-19"], defects: []),
        AuditStop(id: "robot-c2", root: "sproutlab.audit.robot-c2", title: "Little Robot C2", expectation: "The C2 grid shows rocks, empty slots and a palette of four arrow buttons that are each at least 56 points.", flows: ["F-20"], defects: []),
        AuditStop(id: "robot-c3", root: "sproutlab.audit.robot-c3", title: "Little Robot C3", expectation: "The C3 grid shows a short arrow program with a swap palette and a play control.", flows: ["F-21"], defects: []),
        AuditStop(id: "robot-c4", root: "sproutlab.audit.robot-c4", title: "Little Robot C4", expectation: "The C4 screen shows the grid, a visible arrow program strip with a repeat block xN wrapping arrows, the 2...5 repeat-count controls and the play control.", flows: ["F-21"], defects: []),
        AuditStop(id: "music-a4", root: "sproutlab.audit.music-a4", title: "Music A4 rhythm", expectation: "The A4 screen shows a visible 4-slot strip already filled with an example pattern of low sound, high sound and rest symbols, a play control and an expand-to-8 control.", flows: [], defects: []),
        AuditStop(id: "reading-fr-r6", root: "sproutlab.audit.reading-fr-r6", title: "French sentence", expectation: "A sentence question shows the sentence with one blank and three word choices, a Tap to Hear control for the whole sentence and three help steps that never change the answer.", flows: [], defects: []),
        AuditStop(id: "reading-en-r6", root: "sproutlab.audit.reading-en-r6", title: "English sentence", expectation: "An English sentence question shows the sentence with one blank and three word choices, a Tap to Hear control that speaks the whole sentence in an English voice and three help steps that never change the answer.", flows: [], defects: []),
    ]
}
