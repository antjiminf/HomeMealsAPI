import Vapor
import Fluent

struct FavoriteMigration: AsyncMigration {
    func prepare(on database: Database) async throws {
        try await database.schema(Favorite.schema)
            .id()
            .field("user_id", .uuid, .required, .references(User.schema, .id, onDelete: .cascade))
            .field("recipe_id", .uuid, .required, .references(Recipe.schema, .id, onDelete: .cascade))
            .unique(on: "user_id", "recipe_id")
            .create()
    }
    
    func revert(on database: Database) async throws {
        try await database.schema(Favorite.schema).delete()
    }
}

