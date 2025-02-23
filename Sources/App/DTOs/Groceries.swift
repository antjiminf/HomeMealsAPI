import Vapor

struct Groceries: Content {
    let ingredientId: UUID
    let name: String
    var requiredQuantity: Double
    let unit: Unit
}
