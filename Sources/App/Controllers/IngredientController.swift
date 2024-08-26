
import Vapor
import Fluent

struct IngredientController: RouteCollection {
    func boot(routes: any RoutesBuilder) throws {
        let ingredients = routes.grouped("api", "ingredient")
        
        ingredients.get( use: getAllIngredients)
        ingredients.post(use: createIngredient)
        ingredients.group(":id") { ingredient in
            ingredient.get(use: getIngredient)
            ingredient.get("recipes", use: getRecipesWithIngredient)
            ingredient.delete(use: deleteIngredient)
            ingredient.put(use: updateIngredient)
        }
        ingredients.get("category", ":category", use: getIngredientsByCategory)
        
    }
    
    @Sendable func getAllIngredients(req: Request) async throws -> [Ingredient] {
        try await Ingredient
            .query(on: req.db)
            .all()
    }
    
    @Sendable func createIngredient(req: Request) async throws -> HTTPStatus {
        let new = try req.content.decode(Ingredient.self)
        
        let exists = try await Ingredient
            .query(on: req.db)
            .filter(\.$name, .custom("ILIKE"), new.name)
            .first()
        
        if let exists {
            throw Abort(.conflict, reason: "\(new.name) already exists")
        }
        
        try await new.create(on: req.db)
        return .created
    }
    
    @Sendable func getIngredient(req: Request) async throws -> Ingredient {
        guard let id = req.parameters.get("id"),
              let uuid = UUID(uuidString: id) else {
            throw Abort(.badRequest, reason: "Invalid uuid")
        }
        
        let ingredient = try await Ingredient
            .query(on: req.db)
            .filter(\.$id == uuid)
            .first()
        
        if let ingredient {
            return ingredient
        } else {
            throw Abort(.notFound, reason: "Ingredient with id \(id) not found.")
        }
    }
    
    @Sendable func getRecipesWithIngredient(req: Request) async throws -> Ingredient {
        guard let id = req.parameters.get("id"),
              let uuid = UUID(uuidString: id) else {
            throw Abort(.badRequest, reason: "Invalid uuid")
        }
        
        let ingredient = try await Ingredient
            .query(on: req.db)
            .filter(\.$id == uuid)
            .with(\.$recipes)
            .first()
        
        if let ingredient {
            return ingredient
        } else {
            throw Abort(.notFound, reason: "Ingredient with id \(id) not found.")
        }
        
    }
    
    @Sendable func deleteIngredient(req: Request) async throws -> HTTPStatus {
        guard let ingredient = try await Ingredient.find(req.parameters.get("id"), on: req.db) else {
            throw Abort(.notFound, reason: "Ingredient not found.")
        }
        //BORRAR LAS RELACIONES ANTES PANTRY Y RECIPEINGREDIENTS
        //posiblemente no sea buena idea borrar ingredientes.
        
        try await ingredient.delete(on: req.db)
        return .noContent
    }
    
    @Sendable func updateIngredient(req: Request) async throws -> HTTPStatus {
        guard let ingredient = try await Ingredient.find(req.parameters.get("id"), on: req.db) else {
            throw Abort(.notFound, reason: "Ingredient not found.")
        }
        let updated = try req.content.decode(Ingredient.self)
        
        let exists = try await Ingredient
            .query(on: req.db)
            .filter(\.$name, .custom("ILIKE"), updated.name)
            .filter(\.$id != ingredient.id!) //Se que existe porque está en BBDD
            .first()
        
        if let exists {
            throw Abort(.conflict, reason: "\(updated.name) already exists")
        }
        
        ingredient.category = updated.category
        ingredient.name = updated.name
        
        try await ingredient.update(on: req.db)
        return .noContent //Si envio cuerpo -> .ok
    }
    
    @Sendable func getIngredientsByCategory(req: Request) async throws -> [Ingredient] {
        guard let categoryString = req.parameters.get("category"),
              let category = FoodCategory(rawValue: categoryString) else {
            throw Abort(.badRequest, reason: "Invalid ingredient category")
        }
        
        return try await Ingredient
            .query(on: req.db)
            .filter(\.$category == category)
            .all()
    }
}
