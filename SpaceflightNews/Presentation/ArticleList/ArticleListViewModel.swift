//
//  ArticleListViewModel.swift
//  SpaceflightNews
//
//  Created by Melina Miranda on 19/05/2026.
//

import Foundation
import Combine

/// Estados posibles de la lista de artículos
enum ArticleListState: Equatable {
    case idle
    case loading
    case loaded([Article])
    case empty
    case error(String)
}

@MainActor
final class ArticleListViewModel: ObservableObject {
    // MARK: - Published Properties
    @Published internal(set) var state: ArticleListState = .idle
    @Published var searchQuery: String = ""
    
    // MARK: - Dependencies
    private let repository: ArticleRepositoryProtocol
    private var cancellables = Set<AnyCancellable>()
    
    // MARK: - Initialization
    init(repository: ArticleRepositoryProtocol = ArticleRepository()) {
        self.repository = repository
        setupSearchDebounce()
    }
    
    // MARK: - Public Methods
    func loadArticles() async {
        state = .loading
        
        do {
            let articles = try await repository.fetchArticles(limit: 50, offset: 0)
            handleLoadedArticles(articles)
        } catch {
            state = .error(error.localizedDescription)
        }
    }
    
    // MARK: - Private Methods
    private func setupSearchDebounce() {
        $searchQuery
            .debounce(for: .milliseconds(500), scheduler: DispatchQueue.main)
            .removeDuplicates()
            .sink { [weak self] query in
                Task {
                    await self?.performSearch(query: query)
                }
            }
            .store(in: &cancellables)
    }
    
    private func performSearch(query: String) async {
        if query.isEmpty {
            await loadArticles()
            return
        }
        
        state = .loading
        
        do {
            let articles = try await repository.searchArticles(query: query, limit: 50)
            handleLoadedArticles(articles)
        } catch {
            state = .error(error.localizedDescription)
        }
    }
    
    private func handleLoadedArticles(_ articles: [Article]) {
        if articles.isEmpty {
            state = .empty
        } else {
            state = .loaded(articles)
        }
    }
}
