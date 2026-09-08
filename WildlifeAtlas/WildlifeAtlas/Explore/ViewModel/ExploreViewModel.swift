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
    private var loadGeneration = UUID()

    private(set) var state: State = .loading {
        didSet { onStateChange?(state) }
    }

    private(set) var displayMode: ExploreDisplayMode = .list {
        didSet { onDisplayModeChange?(displayMode) }
    }

    private(set) var filters: ObservationFilters = .defaultValue {
        didSet { onFiltersChange?(filters) }
    }

    private(set) var paginationState = PaginationState(isLoadingNextPage: false, error: nil) {
        didSet { onPaginationStateChange?(paginationState) }
    }

    var onStateChange: ((State) -> Void)?
    var onPaginationStateChange: ((PaginationState) -> Void)?
    var onDisplayModeChange: ((ExploreDisplayMode) -> Void)?
    var onFiltersChange: ((ObservationFilters) -> Void)?

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
        loadGeneration = UUID()

        state = .loading
        paginationState = PaginationState(isLoadingNextPage: false, error: nil)
        observations = []
        currentPage = 0
        canLoadMore = true

        let requestedFilters = filters
        let generation = loadGeneration
        let task = Task { [weak self] in
            guard let self else { return }

            do {
                let page = try await observationsRepository.observations(
                    page: 1,
                    perPage: perPage,
                    filters: requestedFilters
                )
                guard !Task.isCancelled, generation == loadGeneration, requestedFilters == filters else { return }

                observations = page.values
                currentPage = page.page
                canLoadMore = page.hasNextPage

                let items = loadedItems
                state = items.isEmpty ? .empty : .content(items)
            } catch {
                guard !Task.isCancelled, generation == loadGeneration, requestedFilters == filters else { return }
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
        let requestedFilters = filters
        let generation = loadGeneration

        let task = Task { [weak self] in
            guard let self else { return }

            do {
                let page = try await observationsRepository.observations(
                    page: nextPage,
                    perPage: perPage,
                    filters: requestedFilters
                )
                guard !Task.isCancelled, generation == loadGeneration, requestedFilters == filters else { return }

                append(page)
                paginationState = PaginationState(isLoadingNextPage: false, error: nil)
                state = .content(loadedItems)
                nextPageTask = nil
            } catch {
                guard !Task.isCancelled, generation == loadGeneration, requestedFilters == filters else { return }
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

    @discardableResult
    func setTaxonFilter(_ taxon: Taxon?) -> Task<Void, Never>? {
        updateFilters {
            $0.taxon = taxon
        }
    }

    @discardableResult
    func setQualityFilter(_ quality: ObservationQualityFilter) -> Task<Void, Never>? {
        updateFilters {
            $0.quality = quality
        }
    }

    @discardableResult
    func setSortOrder(_ sortOrder: ObservationSortOrder) -> Task<Void, Never>? {
        updateFilters {
            $0.sortOrder = sortOrder
        }
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

    @discardableResult
    private func updateFilters(_ update: (inout ObservationFilters) -> Void) -> Task<Void, Never>? {
        var updatedFilters = filters
        update(&updatedFilters)

        guard updatedFilters != filters else {
            return nil
        }

        filters = updatedFilters
        return loadInitialObservations()
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
