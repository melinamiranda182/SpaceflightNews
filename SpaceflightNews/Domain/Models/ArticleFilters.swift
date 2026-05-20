//
//  ArticleFilters.swift
//  SpaceflightNews
//
//  Created by Melina Miranda on 20/05/2026.
//

import Foundation

/// Ordenamiento de artículos - concepto de dominio
enum ArticleOrdering {
    case publishedAscending
    case publishedDescending
    case updatedAscending
    case updatedDescending
    
    /// Mapeo a formato de API (responsabilidad de infraestructura)
    var apiValue: String {
        switch self {
        case .publishedAscending: return "published_at"
        case .publishedDescending: return "-published_at"
        case .updatedAscending: return "updated_at"
        case .updatedDescending: return "-updated_at"
        }
    }
}

/// Filtros para búsqueda y listado de artículos - modelo de dominio
struct ArticleFilters {
    var limit: Int = 20
    var offset: Int = 0
    var search: String?
    var hasEvent: Bool?
    var hasLaunch: Bool?
    var newsSite: String?
    var ordering: ArticleOrdering = .publishedDescending
}
