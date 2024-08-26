import Vapor
import Fluent


extension Ingredient: @unchecked Sendable {}

final class Ingredient: Model, Content {
    
    static let schema = "ingredient"
    
    @ID(key: .id) var id: UUID?
    @Field(key: "name") var name: String
    @Enum(key: "category") var category: FoodCategory
    
    @Siblings(through: RecipeIngredient.self, from: \.$ingredient, to: \.$recipe) var recipes: [Recipe]
    
    init() {}
    
    init(id: UUID? = nil, name: String, category: FoodCategory) {
        self.id = id
        self.name = name
        self.category = category
    }
    
}

//import Vapor
//import Fluent
//
//
//final class Ingredient: Model {
//    
//    static let schema = "ingredient"
//    
//    var id: UUID?
//    
//}
