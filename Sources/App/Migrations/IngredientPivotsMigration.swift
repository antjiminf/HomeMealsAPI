import Vapor
import Fluent

struct IngredientPivotsMigration: AsyncMigration {
    func prepare(on database: any Database) async throws {
        
        let units = try await database.enum("unit")
            .case("volume")
            .case("units")
            .case("weight")
            .create()
        
        try await database.schema(Pantry.schema)
            .id()
            .field("user", .uuid, .references(User.schema, .id), .required)
            .field("ingredient", .uuid, .references(Ingredient.schema, .id), .required)
            .field("quantity", .double, .required)
            .field("unit", units, .required)
            .unique(on: "user", "ingredient")
            .create()
        
        try await database.schema(RecipeIngredient.schema)
            .id()
            .field("user", .uuid, .references(User.schema, .id), .required)
            .field("ingredient", .uuid, .references(Ingredient.schema, .id), .required)
            .field("quantity", .double, .required)
            .field("unit", units, .required)
            .unique(on: "user", "ingredient")
            .create()
    }
    
    func revert(on database: any Database) async throws {
        try await database.enum("unit")
            .delete()
        try await database.schema(Pantry.schema)
            .delete()
        try await database.schema(RecipeIngredient.schema)
            .delete()
    }
}
