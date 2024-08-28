import Vapor
import Fluent

extension Recipe: @unchecked Sendable {}

final class Recipe: Model, Content {
    static let schema = "recipe"
    
    @ID(key: .id) var id: UUID?
    @Field(key: "name") var name: String
    @Field(key: "description") var description: String
    @Field(key: "guide") var guide: [String]
    @Field(key: "is_public") var isPublic: Bool
    @Field(key: "time") var time: Int
    @Field(key: "allergens") var allergens: [Allergen]
//    @Children(for: \.$recipe) var ingredients: [RecipeIngredient]
    @Parent(key: "user") var user: User
    
    @Siblings(through: RecipeIngredient.self, from: \.$recipe, to: \.$ingredient) var ingredients: [Ingredient]
    
    
    init() {}
    
    init(id: UUID? = nil, name: String, description: String, guide: [String], isPublic: Bool, time: Int, allergens: [Allergen], user: User.IDValue) {
        self.id = id
        self.name = name
        self.description = description
        self.guide = guide
        self.isPublic = isPublic
        self.time = time
        self.allergens = allergens
        self.$user.id = user
    }
    
    
}
