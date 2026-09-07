//
//  WildlifeAtlasTests.swift
//  WildlifeAtlasTests
//
//  Created by Artur Bagautdinov on 07.09.2026.
//

import Testing
@testable import WildlifeAtlas

struct WildlifeAtlasTests {

    @MainActor
    @Test func exploreViewModelProvidesBootstrapPlaceholderState() {
        let viewModel = ExploreViewModel()

        #expect(viewModel.state.title == "Wildlife Atlas")
        #expect(viewModel.state.message == "Explore screen foundation is ready.")
    }
}
