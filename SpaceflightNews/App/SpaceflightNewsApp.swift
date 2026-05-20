//
//  SpaceflightNewsApp.swift
//  SpaceflightNews
//
//  Created by Melina Miranda on 19/05/2026.
//

import SwiftUI

@main
struct SpaceflightNewsApp: App {
    var body: some Scene {
        WindowGroup {
            ArticleListView(
                viewModel: ArticleListViewModel()
            )
        }
    }
}
