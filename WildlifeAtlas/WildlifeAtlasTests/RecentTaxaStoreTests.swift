//
//  RecentTaxaStoreTests.swift
//  WildlifeAtlasTests
//
//  Created by Artur Bagautdinov on 08.09.2026.
//

import Foundation
import Testing
@testable import WildlifeAtlas

@Suite(.serialized)
struct RecentTaxaStoreTests {

    @Test func userDefaultsStorePersistsTaxaRequiredForRecentSelection() {
        let suiteName = "RecentTaxaStoreTests-\(UUID().uuidString)"
        let userDefaults = UserDefaults(suiteName: suiteName)!
        defer { userDefaults.removePersistentDomain(forName: suiteName) }

        let store = UserDefaultsRecentTaxaStore(userDefaults: userDefaults, key: "recentTaxa")
        let photo = ObservationPhoto(
            id: 101,
            squareURL: URL(string: "https://example.com/square.jpg"),
            mediumURL: URL(string: "https://example.com/medium.jpg"),
            attribution: "Photo attribution",
            licenseCode: "cc-by"
        )
        let taxon = Taxon(
            id: 46020,
            scientificName: "Vulpes vulpes",
            commonName: "Red Fox",
            rank: "species",
            iconicTaxonName: "Mammalia",
            matchedTerm: "Red Fox",
            wikipediaURL: URL(string: "https://en.wikipedia.org/wiki/Red_fox"),
            wikipediaSummary: "A fox species.",
            defaultPhoto: photo
        )

        store.saveRecentTaxa([taxon])

        #expect(store.loadRecentTaxa() == [taxon])
    }
}
