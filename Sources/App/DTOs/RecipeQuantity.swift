import Vapor

struct RecipeQuantity: Content {
    let id: UUID
    let quantity: Int
}

extension RecipeQuantity: Validatable {
    static func validations(_ validations: inout Vapor.Validations) {
        validations.add("quantity", as: Int.self, is: .range(1...), customFailureDescription: "Recipe quantity must be 1 or higher.")
    }
}
