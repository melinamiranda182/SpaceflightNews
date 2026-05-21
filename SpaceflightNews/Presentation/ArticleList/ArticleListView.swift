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
                .animation(.easeInOut(duration: 0.2), value: viewModel.state)
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
            ArticleList(articles: articles, viewModel: viewModel)
            
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
                    await viewModel.loadArticles()
                }
            )
        }
    }
}

// MARK: - Article List
private struct ArticleList: View {
    let articles: [Article]
    @ObservedObject var viewModel: ArticleListViewModel
    
    var body: some View {
        List(articles) { article in
            NavigationLink(value: article) {
                ArticleRowView(article: article)
            }
        }
        .listStyle(.plain)
        .refreshable {
            await viewModel.loadArticles()
        }
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
            CachedAsyncImage(
                url: URL(string: article.imageURL)
            ) { image in
                image
                    .resizable()
                    .aspectRatio(contentMode: .fill)
            } placeholder: {
                placeholderImage
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
        VStack(spacing: 16) {
            Image(systemName: "magnifyingglass")
                .font(.system(size: 60))
                .foregroundStyle(.secondary)
            
            VStack(spacing: 8) {
                Text(title)
                    .font(.title2)
                    .fontWeight(.semibold)
                
                Text(message)
                    .font(.body)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
            }
        }
        .padding(40)
    }
}

// MARK: - Error State View
private struct ErrorStateView: View {
    let message: String
    let retryAction: () async -> Void
    
    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "exclamationmark.triangle")
                .font(.system(size: 60))
                .foregroundStyle(.orange)
            
            VStack(spacing: 8) {
                Text("Error")
                    .font(.title2)
                    .fontWeight(.semibold)
                
                Text(message)
                    .font(.body)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
            }
            
            Button(action: {
                Task {
                    await retryAction()
                }
            }) {
                Text("Reintentar")
                    .fontWeight(.semibold)
                    .frame(minWidth: 120)
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.large)
        }
        .padding(40)
    }
}

// MARK: - Previews
#Preview("Lista con datos") {
    let vm = ArticleListViewModel(repository: MockArticleRepository())
    vm.state = .loaded(Article.mocks)
    return ArticleListView(viewModel: vm)
}

#Preview("Cargando") {
    let vm = ArticleListViewModel(repository: MockArticleRepository())
    vm.state = .loading
    return ArticleListView(viewModel: vm)
}

#Preview("Vacío") {
    let vm = ArticleListViewModel(repository: MockArticleRepository())
    vm.state = .empty
    return ArticleListView(viewModel: vm)
}

#Preview("Error") {
    let vm = ArticleListViewModel(repository: MockArticleRepository())
    vm.state = .error("No se pudo conectar con el servidor")
    return ArticleListView(viewModel: vm)
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

// MARK: - Preview Helper
extension ArticleListViewModel {
    /// Crea un ViewModel para previews con estado pre-configurado
    static func preview(state: ArticleListState) -> ArticleListViewModel {
        let vm = ArticleListViewModel(repository: MockArticleRepository())
        vm.state = state
        return vm
    }
}
