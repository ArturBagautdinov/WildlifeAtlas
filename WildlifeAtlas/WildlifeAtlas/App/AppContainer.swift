//
//  AppContainer.swift
//  WildlifeAtlas
//
//  Created by Artur Bagautdinov on 07.09.2026.
//

import UIKit

final class AppContainer {
    private let apiClient: APIClient
    private let imageLoader: ImageLoader
    private let recentTaxaStore: RecentTaxaStore

    init() {
        self.apiClient = APIClient(baseURL: INaturalistEndpoint.baseURL)
        self.imageLoader = RemoteImageLoader()
        self.recentTaxaStore = UserDefaultsRecentTaxaStore()
    }

    func makeAppCoordinator(window: UIWindow) -> AppCoordinator {
        AppCoordinator(window: window, appContainer: self)
    }

    func makeExploreViewController() -> ExploreViewController {
        let viewModel = ExploreViewModel(observationsRepository: makeObservationsRepository())
        let taxonSearchViewModel = TaxonSearchViewModel(
            taxaRepository: makeTaxaRepository(),
            recentTaxaStore: recentTaxaStore
        )
        return ExploreViewController(
            viewModel: viewModel,
            taxonSearchViewModel: taxonSearchViewModel,
            imageLoader: imageLoader
        )
    }

    func makeObservationsRepository() -> ObservationsRepository {
        RemoteObservationsRepository(apiClient: apiClient)
    }

    func makeTaxaRepository() -> TaxaRepository {
        RemoteTaxaRepository(apiClient: apiClient)
    }

    func makeImageLoader() -> ImageLoader {
        imageLoader
    }
}
