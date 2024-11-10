import Vapor

struct Groceries: Content {
    let ingredientId: UUID
    let name: String
    let requiredQuantity: Double
    let unit: Unit
}
