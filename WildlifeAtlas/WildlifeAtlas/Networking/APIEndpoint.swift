//
//  APIEndpoint.swift
//  WildlifeAtlas
//
//  Created by Artur Bagautdinov on 07.09.2026.
//

import Foundation

nonisolated struct APIEndpoint: Equatable {
    let path: String
    let queryItems: [URLQueryItem]
    let method: String
    let headers: [String: String]

    init(
        path: String,
        queryItems: [URLQueryItem] = [],
        method: String = "GET",
        headers: [String: String] = [:]
    ) {
        self.path = path
        self.queryItems = queryItems
        self.method = method
        self.headers = headers
    }
}
