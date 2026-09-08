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
    private var loadTask: Task<Void, Never>?

    private(set) var state: State = .loading {
        didSet { onStateChange?(state) }
    }

    var onStateChange: ((State) -> Void)?

    init(observationID: Int, observationsRepository: ObservationsRepository) {
        self.observationID = observationID
        self.observationsRepository = observationsRepository
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
                state = .content(ObservationDetailContent(observation: observation))
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
}

nonisolated struct ObservationDetailErrorViewModel: Equatable {
    let title: String
    let message: String

    static let loadFailed = ObservationDetailErrorViewModel(
        title: "Unable to load observation",
        message: "Check your connection and try again."
    )
}
