import Vapor
import Fluent

struct RecipeController: RouteCollection {
    
    func boot(routes: any RoutesBuilder) throws {
        let recipes = routes.grouped("api", "recipe")
        
        recipes.get(use: getAllRecipes)
        recipes.post(use: createRecipe)
        recipes.group(":id") { recipe in
            recipe.get(use: getRecipe)
            recipe.get("ingredients", use: getIngredientsInRecipe)
            recipe.put(use: updateRecipe)
            recipe.delete(use: deleteRecipe)
        }
    }
    
    @Sendable func getAllRecipes(req: Request) async throws -> [Recipe] {
        try await Recipe
            .query(on: req.db)
            .all()
    }
    
    @Sendable func getRecipe(req: Request) async throws -> Recipe {
        guard let recipe = try await Recipe.find(req.parameters.get("id"), on: req.db) else {
            throw Abort(.notFound, reason: "Recipe not found.")
        }
        return recipe
    }
    
    //DTO PARA ESTE
    @Sendable func getIngredientsInRecipe(req: Request) async throws -> Recipe {
        guard let param = req.parameters.get("id"),
              let id = UUID(uuidString: param) else {
            throw Abort(.notFound, reason: "Invalid uuid")
        }
        
        let recipe = try await Recipe
            .query(on: req.db)
            .filter(\.$id == id)
            .with(\.$ingredients)
            .first()
        
        if let recipe {
            return recipe
        } else {
            throw Abort(.notFound, reason: "Recipe not found.")
        }
    }
    
    @Sendable func createRecipe(req: Request) async throws -> HTTPStatus {
        // Authentication
        let new = try req.content.decode(Recipe.self)
        
        if new.name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            throw Abort(.badRequest, reason: "Recipe name must not be empty.")
        } else if new.guide.isEmpty {
            throw Abort(.badRequest, reason: "Recipe guide must not be empty.")
        } else if new.time <= 0 {
            throw Abort(.badRequest, reason: "Recipe preparation time must not be 0 or lower.")
        }
        
        try await new.create(on: req.db)
        return .created
    }
    
    @Sendable func updateRecipe(req: Request) async throws -> HTTPStatus {
        //Authentication
        //Puede hacerse con catch pero prefiero error del decode
        let updated = try req.content.decode(Recipe.self)
        guard let recipe = try await Recipe.find(req.parameters.get("id"), on: req.db) else {
            throw Abort(.notFound, reason: "Recipe not found.")
        }
        
        if updated.name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            throw Abort(.badRequest, reason: "Recipe name must not be empty.")
        } else if updated.guide.isEmpty {
            throw Abort(.badRequest, reason: "Recipe guide must not be empty.")
        } else if updated.time <= 0 {
            throw Abort(.badRequest, reason: "Recipe preparation time must not be 0 or lower.")
        }
        
        recipe.name = updated.name
        recipe.description = updated.description
        recipe.guide = updated.guide
        recipe.time = updated.time
        recipe.isPublic = updated.isPublic
        recipe.allergens = updated.allergens
        
        try await recipe.update(on: req.db)
        return .noContent
    }
    
    @Sendable func deleteRecipe(req: Request) async throws -> HTTPStatus {
        //Authentication
        guard let recipe = try await Recipe.find(req.parameters.get("id"), on: req.db) else {
            throw Abort(.notFound, reason: "Recipe not found.")
        }
        
        try await recipe.delete(on: req.db)
        return .noContent
    }
}
