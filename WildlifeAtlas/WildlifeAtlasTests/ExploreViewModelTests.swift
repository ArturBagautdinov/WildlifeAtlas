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

    private static func page(values: [Observation], page: Int, total: Int) -> PaginatedPage<Observation> {
        PaginatedPage(values: values, page: page, perPage: 2, totalResults: total)
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
            location: ObservationLocationSummary(placeName: "Place \(id)")
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
        lock.lock()
        defer { lock.unlock() }
        return recordedCalls
    }

    init(results: [Result<PaginatedPage<Observation>, Error>]) {
        self.results = results
    }

    func observations(
        page: Int,
        perPage: Int,
        filters: ObservationFilters
    ) async throws -> PaginatedPage<Observation> {
        lock.lock()
        recordedCalls.append(Call(page: page, perPage: perPage, filters: filters))
        let result = results.removeFirst()
        lock.unlock()

        await Task.yield()
        return try result.get()
    }

    func observation(id: Int) async throws -> Observation {
        throw TestError()
    }
}
