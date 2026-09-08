//
//  FavoritesViewModelTests.swift
//  WildlifeAtlasTests
//
//  Created by Artur Bagautdinov on 08.09.2026.
//

import Foundation
import Testing
@testable import WildlifeAtlas

@MainActor
@Suite(.serialized)
struct FavoritesViewModelTests {

    @Test func emptyFavoritesShowEmptyStateWithoutRepositoryRequest() async {
        let repository = MockFavoritesObservationsRepository()
        let store = MockFavoritesStore()
        let viewModel = FavoritesViewModel(observationsRepository: repository, favoritesStore: store)

        let task = viewModel.loadFavorites()
        await task?.value

        #expect(task == nil)
        #expect(viewModel.state == .empty)
        #expect(repository.requestedIDBatches.isEmpty)
    }

    @Test func favoriteIDsLoadBatchedObservations() async {
        let observations = [Self.observation(id: 2), Self.observation(id: 1)]
        let repository = MockFavoritesObservationsRepository(results: [.success(observations)])
        let store = MockFavoritesStore(ids: [2, 1])
        let viewModel = FavoritesViewModel(observationsRepository: repository, favoritesStore: store)

        await viewModel.loadFavorites()?.value

        #expect(repository.requestedIDBatches == [[2, 1]])

        guard case .content(let items) = viewModel.state else {
            Issue.record("Expected favorite content")
            return
        }

        #expect(items.map(\.id) == [2, 1])
        #expect(items.map(\.isFavorite) == [true, true])
    }

    @Test func failedFavoritesLoadShowsError() async {
        let repository = MockFavoritesObservationsRepository(results: [.failure(FavoritesTestError())])
        let store = MockFavoritesStore(ids: [3])
        let viewModel = FavoritesViewModel(observationsRepository: repository, favoritesStore: store)

        await viewModel.loadFavorites()?.value

        #expect(viewModel.state == FavoritesViewModel.State.error(.loadFailed))
    }

    @Test func removingFavoriteUpdatesContentAndStore() async {
        let repository = MockFavoritesObservationsRepository(results: [
            .success([Self.observation(id: 1), Self.observation(id: 2)])
        ])
        let store = MockFavoritesStore(ids: [1, 2])
        let viewModel = FavoritesViewModel(observationsRepository: repository, favoritesStore: store)

        await viewModel.loadFavorites()?.value
        viewModel.removeFavorite(id: 1)

        #expect(store.loadFavoriteIDs() == [2])

        guard case .content(let items) = viewModel.state else {
            Issue.record("Expected remaining favorite content")
            return
        }

        #expect(items.map(\.id) == [2])
    }

    @Test func removingLastFavoriteShowsEmptyState() async {
        let repository = MockFavoritesObservationsRepository(results: [.success([Self.observation(id: 1)])])
        let store = MockFavoritesStore(ids: [1])
        let viewModel = FavoritesViewModel(observationsRepository: repository, favoritesStore: store)

        await viewModel.loadFavorites()?.value
        viewModel.removeFavorite(id: 1)

        #expect(viewModel.state == .empty)
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
                rank: nil,
                iconicTaxonName: nil,
                matchedTerm: nil,
                wikipediaURL: nil,
                wikipediaSummary: nil,
                defaultPhoto: nil
            ),
            photos: [],
            author: nil,
            location: nil
        )
    }
}

private nonisolated final class MockFavoritesObservationsRepository: ObservationsRepository {
    private let lock = NSLock()
    private var results: [Result<[Observation], Error>]
    private var batches: [[Int]] = []

    var requestedIDBatches: [[Int]] {
        withLock { batches }
    }

    init(results: [Result<[Observation], Error>] = []) {
        self.results = results
    }

    func observations(page: Int, perPage: Int, filters: ObservationFilters) async throws -> PaginatedPage<Observation> {
        PaginatedPage(values: [], page: page, perPage: perPage, totalResults: 0)
    }

    func observations(ids: [Int]) async throws -> [Observation] {
        let result: Result<[Observation], Error> = withLock {
            batches.append(ids)
            return results.isEmpty ? .success([]) : results.removeFirst()
        }

        await Task.yield()
        return try result.get()
    }

    func observation(id: Int) async throws -> Observation {
        throw FavoritesTestError()
    }

    private func withLock<Value>(_ work: () throws -> Value) rethrows -> Value {
        lock.lock()
        defer { lock.unlock() }
        return try work()
    }
}

private nonisolated struct FavoritesTestError: Error {}

private nonisolated final class MockFavoritesStore: FavoritesStore {
    private let lock = NSLock()
    private var ids: [Int]

    init(ids: [Int] = []) {
        self.ids = ids
    }

    func loadFavoriteIDs() -> [Int] {
        withLock { ids }
    }

    func isFavorite(id: Int) -> Bool {
        loadFavoriteIDs().contains(id)
    }

    func addFavorite(id: Int) {
        withLock {
            ids.removeAll { $0 == id }
            ids.insert(id, at: 0)
        }
    }

    func removeFavorite(id: Int) {
        withLock {
            ids.removeAll { $0 == id }
        }
    }

    private func withLock<Value>(_ work: () throws -> Value) rethrows -> Value {
        lock.lock()
        defer { lock.unlock() }
        return try work()
    }
}
