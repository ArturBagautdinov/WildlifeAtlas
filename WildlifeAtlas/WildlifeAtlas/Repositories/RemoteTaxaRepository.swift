//
//  RemoteTaxaRepository.swift
//  WildlifeAtlas
//
//  Created by Artur Bagautdinov on 07.09.2026.
//

import Foundation

nonisolated final class RemoteTaxaRepository: TaxaRepository {
    private let apiClient: APIClient

    init(apiClient: APIClient) {
        self.apiClient = apiClient
    }

    func autocompleteTaxa(query: String, page: Int, perPage: Int) async throws -> PaginatedPage<Taxon> {
        guard !query.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            return PaginatedPage(values: [], page: page, perPage: perPage, totalResults: 0)
        }

        let endpoint = INaturalistEndpoint.taxaAutocomplete(
            query: query,
            page: page,
            perPage: perPage
        )
        let response: PaginatedResponseDTO<TaxonDTO> = try await apiClient.request(endpoint)

        return PaginatedPage(
            values: response.results.map { $0.toDomain() },
            page: response.page,
            perPage: response.perPage,
            totalResults: response.totalResults
        )
    }
}
