import Vapor

struct CreateIngredient: Content {
    var name: String
    var category: FoodCategory
    
    func toIngredient() -> Ingredient {
        return Ingredient(name: self.name, category: self.category)
    }
}

extension CreateIngredient: Validatable {
    
    static func validations(_ validations: inout Validations) {
        validations.add("name", as: String.self, is: !.empty, customFailureDescription: "Name must not be empty")
        validations.add("name", as: String.self, is: .alphanumeric, customFailureDescription: "Name must be alphanumeric")
        validations.add("category", as: String.self, is: .in(FoodCategory.allCases.map{ $0.rawValue}), customFailureDescription: "The category given must be in: \(FoodCategory.allCases.map {$0.rawValue})")
    }
}
