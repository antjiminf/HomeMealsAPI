import Vapor
import Fluent

extension Pantry: @unchecked Sendable {}

final class Pantry: Model {
    
    static let schema = "pantry"
    
    @ID(key: .id) var id: UUID?
    @Parent(key: "user") var user: User
    @Parent(key: "ingredient") var ingredient: Ingredient
    @Field(key: "quantity") var quantity: Double
    @Enum(key: "unit") var unit: Unit
    
    init() {}
    
    init(id: UUID? = nil, user: User.IDValue, ingredient: Ingredient.IDValue, quantity: Double, unit: Unit) {
        self.id = id
        self.$user.id = user
        self.$ingredient.id = ingredient
        self.quantity = quantity
        self.unit = unit
    }
    
    
}
