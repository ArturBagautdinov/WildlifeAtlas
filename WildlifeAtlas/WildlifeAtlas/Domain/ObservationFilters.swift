//
//  ObservationFilters.swift
//  WildlifeAtlas
//
//  Created by Artur Bagautdinov on 07.09.2026.
//

import Foundation

nonisolated struct ObservationFilters: Equatable {
    var taxon: Taxon?
    var quality: ObservationQualityFilter
    var sortOrder: ObservationSortOrder

    static let defaultValue = ObservationFilters(
        taxon: nil,
        quality: .any,
        sortOrder: .newestFirst
    )
}

nonisolated enum ObservationQualityFilter: Equatable {
    case any
    case research

    var apiValue: String? {
        switch self {
        case .any:
            return nil
        case .research:
            return "research"
        }
    }
}

nonisolated enum ObservationSortOrder: Equatable {
    case newestFirst
    case oldestFirst

    var apiValue: String {
        switch self {
        case .newestFirst:
            return "desc"
        case .oldestFirst:
            return "asc"
        }
    }
}
