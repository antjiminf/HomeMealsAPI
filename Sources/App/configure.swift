import NIOSSL
import Fluent
import FluentPostgresDriver
import Vapor


public func configure(_ app: Application) async throws {
    
    app.middleware.use(FileMiddleware(publicDirectory: app.directory.publicDirectory))

    app.databases.use(try .postgres(url: "postgres://admin:admin@localhost:55000/homemeals_db"), as: .psql)
    
    //De-Encoders
    let decoder = JSONDecoder()
    decoder.dateDecodingStrategy = .iso8601
    
    let encoder = JSONEncoder()
    encoder.dateEncodingStrategy = .iso8601
    
    ContentConfiguration.global.use(decoder: decoder, for: .json)
    ContentConfiguration.global.use(encoder: encoder, for: .json)
    
    //Entities migration
    app.migrations.add(UserMigration())
    app.migrations.add(RecipeMigration())
    app.migrations.add(IngredientMigration())
    app.migrations.add(IngredientPivotsMigration())
    
    //Data injection
    app.migrations.add(DataMigration())

    //Routes registration
    try routes(app)
}
