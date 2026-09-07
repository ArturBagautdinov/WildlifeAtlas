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
            .success(Self.page(values: [Self.observation(id: 1), Self.observation(id: 2)]))
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

        #expect(items.map { $0.id } == [1, 2])
        #expect(items.first?.commonName == "Common 1")
        #expect(items.first?.scientificName == "Species 1")
        #expect(items.first?.observedDate == "7 Sep 2026")
        #expect(items.first?.qualityText == "Excellent")
    }

    @Test func emptyInitialLoadShowsEmptyState() async {
        let repository = MockObservationsRepository(results: [
            .success(Self.page(values: []))
        ])
        let viewModel = ExploreViewModel(observationsRepository: repository)
        var states: [ExploreViewModel.State] = []
        viewModel.onStateChange = { states.append($0) }

        await viewModel.loadInitialObservations().value

        #expect(viewModel.state == .empty)
        #expect(states == [ExploreViewModel.State.loading, ExploreViewModel.State.empty])
    }

    @Test func failedInitialLoadShowsErrorState() async {
        let repository = MockObservationsRepository(results: [
            .failure(TestError())
        ])
        let viewModel = ExploreViewModel(observationsRepository: repository)
        var states: [ExploreViewModel.State] = []
        viewModel.onStateChange = { states.append($0) }

        await viewModel.loadInitialObservations().value

        #expect(viewModel.state == .error(
            ExploreErrorViewModel(
                title: "Unable to load observations",
                message: "Check your connection and try again."
            )
        ))
        #expect(states == [
            .loading,
            .error(
                ExploreErrorViewModel(
                    title: "Unable to load observations",
                    message: "Check your connection and try again."
                )
            )
        ])
    }

    @Test func retryPerformsAnotherRepositoryRequest() async {
        let repository = MockObservationsRepository(results: [
            .failure(TestError()),
            .success(Self.page(values: [Self.observation(id: 3)]))
        ])
        let viewModel = ExploreViewModel(observationsRepository: repository)

        await viewModel.loadInitialObservations().value
        await viewModel.retry().value

        #expect(repository.calls.count == 2)
        guard case .content(let items) = viewModel.state else {
            Issue.record("Expected content state after retry")
            return
        }
        #expect(items.map { $0.id } == [3])
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

    private static func page(values: [Observation]) -> PaginatedPage<Observation> {
        PaginatedPage(values: values, page: 1, perPage: 20, totalResults: values.count)
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

    private var results: [Result<PaginatedPage<Observation>, Error>]
    private(set) var calls: [Call] = []

    init(results: [Result<PaginatedPage<Observation>, Error>] = []) {
        self.results = results
    }

    func observations(
        page: Int,
        perPage: Int,
        filters: ObservationFilters
    ) async throws -> PaginatedPage<Observation> {
        calls.append(Call(page: page, perPage: perPage, filters: filters))

        guard !results.isEmpty else {
            return PaginatedPage(values: [], page: page, perPage: perPage, totalResults: 0)
        }

        return try results.removeFirst().get()
    }

    func observation(id: Int) async throws -> Observation {
        throw TestError()
    }
}
