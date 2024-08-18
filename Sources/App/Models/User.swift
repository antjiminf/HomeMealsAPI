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
    @Field(key: "created_at") var createdAt: Date
    // Role
    
    init() {}
    
    init(id: UUID? = nil, name: String, username: String, email: String, avatar: String? = nil, createdAt: Date) {
        self.id = id
        self.name = name
        self.username = username
        self.email = email
        self.avatar = avatar
        self.createdAt = createdAt
    }
}
