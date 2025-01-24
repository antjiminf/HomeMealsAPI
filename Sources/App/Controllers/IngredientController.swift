
import Vapor
import Fluent

struct IngredientController: RouteCollection {
    func boot(routes: any RoutesBuilder) throws {
        let ingredients = routes.grouped("api", "ingredients")
        
        ingredients.get(use: getIngredients)
        ingredients.post(use: createIngredient)
        ingredients.get("search", use: searchIngredients)
        ingredients.group(":id") { ingredient in
            ingredient.get(use: getIngredient)
            ingredient.get("recipes", use: getRecipesWithIngredient)
            ingredient.delete(use: deleteIngredient)
            ingredient.put(use: updateIngredient)
        }
        ingredients.get("all", use: getAllIngredients)
        ingredients.get("exists", ":name", use: existsIngredientName)
        ingredients.get("category", ":category", use: getIngredientsByCategory)
        
    }
    
    @Sendable func getAllIngredients(req: Request) async throws -> [Ingredient] {
        return try await Ingredient.query(on: req.db)
            .all()
    }
    
    @Sendable func getIngredients(req: Request) async throws -> PageDTO<Ingredient> {
        let page = try await Ingredient
            .query(on: req.db)
            .paginate(for: req)
        return PageDTO(pg: page)
    }
    
    @Sendable func searchIngredients(req: Request) async throws -> PageDTO<Ingredient> {
        var ingredients = Ingredient.query(on: req.db)
        
        if let name = req.query[String.self, at: "name"] {
            ingredients = ingredients.filter(\.$name, .custom("ILIKE"), "%\(name)%")
        }
        if let categoriesString = req.query[String.self, at: "categories"] {
            let categories = categoriesString.split(separator: ",").compactMap {
                FoodCategory(rawValue: String($0).trimmingCharacters(in: .whitespaces))
            }
            
            if !categories.isEmpty {
                ingredients = ingredients.filter(\.$category ~~ categories)
            }
        }
        
        let page = try await ingredients.paginate(for: req)
        return PageDTO(pg: page)
    }
    
    @Sendable func existsIngredientName(req: Request) async throws -> HTTPStatus {
        guard let name = req.parameters.get("name") else {
            throw Abort(.badRequest, reason: "Ingredient name not found.")
        }
        
        let exists = try await Ingredient.query(on: req.db)
            .filter(\.$name, .custom("ILIKE"), name)
            .first()
        
        if exists == nil {
            return .ok
        } else {
            return .notAcceptable
        }
    }
    
    @Sendable func createIngredient(req: Request) async throws -> HTTPStatus {
        // Autentication USER
        try CreateIngredient.validate(content: req)
        let new = try req.content.decode(CreateIngredient.self)
        
        let exists = try await Ingredient
            .query(on: req.db)
            .filter(\.$name, .custom("ILIKE"), new.name)
            .first()
        
        if exists != nil {
            throw Abort(.conflict, reason: "\(new.name) already exists")
        }
        
        try await new.toIngredient().create(on: req.db)
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
    
    @Sendable func getRecipesWithIngredient(req: Request) async throws -> Ingredient.RecipesWithIngredient {
        let user = UUID(uuidString: "123E4567-E89B-12D3-A456-426614174000")!
        guard let id = req.parameters.get("id"),
              let uuid = UUID(uuidString: id) else {
            throw Abort(.badRequest, reason: "Invalid uuid")
        }
        
        let ingredient = try await Ingredient
            .query(on: req.db)
            .filter(\.$id == uuid)
            .with(\.$recipes) { recipe in
                recipe.with(\.$user)
                    .with(\.$favorites)
            }
            .first()
        
        if let ingredient {
            return try ingredient.recipesWithIngredient(userId: user)
        } else {
            throw Abort(.notFound, reason: "Ingredient with id \(id) not found.")
        }
        
    }
    
    @Sendable func deleteIngredient(req: Request) async throws -> HTTPStatus {
        //Authentication ADMIN
        guard let ingredient = try await Ingredient.find(req.parameters.get("id"), on: req.db) else {
            throw Abort(.notFound, reason: "Ingredient not found.")
        }
        //BORRAR LAS RELACIONES ANTES PANTRY Y RECIPEINGREDIENTS
        //posiblemente no sea buena idea borrar ingredientes.
        
        try await ingredient.delete(on: req.db)
        return .noContent
    }
    
    @Sendable func updateIngredient(req: Request) async throws -> HTTPStatus {
//        Authentication ADMIN
        try CreateIngredient.validate(content: req)
        let updated = try req.content.decode(CreateIngredient.self)
        guard let ingredient = try await Ingredient.find(req.parameters.get("id"), on: req.db) else {
            throw Abort(.notFound, reason: "Ingredient not found.")
        }
        
        let exists = try await Ingredient
            .query(on: req.db)
            .filter(\.$name, .custom("ILIKE"), updated.name)
            .filter(\.$id != ingredient.id!) //Se que existe porque está en BBDD
            .first()
        
        if exists != nil {
            throw Abort(.conflict, reason: "\(updated.name) already exists")
        }
        
        ingredient.unit = updated.unit
        ingredient.category = updated.category
        ingredient.name = updated.name
        
        try await ingredient.update(on: req.db)
        return .noContent //Si envio cuerpo -> .ok
    }
    
    @Sendable func getIngredientsByCategory(req: Request) async throws -> PageDTO<Ingredient> {
        guard let categoryString = req.parameters.get("category"),
              let category = FoodCategory(rawValue: categoryString) else {
            throw Abort(.badRequest, reason: "Invalid ingredient category")
        }
        
        let page = try await Ingredient
            .query(on: req.db)
            .filter(\.$category == category)
            .paginate(for: req)
        return PageDTO(pg: page)
    }
}
