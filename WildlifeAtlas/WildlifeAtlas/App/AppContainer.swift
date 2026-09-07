//
//  AppContainer.swift
//  WildlifeAtlas
//
//  Created by Artur Bagautdinov on 07.09.2026.
//

import UIKit

final class AppContainer {
    private let apiClient: APIClient

    init() {
        self.apiClient = APIClient(baseURL: INaturalistEndpoint.baseURL)
    }

    func makeAppCoordinator(window: UIWindow) -> AppCoordinator {
        AppCoordinator(window: window, appContainer: self)
    }

    func makeExploreViewController() -> ExploreViewController {
        let viewModel = ExploreViewModel()
        return ExploreViewController(viewModel: viewModel)
    }

    func makeObservationsRepository() -> ObservationsRepository {
        RemoteObservationsRepository(apiClient: apiClient)
    }

    func makeTaxaRepository() -> TaxaRepository {
        RemoteTaxaRepository(apiClient: apiClient)
    }
}
