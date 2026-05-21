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
    
    // MARK: - Initialization Tests
    
    func testInitialStateIsIdle() async {
        let viewModel = ArticleListViewModel(repository: MockSuccessRepository())
        XCTAssertEqual(viewModel.state, .idle)
        
        // Esperar que el debounce inicial complete antes de destruir el ViewModel
        try? await Task.sleep(for: .milliseconds(600))
    }
    
    // MARK: - Load Articles Tests
    
    func testLoadArticlesSuccessfully() async {
        let viewModel = ArticleListViewModel(repository: MockSuccessRepository())
        
        // Esperar que el debounce inicial se complete
        try? await Task.sleep(for: .milliseconds(600))
        
        await viewModel.loadArticles()
        
        guard case .loaded(let articles) = viewModel.state else {
            XCTFail("Expected loaded state with articles, got: \(viewModel.state)")
            return
        }
        
        XCTAssertEqual(articles.count, 3)
        XCTAssertEqual(articles.first?.title, "SpaceX Successfully Launches Starship")
    }
    
    func testLoadArticlesShowsEmptyState() async {
        let viewModel = ArticleListViewModel(repository: MockEmptyRepository())
        
        // Esperar que el debounce inicial termine
        try? await Task.sleep(for: .milliseconds(600))
        
        await viewModel.loadArticles()
        
        XCTAssertEqual(viewModel.state, .empty)
    }
    
    func testLoadArticlesHandlesError() async {
        let viewModel = ArticleListViewModel(repository: MockErrorRepository())
        
        // Esperar que el debounce inicial termine
        try? await Task.sleep(for: .milliseconds(600))
        
        await viewModel.loadArticles()
        
        guard case .error(let message) = viewModel.state else {
            XCTFail("Expected error state, got: \(viewModel.state)")
            return
        }
        
        XCTAssertFalse(message.isEmpty)
    }
}

// MARK: - Mock Repositories

/// Mock que devuelve artículos instantáneamente (sin delay)
final class MockSuccessRepository: ArticleRepositoryProtocol {
    func fetchArticles(limit: Int, offset: Int) async throws -> [Article] {
        // Sin delay para tests más rápidos y deterministas
        return Article.mocks
    }
    
    func fetchArticles(filters: ArticleFilters) async throws -> [Article] {
        return Article.mocks
    }
    
    func searchArticles(query: String, limit: Int) async throws -> [Article] {
        return Article.mocks.filter { $0.title.localizedCaseInsensitiveContains(query) }
    }
    
    func fetchArticle(id: Int) async throws -> Article {
        return Article.mock
    }
}

/// Mock que devuelve array vacío (para probar estado empty)
final class MockEmptyRepository: ArticleRepositoryProtocol {
    func fetchArticles(limit: Int, offset: Int) async throws -> [Article] {
        return []
    }
    
    func fetchArticles(filters: ArticleFilters) async throws -> [Article] {
        return []
    }
    
    func searchArticles(query: String, limit: Int) async throws -> [Article] {
        return []
    }
    
    func fetchArticle(id: Int) async throws -> Article {
        throw NetworkError.noData
    }
}

/// Mock que siempre lanza errores (para probar manejo de errores)
final class MockErrorRepository: ArticleRepositoryProtocol {
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
