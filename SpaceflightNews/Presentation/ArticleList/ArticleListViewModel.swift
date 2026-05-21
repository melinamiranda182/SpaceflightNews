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
    
    // MARK: - Task Management
    private var searchTask: Task<Void, Never>?
    
    // MARK: - Cache
    private var cachedArticles: [Article] = []
    
    // MARK: - Initialization
    init(repository: ArticleRepositoryProtocol = ArticleRepository()) {
        self.repository = repository
        setupSearchDebounce()
    }
    
    deinit {
        searchTask?.cancel()
        cancellables.removeAll()
    }
    
    // MARK: - Public Methods
    func loadArticles() async {
        // Cancelar cualquier búsqueda en progreso
        searchTask?.cancel()
        searchTask = nil
        
        // Guardar estado anterior por si hay cancelación
        let previousState = state
        state = .loading
        
        do {
            let articles = try await repository.fetchArticles(limit: 50, offset: 0)
            
            // Cachear artículos iniciales para restaurar al limpiar búsqueda
            if searchQuery.isEmpty {
                cachedArticles = articles
            }
            
            handleLoadedArticles(articles)
        } catch is CancellationError {
            // Delay breve para transición más suave
            try? await Task.sleep(nanoseconds: 200_000_000) // 0.2 segundos
            state = previousState
            return
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
                guard let self = self else { return }
                
                // Cancelar búsqueda anterior si existe
                self.searchTask?.cancel()
                
                // Iniciar nueva búsqueda
                self.searchTask = Task {
                    await self.performSearch(query: query)
                }
            }
            .store(in: &cancellables)
    }
    
    private func performSearch(query: String) async {
        // Verificar si la tarea fue cancelada antes de empezar
        guard !Task.isCancelled else { return }
        
        if query.isEmpty {
            // Al limpiar búsqueda, restaurar artículos cacheados si existen
            if !cachedArticles.isEmpty {
                state = .loaded(cachedArticles)
                return
            }
            
            if case .idle = state {
                await loadArticles()
            }
            return
        }
        
        // Guardar estado anterior
        let previousState = state
        state = .loading
        
        do {
            let articles = try await repository.searchArticles(query: query, limit: 50)
            
            // Verificar cancelación antes de actualizar el estado
            guard !Task.isCancelled else {
                state = previousState
                return
            }
            
            handleLoadedArticles(articles)
        } catch is CancellationError {
            // Restaurar estado anterior si fue cancelado
            state = previousState
            return
        } catch {
            // Solo actualizar estado si no fue cancelada
            guard !Task.isCancelled else {
                state = previousState
                return
            }
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
