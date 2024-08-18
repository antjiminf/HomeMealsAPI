import Vapor
import Fluent

extension Recipe: @unchecked Sendable {}

final class Recipe: Model {
    static let schema = "recipe"
    
    @ID(key: .id) var id: UUID?
    @Field(key: "name") var name: String
    @Field(key: "description") var description: String
    @Field(key: "guide") var guide: String
    @Field(key: "is_public") var isPublic: Bool
    @Field(key: "time") var time: Int
    @OptionalParent(key: "user") var user: User?
    
    init() {}
    
    init(id: UUID? = nil, name: String, description: String, guide: String, isPublic: Bool, time: Int, user: User? = nil) {
        self.id = id
        self.name = name
        self.description = description
        self.guide = guide
        self.isPublic = isPublic
        self.time = time
        self.user = user
    }
}
