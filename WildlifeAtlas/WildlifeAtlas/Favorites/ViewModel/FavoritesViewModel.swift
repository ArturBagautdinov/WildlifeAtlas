//
//  FavoritesViewModel.swift
//  WildlifeAtlas
//
//  Created by Artur Bagautdinov on 08.09.2026.
//

import Foundation

@MainActor
final class FavoritesViewModel {
    enum State: Equatable {
        case loading
        case content([ExploreObservationItem])
        case empty
        case error(FavoritesErrorViewModel)
    }

    private let observationsRepository: ObservationsRepository
    private let favoritesStore: FavoritesStore
    private var observations: [Observation] = []
    private var loadedFavoriteIDs: [Int] = []
    private var loadTask: Task<Void, Never>?

    private(set) var state: State = .empty {
        didSet { onStateChange?(state) }
    }

    var onStateChange: ((State) -> Void)?

    init(observationsRepository: ObservationsRepository, favoritesStore: FavoritesStore) {
        self.observationsRepository = observationsRepository
        self.favoritesStore = favoritesStore
    }

    @discardableResult
    func loadFavorites() -> Task<Void, Never>? {
        loadTask?.cancel()

        let ids = favoritesStore.loadFavoriteIDs()
        guard ids.isEmpty == false else {
            observations = []
            loadedFavoriteIDs = []
            state = .empty
            return nil
        }

        if ids == loadedFavoriteIDs, observations.isEmpty == false {
            state = .content(items(from: observations))
            return nil
        }

        state = .loading

        let task = Task { [weak self] in
            guard let self else { return }

            do {
                let observations = try await observationsRepository.observations(ids: ids)
                guard !Task.isCancelled else { return }

                self.observations = observations
                self.loadedFavoriteIDs = ids
                let items = self.items(from: observations)
                state = items.isEmpty ? .empty : .content(items)
            } catch {
                guard !Task.isCancelled else { return }
                state = .error(.loadFailed)
            }
        }

        loadTask = task
        return task
    }

    func removeFavorite(id: Int) {
        favoritesStore.removeFavorite(id: id)
        observations.removeAll { $0.id == id }
        loadedFavoriteIDs.removeAll { $0 == id }
        let items = items(from: observations)
        state = items.isEmpty ? .empty : .content(items)
    }

    private func items(from observations: [Observation]) -> [ExploreObservationItem] {
        observations.map { observation in
            ExploreObservationItem(observation: observation, isFavorite: favoritesStore.isFavorite(id: observation.id))
        }
    }
}

nonisolated struct FavoritesErrorViewModel: Equatable {
    let title: String
    let message: String

    static let loadFailed = FavoritesErrorViewModel(
        title: "Unable to load favorites",
        message: "Check your connection and try again."
    )
}
