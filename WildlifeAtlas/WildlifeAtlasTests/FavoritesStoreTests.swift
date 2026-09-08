//
//  FavoritesStoreTests.swift
//  WildlifeAtlasTests
//
//  Created by Artur Bagautdinov on 08.09.2026.
//

import Foundation
import Testing
@testable import WildlifeAtlas

@Suite(.serialized)
struct FavoritesStoreTests {

    @Test func newStoreStartsEmpty() {
        let store = makeStore()

        #expect(store.loadFavoriteIDs().isEmpty)
    }

    @Test func addPersistsFavoriteID() {
        let store = makeStore()

        store.addFavorite(id: 42)

        #expect(store.loadFavoriteIDs() == [42])
        #expect(store.isFavorite(id: 42))
    }

    @Test func duplicateAddMovesExistingFavoriteToFrontWithoutDuplicating() {
        let store = makeStore()

        store.addFavorite(id: 1)
        store.addFavorite(id: 2)
        store.addFavorite(id: 1)

        #expect(store.loadFavoriteIDs() == [1, 2])
    }

    @Test func removeDeletesFavoriteID() {
        let store = makeStore()

        store.addFavorite(id: 1)
        store.addFavorite(id: 2)
        store.removeFavorite(id: 1)

        #expect(store.loadFavoriteIDs() == [2])
        #expect(store.isFavorite(id: 1) == false)
    }

    @Test func favoritesSurviveStoreRecreation() {
        let suiteName = "FavoritesStoreTests.persistence.\(UUID().uuidString)"
        let defaults = UserDefaults(suiteName: suiteName)!
        defaults.removePersistentDomain(forName: suiteName)

        UserDefaultsFavoritesStore(userDefaults: defaults, key: "favorites").addFavorite(id: 5)
        let recreatedStore = UserDefaultsFavoritesStore(userDefaults: defaults, key: "favorites")

        #expect(recreatedStore.loadFavoriteIDs() == [5])

        defaults.removePersistentDomain(forName: suiteName)
    }

    private func makeStore() -> UserDefaultsFavoritesStore {
        let suiteName = "FavoritesStoreTests.\(UUID().uuidString)"
        let defaults = UserDefaults(suiteName: suiteName)!
        defaults.removePersistentDomain(forName: suiteName)
        return UserDefaultsFavoritesStore(userDefaults: defaults, key: "favorites")
    }
}
