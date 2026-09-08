//
//  FavoritesStore.swift
//  WildlifeAtlas
//
//  Created by Artur Bagautdinov on 08.09.2026.
//

import Foundation

nonisolated protocol FavoritesStore {
    func loadFavoriteIDs() -> [Int]
    func isFavorite(id: Int) -> Bool
    func addFavorite(id: Int)
    func removeFavorite(id: Int)
}
