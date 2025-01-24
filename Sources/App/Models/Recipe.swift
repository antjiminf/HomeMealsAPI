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
    @Children(for: \.$recipe) var ingredientsDetails: [RecipeIngredient]
    @Parent(key: "user") var user: User
    @Children(for: \.$recipe) var favorites: [Favorite]
    
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

extension Recipe {
    struct RecipeResponse: Content {
        let id: UUID
        let name: String
        let description: String
        let guide: [String]
        let isPublic: Bool
        let time: Int
        let allergens: [Allergen]
        let owner: UUID
        let favorite: Bool
        let favTotal: Int
    }
    
    struct RecipeListResponse: Content {
        let id: UUID
        let name: String
        let description: String
        let time: Int
        let allergens: [Allergen]
        let owner: UUID
        let favorite: Bool
        let favTotal: Int
    }
    
    struct RecipeIngredientsResponse: Content {
        let id: UUID
        let name: String
        let description: String
        let guide: [String]
        //        let isPublic: Bool
        let time: Int
        let allergens: [Allergen]
        let owner: UUID
        let ingredients: [RecipeIngredient.IngredientDetails]
        let favorite: Bool
        let favTotal: Int
    }
    
    func recipeResponse(userId: UUID) throws -> RecipeResponse {
        let isFavorite = try favorites.contains(where: { try $0.user.requireID() == userId })
        return try RecipeResponse(id: requireID(),
                                  name: name,
                                  description: description,
                                  guide: guide,
                                  isPublic: isPublic,
                                  time: time,
                                  allergens: allergens,
                                  owner: user.requireID(),
                                  favorite: isFavorite,
                                  favTotal: favorites.count)
    }
    
    //    var recipeResponse: RecipeResponse {
    //        get throws {
    //            let favorite = favorites.contains(where: { $0.user.id ==  })
    //            try RecipeResponse(
    //                id: requireID(),
    //                name: name,
    //                description: description,
    //                guide: guide,
    //                isPublic: isPublic,
    //                time: time,
    //                allergens: allergens,
    //                owner: user.requireID(),
    //                favorite: <#T##Bool#>)
    //        }
    //    }
    
    func recipeListResponse(userId: UUID) throws -> RecipeListResponse {
        let isFavorite = try favorites.contains(where: { try $0.user.requireID() == userId })
        return try RecipeListResponse(id: requireID(),
                                      name: name,
                                      description: description,
                                      time: time,
                                      allergens: allergens,
                                      owner: user.requireID(),
                                      favorite: isFavorite,
                                      favTotal: favorites.count)
    }
    
//    var recipeListResponse: RecipeListResponse {
//        get throws {
//            try RecipeListResponse(
//                id: requireID(),
//                name: name,
//                description: description,
//                time: time,
//                allergens: allergens,
//                owner: user.requireID(),
//                favorite: <#T##Bool#>)
//        }
//    }
    
    func recipeIngredientsResponse(userId: UUID) throws -> RecipeIngredientsResponse {
        let isFavorite = try favorites.contains(where: { try $0.user.requireID() == userId })
        return try RecipeIngredientsResponse( id: requireID(),
                                              name: name,
                                              description: description,
                                              guide: guide,
                                              time: time,
                                              allergens: allergens,
                                              owner: user.requireID(),
                                              ingredients: ingredientsDetails.map { try $0.ingredientDetails },
                                              favorite: isFavorite,
                                              favTotal: favorites.count)
    }
//    
//    var recipeIngredientsResponse: RecipeIngredientsResponse {
//        get throws {
//            try RecipeIngredientsResponse(
//                id: requireID(),
//                name: name,
//                description: description,
//                guide: guide,
//                //                isPublic: isPublic,
//                time: time,
//                allergens: allergens,
//                owner: user.requireID(),
//                ingredients: ingredientsDetails.map { try $0.ingredientDetails}, //DTO
//                favorite: <#T##Bool#>)
//        }
//    }
}
