//
//  TaxonSearchItem.swift
//  WildlifeAtlas
//
//  Created by Artur Bagautdinov on 08.09.2026.
//

import Foundation

nonisolated struct TaxonSearchItem: Equatable, Identifiable {
    let id: Int
    let taxon: Taxon
    let primaryName: String
    let scientificName: String?
    let iconicTaxonName: String?
    let imageURL: URL?

    init(taxon: Taxon) {
        self.id = taxon.id
        self.taxon = taxon

        let commonName = Self.visibleText(taxon.commonName)
        let scientificName = Self.visibleText(taxon.scientificName)

        self.primaryName = commonName ?? scientificName ?? taxon.scientificName
        self.scientificName = commonName == nil || commonName == scientificName ? nil : scientificName
        self.iconicTaxonName = Self.displayIconicTaxonName(taxon.iconicTaxonName)
        self.imageURL = taxon.defaultPhoto?.squareURL ?? taxon.defaultPhoto?.mediumURL
    }

    var accessibilityLabel: String {
        [
            primaryName,
            scientificName,
            iconicTaxonName
        ]
        .compactMap(Self.visibleText)
        .joined(separator: ", ")
    }

    private static func visibleText(_ text: String?) -> String? {
        guard let text = text?.trimmingCharacters(in: .whitespacesAndNewlines), !text.isEmpty else {
            return nil
        }
        return text
    }

    private static func displayIconicTaxonName(_ value: String?) -> String? {
        guard let value = visibleText(value) else {
            return nil
        }

        switch value {
        case "Actinopterygii":
            return "Fishes"
        case "Amphibia":
            return "Amphibians"
        case "Animalia":
            return "Animals"
        case "Arachnida":
            return "Arachnids"
        case "Aves":
            return "Birds"
        case "Fungi":
            return "Fungi"
        case "Insecta":
            return "Insects"
        case "Mammalia":
            return "Mammals"
        case "Mollusca":
            return "Mollusks"
        case "Plantae":
            return "Plants"
        case "Reptilia":
            return "Reptiles"
        default:
            return value
        }
    }
}
