//
//  AppContainer.swift
//  WildlifeAtlas
//
//  Created by Artur Bagautdinov on 07.09.2026.
//

import UIKit

final class AppContainer {

    func makeAppCoordinator(window: UIWindow) -> AppCoordinator {
        AppCoordinator(window: window, appContainer: self)
    }

    func makeExploreViewController() -> ExploreViewController {
        let viewModel = ExploreViewModel()
        return ExploreViewController(viewModel: viewModel)
    }
}
