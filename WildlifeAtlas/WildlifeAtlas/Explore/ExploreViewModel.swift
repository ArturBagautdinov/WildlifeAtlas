//
//  ExploreViewModel.swift
//  WildlifeAtlas
//
//  Created by Artur Bagautdinov on 07.09.2026.
//

import Foundation

@MainActor
final class ExploreViewModel {
    struct State: Equatable {
        let title: String
        let message: String
    }

    let state = State(
        title: "Wildlife Atlas",
        message: "Explore screen foundation is ready."
    )
}
