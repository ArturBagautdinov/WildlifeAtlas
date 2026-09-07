//
//  PaginatedResponseDTO.swift
//  WildlifeAtlas
//
//  Created by Artur Bagautdinov on 07.09.2026.
//

import Foundation

nonisolated struct PaginatedResponseDTO<Result: Decodable>: Decodable {
    let totalResults: Int
    let page: Int
    let perPage: Int
    let results: [Result]

    enum CodingKeys: String, CodingKey {
        case totalResults = "total_results"
        case page
        case perPage = "per_page"
        case results
    }
}
