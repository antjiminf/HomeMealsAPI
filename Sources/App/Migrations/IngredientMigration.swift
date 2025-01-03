import Vapor
import Fluent

struct IngredientMigration: AsyncMigration {
    func prepare(on database: any Database) async throws {
        let foodCategories = try await database.enum("food_categories")
            .case("bakery-pastry")
            .case("beverage")
            .case("cereals-grains")
            .case("dairy")
            .case("fish")
            .case("fruit")
            .case("herbs-spices")
            .case("legumes")
            .case("meat")
            .case("nuts-seeds")
            .case("oil-fat")
            .case("seafood")
            .case("sweet-dessert")
            .case("vegetable")
            .create()
        
        let units = try await database.enum("unit")
            .case("volume")
            .case("units")
            .case("weight")
            .create()
        
        try await database.schema(Ingredient.schema)
            .id()
            .field("name", .string, .required)
            .field("unit", units, .required)
            .field("category", foodCategories, .required)
            .unique(on: "name")
            .create()
    }
    
    func revert(on database: any Database) async throws {
        try await database.schema(Ingredient.schema)
            .delete()
        try await database.enum("food_categories")
            .delete()
    }
}
