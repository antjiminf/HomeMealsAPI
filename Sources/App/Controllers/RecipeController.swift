import Vapor
import Fluent

struct RecipeController: RouteCollection {
    
    func boot(routes: any RoutesBuilder) throws {
        let recipes = routes.grouped("api", "recipes")
        
        recipes.get(use: getAllPublicRecipes)
        recipes.post(use: createRecipe)
        recipes.get("search", use: searchPublicRecipes)
        recipes.group(":id") { recipe in
            recipe.get(use: getPublicRecipe)
            recipe.get("ingredients", use: getIngredientsInRecipe)
            recipe.put(use: updateRecipe)
            recipe.delete(use: deleteRecipe)
        }
    }
    
    
    @Sendable func getAllPublicRecipes(req: Request) async throws -> PageDTO<Recipe.RecipeListResponse> {
        let page = try await Recipe
            .query(on: req.db)
            .filter(\.$isPublic == true)
            .with(\.$user)
            .paginate(for: req)
            .map {
                try $0.recipeListResponse
            }
        
        return PageDTO(pg: page)
        
    }
    
    @Sendable func searchPublicRecipes(req: Request) async throws -> PageDTO<Recipe.RecipeListResponse> {
        var recipes = Recipe.query(on: req.db)
            .filter(\.$isPublic == true)
        
        if let name = req.query[String.self, at: "name"] {
            recipes = recipes.filter(\.$name, .custom("ILIKE"), "%\(name)%")
        }
        if let maxTime = req.query[Int.self, at: "maxTime"] {
            recipes = recipes.filter(\.$time <= maxTime)
        }
        
        if let minTime = req.query[Int.self, at: "minTime"] {
            recipes = recipes.filter(\.$time >= minTime)
        }
        
        if let allergensString = req.query[String.self, at: "allergens"] {
            
            let allergens = allergensString.split(separator: ",").compactMap {
                Allergen(rawValue: String($0).trimmingCharacters(in: .whitespaces))
            }
            
            if !allergens.isEmpty {
                recipes = recipes.filter(.sql(unsafeRaw: "NOT allergens && ARRAY[\(allergens.map{"'\($0)'"}.joined(separator: ","))]::text[]"))
            }
        }
        
        let page = try await recipes
            .with(\.$user)
            .paginate(for: req)
            .map{ recipe in
                return try recipe.recipeListResponse
            }
        return PageDTO(pg: page)
    }
    
    @Sendable func getPublicRecipe(req: Request) async throws -> Recipe.RecipeResponse {
        guard let recipe = try await Recipe.find(req.parameters.get("id"), on: req.db) else {
            throw Abort(.notFound, reason: "Recipe not found.")
        }
        try await recipe.$user.load(on: req.db)
        
        if recipe.isPublic {
            return try recipe.recipeResponse
        }
        throw Abort(.notFound, reason: "Recipe not found")
    }
    
    
    @Sendable func getIngredientsInRecipe(req: Request) async throws -> Recipe.RecipeIngredientsResponse {
        guard let param = req.parameters.get("id"),
              let id = UUID(uuidString: param) else {
            throw Abort(.notFound, reason: "Invalid uuid")
        }
        
        let recipe = try await Recipe
            .query(on: req.db)
            .filter(\.$id == id)
            .with(\.$ingredientsDetails) { detail in
                detail.with(\.$ingredient)
            }
            .with(\.$user)
            .first()
        
        if let recipe {
            return try recipe.recipeIngredientsResponse
        } else {
            throw Abort(.notFound, reason: "Recipe not found.")
        }
    }
    
    @Sendable func createRecipe(req: Request) async throws -> HTTPStatus {
        // Authentication USER
        try CreateRecipe.validate(content: req)
        let new = try req.content.decode(CreateRecipe.self)
        
        //Todo id de usuario en cuestión
        try await new.toRecipe(user: UUID(uuidString: "123E4567-E89B-12D3-A456-426614174000")!).create(on: req.db)
        return .created
    }
    
    @Sendable func updateRecipe(req: Request) async throws -> HTTPStatus {
        //Authentication USER -> user == owner
        try CreateRecipe.validate(content: req)
        let updated = try req.content.decode(CreateRecipe.self)
        guard let recipe = try await Recipe.find(req.parameters.get("id"), on: req.db) else {
            throw Abort(.notFound, reason: "Recipe not found.")
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
        //Authentication USER -> user == owner
        guard let recipe = try await Recipe.find(req.parameters.get("id"), on: req.db) else {
            throw Abort(.notFound, reason: "Recipe not found.")
        }
        
        try await recipe.delete(on: req.db)
        return .noContent
    }
}
