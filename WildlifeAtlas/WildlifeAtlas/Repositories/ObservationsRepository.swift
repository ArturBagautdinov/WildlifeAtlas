//
//  ObservationsRepository.swift
//  WildlifeAtlas
//
//  Created by Artur Bagautdinov on 07.09.2026.
//

import Foundation

nonisolated protocol ObservationsRepository {
    func observations(page: Int, perPage: Int, filters: ObservationFilters) async throws -> PaginatedPage<Observation>
    func observations(ids: [Int]) async throws -> [Observation]
    func observation(id: Int) async throws -> Observation
}
