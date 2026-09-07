//
//  TaxaRepository.swift
//  WildlifeAtlas
//
//  Created by Artur Bagautdinov on 07.09.2026.
//

import Foundation

nonisolated protocol TaxaRepository {
    func autocompleteTaxa(query: String, page: Int, perPage: Int) async throws -> PaginatedPage<Taxon>
}
