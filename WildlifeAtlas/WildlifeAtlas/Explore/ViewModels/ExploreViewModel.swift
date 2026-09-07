//
//  ExploreViewModel.swift
//  WildlifeAtlas
//
//  Created by Artur Bagautdinov on 07.09.2026.
//

import Foundation

@MainActor
final class ExploreViewModel {
    enum State: Equatable {
        case loading
        case content([ExploreObservationItem])
        case empty
        case error(ExploreErrorViewModel)
    }

    private let observationsRepository: ObservationsRepository
    private let perPage: Int
    private var loadTask: Task<Void, Never>?

    var onStateChange: ((State) -> Void)?

    private(set) var state: State = .loading {
        didSet {
            onStateChange?(state)
        }
    }

    init(
        observationsRepository: ObservationsRepository,
        perPage: Int = 20
    ) {
        self.observationsRepository = observationsRepository
        self.perPage = perPage
    }

    deinit {
        loadTask?.cancel()
    }

    @discardableResult
    func loadInitialObservations() -> Task<Void, Never> {
        loadTask?.cancel()
        state = .loading

        let task = Task { [weak self] in
            guard let self else { return }
            await self.loadPageOne()
        }
        loadTask = task
        return task
    }

    @discardableResult
    func retry() -> Task<Void, Never> {
        loadInitialObservations()
    }

    private func loadPageOne() async {
        do {
            let page = try await observationsRepository.observations(
                page: 1,
                perPage: perPage,
                filters: .defaultValue
            )

            guard !Task.isCancelled else { return }

            let items = page.values.map(ExploreObservationItem.init(observation:))
            state = items.isEmpty ? .empty : .content(items)
        } catch is CancellationError {
            return
        } catch {
            guard !Task.isCancelled else { return }
            state = .error(
                ExploreErrorViewModel(
                    title: "Unable to load observations",
                    message: "Check your connection and try again."
                )
            )
        }
    }
}

nonisolated struct ExploreErrorViewModel: Equatable {
    let title: String
    let message: String
}
