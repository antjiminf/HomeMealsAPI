import NIOSSL
import Fluent
import FluentPostgresDriver
import Vapor


public func configure(_ app: Application) async throws {
    
    app.middleware.use(FileMiddleware(publicDirectory: app.directory.publicDirectory))

    app.databases.use(try .postgres(url: "postgres://admin:admin@localhost:55000/homemeals_db"), as: .psql)
    
    app.migrations.add(UserMigration())
    app.migrations.add(RecipeMigration())
    app.migrations.add(IngredientMigration())
    app.migrations.add(IngredientPivotsMigration())
    
    app.migrations.add(DataMigration())

    // register routes
    try routes(app)
}
