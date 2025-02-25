import Vapor
import Fluent

extension RecipeIngredient: @unchecked Sendable {}

final class RecipeIngredient: Model {
    
    static let schema = "recipe_ingredient"
    
    @ID(key: .id) var id: UUID?
    @Parent(key: "recipe") var recipe: Recipe
    @Parent(key: "ingredient") var ingredient: Ingredient
    @Field(key: "quantity") var quantity: Double
    @Enum(key: "unit") var unit: Unit
    
    init() {}
    
    init(id: UUID? = nil, recipe: Recipe.IDValue, ingredient: Ingredient.IDValue, quantity: Double, unit: Unit) {
        self.id = id
        self.$recipe.id = recipe
        self.$ingredient.id = ingredient
        self.quantity = quantity
        self.unit = unit
    }
    
}

extension RecipeIngredient {
    struct IngredientDetails: Content {
        let ingredientId: UUID
        let name: String
        let quantity: Double
        let unit: Unit
    }
    
    var ingredientDetails: IngredientDetails {
        get throws {
            try IngredientDetails(
                ingredientId: ingredient.requireID(),
                name: ingredient.name,
                quantity: quantity,
                unit: unit)
        }
    }
}
