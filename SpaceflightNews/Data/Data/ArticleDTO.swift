//
//  ArticleDTO.swift
//  SpaceflightNews
//
//  Created by Melina Miranda on 19/05/2026.
//

import Foundation

/// Data Transfer Object - mapea directamente la respuesta de la API
struct ArticleDTO: Decodable {
    let id: Int
    let title: String
    let url: String
    let imageUrl: String?             // ✅ Opcional (puede ser null)
    let newsSite: String
    let summary: String
    let publishedAt: String
    let updatedAt: String
    let featured: Bool?               // ✅ Opcional
    let launches: [LaunchDTO]?        // ✅ Opcional
    let events: [EventDTO]?           // ✅ Opcional
    
    enum CodingKeys: String, CodingKey {
        case id, title, url, summary, featured, launches, events
        case imageUrl = "image_url"
        case newsSite = "news_site"
        case publishedAt = "published_at"
        case updatedAt = "updated_at"
    }
}

// MARK: - Related DTOs

struct LaunchDTO: Decodable {
    let launchId: String
    let provider: String
    
    enum CodingKeys: String, CodingKey {
        case launchId = "launch_id"
        case provider
    }
}

struct EventDTO: Decodable {
    let eventId: Int
    let provider: String
    
    enum CodingKeys: String, CodingKey {
        case eventId = "event_id"
        case provider
    }
}

// MARK: - Conversión a Modelo de Dominio
extension ArticleDTO {
    /// Formateador ISO8601 con opciones flexibles
    private static let dateFormatter: ISO8601DateFormatter = {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        return formatter
    }()
    
    private static let fallbackDateFormatter: ISO8601DateFormatter = {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime]
        return formatter
    }()
    
    func toDomain() -> Article? {
        // Intentar parsear fechas con diferentes formatos
        guard let published = Self.dateFormatter.date(from: publishedAt) 
                ?? Self.fallbackDateFormatter.date(from: publishedAt),
              let updated = Self.dateFormatter.date(from: updatedAt) 
                ?? Self.fallbackDateFormatter.date(from: updatedAt) else {
            #if DEBUG
            print("⚠️ Error parseando fechas:")
            print("   published_at: \(publishedAt)")
            print("   updated_at: \(updatedAt)")
            #endif
            return nil
        }
        
        return Article(
            id: id,
            title: title,
            url: url,
            imageURL: imageUrl ?? "",  // ✅ Default a string vacío si es nil
            newsSite: newsSite,
            summary: summary,
            publishedAt: published,
            updatedAt: updated,
            featured: featured ?? false,
            hasLaunches: !(launches?.isEmpty ?? true),
            hasEvents: !(events?.isEmpty ?? true)
        )
    }
}

/// Respuesta paginada de la API
struct ArticlesResponse: Decodable {
    let count: Int
    let next: String?
    let previous: String?
    let results: [ArticleDTO]
}
