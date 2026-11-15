import Foundation

/// One short sentence per resident, authored separately in French and in English.
public enum ResidentFacts {
    private static let french: [String: String] = [
        "sunflower": "Le tournesol tourne sa grande fleur vers le soleil.",
        "earthworm": "Le ver de terre creuse des tunnels sous tes pieds.",
        "ant": "La fourmi porte des graines bien plus lourdes qu'elle.",
        "fern": "La fougère déroule ses feuilles comme une petite spirale.",
        "ladybug": "La coccinelle a des points noirs sur son dos rouge.",
        "tree-frog": "La rainette grimpe aux feuilles avec ses doigts collants.",
        "glowing-mushroom": "Le champignon lumineux brille doucement dans le noir.",
        "axolotl": "L'axolotl sourit toujours et respire par ses plumeaux.",
        "butterfly": "Le papillon sort d'une chrysalide avec de grandes ailes.",
        "honeybee": "L'abeille danse pour montrer où sont les fleurs.",
        "snail": "L'escargot porte sa maison sur son dos.",
        "poppy": "Le coquelicot ouvre ses pétales rouges au grand soleil.",
        "dandelion": "Le pissenlit envoie ses graines voler dans le vent.",
        "robin": "Le rouge-gorge chante même quand il fait encore nuit.",
        "cricket": "Le grillon chante en frottant ses ailes l'une contre l'autre."
    ]

    private static let english: [String: String] = [
        "sunflower": "A sunflower turns its big face to follow the sun.",
        "earthworm": "An earthworm digs tiny tunnels in the soil.",
        "ant": "An ant can carry a seed much heavier than itself.",
        "fern": "A young fern unrolls its leaf from a tight curl.",
        "ladybug": "A ladybug has black dots on its red back.",
        "tree-frog": "A tree frog has sticky toes for climbing leaves.",
        "glowing-mushroom": "This mushroom glows softly when it is dark.",
        "axolotl": "An axolotl looks like it smiles and has feathery gills.",
        "butterfly": "A butterfly comes out of its chrysalis with new wings.",
        "honeybee": "A honeybee wiggles in a dance to show where flowers are.",
        "snail": "A snail carries its little house everywhere it goes.",
        "poppy": "A poppy opens its red petals when the sun is bright.",
        "dandelion": "A dandelion lets the wind carry its fluffy seeds away.",
        "robin": "A robin sings its song very early in the morning.",
        "cricket": "A cricket sings by rubbing its two wings together."
    ]

    /// The sentence for a resident id, or "" for an unknown id.
    public static func text(_ id: String, _ language: Language) -> String {
        (language == .fr ? french : english)[id] ?? ""
    }
}
