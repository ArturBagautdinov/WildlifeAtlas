//
//  UserDefaultsRecentTaxaStore.swift
//  WildlifeAtlas
//
//  Created by Artur Bagautdinov on 08.09.2026.
//

import Foundation

nonisolated final class UserDefaultsRecentTaxaStore: RecentTaxaStore {
    private struct StoredTaxon: Codable {
        let id: Int
        let scientificName: String
        let commonName: String?
        let rank: String?
        let iconicTaxonName: String?
        let matchedTerm: String?
        let wikipediaURL: URL?
        let wikipediaSummary: String?
        let defaultPhoto: StoredPhoto?

        init(taxon: Taxon) {
            self.id = taxon.id
            self.scientificName = taxon.scientificName
            self.commonName = taxon.commonName
            self.rank = taxon.rank
            self.iconicTaxonName = taxon.iconicTaxonName
            self.matchedTerm = taxon.matchedTerm
            self.wikipediaURL = taxon.wikipediaURL
            self.wikipediaSummary = taxon.wikipediaSummary
            self.defaultPhoto = taxon.defaultPhoto.map(StoredPhoto.init(photo:))
        }

        func toDomain() -> Taxon {
            Taxon(
                id: id,
                scientificName: scientificName,
                commonName: commonName,
                rank: rank,
                iconicTaxonName: iconicTaxonName,
                matchedTerm: matchedTerm,
                wikipediaURL: wikipediaURL,
                wikipediaSummary: wikipediaSummary,
                defaultPhoto: defaultPhoto?.toDomain()
            )
        }
    }

    private struct StoredPhoto: Codable {
        let id: Int
        let squareURL: URL?
        let mediumURL: URL?
        let attribution: String?
        let licenseCode: String?

        init(photo: ObservationPhoto) {
            self.id = photo.id
            self.squareURL = photo.squareURL
            self.mediumURL = photo.mediumURL
            self.attribution = photo.attribution
            self.licenseCode = photo.licenseCode
        }

        func toDomain() -> ObservationPhoto {
            ObservationPhoto(
                id: id,
                squareURL: squareURL,
                mediumURL: mediumURL,
                attribution: attribution,
                licenseCode: licenseCode
            )
        }
    }

    private let userDefaults: UserDefaults
    private let key: String
    private let encoder = JSONEncoder()
    private let decoder = JSONDecoder()

    init(
        userDefaults: UserDefaults = .standard,
        key: String = "recentTaxa"
    ) {
        self.userDefaults = userDefaults
        self.key = key
    }

    func loadRecentTaxa() -> [Taxon] {
        guard let data = userDefaults.data(forKey: key) else {
            return []
        }

        do {
            return try decoder.decode([StoredTaxon].self, from: data).map { $0.toDomain() }
        } catch {
            return []
        }
    }

    func saveRecentTaxa(_ taxa: [Taxon]) {
        let storedTaxa = taxa.map(StoredTaxon.init(taxon:))
        do {
            let data = try encoder.encode(storedTaxa)
            userDefaults.set(data, forKey: key)
        } catch {
            userDefaults.removeObject(forKey: key)
        }
    }
}
