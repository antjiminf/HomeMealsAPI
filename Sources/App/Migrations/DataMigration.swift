import Vapor
import Fluent

struct DataMigration: AsyncMigration {
    func prepare(on database: any Database) async throws {
        let ingredients = try loadIngredients()
        for i in ingredients {
            try await i.create(on: database)
        }
    }
    
    func revert(on database: any Database) async throws {
        
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
}
