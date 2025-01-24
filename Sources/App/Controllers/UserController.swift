import Vapor
import Fluent

struct UserController: RouteCollection {
    func boot(routes: any RoutesBuilder) throws {
        let users = routes.grouped("api", "users")
        
        users.group("inventory") { inventory in
            inventory.get(use: getUserInventory)
            inventory.get("recipe-suggestions", use: getSuggestedRecipes)
            inventory.post(use: createUserIngredient)
            inventory.post("groceries-list", use: getMissingGroceries)
            inventory.put(use: updateInventoryItems)
            inventory.put(":id", use: updateInventoryItem)
            inventory.put("groceries", use: addGroceries)
            inventory.put("consume", use: consumeInventoryIngredients)
            inventory.delete(":id", use: deleteUserIngredient)
        }
    }
    
    // USER ACCOUNT ENDPOINTS
    
    
    
    // INVENTORY ENDPOINTS
    
    @Sendable func getUserInventory(req: Request) async throws -> [Pantry.UserIngredient] {
        //TODO: Recuperar user
        let user = UUID(uuidString: "123E4567-E89B-12D3-A456-426614174000")!
        return try await Pantry.query(on: req.db)
            .with(\.$ingredient)
            .filter(\.$user.$id == user)
            .all()
            .map {
                try $0.userIngredient
            }
    }
    
    @Sendable func getSuggestedRecipes(req: Request) async throws -> [Recipe.RecipeListResponse] {
        //TODO: Recuperar user
        let user = UUID(uuidString: "123E4567-E89B-12D3-A456-426614174000")!
        
        let inventory = try await Pantry.query(on: req.db)
            .filter(\.$user.$id == user)
            .with(\.$ingredient)
            .all()
        
        let inventoryDict = Dictionary(uniqueKeysWithValues: inventory.map { ($0.$ingredient.id, $0.quantity) })
        
        let recipes = try await Recipe.query(on: req.db)
            .with(\.$user)
            .with(\.$ingredientsDetails) { details in
                details.with(\.$ingredient)
            }
            .with(\.$favorites) { fav in
                fav.with(\.$user)
            }
            .group(.or) { or in
                or.filter(\.$isPublic == true)
                or.filter(\.$user.$id == user)
            }
            .all()
        
        let recommendedRecipes = recipes.filter { recipe in
            for details in recipe.ingredientsDetails {
                
                guard let quantity = inventoryDict[details.$ingredient.id],
                      quantity >= details.quantity else {
                    return false
                }
            }
            return true
        }
        
        return try recommendedRecipes.map{
            try $0.recipeListResponse(userId: user)
        }
    }
    
    @Sendable func createUserIngredient(req: Request) async throws -> HTTPStatus {
        //TODO: Recuperar user
        let user = UUID(uuidString: "123E4567-E89B-12D3-A456-426614174000")!
        
        try IngredientQuantity.validate(content: req)
        let newDto = try req.content.decode(IngredientQuantity.self)
        
        if let _ = try await Pantry.query(on: req.db)
            .filter(\.$user.$id == user)
            .filter(\.$ingredient.$id == newDto.ingredient)
            .first() {
            
            throw Abort(.badRequest, reason: "The user already has this ingredient")
        }
        
        let new = Pantry(user: user,
                         ingredient: newDto.ingredient,
                         quantity: newDto.quantity,
                         unit: newDto.unit)
        
        try await new.save(on: req.db)
        return .created
    }
    
    @Sendable func getMissingGroceries(req: Request) async throws -> [Groceries] {
        //TODO: Recuperar user
        let user = UUID(uuidString: "123E4567-E89B-12D3-A456-426614174000")!
        
        //        try IngredientQuantity.validate(content: req)
        let requiredIng = try req.content.decode([IngredientQuantity].self)
        
        return try await req.db.transaction { db in
            
            let inventory = try await Pantry.query(on: db)
                .filter(\.$user.$id == user)
                .all()
            
            let inventoryDict = Dictionary(uniqueKeysWithValues: inventory.map { ($0.$ingredient.id, $0) })
            
            var missingIng: [Groceries] = []
            
            for i in requiredIng {
                if let existing = inventoryDict[i.ingredient] {
                    
                    if existing.quantity < i.quantity {
                        
                        try await existing.$ingredient.load(on: db)
                        
                        let missingQuantity = i.quantity - existing.quantity
                        let missing = try Groceries(ingredientId: existing.ingredient.requireID(),
                                                    name: existing.ingredient.name,
                                                    requiredQuantity: missingQuantity,
                                                    unit: existing.unit)
                        
                        missingIng.append(missing)
                    }
                } else {
                    
                    if let ingredient = try await Ingredient.find(i.ingredient, on: db) {
                        let missing = try Groceries(ingredientId: ingredient.requireID(),
                                                    name: ingredient.name,
                                                    requiredQuantity: i.quantity,
                                                    unit: ingredient.unit)
                        
                        missingIng.append(missing)
                    }
                }
            }
            
            return missingIng
        }
    }
    
    
    @Sendable func updateInventoryItems(req: Request) async throws -> HTTPStatus {
        //TODO: Recuperar user
        let user = UUID(uuidString: "123E4567-E89B-12D3-A456-426614174000")!
        let newIng = try req.content.decode([IngredientQuantity].self)
        
        return try await req.db.transaction { db in
            
            let inventory = try await Pantry.query(on: db)
                .filter(\.$user.$id == user)
                .all()
            
            let inventoryDict = Dictionary(uniqueKeysWithValues: inventory.map {
                ($0.$ingredient.id, $0)
            })
            
            for ing in newIng {
                if let existing = inventoryDict[ing.ingredient] {
                    
                    existing.quantity = ing.quantity
                    try await existing.save(on: db)
                    
                } else {
                    
                    let new = Pantry(user: user,
                                     ingredient: ing.ingredient,
                                     quantity: ing.quantity,
                                     unit: ing.unit)
                    try await new.save(on: db)
                }
            }
            return .noContent
        }
    }
    
    @Sendable func updateInventoryItem(req: Request) async throws -> HTTPStatus {
        //TODO: Recuperar user
        let user = UUID(uuidString: "123E4567-E89B-12D3-A456-426614174000")!
        try IngredientQuantity.validate(content: req)
        let updated = try req.content.decode(IngredientQuantity.self)
        
        guard let ingredient = try await Pantry.find(req.parameters.get("id"), on: req.db) else {
            throw Abort(.notFound, reason: "Ingredient not found")
        }
        try await ingredient.$user.load(on: req.db)
        
        if ingredient.user.id != user {
            throw Abort(.unauthorized, reason: "Owner does not match with authenticated user")
        }
        
        ingredient.quantity = updated.quantity
        try await ingredient.save(on: req.db)
        
        return .noContent
    }
    
    @Sendable func addGroceries(req: Request) async throws -> HTTPStatus {
        //TODO: Recuperar user
        let user = UUID(uuidString: "123E4567-E89B-12D3-A456-426614174000")!
        let newIng = try req.content.decode([IngredientQuantity].self)
        
        return try await req.db.transaction { db in
            let inventory = try await Pantry.query(on: db)
                .filter(\.$user.$id == user)
                .all()
            
            let inventoryDict = Dictionary(uniqueKeysWithValues: inventory.map {
                ($0.$ingredient.id, $0)
            })
            
            for ing in newIng {
                if let existing = inventoryDict[ing.ingredient] {
                    
                    existing.quantity += ing.quantity
                    try await existing.save(on: db)
                    
                } else {
                    
                    let new = Pantry(user: user,
                                     ingredient: ing.ingredient,
                                     quantity: ing.quantity,
                                     unit: ing.unit)
                    try await new.save(on: db)
                }
            }
            return .noContent
        }
    }
    
    //CREO QUE ES MÁS EFICIENTE EN OPERACIONES GRANDES
    
//    @Sendable func addGroceries(req: Request) async throws -> HTTPStatus {
//        //TODO: Recuperar user
//        let user = UUID(uuidString: "123E4567-E89B-12D3-A456-426614174000")!
//        let newIng = try req.content.decode([IngredientQuantity].self)
//        
//        return try await req.db.transaction { db in
//            let inventory = try await Pantry.query(on: db)
//                .filter(\.$user.$id == user)
//                .all()
//            
//            let inventoryDict = Dictionary(uniqueKeysWithValues: inventory.map {
//                ($0.$ingredient.id, $0)
//            })
//            var newItems: [Pantry] = []
//            var updatedItems: [Pantry] = []
//            
//            for ing in newIng {
//                if let existing = inventoryDict[ing.ingredient] {
//                    existing.quantity += ing.quantity
//                    updatedItems.append(existing)
//                } else {
//                    let new = Pantry(user: user,
//                                     ingredient: ing.ingredient,
//                                     quantity: ing.quantity,
//                                     unit: ing.unit)
//                    newItems.append(new)
//                }
//            }
//            
//            for chunk in updatedItems.chunks(ofCount: 100) {
//                let _ = chunk.map { $0.update(on: db) }.flatten(on: db.eventLoop)
//            }
//            
//            for chunk in newItems.chunks(ofCount: 100) {
//                try await chunk.create(on: db)
//            }
//            
//            return .noContent
//        }
//    }
    
    
    @Sendable func consumeInventoryIngredients(req: Request) async throws -> HTTPStatus {
        //TODO: Recuperar user
        let user = UUID(uuidString: "123E4567-E89B-12D3-A456-426614174000")!
        
        //        try IngredientQuantity.validate(content: req)
        let consumedIng = try req.content.decode([IngredientQuantity].self)
        
        return try await req.db.transaction { db in
            let inventory = try await Pantry.query(on: db)
                .filter(\.$user.$id == user)
                .all()
            
            let inventoryDict = Dictionary(uniqueKeysWithValues: inventory.map {
                ($0.$ingredient.id, $0)
            })
            
            for i in consumedIng {
                if let existing = inventoryDict[i.ingredient] {
                    if existing.quantity >= i.quantity {
                        
                        existing.quantity -= i.quantity
                        try await existing.save(on: db)
                        
                        if existing.quantity == 0 {
                            try await existing.delete(on: db)
                        }
                    } else {
                        throw Abort(.badRequest, reason: "Insufficient quantity for ingredient \(i.ingredient)")
                    }
                } else {
                    throw Abort(.notFound, reason: "Ingredient \(i.ingredient) not found in inventory")
                }
            }
            
            return .noContent
        }
        
    }
    
    
    @Sendable func deleteUserIngredient(req: Request) async throws -> HTTPStatus {
        //TODO: Recuperar user
        let user = UUID(uuidString: "123E4567-E89B-12D3-A456-426614174000")!
        
        guard let ingredient = try await Pantry.find(req.parameters.get("id"), on: req.db) else {
            throw Abort(.notFound, reason: "Ingredient not found")
        }
        try await ingredient.$user.load(on: req.db)
        
        if ingredient.user.id != user {
            throw Abort(.unauthorized, reason: "Owner does not match with authenticated user")
        }
        
        try await ingredient.delete(on: req.db)
        return .noContent
    }
    
}
