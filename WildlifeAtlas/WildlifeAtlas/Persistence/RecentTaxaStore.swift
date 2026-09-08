//
//  RecentTaxaStore.swift
//  WildlifeAtlas
//
//  Created by Artur Bagautdinov on 08.09.2026.
//

import Foundation

nonisolated protocol RecentTaxaStore {
    func loadRecentTaxa() -> [Taxon]
    func saveRecentTaxa(_ taxa: [Taxon])
}
