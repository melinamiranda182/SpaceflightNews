//
//  Article.swift
//  SpaceflightNews
//
//  Created by Melina Miranda on 19/05/2026.
//

import Foundation

/// Modelo de dominio puro - representa un artículo de noticias espaciales
struct Article: Identifiable, Hashable {
    let id: Int
    let title: String
    let url: String
    let imageURL: String
    let newsSite: String
    let summary: String
    let publishedAt: Date
    let updatedAt: Date
    let featured: Bool
    let hasLaunches: Bool
    let hasEvents: Bool
    
    var formattedPublishedDate: String {
        publishedAt.formatted(date: .abbreviated, time: .omitted)
    }
    
    var isFeatured: Bool {
        featured
    }
}

// MARK: - Mock Data para Previews y Tests
extension Article {
    static let mock = Article(
        id: 1,
        title: "SpaceX Successfully Launches Starship",
        url: "https://example.com/article",
        imageURL: "https://example.com/image.jpg",
        newsSite: "Space News",
        summary: "SpaceX has successfully launched its Starship vehicle, marking a historic moment in space exploration. The launch represents years of development and testing.",
        publishedAt: Date(),
        updatedAt: Date(),
        featured: true,
        hasLaunches: true,
        hasEvents: false
    )
    
    static let mocks = [
        Article(
            id: 1,
            title: "SpaceX Successfully Launches Starship",
            url: "https://example.com/article1",
            imageURL: "https://example.com/image1.jpg",
            newsSite: "Space News",
            summary: "SpaceX has successfully launched its Starship vehicle.",
            publishedAt: Date(),
            updatedAt: Date(),
            featured: true,
            hasLaunches: true,
            hasEvents: false
        ),
        Article(
            id: 2,
            title: "NASA Discovers New Exoplanet",
            url: "https://example.com/article2",
            imageURL: "https://example.com/image2.jpg",
            newsSite: "NASA",
            summary: "NASA astronomers have discovered a potentially habitable exoplanet.",
            publishedAt: Date().addingTimeInterval(-86400),
            updatedAt: Date().addingTimeInterval(-86400),
            featured: false,
            hasLaunches: false,
            hasEvents: true
        ),
        Article(
            id: 3,
            title: "Mars Rover Sends Stunning Images",
            url: "https://example.com/article3",
            imageURL: "https://example.com/image3.jpg",
            newsSite: "Mars Daily",
            summary: "The latest Mars rover has transmitted high-resolution images of the Martian surface.",
            publishedAt: Date().addingTimeInterval(-172800),
            updatedAt: Date().addingTimeInterval(-172800),
            featured: false,
            hasLaunches: false,
            hasEvents: false
        )
    ]
}
