//
//  NetworkServiceTests.swift
//  SpaceflightNewsTests
//
//  Created by Melina Miranda on 19/05/2026.
//

import XCTest
import Foundation
@testable import SpaceflightNews

final class NetworkServiceTests: XCTestCase {
    
    // MARK: - APIEndpoint Tests
    
    func testArticleEndpointGeneratesCorrectURL() {
        var filters = ArticleFilters()
        filters.limit = 20
        filters.offset = 0
        let endpoint = APIEndpoint.articles(filters: filters)
        let url = endpoint.url
        
        XCTAssertNotNil(url)
        XCTAssertTrue(url?.absoluteString.contains("limit=20") ?? false)
        XCTAssertTrue(url?.absoluteString.contains("offset=0") ?? false)
        XCTAssertTrue(url?.absoluteString.contains("/articles") ?? false)
    }
    
    func testSearchEndpointGeneratesCorrectURL() {
        let endpoint = APIEndpoint.searchArticles(query: "SpaceX", limit: 10)
        let url = endpoint.url
        
        XCTAssertNotNil(url)
        XCTAssertTrue(url?.absoluteString.contains("search=SpaceX") ?? false)
        XCTAssertTrue(url?.absoluteString.contains("limit=10") ?? false)
    }
    
    func testSingleArticleEndpointGeneratesCorrectURL() {
        let endpoint = APIEndpoint.article(id: 123)
        let url = endpoint.url
        
        XCTAssertNotNil(url)
        XCTAssertTrue(url?.absoluteString.contains("/articles/123") ?? false)
    }
    
    // MARK: - ArticleDTO Tests
    
    func testArticleDTOConvertsToDomainModelCorrectly() {
        let dto = ArticleDTO(
            id: 1,
            title: "Test Article",
            url: "https://example.com",
            imageUrl: "https://example.com/image.jpg",
            newsSite: "Test Site",
            summary: "Test summary",
            publishedAt: "2026-05-19T10:00:00Z",
            updatedAt: "2026-05-19T10:00:00Z",
            featured: true,
            launches: [],
            events: []
        )
        
        let article = dto.toDomain()
        
        XCTAssertNotNil(article)
        XCTAssertEqual(article?.id, 1)
        XCTAssertEqual(article?.title, "Test Article")
        XCTAssertEqual(article?.url, "https://example.com")
        XCTAssertEqual(article?.imageURL, "https://example.com/image.jpg")
        XCTAssertEqual(article?.newsSite, "Test Site")
        XCTAssertEqual(article?.summary, "Test summary")
        XCTAssertEqual(article?.featured, true)
        XCTAssertEqual(article?.hasLaunches, false)
        XCTAssertEqual(article?.hasEvents, false)
    }
    
    func testArticleDTOReturnsNilForInvalidDates() {
        let dto = ArticleDTO(
            id: 1,
            title: "Test Article",
            url: "https://example.com",
            imageUrl: "https://example.com/image.jpg",
            newsSite: "Test Site",
            summary: "Test summary",
            publishedAt: "invalid-date",
            updatedAt: "invalid-date",
            featured: false,
            launches: [],
            events: []
        )
        
        let article = dto.toDomain()
        
        XCTAssertNil(article)
    }
    
    func testArticleDTODecodesCorrectlyWithSnakeCase() throws {
        let json = """
        {
            "id": 1,
            "title": "Test Article",
            "url": "https://example.com",
            "image_url": "https://example.com/image.jpg",
            "news_site": "Test Site",
            "summary": "Test summary",
            "published_at": "2026-05-19T10:00:00Z",
            "updated_at": "2026-05-19T10:00:00Z",
            "featured": false,
            "launches": [],
            "events": []
        }
        """
        
        let data = json.data(using: .utf8)!
        let decoder = JSONDecoder()
        
        let dto = try decoder.decode(ArticleDTO.self, from: data)
        
        XCTAssertEqual(dto.id, 1)
        XCTAssertEqual(dto.title, "Test Article")
        XCTAssertEqual(dto.imageUrl, "https://example.com/image.jpg")
        XCTAssertEqual(dto.newsSite, "Test Site")
    }
}

