import Vapor

struct IngredientQuantity: Content {
    var ingredient: UUID
    var unit: Unit
    var quantity: Double
    
    func toUserIngredient(user: UUID) -> Pantry {
        Pantry(user: user,
               ingredient: ingredient,
               quantity: quantity,
               unit: unit)
    }
}

extension IngredientQuantity: Validatable {
    static func validations(_ validations: inout Validations) {
        validations.add("quantity", as: Double.self, is: .range(0.1...), customFailureDescription: "The quantity given must be a minimum of 0.1")
        validations.add("unit", as: String.self, is: .in(Unit.allCases.map{$0.rawValue}), customFailureDescription: "The unit given must be a value in: \(Unit.allCases.map{$0.rawValue})")
    }
}
