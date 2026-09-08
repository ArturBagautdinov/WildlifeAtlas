//
//  ObservationDetailViewModelTests.swift
//  WildlifeAtlasTests
//
//  Created by Artur Bagautdinov on 08.09.2026.
//

import Foundation
import Testing
@testable import WildlifeAtlas

@MainActor
@Suite(.serialized)
struct ObservationDetailViewModelTests {

    @Test func loadFetchesObservationUsingProvidedID() async {
        let observation = Self.observation(id: 42)
        let repository = MockDetailObservationsRepository(results: [.success(observation)])
        let viewModel = ObservationDetailViewModel(observationID: 42, observationsRepository: repository)

        await viewModel.loadObservation().value

        #expect(repository.requestedObservationIDs == [42])
    }

    @Test func successfulLoadShowsContent() async {
        let observation = Self.observation(id: 7)
        let repository = MockDetailObservationsRepository(results: [.success(observation)])
        let viewModel = ObservationDetailViewModel(observationID: 7, observationsRepository: repository)

        await viewModel.loadObservation().value

        guard case .content(let content) = viewModel.state else {
            Issue.record("Expected content state")
            return
        }

        #expect(content.id == 7)
        #expect(content.commonName == "Red Fox")
        #expect(content.scientificName == "Vulpes vulpes")
        #expect(content.qualityText == "Excellent")
        #expect(content.qualitySymbol == "A")
        #expect(content.observedDate == "14 May 2024 at 06:42")
        #expect(content.locationName == "Samish TDSA, WA, US")
        #expect(content.authorName == "Alex Morgan")
        #expect(content.photoAttribution == "(c) Alex Morgan")
        #expect(content.photoLicense == "CC BY NC")
    }

    @Test func notFoundRepositoryErrorShowsNotFound() async {
        let repository = MockDetailObservationsRepository(results: [.failure(RepositoryError.notFound)])
        let viewModel = ObservationDetailViewModel(observationID: 8, observationsRepository: repository)

        await viewModel.loadObservation().value

        #expect(viewModel.state == .notFound)
    }

    @Test func failureShowsError() async {
        let repository = MockDetailObservationsRepository(results: [.failure(TestError())])
        let viewModel = ObservationDetailViewModel(observationID: 9, observationsRepository: repository)

        await viewModel.loadObservation().value

        #expect(viewModel.state == .error(.loadFailed))
    }

    @Test func retryPerformsAnotherRequest() async {
        let repository = MockDetailObservationsRepository(results: [
            .failure(TestError()),
            .success(Self.observation(id: 10))
        ])
        let viewModel = ObservationDetailViewModel(observationID: 10, observationsRepository: repository)

        await viewModel.loadObservation().value
        await viewModel.retry().value

        #expect(repository.requestedObservationIDs == [10, 10])

        guard case .content(let content) = viewModel.state else {
            Issue.record("Expected content state after retry")
            return
        }
        #expect(content.id == 10)
    }

    @Test func missingOptionalFieldsRemainAbsentInContent() {
        let content = ObservationDetailContent(
            observation: Observation(
                id: 11,
                uri: nil,
                quality: nil,
                observedOn: nil,
                observedAt: nil,
                taxon: Taxon(
                    id: 1,
                    scientificName: "",
                    commonName: nil,
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
        )

        #expect(content.photos.isEmpty)
        #expect(content.commonName == nil)
        #expect(content.scientificName == nil)
        #expect(content.qualityText == nil)
        #expect(content.qualitySymbol == nil)
        #expect(content.observedDate == nil)
        #expect(content.taxonRows.isEmpty)
        #expect(content.locationName == nil)
        #expect(content.authorName == nil)
        #expect(content.photoAttribution == nil)
        #expect(content.photoLicense == nil)
    }

    @Test func taxonRowsUseOnlyAvailableUsefulTaxonFields() {
        let content = ObservationDetailContent(observation: Self.observation(id: 12))

        #expect(content.taxonRows.map(\.title) == ["Rank", "Group", "About"])
        #expect(content.taxonRows.map(\.value) == ["species", "Mammalia", "A widespread fox species."])
    }

    @Test func taxonSummaryHTMLIsPresentedAsPlainText() {
        let content = ObservationDetailContent(
            observation: Self.observation(
                id: 13,
                taxonSummary: "<p>A <i>widespread</i> fox &amp; adaptable carnivore.</p>"
            )
        )

        #expect(content.taxonRows.first(where: { $0.id == "summary" })?.value == "A widespread fox & adaptable carnivore.")
    }

    @Test func privateOrHiddenLocationNeverProducesPresentationLocation() throws {
        let data = Data("""
        {
          "id": 13,
          "place_guess": "Sensitive habitat",
          "geoprivacy": "private",
          "taxon_geoprivacy": null,
          "obscured": false,
          "taxon": {
            "id": 1,
            "name": "Vulpes vulpes"
          }
        }
        """.utf8)

        let observation = try JSONDecoder().decode(ObservationDTO.self, from: data).toDomain()
        let content = ObservationDetailContent(observation: observation)

        #expect(observation.location == nil)
        #expect(content.locationName == nil)
    }

    @Test func exactCoordinatesNeverBecomePresentationText() throws {
        let data = Data("""
        {
          "id": 14,
          "latitude": "55.751244",
          "longitude": "37.618423",
          "geojson": {
            "type": "Point",
            "coordinates": [37.618423, 55.751244]
          },
          "place_guess": null,
          "geoprivacy": null,
          "taxon_geoprivacy": null,
          "obscured": false,
          "taxon": {
            "id": 1,
            "name": "Vulpes vulpes"
          }
        }
        """.utf8)

        let observation = try JSONDecoder().decode(ObservationDTO.self, from: data).toDomain()
        let content = ObservationDetailContent(observation: observation)

        #expect(content.locationName == nil)
        #expect(content.accessibilityLabel.contains("55.751244") == false)
        #expect(content.accessibilityLabel.contains("37.618423") == false)
    }

    @Test func galleryUsesAllPhotosWithUsableURLs() {
        let content = ObservationDetailContent(
            observation: Self.observation(
                id: 15,
                photos: [
                    ObservationPhoto(
                        id: 1,
                        squareURL: URL(string: "https://example.com/one-square.jpg"),
                        mediumURL: URL(string: "https://example.com/one-medium.jpg"),
                        attribution: "(c) One",
                        licenseCode: "cc-by"
                    ),
                    ObservationPhoto(
                        id: 2,
                        squareURL: URL(string: "https://example.com/two-square.jpg"),
                        mediumURL: nil,
                        attribution: "(c) Two",
                        licenseCode: "cc0"
                    )
                ]
            )
        )

        #expect(content.photos.map(\.id) == [1, 2])
        #expect(content.photos.map(\.imageURL.absoluteString) == [
            "https://example.com/one-medium.jpg",
            "https://example.com/two-square.jpg"
        ])
    }

    @Test func galleryOmitsPhotosWithoutDisplayableURLs() {
        let content = ObservationDetailContent(
            observation: Self.observation(
                id: 16,
                photos: [
                    ObservationPhoto(
                        id: 1,
                        squareURL: nil,
                        mediumURL: nil,
                        attribution: "(c) One",
                        licenseCode: "cc-by"
                    ),
                    ObservationPhoto(
                        id: 2,
                        squareURL: URL(string: "https://example.com/two-square.jpg"),
                        mediumURL: nil,
                        attribution: "(c) Two",
                        licenseCode: "cc0"
                    )
                ]
            )
        )

        #expect(content.photos.map(\.id) == [2])
    }

    @Test func sharePayloadUsesSafePublicObservationInformation() {
        let content = ObservationDetailContent(observation: Self.observation(id: 17))

        #expect(content.canShare)
        #expect(content.shareText?.contains("Red Fox") == true)
        #expect(content.shareText?.contains("Vulpes vulpes") == true)
        #expect(content.shareText?.contains("Observed on 14 May 2024 at 06:42") == true)
        #expect(content.shareURL == URL(string: "https://www.inaturalist.org/observations/17"))
        #expect(content.shareText?.contains("Samish TDSA") == false)
        #expect(content.shareText?.contains("55.") == false)
        #expect(content.shareText?.contains("37.") == false)
    }

    @Test func shareIsUnavailableWhenNoSafeShareDataExists() {
        let content = ObservationDetailContent(
            observation: Observation(
                id: 18,
                uri: nil,
                quality: nil,
                observedOn: nil,
                observedAt: nil,
                taxon: nil,
                photos: [],
                author: nil,
                location: ObservationLocationSummary(placeName: "Private location")
            )
        )

        #expect(content.canShare == false)
        #expect(content.shareText == nil)
        #expect(content.shareURL == nil)
    }

    private static func observation(
        id: Int,
        taxonSummary: String? = "A widespread fox species.",
        photos: [ObservationPhoto]? = nil
    ) -> Observation {
        Observation(
            id: id,
            uri: URL(string: "https://www.inaturalist.org/observations/\(id)"),
            quality: .research,
            observedOn: "2024-05-14",
            observedAt: "2024-05-14T06:42:00Z",
            taxon: Taxon(
                id: 420,
                scientificName: "Vulpes vulpes",
                commonName: "Red Fox",
                rank: "species",
                iconicTaxonName: "Mammalia",
                matchedTerm: nil,
                wikipediaURL: nil,
                wikipediaSummary: taxonSummary,
                defaultPhoto: nil
            ),
            photos: photos ?? [
                ObservationPhoto(
                    id: 1,
                    squareURL: URL(string: "https://example.com/square.jpg"),
                    mediumURL: URL(string: "https://example.com/medium.jpg"),
                    attribution: "(c) Alex Morgan",
                    licenseCode: "cc-by-nc"
                )
            ],
            author: ObservationAuthor(
                id: 2,
                login: "alexmorgan",
                displayName: "Alex Morgan",
                iconURL: nil
            ),
            location: ObservationLocationSummary(placeName: "Samish TDSA, WA, US")
        )
    }
}

private nonisolated struct TestError: Error {}

private nonisolated final class MockDetailObservationsRepository: ObservationsRepository {
    private let lock = NSLock()
    private var results: [Result<Observation, Error>]
    private var requestedIDs: [Int] = []

    var requestedObservationIDs: [Int] {
        withLock { requestedIDs }
    }

    init(results: [Result<Observation, Error>]) {
        self.results = results
    }

    func observations(page: Int, perPage: Int, filters: ObservationFilters) async throws -> PaginatedPage<Observation> {
        PaginatedPage(values: [], page: page, perPage: perPage, totalResults: 0)
    }

    func observation(id: Int) async throws -> Observation {
        let result: Result<Observation, Error> = withLock {
            requestedIDs.append(id)
            return results.isEmpty ? .failure(TestError()) : results.removeFirst()
        }

        await Task.yield()
        return try result.get()
    }

    private func withLock<Value>(_ work: () throws -> Value) rethrows -> Value {
        lock.lock()
        defer { lock.unlock() }
        return try work()
    }
}
