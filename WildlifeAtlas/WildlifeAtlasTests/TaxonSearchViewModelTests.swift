//
//  TaxonSearchViewModelTests.swift
//  WildlifeAtlasTests
//
//  Created by Artur Bagautdinov on 08.09.2026.
//

import Foundation
import Testing
@testable import WildlifeAtlas

@MainActor
@Suite(.serialized)
struct TaxonSearchViewModelTests {

    @Test func emptyQueryShowsRecentsAndDoesNotSearch() {
        let recentTaxon = Self.taxon(id: 1, commonName: "Red Fox", scientificName: "Vulpes vulpes")
        let repository = MockTaxaRepository()
        let store = MockRecentTaxaStore(taxa: [recentTaxon])
        let viewModel = TaxonSearchViewModel(
            taxaRepository: repository,
            recentTaxaStore: store,
            debounceNanoseconds: 1
        )

        viewModel.updateQuery("   ")

        #expect(repository.calls.isEmpty)
        #expect(viewModel.state == .recent([TaxonSearchItem(taxon: recentTaxon)]))
    }

    @Test func debounceDelaysSearchRequest() async throws {
        let repository = MockTaxaRepository(responses: [
            "fox": .success(Self.page([Self.taxon(id: 1)]))
        ])
        let viewModel = TaxonSearchViewModel(
            taxaRepository: repository,
            recentTaxaStore: MockRecentTaxaStore(),
            debounceNanoseconds: 80_000_000
        )

        viewModel.updateQuery("fox")
        try await Task.sleep(nanoseconds: 10_000_000)

        #expect(repository.calls.isEmpty)

        try await Task.sleep(nanoseconds: 110_000_000)
        #expect(repository.calls == ["fox"])
    }

    @Test func successfulSearchShowsResults() async throws {
        let redFox = Self.taxon(id: 1, commonName: "Red Fox", scientificName: "Vulpes vulpes", iconicTaxonName: "Mammalia")
        let repository = MockTaxaRepository(responses: [
            "red fox": .success(Self.page([redFox]))
        ])
        let viewModel = TaxonSearchViewModel(
            taxaRepository: repository,
            recentTaxaStore: MockRecentTaxaStore(),
            debounceNanoseconds: 1
        )

        viewModel.updateQuery("red fox")
        try await Task.sleep(nanoseconds: 20_000_000)

        #expect(repository.calls == ["red fox"])
        #expect(viewModel.state == .results([TaxonSearchItem(taxon: redFox)]))
    }

    @Test func emptySearchResponseShowsSearchEmptyState() async throws {
        let repository = MockTaxaRepository(responses: [
            "zzzz": .success(Self.page([]))
        ])
        let viewModel = TaxonSearchViewModel(
            taxaRepository: repository,
            recentTaxaStore: MockRecentTaxaStore(),
            debounceNanoseconds: 1
        )

        viewModel.updateQuery("zzzz")
        try await Task.sleep(nanoseconds: 20_000_000)

        #expect(viewModel.state == .empty(query: "zzzz"))
    }

    @Test func failedSearchShowsLightweightErrorState() async throws {
        let repository = MockTaxaRepository(responses: [
            "fox": .failure(TestSearchError())
        ])
        let viewModel = TaxonSearchViewModel(
            taxaRepository: repository,
            recentTaxaStore: MockRecentTaxaStore(),
            debounceNanoseconds: 1
        )

        viewModel.updateQuery("fox")
        try await Task.sleep(nanoseconds: 20_000_000)

        #expect(viewModel.state == .error(query: "fox", message: "Unable to search taxa. Try editing the search."))
    }

    @Test func supersededQueryDoesNotIssueRequestBeforeDebounceCompletes() async throws {
        let repository = MockTaxaRepository(responses: [
            "red fox": .success(Self.page([Self.taxon(id: 2)]))
        ])
        let viewModel = TaxonSearchViewModel(
            taxaRepository: repository,
            recentTaxaStore: MockRecentTaxaStore(),
            debounceNanoseconds: 80_000_000
        )

        viewModel.updateQuery("red")
        try await Task.sleep(nanoseconds: 10_000_000)
        viewModel.updateQuery("red fox")
        try await Task.sleep(nanoseconds: 120_000_000)

        #expect(repository.calls == ["red fox"])
    }

    @Test func olderResponseCannotOverwriteNewerQuery() async throws {
        let redTaxon = Self.taxon(id: 1, commonName: "Red")
        let redFox = Self.taxon(id: 2, commonName: "Red Fox")
        let repository = MockTaxaRepository(
            responses: [
                "red": .success(Self.page([redTaxon])),
                "red fox": .success(Self.page([redFox]))
            ],
            delays: [
                "red": 80_000_000,
                "red fox": 1
            ]
        )
        let viewModel = TaxonSearchViewModel(
            taxaRepository: repository,
            recentTaxaStore: MockRecentTaxaStore(),
            debounceNanoseconds: 1
        )

        viewModel.updateQuery("red")
        try await Task.sleep(nanoseconds: 20_000_000)
        viewModel.updateQuery("red fox")
        try await Task.sleep(nanoseconds: 140_000_000)

        #expect(repository.calls == ["red", "red fox"])
        #expect(viewModel.state == .results([TaxonSearchItem(taxon: redFox)]))
    }

    @Test func selectingTaxonSavesRecentAndEmitsSelection() async throws {
        let fox = Self.taxon(id: 1, commonName: "Red Fox")
        let repository = MockTaxaRepository(responses: [
            "fox": .success(Self.page([fox]))
        ])
        let store = MockRecentTaxaStore()
        let viewModel = TaxonSearchViewModel(
            taxaRepository: repository,
            recentTaxaStore: store,
            debounceNanoseconds: 1
        )
        var selectedTaxon: Taxon?
        viewModel.onTaxonSelected = { selectedTaxon = $0 }

        viewModel.updateQuery("fox")
        try await Task.sleep(nanoseconds: 20_000_000)
        viewModel.selectItem(id: fox.id)

        #expect(selectedTaxon == fox)
        #expect(store.taxa == [fox])
    }

    @Test func selectingExistingRecentTaxonMovesItToFront() {
        let fox = Self.taxon(id: 1, commonName: "Red Fox")
        let falcon = Self.taxon(id: 2, commonName: "Red-footed Falcon")
        let store = MockRecentTaxaStore(taxa: [falcon, fox])
        let viewModel = TaxonSearchViewModel(
            taxaRepository: MockTaxaRepository(),
            recentTaxaStore: store,
            debounceNanoseconds: 1
        )

        viewModel.selectItem(id: fox.id)

        #expect(store.taxa == [fox, falcon])
    }

    @Test func recentTaxaStayUniqueAndLimitedToFive() {
        let taxa = (1...5).map { Self.taxon(id: $0) }
        let sixth = Self.taxon(id: 6)
        let store = MockRecentTaxaStore(taxa: taxa)
        let viewModel = TaxonSearchViewModel(
            taxaRepository: MockTaxaRepository(),
            recentTaxaStore: store,
            debounceNanoseconds: 1
        )

        viewModel.updateQuery("")
        store.taxa = taxa
        viewModel.selectTaxon(sixth)

        #expect(store.taxa.map(\.id) == [6, 1, 2, 3, 4])

        viewModel.selectTaxon(Self.taxon(id: 3))
        #expect(store.taxa.map(\.id) == [3, 6, 1, 2, 4])
    }

    @Test func storedRecentTaxaDisplayAsUniqueFiveItemPrefix() {
        let store = MockRecentTaxaStore(taxa: [
            Self.taxon(id: 1),
            Self.taxon(id: 2),
            Self.taxon(id: 1),
            Self.taxon(id: 3),
            Self.taxon(id: 4),
            Self.taxon(id: 5),
            Self.taxon(id: 6)
        ])
        let viewModel = TaxonSearchViewModel(
            taxaRepository: MockTaxaRepository(),
            recentTaxaStore: store,
            debounceNanoseconds: 1
        )

        #expect(viewModel.state == .recent((1...5).map { TaxonSearchItem(taxon: Self.taxon(id: $0)) }))
    }

    private static func page(_ taxa: [Taxon]) -> PaginatedPage<Taxon> {
        PaginatedPage(values: taxa, page: 1, perPage: 10, totalResults: taxa.count)
    }

    private static func taxon(
        id: Int,
        commonName: String? = nil,
        scientificName: String? = nil,
        iconicTaxonName: String? = nil
    ) -> Taxon {
        Taxon(
            id: id,
            scientificName: scientificName ?? "Species \(id)",
            commonName: commonName,
            rank: "species",
            iconicTaxonName: iconicTaxonName,
            matchedTerm: nil,
            wikipediaURL: nil,
            wikipediaSummary: nil,
            defaultPhoto: nil
        )
    }
}

private nonisolated struct TestSearchError: Error {}

private nonisolated final class MockTaxaRepository: TaxaRepository {
    private let lock = NSLock()
    private var responses: [String: Result<PaginatedPage<Taxon>, Error>]
    private let delays: [String: UInt64]
    private var recordedCalls: [String] = []

    var calls: [String] {
        withLock { recordedCalls }
    }

    init(
        responses: [String: Result<PaginatedPage<Taxon>, Error>] = [:],
        delays: [String: UInt64] = [:]
    ) {
        self.responses = responses
        self.delays = delays
    }

    func autocompleteTaxa(query: String, page: Int, perPage: Int) async throws -> PaginatedPage<Taxon> {
        let delay = withLock {
            recordedCalls.append(query)
            return delays[query] ?? 0
        }

        if delay > 0 {
            try await Task.sleep(nanoseconds: delay)
        }

        let result = withLock {
            responses[query] ?? .success(PaginatedPage(values: [], page: page, perPage: perPage, totalResults: 0))
        }
        return try result.get()
    }

    private func withLock<Value>(_ work: () throws -> Value) rethrows -> Value {
        lock.lock()
        defer { lock.unlock() }
        return try work()
    }
}

private nonisolated final class MockRecentTaxaStore: RecentTaxaStore {
    var taxa: [Taxon]

    init(taxa: [Taxon] = []) {
        self.taxa = taxa
    }

    func loadRecentTaxa() -> [Taxon] {
        taxa
    }

    func saveRecentTaxa(_ taxa: [Taxon]) {
        self.taxa = taxa
    }
}
