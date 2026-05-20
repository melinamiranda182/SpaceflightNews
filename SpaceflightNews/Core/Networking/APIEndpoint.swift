//
//  APIEndpoint.swift
//  SpaceflightNews
//
//  Created by Melina Miranda on 19/05/2026.
//

import Foundation

enum HTTPMethod: String {
    case get = "GET"
    case post = "POST"
    case put = "PUT"
    case delete = "DELETE"
}

/// Define todos los endpoints de la API de manera type-safe
enum APIEndpoint {
    case articles(filters: ArticleFilters)
    case searchArticles(query: String, limit: Int = 20)
    case article(id: Int)
    case blogs(limit: Int = 20, offset: Int = 0)
    case reports(limit: Int = 20, offset: Int = 0)
    
    private var baseURL: String {
        "https://api.spaceflightnewsapi.net/v4"
    }
    
    private var path: String {
        switch self {
        case .articles, .searchArticles:
            return "/articles"
        case .article(let id):
            return "/articles/\(id)"
        case .blogs:
            return "/blogs"
        case .reports:
            return "/reports"
        }
    }
    
    private var queryItems: [URLQueryItem] {
        switch self {
        case .articles(let filters):
            var items = [
                URLQueryItem(name: "limit", value: "\(filters.limit)"),
                URLQueryItem(name: "offset", value: "\(filters.offset)"),
                URLQueryItem(name: "ordering", value: filters.ordering.apiValue)
            ]
            
            if let search = filters.search, !search.isEmpty {
                items.append(URLQueryItem(name: "search", value: search))
            }
            
            if let hasEvent = filters.hasEvent {
                items.append(URLQueryItem(name: "has_event", value: "\(hasEvent)"))
            }
            
            if let hasLaunch = filters.hasLaunch {
                items.append(URLQueryItem(name: "has_launch", value: "\(hasLaunch)"))
            }
            
            if let newsSite = filters.newsSite {
                items.append(URLQueryItem(name: "news_site", value: newsSite))
            }
            
            return items
            
        case .searchArticles(let query, let limit):
            return [
                URLQueryItem(name: "search", value: query),
                URLQueryItem(name: "limit", value: "\(limit)")
            ]
            
        case .article:
            return []
            
        case .blogs(let limit, let offset),
             .reports(let limit, let offset):
            return [
                URLQueryItem(name: "limit", value: "\(limit)"),
                URLQueryItem(name: "offset", value: "\(offset)")
            ]
        }
    }
    
    var url: URL? {
        var components = URLComponents(string: baseURL + path)
        components?.queryItems = queryItems.isEmpty ? nil : queryItems
        return components?.url
    }
    
    var method: HTTPMethod {
        switch self {
        case .articles, .searchArticles, .article, .blogs, .reports:
            return .get
        }
    }
    
    var headers: [String: String] {
        [
            "Content-Type": "application/json",
            "Accept": "application/json"
        ]
    }
}
