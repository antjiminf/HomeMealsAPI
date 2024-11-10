import Fluent
import Vapor

func routes(_ app: Application) throws {
    try app.register(collection: IngredientController())
    try app.register(collection: RecipeController())
    try app.register(collection: UserController())
}
