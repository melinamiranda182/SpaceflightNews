//
//  ArticleRepositoryTests.swift
//  SpaceflightNewsTests
//
//  Created by Melina Miranda on 19/05/2026.
//

import XCTest
@testable import SpaceflightNews

final class ArticleRepositoryTests: XCTestCase {
    
    // MARK: - Tests
    
    func testRepositoryWithMockNetworkService() async throws {
        let mockService = MockNetworkService()
        let repository = ArticleRepository(networkService: mockService)
        
        let articles = try await repository.fetchArticles(limit: 10, offset: 0)
        
        XCTAssertEqual(articles.count, 2)
        XCTAssertEqual(articles.first?.title, "Mock Article 1")
    }
    
    func testSearchArticlesWithEmptyQueryReturnsEmpty() async throws {
        let mockService = MockNetworkService()
        let repository = ArticleRepository(networkService: mockService)
        
        let articles = try await repository.searchArticles(query: "", limit: 10)
        
        XCTAssertTrue(articles.isEmpty)
    }
    
    func testSearchArticlesWithValidQuery() async throws {
        let mockService = MockNetworkService()
        let repository = ArticleRepository(networkService: mockService)
        
        let articles = try await repository.searchArticles(query: "test", limit: 10)
        
        XCTAssertEqual(articles.count, 2)
    }
}

// MARK: - Mock Network Service

private final class MockNetworkService: NetworkServiceProtocol {
    func request<T: Decodable>(_ endpoint: APIEndpoint) async throws -> T {
        if T.self == ArticlesResponse.self {
            let response = ArticlesResponse(
                count: 2,
                next: nil,
                previous: nil,
                results: [
                    ArticleDTO(
                        id: 1,
                        title: "Mock Article 1",
                        url: "https://example.com/1",
                        imageUrl: "https://example.com/image1.jpg",
                        newsSite: "Mock Site",
                        summary: "Mock summary 1",
                        publishedAt: "2026-05-19T10:00:00Z",
                        updatedAt: "2026-05-19T10:00:00Z",
                        featured: false,
                        launches: [],
                        events: []
                    ),
                    ArticleDTO(
                        id: 2,
                        title: "Mock Article 2",
                        url: "https://example.com/2",
                        imageUrl: "https://example.com/image2.jpg",
                        newsSite: "Mock Site",
                        summary: "Mock summary 2",
                        publishedAt: "2026-05-19T11:00:00Z",
                        updatedAt: "2026-05-19T11:00:00Z",
                        featured: true,
                        launches: [],
                        events: []
                    )
                ]
            )
            return response as! T
        }
        
        if T.self == ArticleDTO.self {
            let dto = ArticleDTO(
                id: 1,
                title: "Mock Single Article",
                url: "https://example.com/1",
                imageUrl: "https://example.com/image1.jpg",
                newsSite: "Mock Site",
                summary: "Mock summary",
                publishedAt: "2026-05-19T10:00:00Z",
                updatedAt: "2026-05-19T10:00:00Z",
                featured: false,
                launches: [],
                events: []
            )
            return dto as! T
        }
        
        throw NetworkError.noData
    }
}
