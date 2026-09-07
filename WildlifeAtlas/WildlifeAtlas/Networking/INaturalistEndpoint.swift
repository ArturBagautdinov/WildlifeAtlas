//
//  INaturalistEndpoint.swift
//  WildlifeAtlas
//
//  Created by Artur Bagautdinov on 07.09.2026.
//

import Foundation

nonisolated enum INaturalistEndpoint {
    static let baseURL = URL(string: "https://api.inaturalist.org/v1")!

    static func observations(page: Int, perPage: Int, filters: ObservationFilters) -> APIEndpoint {
        var queryItems = [
            URLQueryItem(name: "page", value: String(page)),
            URLQueryItem(name: "per_page", value: String(perPage)),
            URLQueryItem(name: "captive", value: "false"),
            URLQueryItem(name: "order_by", value: "observed_on"),
            URLQueryItem(name: "order", value: filters.sortOrder.apiValue)
        ]

        if let taxon = filters.taxon {
            queryItems.append(URLQueryItem(name: "taxon_id", value: String(taxon.id)))
        }

        if let quality = filters.quality.apiValue {
            queryItems.append(URLQueryItem(name: "quality_grade", value: quality))
        }

        return APIEndpoint(path: "observations", queryItems: queryItems)
    }

    static func observation(id: Int) -> APIEndpoint {
        APIEndpoint(path: "observations/\(id)")
    }

    static func taxaAutocomplete(query: String, page: Int, perPage: Int) -> APIEndpoint {
        APIEndpoint(
            path: "taxa/autocomplete",
            queryItems: [
                URLQueryItem(name: "q", value: query),
                URLQueryItem(name: "page", value: String(page)),
                URLQueryItem(name: "per_page", value: String(perPage))
            ]
        )
    }
}
