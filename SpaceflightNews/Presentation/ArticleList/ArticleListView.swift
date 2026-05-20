//
//  ArticleListView.swift
//  SpaceflightNews
//
//  Created by Melina Miranda on 19/05/2026.
//

import SwiftUI

struct ArticleListView: View {
    @StateObject private var viewModel: ArticleListViewModel
    
    init(viewModel: ArticleListViewModel) {
        _viewModel = StateObject(wrappedValue: viewModel)
    }
    
    var body: some View {
        NavigationStack {
            contentView
                .navigationTitle("Space News")
                .searchable(
                    text: $viewModel.searchQuery,
                    prompt: "Buscar artículos..."
                )
                .task {
                    if case .idle = viewModel.state {
                        await viewModel.loadArticles()
                    }
                }
        }
    }
    
    @ViewBuilder
    private var contentView: some View {
        switch viewModel.state {
        case .idle:
            Color.clear
            
        case .loading:
            LoadingView()
            
        case .loaded(let articles):
            ArticleList(articles: articles)
            
        case .empty:
            EmptyStateView(
                title: "No hay resultados",
                message: viewModel.searchQuery.isEmpty
                    ? "No se encontraron artículos"
                    : "No se encontraron resultados para '\(viewModel.searchQuery)'"
            )
            
        case .error(let message):
            ErrorStateView(
                message: message,
                retryAction: {
                    Task {
                        await viewModel.loadArticles()
                    }
                }
            )
        }
    }
}

// MARK: - Article List
private struct ArticleList: View {
    let articles: [Article]
    
    var body: some View {
        List(articles) { article in
            NavigationLink(value: article) {
                ArticleRowView(article: article)
            }
        }
        .listStyle(.plain)
        .navigationDestination(for: Article.self) { article in
            ArticleDetailView(article: article)
        }
    }
}

// MARK: - Article Row
private struct ArticleRowView: View {
    let article: Article
    
    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            AsyncImage(url: URL(string: article.imageURL)) { phase in
                switch phase {
                case .empty:
                    placeholderImage
                case .success(let image):
                    image
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                case .failure:
                    placeholderImage
                @unknown default:
                    placeholderImage
                }
            }
            .frame(width: 80, height: 80)
            .clipShape(RoundedRectangle(cornerRadius: 8))
            
            VStack(alignment: .leading, spacing: 4) {
                Text(article.title)
                    .font(.headline)
                    .lineLimit(2)
                
                Text(article.newsSite)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                
                Text(article.formattedPublishedDate)
                    .font(.caption)
                    .foregroundStyle(.tertiary)
            }
        }
        .padding(.vertical, 4)
    }
    
    private var placeholderImage: some View {
        Rectangle()
            .fill(Color.gray.opacity(0.2))
            .overlay {
                Image(systemName: "photo")
                    .foregroundStyle(.tertiary)
            }
    }
}

// MARK: - Loading View
private struct LoadingView: View {
    var body: some View {
        VStack(spacing: 16) {
            ProgressView()
                .scaleEffect(1.5)
            Text("Cargando artículos...")
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
    }
}

// MARK: - Empty State View
private struct EmptyStateView: View {
    let title: String
    let message: String
    
    var body: some View {
        ContentUnavailableView(
            title,
            systemImage: "magnifyingglass",
            description: Text(message)
        )
    }
}

// MARK: - Error State View
private struct ErrorStateView: View {
    let message: String
    let retryAction: () -> Void
    
    var body: some View {
        ContentUnavailableView {
            Label("Error", systemImage: "exclamationmark.triangle")
        } description: {
            Text(message)
        } actions: {
            Button("Reintentar", action: retryAction)
                .buttonStyle(.borderedProminent)
        }
    }
}

// MARK: - Previews
#Preview("Lista con datos") {
    ArticleListView(
        viewModel: {
            let vm = ArticleListViewModel(repository: MockArticleRepository())
            Task { @MainActor in
                vm.state = .loaded(Article.mocks)
            }
            return vm
        }()
    )
}

#Preview("Cargando") {
    ArticleListView(
        viewModel: {
            let vm = ArticleListViewModel(repository: MockArticleRepository())
            Task { @MainActor in
                vm.state = .loading
            }
            return vm
        }()
    )
}

#Preview("Vacío") {
    ArticleListView(
        viewModel: {
            let vm = ArticleListViewModel(repository: MockArticleRepository())
            Task { @MainActor in
                vm.state = .empty
            }
            return vm
        }()
    )
}

#Preview("Error") {
    ArticleListView(
        viewModel: {
            let vm = ArticleListViewModel(repository: MockArticleRepository())
            Task { @MainActor in
                vm.state = .error("No se pudo conectar con el servidor")
            }
            return vm
        }()
    )
}

// MARK: - Mock Repository para Previews
private final class MockArticleRepository: ArticleRepositoryProtocol {
    func fetchArticles(limit: Int, offset: Int) async throws -> [Article] {
        Article.mocks
    }
    
    func fetchArticles(filters: ArticleFilters) async throws -> [Article] {
        Article.mocks
    }
    
    func searchArticles(query: String, limit: Int) async throws -> [Article] {
        Article.mocks
    }
    
    func fetchArticle(id: Int) async throws -> Article {
        Article.mock
    }
}
