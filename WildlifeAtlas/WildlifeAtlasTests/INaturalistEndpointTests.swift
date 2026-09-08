//
//  INaturalistEndpointTests.swift
//  WildlifeAtlasTests
//
//  Created by Artur Bagautdinov on 07.09.2026.
//

import Foundation
import Testing
@testable import WildlifeAtlas

struct INaturalistEndpointTests {

    @Test func observationsEndpointIncludesRequiredQueryItems() throws {
        let endpoint = INaturalistEndpoint.observations(
            page: 2,
            perPage: 25,
            filters: ObservationFilters(
                taxon: Taxon(
                    id: 46020,
                    scientificName: "Sciurus niger",
                    commonName: "Eastern Fox Squirrel",
                    rank: "species",
                    iconicTaxonName: "Mammalia",
                    matchedTerm: "Fox Squirrel",
                    wikipediaURL: nil,
                    wikipediaSummary: nil,
                    defaultPhoto: nil
                ),
                quality: .research,
                sortOrder: .oldestFirst
            )
        )

        let query = Dictionary(uniqueKeysWithValues: endpoint.queryItems.compactMap { item in
            item.value.map { (item.name, $0) }
        })

        #expect(endpoint.path == "observations")
        #expect(query["page"] == "2")
        #expect(query["per_page"] == "25")
        #expect(query["captive"] == "false")
        #expect(query["order_by"] == "observed_on")
        #expect(query["order"] == "asc")
        #expect(query["taxon_id"] == "46020")
        #expect(query["quality_grade"] == "research")
    }

    @Test func newestSortMapsToDescendingObservedDate() {
        let endpoint = INaturalistEndpoint.observations(
            page: 1,
            perPage: 10,
            filters: .defaultValue
        )

        #expect(endpoint.queryValue(named: "order_by") == "observed_on")
        #expect(endpoint.queryValue(named: "order") == "desc")
    }

    @Test func anyQualityAndNoTaxonAreOmitted() {
        let endpoint = INaturalistEndpoint.observations(
            page: 1,
            perPage: 10,
            filters: .defaultValue
        )

        #expect(endpoint.queryValue(named: "quality_grade") == nil)
        #expect(endpoint.queryValue(named: "taxon_id") == nil)
    }

    @Test func observationDetailEndpointUsesObservationID() {
        let endpoint = INaturalistEndpoint.observation(id: 398054233)

        #expect(endpoint.path == "observations/398054233")
        #expect(endpoint.queryItems.isEmpty)
    }

    @Test func favoriteObservationsEndpointUsesBatchedIDs() {
        let endpoint = INaturalistEndpoint.observations(ids: [3, 1, 2])

        #expect(endpoint.path == "observations")
        #expect(endpoint.queryValue(named: "page") == "1")
        #expect(endpoint.queryValue(named: "per_page") == "3")
        #expect(endpoint.queryValue(named: "id") == "3,1,2")
        #expect(endpoint.queryValue(named: "captive") == "false")
    }

    @Test func taxaAutocompleteEndpointUsesQueryAndPagination() {
        let endpoint = INaturalistEndpoint.taxaAutocomplete(
            query: "red fox",
            page: 1,
            perPage: 5
        )

        #expect(endpoint.path == "taxa/autocomplete")
        #expect(endpoint.queryValue(named: "q") == "red fox")
        #expect(endpoint.queryValue(named: "page") == "1")
        #expect(endpoint.queryValue(named: "per_page") == "5")
    }
}

private extension APIEndpoint {
    func queryValue(named name: String) -> String? {
        queryItems.first { $0.name == name }?.value
    }
}
