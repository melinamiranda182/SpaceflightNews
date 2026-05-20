//
//  ArticleDetailViewModel.swift
//  SpaceflightNews
//
//  Created by Melina Miranda on 19/05/2026.
//

import Foundation
import Combine

@MainActor
final class ArticleDetailViewModel: ObservableObject {
    @Published private(set) var article: Article
    
    init(article: Article) {
        self.article = article
    }
}
