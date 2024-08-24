import Vapor
import Fluent

struct DataMigration: AsyncMigration {
    func prepare(on database: any Database) async throws {
        let users = try loadUsers()
        try await users.create(on: database)
        
        let ingredients = try loadIngredients()
        try await ingredients.create(on: database)
        
        let recipes = try loadRecipes()
        try await recipes.create(on: database)
        
        let recipeIngredients = try loadRecipeIngredients()
        try await recipeIngredients.create(on: database)
        
        let pantries = try loadPantries()
        try await pantries.create(on: database)
    }
    
    func revert(on database: any Database) async throws {
        try await database.query(Pantry.self)
            .delete()
        try await database.query(RecipeIngredient.self)
            .delete()
        try await database.query(Recipe.self)
            .delete()
        try await database.query(Ingredient.self)
            .delete()
        try await database.query(User.self)
            .delete()
    }
    
    func loadIngredients() throws -> [Ingredient] {
        let path = URL(fileURLWithPath: DirectoryConfiguration.detect().workingDirectory).appending(path: "Sources/App/Data")
        let ingredientsJson = path.appending(path: "ingredients.json")
        
        if FileManager.default.fileExists(atPath: ingredientsJson.path()) {
            let data = try Data(contentsOf: ingredientsJson)
            
            return try JSONDecoder().decode([Ingredient].self, from: data)
        } else {
            return []
        }
    }
    
    func loadRecipes() throws -> [Recipe] {
        let path = URL(fileURLWithPath: DirectoryConfiguration.detect().workingDirectory).appending(path: "Sources/App/Data")
        let recipesJson = path.appending(path: "recipes.json")
        
        if FileManager.default.fileExists(atPath: recipesJson.path()) {
            let data = try Data(contentsOf: recipesJson)
            
            return try JSONDecoder().decode([Recipe].self, from: data)
        } else {
            return []
        }
    }
    
    func loadUsers() throws -> [User] {
        let path = URL(fileURLWithPath: DirectoryConfiguration.detect().workingDirectory).appending(path: "Sources/App/Data")
        let usersJson = path.appending(path: "users.json")
        
        if FileManager.default.fileExists(atPath: usersJson.path()) {
            let data = try Data(contentsOf: usersJson)
            
            return try JSONDecoder().decode([User].self, from: data)
        } else {
            return []
        }
    }
    
    func loadRecipeIngredients() throws -> [RecipeIngredient] {
        let path = URL(fileURLWithPath: DirectoryConfiguration.detect().workingDirectory).appending(path: "Sources/App/Data")
        let recipeIngredientsJson = path.appending(path: "recipeIngredients.json")
        
        if FileManager.default.fileExists(atPath: recipeIngredientsJson.path()) {
            let data = try Data(contentsOf: recipeIngredientsJson)
            
            return try JSONDecoder().decode([RecipeIngredient].self, from: data)
        } else {
            return []
        }
    }
    
    func loadPantries() throws -> [Pantry] {
        let path = URL(fileURLWithPath: DirectoryConfiguration.detect().workingDirectory).appending(path: "Sources/App/Data")
        let pantryJson = path.appending(path: "pantries.json")
        
        if FileManager.default.fileExists(atPath: pantryJson.path()) {
            let data = try Data(contentsOf: pantryJson)
            
            return try JSONDecoder().decode([Pantry].self, from: data)
        } else {
            return []
        }
    }
}
