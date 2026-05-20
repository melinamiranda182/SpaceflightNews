//
//  ArticleDetailView.swift
//  SpaceflightNews
//
//  Created by Melina Miranda on 19/05/2026.
//

import SwiftUI

struct ArticleDetailView: View {
    @StateObject private var viewModel: ArticleDetailViewModel
    @Environment(\.openURL) private var openURL
    
    init(article: Article) {
        _viewModel = StateObject(wrappedValue: ArticleDetailViewModel(article: article))
    }
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                headerImage
                contentSection
            }
        }
        .navigationTitle("Detalle")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                ShareLink(item: URL(string: viewModel.article.url)!) {
                    Label("Compartir", systemImage: "square.and.arrow.up")
                }
            }
        }
    }
    
    // MARK: - Header Image
    private var headerImage: some View {
        AsyncImage(url: URL(string: viewModel.article.imageURL)) { phase in
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
        .frame(height: 250)
        .clipped()
    }
    
    private var placeholderImage: some View {
        Rectangle()
            .fill(Color.gray.opacity(0.2))
            .overlay {
                Image(systemName: "photo")
                    .font(.largeTitle)
                    .foregroundStyle(.tertiary)
            }
    }
    
    // MARK: - Content Section
    private var contentSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text(viewModel.article.title)
                .font(.title2)
                .fontWeight(.bold)
            
            HStack {
                Label(viewModel.article.newsSite, systemImage: "building.2")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                
                Spacer()
                
                Label(viewModel.article.formattedPublishedDate, systemImage: "calendar")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
            
            Divider()
            
            Text(viewModel.article.summary)
                .font(.body)
                .lineSpacing(4)
            
            Button {
                if let url = URL(string: viewModel.article.url) {
                    openURL(url)
                }
            } label: {
                Label("Leer artículo completo", systemImage: "safari")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.large)
        }
        .padding()
    }
}

// MARK: - Previews
#Preview {
    NavigationStack {
        ArticleDetailView(article: .mock)
    }
}
