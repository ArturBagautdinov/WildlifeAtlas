//
//  TaxonDTO.swift
//  WildlifeAtlas
//
//  Created by Artur Bagautdinov on 07.09.2026.
//

import Foundation

nonisolated struct TaxonDTO: Decodable {
    let id: Int
    let name: String
    let rank: String?
    let preferredCommonName: String?
    let matchedTerm: String?
    let iconicTaxonName: String?
    let wikipediaURL: String?
    let wikipediaSummary: String?
    let defaultPhoto: PhotoDTO?

    enum CodingKeys: String, CodingKey {
        case id
        case name
        case rank
        case preferredCommonName = "preferred_common_name"
        case matchedTerm = "matched_term"
        case iconicTaxonName = "iconic_taxon_name"
        case wikipediaURL = "wikipedia_url"
        case wikipediaSummary = "wikipedia_summary"
        case defaultPhoto = "default_photo"
    }

    func toDomain() -> Taxon {
        Taxon(
            id: id,
            scientificName: name,
            commonName: preferredCommonName,
            rank: rank,
            iconicTaxonName: iconicTaxonName,
            matchedTerm: matchedTerm,
            wikipediaURL: wikipediaURL.flatMap(URL.init(string:)),
            wikipediaSummary: wikipediaSummary,
            defaultPhoto: defaultPhoto?.toDomain()
        )
    }
}
