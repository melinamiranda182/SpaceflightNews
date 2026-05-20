//
//  ArticleListViewModelTests.swift
//  SpaceflightNewsTests
//
//  Created by Melina Miranda on 19/05/2026.
//

import XCTest
import Combine
@testable import SpaceflightNews

@MainActor
final class ArticleListViewModelTests: XCTestCase {
    
    // MARK: - Tests
    
    func testInitialStateIsIdle() {
        let viewModel = ArticleListViewModel(repository: MockSuccessRepository())
        XCTAssertEqual(viewModel.state, .idle)
    }
    
    func testLoadArticlesSuccessfully() async {
        let viewModel = ArticleListViewModel(repository: MockSuccessRepository())
        
        await viewModel.loadArticles()
        
        guard case .loaded(let articles) = viewModel.state else {
            XCTFail("Expected loaded state with articles")
            return
        }
        
        XCTAssertEqual(articles.count, 3)
        XCTAssertEqual(articles.first?.title, "SpaceX Successfully Launches Starship")
    }
    
    func testLoadArticlesShowsEmptyState() async {
        let viewModel = ArticleListViewModel(repository: MockEmptyRepository())
        
        await viewModel.loadArticles()
        
        XCTAssertEqual(viewModel.state, .empty)
    }
    
    func testLoadArticlesHandlesError() async {
        let viewModel = ArticleListViewModel(repository: MockErrorRepository())
        
        await viewModel.loadArticles()
        
        guard case .error(let message) = viewModel.state else {
            XCTFail("Expected error state")
            return
        }
        
        XCTAssertFalse(message.isEmpty)
    }
    
    func testSearchWithEmptyQueryLoadsAllArticles() async {
        let viewModel = ArticleListViewModel(repository: MockSuccessRepository())
        
        viewModel.searchQuery = ""
        
        // Esperar para el debounce
        try? await Task.sleep(for: .milliseconds(600))
        
        // El estado debe ser idle o loaded
        switch viewModel.state {
        case .idle, .loaded:
            break // Success
        default:
            XCTFail("Expected loaded or idle state, got \(viewModel.state)")
        }
    }
    
    func testSearchWithQueryFiltersArticles() async {
        let viewModel = ArticleListViewModel(repository: MockSuccessRepository())
        
        // Cargar artículos primero
        await viewModel.loadArticles()
        
        // Buscar
        viewModel.searchQuery = "SpaceX"
        
        // Esperar para el debounce
        try? await Task.sleep(for: .milliseconds(600))
        
        guard case .loaded(let articles) = viewModel.state else {
            XCTFail("Expected loaded state")
            return
        }
        
        XCTAssertTrue(articles.allSatisfy { $0.title.localizedCaseInsensitiveContains("SpaceX") })
    }
}

// MARK: - Mock Repositories

private final class MockSuccessRepository: ArticleRepositoryProtocol {
    func fetchArticles(limit: Int, offset: Int) async throws -> [Article] {
        Article.mocks
    }
    
    func fetchArticles(filters: ArticleFilters) async throws -> [Article] {
        Article.mocks
    }
    
    func searchArticles(query: String, limit: Int) async throws -> [Article] {
        Article.mocks.filter { $0.title.localizedCaseInsensitiveContains(query) }
    }
    
    func fetchArticle(id: Int) async throws -> Article {
        Article.mock
    }
}

private final class MockEmptyRepository: ArticleRepositoryProtocol {
    func fetchArticles(limit: Int, offset: Int) async throws -> [Article] {
        []
    }
    
    func fetchArticles(filters: ArticleFilters) async throws -> [Article] {
        []
    }
    
    func searchArticles(query: String, limit: Int) async throws -> [Article] {
        []
    }
    
    func fetchArticle(id: Int) async throws -> Article {
        throw NetworkError.noData
    }
}

private final class MockErrorRepository: ArticleRepositoryProtocol {
    func fetchArticles(limit: Int, offset: Int) async throws -> [Article] {
        throw NetworkError.httpError(statusCode: 500)
    }
    
    func fetchArticles(filters: ArticleFilters) async throws -> [Article] {
        throw NetworkError.httpError(statusCode: 500)
    }
    
    func searchArticles(query: String, limit: Int) async throws -> [Article] {
        throw NetworkError.httpError(statusCode: 500)
    }
    
    func fetchArticle(id: Int) async throws -> Article {
        throw NetworkError.httpError(statusCode: 500)
    }
}
