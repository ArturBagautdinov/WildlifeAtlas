//
//  TaxonSearchViewModel.swift
//  WildlifeAtlas
//
//  Created by Artur Bagautdinov on 08.09.2026.
//

import Foundation

@MainActor
final class TaxonSearchViewModel {
    enum State: Equatable {
        case recent([TaxonSearchItem])
        case loading(previousItems: [TaxonSearchItem])
        case results([TaxonSearchItem])
        case empty(query: String)
        case error(query: String, message: String)
    }

    private nonisolated enum Constants {
        static let defaultDebounceNanoseconds: UInt64 = 300_000_000
        static let perPage = 10
        static let maxRecentTaxa = 5
    }

    private let taxaRepository: TaxaRepository
    private let recentTaxaStore: RecentTaxaStore
    private let debounceNanoseconds: UInt64
    private var searchTask: Task<Void, Never>?
    private var latestQuery = ""
    private var lastRequestedQuery: String?

    var onStateChange: ((State) -> Void)?
    var onTaxonSelected: ((Taxon) -> Void)?

    private(set) var state: State {
        didSet {
            onStateChange?(state)
        }
    }

    init(
        taxaRepository: TaxaRepository,
        recentTaxaStore: RecentTaxaStore,
        debounceNanoseconds: UInt64 = Constants.defaultDebounceNanoseconds
    ) {
        self.taxaRepository = taxaRepository
        self.recentTaxaStore = recentTaxaStore
        self.debounceNanoseconds = debounceNanoseconds
        self.state = .recent(Self.items(from: Self.uniquePrefix(recentTaxaStore.loadRecentTaxa(), maxCount: Constants.maxRecentTaxa)))
    }

    deinit {
        searchTask?.cancel()
    }

    func viewDidLoad() {
        showRecentTaxa()
    }

    func updateQuery(_ query: String) {
        latestQuery = query
        searchTask?.cancel()

        let normalizedQuery = Self.normalizedQuery(query)
        guard let normalizedQuery else {
            lastRequestedQuery = nil
            showRecentTaxa()
            return
        }

        if normalizedQuery == lastRequestedQuery {
            return
        }

        let previousItems = currentItems
        state = .loading(previousItems: previousItems)

        let task = Task { [weak self] in
            guard let self else { return }

            do {
                try await Task.sleep(nanoseconds: debounceNanoseconds)
                try Task.checkCancellation()

                let page = try await taxaRepository.autocompleteTaxa(
                    query: normalizedQuery,
                    page: 1,
                    perPage: Constants.perPage
                )
                try Task.checkCancellation()

                guard Self.normalizedQuery(latestQuery) == normalizedQuery else {
                    return
                }

                lastRequestedQuery = normalizedQuery
                let items = Self.items(from: page.values)
                state = items.isEmpty ? .empty(query: normalizedQuery) : .results(items)
            } catch is CancellationError {
                return
            } catch {
                guard Self.normalizedQuery(latestQuery) == normalizedQuery else {
                    return
                }

                lastRequestedQuery = nil
                state = .error(
                    query: normalizedQuery,
                    message: "Unable to search taxa. Try editing the search."
                )
            }
        }

        searchTask = task
    }

    func selectItem(id: Int) {
        guard let item = currentItems.first(where: { $0.id == id }) else {
            return
        }

        selectTaxon(item.taxon)
    }

    func selectTaxon(_ taxon: Taxon) {
        saveRecentTaxon(taxon)
        onTaxonSelected?(taxon)
    }

    private var currentItems: [TaxonSearchItem] {
        switch state {
        case .recent(let items), .loading(let items), .results(let items):
            return items
        case .empty, .error:
            return []
        }
    }

    private func showRecentTaxa() {
        let recentItems = Self.items(from: Self.uniquePrefix(recentTaxaStore.loadRecentTaxa(), maxCount: Constants.maxRecentTaxa))
        state = .recent(recentItems)
    }

    private func saveRecentTaxon(_ taxon: Taxon) {
        let existingTaxa = recentTaxaStore.loadRecentTaxa()
        let updatedTaxa = ([taxon] + existingTaxa.filter { $0.id != taxon.id })
            .prefix(Constants.maxRecentTaxa)
        recentTaxaStore.saveRecentTaxa(Array(updatedTaxa))
    }

    private static func items(from taxa: [Taxon]) -> [TaxonSearchItem] {
        taxa.map(TaxonSearchItem.init(taxon:))
    }

    private static func normalizedQuery(_ query: String) -> String? {
        let trimmedQuery = query.trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmedQuery.isEmpty ? nil : trimmedQuery
    }

    private static func uniquePrefix(_ taxa: [Taxon], maxCount: Int) -> [Taxon] {
        var seenIDs = Set<Int>()
        return taxa.filter { seenIDs.insert($0.id).inserted }.prefix(maxCount).map { $0 }
    }
}
