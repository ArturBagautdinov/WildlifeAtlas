//
//  ExploreViewModelTests.swift
//  WildlifeAtlasTests
//
//  Created by Artur Bagautdinov on 07.09.2026.
//

import Foundation
import Testing
@testable import WildlifeAtlas

@MainActor
@Suite(.serialized)
struct ExploreViewModelTests {

    @Test func initialStateIsLoading() {
        let viewModel = ExploreViewModel(observationsRepository: MockObservationsRepository())

        #expect(viewModel.state == .loading)
    }

    @Test func successfulInitialLoadRequestsFirstPageAndShowsContent() async {
        let repository = MockObservationsRepository(results: [
            .success(Self.page(values: [Self.observation(id: 1), Self.observation(id: 2)], page: 1, perPage: 12, total: 2))
        ])
        let viewModel = ExploreViewModel(observationsRepository: repository, perPage: 12)
        var states: [ExploreViewModel.State] = []
        viewModel.onStateChange = { states.append($0) }

        await viewModel.loadInitialObservations().value

        #expect(repository.calls == [
            MockObservationsRepository.Call(page: 1, perPage: 12, filters: ObservationFilters.defaultValue)
        ])
        #expect(states.count == 2)
        #expect(states.first == .loading)

        guard case .content(let items) = viewModel.state else {
            Issue.record("Expected content state")
            return
        }

        #expect(items.map(\.id) == [1, 2])
        #expect(items.first?.commonName == "Common 1")
        #expect(items.first?.scientificName == "Species 1")
        #expect(items.first?.observedDate == "7 Sep 2026")
        #expect(items.first?.qualityText == "Excellent")
        #expect(items.first?.qualitySymbol == "A")
    }

    @Test func emptyInitialLoadShowsEmptyState() async {
        let repository = MockObservationsRepository(results: [
            .success(Self.page(values: [], page: 1, total: 0))
        ])
        let viewModel = ExploreViewModel(observationsRepository: repository)
        var states: [ExploreViewModel.State] = []
        viewModel.onStateChange = { states.append($0) }

        await viewModel.loadInitialObservations().value

        #expect(viewModel.state == .empty)
        #expect(states == [.loading, .empty])
    }

    @Test func failedInitialLoadShowsErrorState() async {
        let repository = MockObservationsRepository(results: [
            .failure(TestError())
        ])
        let viewModel = ExploreViewModel(observationsRepository: repository)
        var states: [ExploreViewModel.State] = []
        viewModel.onStateChange = { states.append($0) }

        await viewModel.loadInitialObservations().value

        #expect(viewModel.state == .error(.initialLoadFailed))
        #expect(states == [.loading, .error(.initialLoadFailed)])
    }

    @Test func retryPerformsAnotherInitialRepositoryRequest() async {
        let repository = MockObservationsRepository(results: [
            .failure(TestError()),
            .success(Self.page(values: [Self.observation(id: 3)], page: 1, total: 1))
        ])
        let viewModel = ExploreViewModel(observationsRepository: repository)

        await viewModel.loadInitialObservations().value
        await viewModel.loadInitialObservations().value

        #expect(repository.calls.map(\.page) == [1, 1])

        guard case .content(let items) = viewModel.state else {
            Issue.record("Expected content state after retry")
            return
        }
        #expect(items.map(\.id) == [3])
    }

    @Test func missingOptionalFieldsRemainAbsentInPresentationModel() {
        let item = ExploreObservationItem(
            observation: Observation(
                id: 10,
                uri: nil,
                quality: nil,
                observedOn: nil,
                observedAt: nil,
                taxon: nil,
                photos: [],
                author: nil,
                location: nil
            )
        )

        #expect(item.commonName == nil)
        #expect(item.scientificName == nil)
        #expect(item.observedDate == nil)
        #expect(item.qualityText == nil)
        #expect(item.qualitySymbol == nil)
        #expect(item.imageURL == nil)
        #expect(item.accessibilityLabel.isEmpty)
    }

    @Test func firstAndSecondPagesAccumulateInOrder() async {
        let repository = MockObservationsRepository(results: [
            .success(Self.page(values: [Self.observation(id: 1), Self.observation(id: 2)], page: 1, total: 4)),
            .success(Self.page(values: [Self.observation(id: 3), Self.observation(id: 4)], page: 2, total: 4))
        ])
        let viewModel = ExploreViewModel(observationsRepository: repository, perPage: 2)

        await viewModel.loadInitialObservations().value
        await viewModel.loadNextPageIfNeeded(currentItemID: 2)?.value

        #expect(repository.calls.map(\.page) == [1, 2])
        #expect(viewModel.loadedItems.map(\.id) == [1, 2, 3, 4])
        #expect(viewModel.currentPageNumber == 2)
        #expect(viewModel.canRequestNextPage == false)
    }

    @Test func duplicateNextPageRequestsAreIgnoredWhileLoading() async {
        let repository = MockObservationsRepository(results: [
            .success(Self.page(values: [Self.observation(id: 1), Self.observation(id: 2)], page: 1, total: 4)),
            .success(Self.page(values: [Self.observation(id: 3), Self.observation(id: 4)], page: 2, total: 4))
        ])
        let viewModel = ExploreViewModel(observationsRepository: repository, perPage: 2)

        await viewModel.loadInitialObservations().value
        let firstNextPageTask = viewModel.loadNextPageIfNeeded(currentItemID: 2)
        let duplicateTask = viewModel.loadNextPageIfNeeded(currentItemID: 2)
        await firstNextPageTask?.value

        #expect(firstNextPageTask != nil)
        #expect(duplicateTask == nil)
        #expect(repository.calls.map(\.page) == [1, 2])
    }

    @Test func finalPageDoesNotRequestAnotherPage() async {
        let repository = MockObservationsRepository(results: [
            .success(Self.page(values: [Self.observation(id: 1), Self.observation(id: 2)], page: 1, total: 2))
        ])
        let viewModel = ExploreViewModel(observationsRepository: repository, perPage: 2)

        await viewModel.loadInitialObservations().value
        let nextPageTask = viewModel.loadNextPageIfNeeded(currentItemID: 2)

        #expect(nextPageTask == nil)
        #expect(repository.calls.map(\.page) == [1])
        #expect(viewModel.canRequestNextPage == false)
    }

    @Test func nextPageFailurePreservesLoadedContentAndAvoidsFullscreenError() async {
        let repository = MockObservationsRepository(results: [
            .success(Self.page(values: [Self.observation(id: 1), Self.observation(id: 2)], page: 1, total: 4)),
            .failure(TestError())
        ])
        let viewModel = ExploreViewModel(observationsRepository: repository, perPage: 2)

        await viewModel.loadInitialObservations().value
        await viewModel.loadNextPageIfNeeded(currentItemID: 2)?.value

        #expect(viewModel.loadedItems.map(\.id) == [1, 2])
        #expect(viewModel.paginationState.isLoadingNextPage == false)
        #expect(viewModel.paginationState.error == .nextPageFailed)

        guard case .content(let items) = viewModel.state else {
            Issue.record("Expected existing content to remain visible")
            return
        }
        #expect(items.map(\.id) == [1, 2])
    }

    @Test func retryNextPageKeepsExistingContentAndAppendsSuccessfulRetry() async {
        let repository = MockObservationsRepository(results: [
            .success(Self.page(values: [Self.observation(id: 1), Self.observation(id: 2)], page: 1, total: 4)),
            .failure(TestError()),
            .success(Self.page(values: [Self.observation(id: 3), Self.observation(id: 4)], page: 2, total: 4))
        ])
        let viewModel = ExploreViewModel(observationsRepository: repository, perPage: 2)

        await viewModel.loadInitialObservations().value
        await viewModel.loadNextPageIfNeeded(currentItemID: 2)?.value
        await viewModel.retryNextPage()?.value

        #expect(repository.calls.map(\.page) == [1, 2, 2])
        #expect(viewModel.loadedItems.map(\.id) == [1, 2, 3, 4])
        #expect(viewModel.paginationState.error == nil)
    }

    @Test func nextPageLoadingDoesNotReplaceContentWithFullscreenLoading() async {
        let repository = MockObservationsRepository(results: [
            .success(Self.page(values: [Self.observation(id: 1), Self.observation(id: 2)], page: 1, total: 4)),
            .success(Self.page(values: [Self.observation(id: 3)], page: 2, total: 4))
        ])
        let viewModel = ExploreViewModel(observationsRepository: repository, perPage: 2)
        var states: [ExploreViewModel.State] = []
        viewModel.onStateChange = { states.append($0) }

        await viewModel.loadInitialObservations().value
        states.removeAll()
        let nextPageTask = viewModel.loadNextPageIfNeeded(currentItemID: 2)

        #expect(viewModel.isLoadingNextPage)
        #expect(states.isEmpty)

        await nextPageTask?.value
        #expect(states == [.content(viewModel.loadedItems)])
    }

    @Test func duplicateObservationIDsAreNotAppended() async {
        let repository = MockObservationsRepository(results: [
            .success(Self.page(values: [Self.observation(id: 1), Self.observation(id: 2)], page: 1, total: 4)),
            .success(Self.page(values: [Self.observation(id: 2), Self.observation(id: 3)], page: 2, total: 4))
        ])
        let viewModel = ExploreViewModel(observationsRepository: repository, perPage: 2)

        await viewModel.loadInitialObservations().value
        await viewModel.loadNextPageIfNeeded(currentItemID: 2)?.value

        #expect(viewModel.loadedItems.map(\.id) == [1, 2, 3])
    }

    @Test func switchingDisplayModeDoesNotReloadOrResetPagination() async {
        let repository = MockObservationsRepository(results: [
            .success(Self.page(values: [Self.observation(id: 1), Self.observation(id: 2)], page: 1, total: 4)),
            .success(Self.page(values: [Self.observation(id: 3), Self.observation(id: 4)], page: 2, total: 4))
        ])
        let viewModel = ExploreViewModel(observationsRepository: repository, perPage: 2)

        await viewModel.loadInitialObservations().value
        await viewModel.loadNextPageIfNeeded(currentItemID: 2)?.value
        viewModel.setDisplayMode(.grid)

        #expect(viewModel.displayMode == .grid)
        #expect(repository.calls.map(\.page) == [1, 2])
        #expect(viewModel.loadedItems.map(\.id) == [1, 2, 3, 4])
        #expect(viewModel.currentPageNumber == 2)
        #expect(viewModel.canRequestNextPage == false)
    }

    private static func page(
        values: [Observation],
        page: Int,
        perPage: Int = 2,
        total: Int
    ) -> PaginatedPage<Observation> {
        PaginatedPage(values: values, page: page, perPage: perPage, totalResults: total)
    }

    private static func observation(id: Int) -> Observation {
        Observation(
            id: id,
            uri: nil,
            quality: .research,
            observedOn: "2026-09-07",
            observedAt: nil,
            taxon: Taxon(
                id: id,
                scientificName: "Species \(id)",
                commonName: "Common \(id)",
                rank: "species",
                iconicTaxonName: nil,
                matchedTerm: nil,
                wikipediaURL: nil,
                wikipediaSummary: nil,
                defaultPhoto: nil
            ),
            photos: [
                ObservationPhoto(
                    id: id,
                    squareURL: URL(string: "https://example.com/\(id)-square.jpg"),
                    mediumURL: URL(string: "https://example.com/\(id)-medium.jpg"),
                    attribution: nil,
                    licenseCode: nil
                )
            ],
            author: nil,
            location: nil
        )
    }
}

private nonisolated struct TestError: Error {}

private nonisolated final class MockObservationsRepository: ObservationsRepository {
    struct Call: Equatable {
        let page: Int
        let perPage: Int
        let filters: ObservationFilters
    }

    private let lock = NSLock()
    private var results: [Result<PaginatedPage<Observation>, Error>]
    private var recordedCalls: [Call] = []

    var calls: [Call] {
        withLock { recordedCalls }
    }

    init(results: [Result<PaginatedPage<Observation>, Error>] = []) {
        self.results = results
    }

    func observations(
        page: Int,
        perPage: Int,
        filters: ObservationFilters
    ) async throws -> PaginatedPage<Observation> {
        let result: Result<PaginatedPage<Observation>, Error> = withLock {
            recordedCalls.append(Call(page: page, perPage: perPage, filters: filters))
            return results.isEmpty
                ? .success(PaginatedPage(values: [], page: page, perPage: perPage, totalResults: 0))
                : results.removeFirst()
        }

        await Task.yield()
        return try result.get()
    }

    func observation(id: Int) async throws -> Observation {
        throw TestError()
    }

    private func withLock<Value>(_ work: () throws -> Value) rethrows -> Value {
        lock.lock()
        defer { lock.unlock() }
        return try work()
    }
}
