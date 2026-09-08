//
//  UserDefaultsFavoritesStore.swift
//  WildlifeAtlas
//
//  Created by Artur Bagautdinov on 08.09.2026.
//

import Foundation

nonisolated final class UserDefaultsFavoritesStore: FavoritesStore {
    private let userDefaults: UserDefaults
    private let key: String
    private let lock = NSLock()

    init(
        userDefaults: UserDefaults = .standard,
        key: String = "favoriteObservationIDs"
    ) {
        self.userDefaults = userDefaults
        self.key = key
    }

    func loadFavoriteIDs() -> [Int] {
        withLock {
            userDefaults.array(forKey: key) as? [Int] ?? []
        }
    }

    func isFavorite(id: Int) -> Bool {
        loadFavoriteIDs().contains(id)
    }

    func addFavorite(id: Int) {
        withLock {
            var ids = userDefaults.array(forKey: key) as? [Int] ?? []
            ids.removeAll { $0 == id }
            ids.insert(id, at: 0)
            userDefaults.set(ids, forKey: key)
        }
    }

    func removeFavorite(id: Int) {
        withLock {
            var ids = userDefaults.array(forKey: key) as? [Int] ?? []
            ids.removeAll { $0 == id }
            userDefaults.set(ids, forKey: key)
        }
    }

    private func withLock<Value>(_ work: () -> Value) -> Value {
        lock.lock()
        defer { lock.unlock() }
        return work()
    }
}
