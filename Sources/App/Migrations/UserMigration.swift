import Vapor
import Fluent

struct UserMigration: AsyncMigration {
    
    func prepare(on database: any Database) async throws {
        try await database.schema(User.schema)
            .id()
            .field("name", .string)
            .field("username", .string, .required)
            .unique(on: "username")
            .field("email", .string, .required)
            .unique(on: "email")
            .field("avatar", .string)
            .field("created_at", .date, .required)
            .create()
    }
    
    func revert(on database: any Database) async throws {
        try await database.schema(User.schema)
            .delete()
    }
    
}
