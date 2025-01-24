import Vapor
import Fluent

extension Favorite: @unchecked Sendable {}

//Podría aprovechar para tener también aquí ratings de todo tipo

final class Favorite: Model, Content {
    static let schema = "favorites"
    
    @ID(key: .id) var id: UUID?
    
    @Parent(key: "user_id") var user: User
    
    @Parent(key: "recipe_id") var recipe: Recipe
    
    init() {}
    
    init(id: UUID? = nil, userId: User.IDValue, recipeId: Recipe.IDValue) {
        self.id = id
        self.$user.id = userId
        self.$recipe.id = recipeId
    }
}

extension Favorite {
    
    struct UserLikeInfo: Content {
        let id: UUID
        let name: String
    }
    
    var userInfo: UserLikeInfo {
        get throws {
            try UserLikeInfo(id: user.requireID(), name: user.name)
        }
    }
}
