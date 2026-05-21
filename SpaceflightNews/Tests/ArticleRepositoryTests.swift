//
//  ArticleRepositoryTests.swift
//  SpaceflightNewsTests
//
//  Created by Melina Miranda on 19/05/2026.
//

import XCTest
@testable import SpaceflightNews

final class ArticleRepositoryTests: XCTestCase {
    
    // MARK: - Fetch Tests
    
    func testFetchArticlesSuccessfully() async throws {
        let mockService = MockNetworkService()
        let repository = ArticleRepository(networkService: mockService)
        
        let articles = try await repository.fetchArticles(limit: 10, offset: 0)
        
        XCTAssertEqual(articles.count, 2)
        XCTAssertEqual(articles.first?.title, "Mock Article 1")
        XCTAssertEqual(articles.last?.title, "Mock Article 2")
    }
    
    // MARK: - Search Tests
    
    func testSearchArticlesWithValidQuery() async throws {
        let mockService = MockNetworkService()
        let repository = ArticleRepository(networkService: mockService)
        
        let articles = try await repository.searchArticles(query: "test", limit: 10)
        
        XCTAssertEqual(articles.count, 2)
        XCTAssertNotNil(articles.first)
    }
    
    // MARK: - Single Article Tests
    
    func testFetchSingleArticleById() async throws {
        let mockService = MockNetworkService()
        let repository = ArticleRepository(networkService: mockService)
        
        let article = try await repository.fetchArticle(id: 123)
        
        XCTAssertEqual(article.id, 1)
        XCTAssertEqual(article.title, "Mock Single Article")
        XCTAssertEqual(article.newsSite, "Mock Site")
    }
    
    // MARK: - Error Handling Tests
    
    func testRepositoryHandlesNetworkError() async {
        let errorService = MockErrorNetworkService()
        let repository = ArticleRepository(networkService: errorService)
        
        do {
            _ = try await repository.fetchArticles(limit: 10, offset: 0)
            XCTFail("Should have thrown an error")
        } catch {
            XCTAssertNotNil(error)
        }
    }
    
    func testRepositoryFiltersOutInvalidDTOs() async throws {
        let invalidDTOService = MockPartiallyInvalidDTOService()
        let repository = ArticleRepository(networkService: invalidDTOService)
        
        let articles = try await repository.fetchArticles(limit: 10, offset: 0)
        
        // Debe filtrar los DTOs inválidos con compactMap
        XCTAssertEqual(articles.count, 1) // Solo 1 de 2 es válido
        XCTAssertEqual(articles.first?.title, "Valid Article")
    }
}

// MARK: - Mock Network Services

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

private final class MockErrorNetworkService: NetworkServiceProtocol {
    func request<T: Decodable>(_ endpoint: APIEndpoint) async throws -> T {
        throw NetworkError.httpError(statusCode: 500)
    }
}

private final class MockPartiallyInvalidDTOService: NetworkServiceProtocol {
    func request<T: Decodable>(_ endpoint: APIEndpoint) async throws -> T {
        if T.self == ArticlesResponse.self {
            let response = ArticlesResponse(
                count: 2,
                next: nil,
                previous: nil,
                results: [
                    ArticleDTO(
                        id: 1,
                        title: "Valid Article",
                        url: "https://example.com/1",
                        imageUrl: "https://example.com/image1.jpg",
                        newsSite: "Test",
                        summary: "Valid",
                        publishedAt: "2026-05-19T10:00:00Z",
                        updatedAt: "2026-05-19T10:00:00Z",
                        featured: false,
                        launches: [],
                        events: []
                    ),
                    ArticleDTO(
                        id: 2,
                        title: "Invalid Article",
                        url: "https://example.com/2",
                        imageUrl: "https://example.com/image2.jpg",
                        newsSite: "Test",
                        summary: "Invalid",
                        publishedAt: "invalid-date", // ❌ Fecha inválida
                        updatedAt: "invalid-date",
                        featured: false,
                        launches: [],
                        events: []
                    )
                ]
            )
            return response as! T
        }
        throw NetworkError.noData
    }
}

