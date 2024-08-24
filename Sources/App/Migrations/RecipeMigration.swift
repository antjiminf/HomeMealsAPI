import Vapor
import Fluent

struct RecipeMigration: AsyncMigration {
    func prepare(on database: Database) async throws {
//        let allergens = try await database.enum("allergen")
//            .case("celery")
//            .case("crustaceans")
//            .case("dairy")
//            .case("egg")
//            .case("fish")
//            .case("gluten")
//            .case("lupin")
//            .case("moluscs")
//            .case("mustard")
//            .case("nuts")
//            .case("peanut")
//            .case("sesame")
//            .case("soy")
//            .case("sulphites")
//            .create()
        
        try await database.schema(Recipe.schema)
            .id()
            .field("name", .string, .required)
            .field("description", .string)
            .field("guide", .array(of: .string), .required)
            .field("is_public", .bool, .required)
            .field("time", .int)
            .field("allergens", .array(of: .string))
            .field("user", .uuid, .references(User.schema, .id), .required)
            .create()
    }
    
    func revert(on database: Database) async throws {
//        try await database.enum("allergen").delete()
        try await database.schema(Recipe.schema)
            .delete()
    }
}
