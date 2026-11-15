import Foundation

public enum RecipeLint {
    public static func run(_ table: [Recipe]) -> [ContentFinding] {
        var findings: [ContentFinding] = []
        var seen = Set<String>()
        for recipe in table {
            if !seen.insert(recipe.id).inserted {
                findings.append(ContentFinding(kind: "recipe-duplicate-id", subject: recipe.id))
            }
            findings += recipeFindings(recipe)
        }
        for resident in Collectible.table where resident.kind == .creature && !seen.contains(resident.id) {
            findings.append(ContentFinding(kind: "recipe-missing-resident", subject: resident.id))
        }
        return Set(findings).sorted { ($0.kind, $0.subject) < ($1.kind, $1.subject) }
    }

    static func recipeFindings(_ recipe: Recipe) -> [ContentFinding] {
        var findings: [ContentFinding] = []
        if !(1...Recipe.maxParts).contains(recipe.parts.count) {
            findings.append(ContentFinding(kind: "recipe-part-count", subject: recipe.id))
        }
        for part in recipe.parts {
            findings += partFindings(part, id: recipe.id)
        }
        if !ContentRegistry.knownColourTokens.contains(recipe.bodyColourToken) {
            findings.append(ContentFinding(kind: "recipe-unknown-colour", subject: recipe.bodyColourToken))
        }
        for symbol in recipe.symbolNames where !ChromeCatalog.allSymbolNames.contains(symbol) {
            findings.append(ContentFinding(kind: "recipe-unknown-symbol", subject: symbol))
        }
        if TextTable.string(recipe.nameKey, .fr) == recipe.nameKey {
            findings.append(ContentFinding(kind: "recipe-missing-name", subject: recipe.nameKey))
        }
        return findings
    }

    static func partFindings(_ part: RecipePart, id: String) -> [ContentFinding] {
        var findings: [ContentFinding] = []
        if part.points.contains(where: { !(0...1).contains($0.x) || !(0...1).contains($0.y) }) {
            findings.append(ContentFinding(kind: "recipe-point-range", subject: id))
        }
        for token in [part.colourToken] + [part.gradientToken].compactMap({ $0 })
        where !ContentRegistry.knownColourTokens.contains(token) {
            findings.append(ContentFinding(kind: "recipe-unknown-colour", subject: token))
        }
        return findings
    }
}
