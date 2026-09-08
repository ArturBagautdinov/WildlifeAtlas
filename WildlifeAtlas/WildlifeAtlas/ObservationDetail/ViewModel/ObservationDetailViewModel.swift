//
//  ObservationDetailViewModel.swift
//  WildlifeAtlas
//
//  Created by Artur Bagautdinov on 08.09.2026.
//

import Foundation

@MainActor
final class ObservationDetailViewModel {
    enum State: Equatable {
        case loading
        case content(ObservationDetailContent)
        case notFound
        case error(ObservationDetailErrorViewModel)
    }

    private let observationID: Int
    private let observationsRepository: ObservationsRepository
    private let favoritesStore: FavoritesStore
    private var observation: Observation?
    private var loadTask: Task<Void, Never>?

    private(set) var state: State = .loading {
        didSet { onStateChange?(state) }
    }

    var onStateChange: ((State) -> Void)?

    init(
        observationID: Int,
        observationsRepository: ObservationsRepository,
        favoritesStore: FavoritesStore = EmptyObservationDetailFavoritesStore()
    ) {
        self.observationID = observationID
        self.observationsRepository = observationsRepository
        self.favoritesStore = favoritesStore
    }

    @discardableResult
    func loadObservation() -> Task<Void, Never> {
        loadTask?.cancel()
        state = .loading

        let observationID = observationID
        let task = Task { [weak self] in
            guard let self else { return }

            do {
                let observation = try await observationsRepository.observation(id: observationID)
                guard !Task.isCancelled else { return }
                self.observation = observation
                state = .content(makeContent(from: observation))
            } catch RepositoryError.notFound {
                guard !Task.isCancelled else { return }
                state = .notFound
            } catch {
                guard !Task.isCancelled else { return }
                state = .error(.loadFailed)
            }
        }

        loadTask = task
        return task
    }

    @discardableResult
    func retry() -> Task<Void, Never> {
        loadObservation()
    }

    func toggleFavorite() {
        if favoritesStore.isFavorite(id: observationID) {
            favoritesStore.removeFavorite(id: observationID)
        } else {
            favoritesStore.addFavorite(id: observationID)
        }

        guard let observation else { return }
        state = .content(makeContent(from: observation))
    }

    private func makeContent(from observation: Observation) -> ObservationDetailContent {
        ObservationDetailContent(
            observation: observation,
            isFavorite: favoritesStore.isFavorite(id: observation.id)
        )
    }
}

private nonisolated final class EmptyObservationDetailFavoritesStore: FavoritesStore {
    func loadFavoriteIDs() -> [Int] { [] }
    func isFavorite(id: Int) -> Bool { false }
    func addFavorite(id: Int) {}
    func removeFavorite(id: Int) {}
}

nonisolated struct ObservationDetailErrorViewModel: Equatable {
    let title: String
    let message: String

    static let loadFailed = ObservationDetailErrorViewModel(
        title: "Unable to load observation",
        message: "Check your connection and try again."
    )
}
