import Vapor
import Fluent


extension Ingredient: @unchecked Sendable {}

final class Ingredient: Model, Content {
    
    static let schema = "ingredient"
    
    @ID(key: .id) var id: UUID?
    @Field(key: "name") var name: String
    @Enum(key: "unit") var unit: Unit
    @Enum(key: "category") var category: FoodCategory
    
    @Siblings(through: RecipeIngredient.self, from: \.$ingredient, to: \.$recipe) var recipes: [Recipe]
    
    init() {}
    
    init(id: UUID? = nil, name: String, unit: Unit, category: FoodCategory) {
        self.id = id
        self.name = name
        self.unit = unit
        self.category = category
    }
    
}

extension Ingredient {
    struct RecipesWithIngredient: Content {
        let id: UUID
        let name: String
        let category: String
        let recipes: [Recipe.RecipeListResponse]
    }
    
    func recipesWithIngredient(userId: UUID) throws -> RecipesWithIngredient {
        try RecipesWithIngredient(
            id: requireID(), 
            name: name,
            category: category.rawValue,
            recipes: try recipes.map{ try $0.recipeListResponse(userId: userId) })
    }
    
//    var recipesWithIngredient: RecipesWithIngredient {
//        get throws {
//            try RecipesWithIngredient(
//                id: requireID(), 
//                name: name,
//                category: category.rawValue,
//                recipes: try recipes.map{ try $0.recipeListResponse(userId: <#T##UUID#>) })
//        }
//    }
}
