//
//  APIError.swift
//  WildlifeAtlas
//
//  Created by Artur Bagautdinov on 07.09.2026.
//

import Foundation

nonisolated enum APIError: Error, Equatable {
    case invalidURL
    case transport(String)
    case invalidResponse
    case httpStatus(Int)
    case decoding(String)
}
