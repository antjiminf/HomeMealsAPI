enum FoodCategory: String, Codable, CaseIterable {
    case bakeryPastry = "bakery-pastry"
    case beverage
    case cerealsGrains = "cereals-grains"
    case dairy
    case fish
    case fruit
    case herbsSpices = "herbs-spices"
    case legumes
    case meat
    case nutsSeeds = "nuts-seeds"
    case oilFat = "oil-fat"
    case seafood
    case sweetDessert = "sweet-dessert"
    case vegetable
}

enum Unit: String, Codable, CaseIterable {
    case volume
    case units
    case weight
}

enum Allergen: String, Codable, CaseIterable{
    case celery
    case crustaceans
    case dairy
    case egg
    case fish
    case gluten
    case lupin
    case molluscs
    case mustard
    case nuts
    case peanut
    case sesame
    case soy
    case sulphites
}

