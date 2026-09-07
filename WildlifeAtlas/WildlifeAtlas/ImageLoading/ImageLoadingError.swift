//
//  ImageLoadingError.swift
//  WildlifeAtlas
//
//  Created by Artur Bagautdinov on 07.09.2026.
//

import Foundation

nonisolated enum ImageLoadingError: Error, Equatable {
    case invalidURL
    case invalidResponse
    case httpStatus(Int)
    case invalidImageData
    case transport(String)
}
