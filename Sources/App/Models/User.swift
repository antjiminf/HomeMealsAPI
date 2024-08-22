import Vapor
import Fluent

extension User: @unchecked Sendable {}

final class User: Model {
    static let schema = "user"
    
    @ID(key: .id) var id: UUID?
    @Field(key: "name") var name: String
    @Field(key: "username") var username: String
    @Field(key: "email") var email: String
    @Field(key: "avatar") var avatar: String?
    @Timestamp(key: "created_at", on: .create) var createdAt: Date?
    @Children(for: \.$user) var recipes: [Recipe]
    // Role
    @Siblings(through: Pantry.self, from: \.$user, to: \.$ingredient) var ingredients: [Ingredient]
    
    init() {}
    
    init(id: UUID? = nil, name: String, username: String, email: String, avatar: String? = nil) {
        self.id = id
        self.name = name
        self.username = username
        self.email = email
        self.avatar = avatar
    }
}
