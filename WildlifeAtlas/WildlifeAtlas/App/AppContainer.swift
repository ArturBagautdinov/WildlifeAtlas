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
    private let favoritesStore: FavoritesStore

    init() {
        self.apiClient = APIClient(baseURL: INaturalistEndpoint.baseURL)
        self.imageLoader = RemoteImageLoader()
        self.recentTaxaStore = UserDefaultsRecentTaxaStore()
        self.favoritesStore = UserDefaultsFavoritesStore()
    }

    func makeAppCoordinator(window: UIWindow) -> AppCoordinator {
        AppCoordinator(window: window, appContainer: self)
    }

    func makeExploreViewController() -> ExploreViewController {
        let viewModel = ExploreViewModel(
            observationsRepository: makeObservationsRepository(),
            favoritesStore: favoritesStore
        )
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

    func makeFavoritesViewController() -> FavoritesViewController {
        let viewModel = FavoritesViewModel(
            observationsRepository: makeObservationsRepository(),
            favoritesStore: favoritesStore
        )
        return FavoritesViewController(viewModel: viewModel, imageLoader: imageLoader)
    }

    func makeObservationDetailViewController(observationID: Int) -> ObservationDetailViewController {
        let viewModel = ObservationDetailViewModel(
            observationID: observationID,
            observationsRepository: makeObservationsRepository(),
            favoritesStore: favoritesStore
        )
        return ObservationDetailViewController(viewModel: viewModel, imageLoader: imageLoader)
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
