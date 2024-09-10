import Vapor
import Fluent

struct PageDTO<T: Content>: Content {
    let page: Int
    let perPage: Int
    let total: Int
    let items: [T]
    
    init(pg: Page<T>) {
        self.page = pg.metadata.page
        self.perPage = pg.metadata.per
        self.total = pg.metadata.total
        self.items = pg.items
    }
}
