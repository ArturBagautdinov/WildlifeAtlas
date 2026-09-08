//
//  ObservationDetailPhotoItem.swift
//  WildlifeAtlas
//
//  Created by Artur Bagautdinov on 08.09.2026.
//

import Foundation

nonisolated struct ObservationDetailPhotoItem: Equatable, Hashable, Identifiable {
    let id: Int
    let imageURL: URL
    let accessibilityLabel: String
}
