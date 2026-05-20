//
//  ArticleRepository.swift
//  SpaceflightNews
//
//  Created by Melina Miranda on 19/05/2026.
//

import Foundation

/// Abstracción del origen de datos - facilita testing y posibles cambios futuros
protocol ArticleRepositoryProtocol {
    func fetchArticles(limit: Int, offset: Int) async throws -> [Article]
    func fetchArticles(filters: ArticleFilters) async throws -> [Article]
    func searchArticles(query: String, limit: Int) async throws -> [Article]
    func fetchArticle(id: Int) async throws -> Article
}

final class ArticleRepository: ArticleRepositoryProtocol {
    private let networkService: NetworkServiceProtocol
    
    init(networkService: NetworkServiceProtocol = NetworkService.createDefault()) {
        self.networkService = networkService
    }
    
    func fetchArticles(limit: Int = 20, offset: Int = 0) async throws -> [Article] {
        var filters = ArticleFilters()
        filters.limit = limit
        filters.offset = offset
        return try await fetchArticles(filters: filters)
    }
    
    func fetchArticles(filters: ArticleFilters) async throws -> [Article] {
        let response: ArticlesResponse = try await networkService.request(
            .articles(filters: filters)
        )
        return response.results.compactMap { $0.toDomain() }
    }
    
    func searchArticles(query: String, limit: Int = 20) async throws -> [Article] {
        guard !query.isEmpty else {
            return []
        }
        
        let response: ArticlesResponse = try await networkService.request(
            .searchArticles(query: query, limit: limit)
        )
        return response.results.compactMap { $0.toDomain() }
    }
    
    func fetchArticle(id: Int) async throws -> Article {
        let dto: ArticleDTO = try await networkService.request(.article(id: id))
        guard let article = dto.toDomain() else {
            throw NetworkError.decodingError
        }
        return article
    }
}
