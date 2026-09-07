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

    struct PaginationState: Equatable {
        let isLoadingNextPage: Bool
        let error: ExploreErrorViewModel?
    }

    private let observationsRepository: ObservationsRepository
    private let perPage: Int
    private var observations: [Observation] = []
    private var currentPage = 0
    private var canLoadMore = true
    private var initialLoadTask: Task<Void, Never>?
    private var nextPageTask: Task<Void, Never>?

    private(set) var state: State = .loading {
        didSet { onStateChange?(state) }
    }

    private(set) var displayMode: ExploreDisplayMode = .list {
        didSet { onDisplayModeChange?(displayMode) }
    }

    private(set) var paginationState = PaginationState(isLoadingNextPage: false, error: nil) {
        didSet { onPaginationStateChange?(paginationState) }
    }

    var onStateChange: ((State) -> Void)?
    var onPaginationStateChange: ((PaginationState) -> Void)?
    var onDisplayModeChange: ((ExploreDisplayMode) -> Void)?

    init(observationsRepository: ObservationsRepository, perPage: Int = 20) {
        self.observationsRepository = observationsRepository
        self.perPage = perPage
    }

    var loadedItems: [ExploreObservationItem] {
        observations.map(ExploreObservationItem.init(observation:))
    }

    var currentPageNumber: Int {
        currentPage
    }

    var canRequestNextPage: Bool {
        canLoadMore
    }

    var isLoadingNextPage: Bool {
        paginationState.isLoadingNextPage
    }

    @discardableResult
    func loadInitialObservations() -> Task<Void, Never> {
        initialLoadTask?.cancel()
        nextPageTask?.cancel()

        state = .loading
        paginationState = PaginationState(isLoadingNextPage: false, error: nil)
        observations = []
        currentPage = 0
        canLoadMore = true

        let task = Task { [weak self] in
            guard let self else { return }

            do {
                let page = try await observationsRepository.observations(
                    page: 1,
                    perPage: perPage,
                    filters: .defaultValue
                )
                guard !Task.isCancelled else { return }

                observations = page.values
                currentPage = page.page
                canLoadMore = page.hasNextPage

                let items = loadedItems
                state = items.isEmpty ? .empty : .content(items)
            } catch {
                guard !Task.isCancelled else { return }
                observations = []
                currentPage = 0
                canLoadMore = true
                state = .error(.initialLoadFailed)
            }
        }

        initialLoadTask = task
        return task
    }

    @discardableResult
    func loadNextPageIfNeeded(currentItemID: Int?) -> Task<Void, Never>? {
        guard shouldLoadNextPage(currentItemID: currentItemID) else {
            return nil
        }

        paginationState = PaginationState(isLoadingNextPage: true, error: nil)
        let nextPage = currentPage + 1

        let task = Task { [weak self] in
            guard let self else { return }

            do {
                let page = try await observationsRepository.observations(
                    page: nextPage,
                    perPage: perPage,
                    filters: .defaultValue
                )
                guard !Task.isCancelled else { return }

                append(page)
                paginationState = PaginationState(isLoadingNextPage: false, error: nil)
                state = .content(loadedItems)
                nextPageTask = nil
            } catch {
                guard !Task.isCancelled else { return }
                paginationState = PaginationState(isLoadingNextPage: false, error: .nextPageFailed)
                nextPageTask = nil
            }
        }

        nextPageTask = task
        return task
    }

    @discardableResult
    func retryNextPage() -> Task<Void, Never>? {
        loadNextPageIfNeeded(currentItemID: nil)
    }

    func setDisplayMode(_ mode: ExploreDisplayMode) {
        guard displayMode != mode else { return }
        displayMode = mode
    }

    private func shouldLoadNextPage(currentItemID: Int?) -> Bool {
        guard case .content(let items) = state else { return false }
        guard canLoadMore, paginationState.isLoadingNextPage == false else { return false }

        guard let currentItemID else {
            return true
        }

        guard let index = items.firstIndex(where: { $0.id == currentItemID }) else {
            return false
        }

        let threshold = max(items.count - 5, 0)
        return index >= threshold
    }

    private func append(_ page: PaginatedPage<Observation>) {
        var seenIDs = Set(observations.map(\.id))
        let uniqueNewObservations = page.values.filter { seenIDs.insert($0.id).inserted }

        observations.append(contentsOf: uniqueNewObservations)
        currentPage = page.page
        canLoadMore = page.hasNextPage
    }
}

nonisolated struct ExploreErrorViewModel: Equatable {
    let title: String
    let message: String

    static let initialLoadFailed = ExploreErrorViewModel(
        title: "Unable to load observations",
        message: "Check your connection and try again."
    )

    static let nextPageFailed = ExploreErrorViewModel(
        title: "Unable to load more observations",
        message: "Try again"
    )
}
