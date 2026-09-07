//
//  Taxon.swift
//  WildlifeAtlas
//
//  Created by Artur Bagautdinov on 07.09.2026.
//

import Foundation

nonisolated struct Taxon: Equatable, Identifiable {
    let id: Int
    let scientificName: String
    let commonName: String?
    let rank: String?
    let iconicTaxonName: String?
    let matchedTerm: String?
    let wikipediaURL: URL?
    let wikipediaSummary: String?
    let defaultPhoto: ObservationPhoto?
}
