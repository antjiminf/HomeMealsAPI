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
        recipes.get("exists", ":name", use: existsRecipeName)
        recipes.get("all", use: getAllRecipes)		    
    }
    
    @Sendable func getAllRecipes(req: Request) async throws -> [Recipe.RecipeListResponse] {
        return try await Recipe.query(on: req.db)
            .with(\.$user)
            .all()
            .map {
                try $0.recipeListResponse
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
    
    @Sendable func existsRecipeName(req: Request) async throws -> HTTPStatus {
        guard let name = req.parameters.get("name") else {
            throw Abort(.badRequest, reason: "Recipe name not found.")
        }
        
        let exists = try await Recipe.query(on: req.db)
            .filter(\.$name, .custom("ILIKE"), name)
            .first()
        
        if exists == nil {
            return .ok
        } else {
            return .notAcceptable
        }
    }
    
    @Sendable func createRecipe(req: Request) async throws -> HTTPStatus {
        // TODO: Authentication USER y dar el uuid correcto
        try CreateRecipe.validate(content: req)
        let new = try req.content.decode(CreateRecipe.self)
        
        return try await req.db.transaction { database in
            
            let recipe = new.toRecipe(user: UUID(uuidString: "123E4567-E89B-12D3-A456-426614174000")!)
            try await recipe.create(on: database)
            
            for i in new.ingredients {
                let newRecipeIngredient = RecipeIngredient(
                    recipe: try recipe.requireID(),
                    ingredient: i.ingredient,
                    quantity: i.quantity,
                    unit: i.unit
                )
                try await newRecipeIngredient.create(on: database)
            }
            return .created
        }
    }
    
    @Sendable func updateRecipe(req: Request) async throws -> HTTPStatus {
        // TODO: Authentication USER -> user == owner
        try CreateRecipe.validate(content: req)
        let updatedRecipe = try req.content.decode(CreateRecipe.self)
        
        guard let id = req.parameters.get("id", as: UUID.self) else {
            throw Abort(.notFound, reason: "Parameter recipe id not found.")
        }
        
        return try await req.db.transaction { database in
            
            guard let recipe = try await Recipe.find(id, on: database) else {
                throw Abort(.notFound, reason: "Recipe not found")
            }
            
            recipe.name = updatedRecipe.name
            recipe.description = updatedRecipe.description
            recipe.guide = updatedRecipe.guide
            recipe.time = updatedRecipe.time
            recipe.isPublic = updatedRecipe.isPublic
            recipe.allergens = updatedRecipe.allergens
            
            try await recipe.update(on: database)
            
            try await RecipeIngredient.query(on: database)
                .filter(\.$recipe.$id == id)
                .delete()
            
            for ingredient in updatedRecipe.ingredients {
                let newIngredient = RecipeIngredient(
                    recipe: try recipe.requireID(),
                    ingredient: ingredient.ingredient,
                    quantity: ingredient.quantity,
                    unit: ingredient.unit
                )
                try await newIngredient.create(on: database)
            }
            return .noContent
        }
    }
    
    @Sendable func deleteRecipe(req: Request) async throws -> HTTPStatus {
        // TODO: Authentication USER -> user == owner
        guard let recipe = try await Recipe.find(req.parameters.get("id"), on: req.db) else {
            throw Abort(.notFound, reason: "Recipe not found.")
        }
        
        return try await req.db.transaction { db in
            
            try await recipe.$ingredientsDetails.load(on: db)
            for ing in recipe.ingredientsDetails {
                try await ing.delete(on: db)
            }
            
            try await recipe.delete(on: db)
            return .noContent
        }
    }
}
