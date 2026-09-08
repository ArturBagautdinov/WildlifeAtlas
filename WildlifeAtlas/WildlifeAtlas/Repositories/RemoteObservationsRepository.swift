//
//  RemoteObservationsRepository.swift
//  WildlifeAtlas
//
//  Created by Artur Bagautdinov on 07.09.2026.
//

import Foundation

nonisolated final class RemoteObservationsRepository: ObservationsRepository {
    private let apiClient: APIClient

    init(apiClient: APIClient) {
        self.apiClient = apiClient
    }

    func observations(page: Int, perPage: Int, filters: ObservationFilters) async throws -> PaginatedPage<Observation> {
        let endpoint = INaturalistEndpoint.observations(
            page: page,
            perPage: perPage,
            filters: filters
        )
        let response: PaginatedResponseDTO<ObservationDTO> = try await apiClient.request(endpoint)

        return PaginatedPage(
            values: response.results.map { $0.toDomain() },
            page: response.page,
            perPage: response.perPage,
            totalResults: response.totalResults
        )
    }

    func observation(id: Int) async throws -> Observation {
        let endpoint = INaturalistEndpoint.observation(id: id)
        let response: PaginatedResponseDTO<ObservationDTO> = try await apiClient.request(endpoint)

        guard let observation = response.results.first?.toDomain() else {
            throw RepositoryError.notFound
        }

        return observation
    }

    func observations(ids: [Int]) async throws -> [Observation] {
        guard ids.isEmpty == false else { return [] }

        let endpoint = INaturalistEndpoint.observations(ids: ids)
        let response: PaginatedResponseDTO<ObservationDTO> = try await apiClient.request(endpoint)
        let observations = response.results.map { $0.toDomain() }
        let observationsByID = Dictionary(uniqueKeysWithValues: observations.map { ($0.id, $0) })

        return ids.compactMap { observationsByID[$0] }
    }
}
