//
//  PaginatedPage.swift
//  WildlifeAtlas
//
//  Created by Artur Bagautdinov on 07.09.2026.
//

import Foundation

nonisolated struct PaginatedPage<Value: Equatable>: Equatable {
    let values: [Value]
    let page: Int
    let perPage: Int
    let totalResults: Int

    var hasNextPage: Bool {
        page * perPage < totalResults
    }
}
