//
//  DTOMappingTests.swift
//  WildlifeAtlasTests
//
//  Created by Artur Bagautdinov on 07.09.2026.
//

import Foundation
import Testing
@testable import WildlifeAtlas

struct DTOMappingTests {

    @Test func observationPageDecodesAndMapsRepresentativeFields() throws {
        let data = Data("""
        {
          "total_results": 1,
          "page": 1,
          "per_page": 1,
          "results": [
            {
              "id": 398054233,
              "uri": "https://www.inaturalist.org/observations/398054233",
              "quality_grade": "needs_id",
              "observed_on": "2026-09-07",
              "time_observed_at": "2026-09-07T20:22:16-07:00",
              "place_guess": "Samish TDSA, WA, US",
              "geoprivacy": null,
              "taxon_geoprivacy": null,
              "obscured": false,
              "taxon": {
                "id": 48455,
                "name": "Melibe leonina",
                "rank": "species",
                "rank_level": 10,
                "preferred_common_name": "Hooded Nudibranch",
                "iconic_taxon_name": "Mollusca",
                "wikipedia_url": "https://en.wikipedia.org/wiki/Melibe leonina",
                "wikipedia_summary": "A nudibranch species."
              },
              "photos": [
                {
                  "id": 730155390,
                  "url": "https://static.inaturalist.org/photos/730155390/square.jpg",
                  "attribution": "(c) ellagouran, some rights reserved (CC BY-NC)",
                  "license_code": "cc-by-nc"
                }
              ],
              "user": {
                "id": 10996492,
                "login": "ellagouran",
                "name": null,
                "icon_url": null
              }
            }
          ]
        }
        """.utf8)

        let response = try JSONDecoder().decode(PaginatedResponseDTO<ObservationDTO>.self, from: data)
        let observation = response.results[0].toDomain()

        #expect(response.totalResults == 1)
        #expect(response.page == 1)
        #expect(response.perPage == 1)
        #expect(observation.id == 398054233)
        #expect(observation.quality == .needsID)
        #expect(observation.observedOn == "2026-09-07")
        #expect(observation.location?.placeName == "Samish TDSA, WA, US")
        #expect(observation.taxon?.scientificName == "Melibe leonina")
        #expect(observation.taxon?.commonName == "Hooded Nudibranch")
        #expect(observation.photos.first?.licenseCode == "cc-by-nc")
        #expect(observation.author?.login == "ellagouran")
    }

    @Test func missingOptionalObservationFieldsRemainAbsent() throws {
        let data = Data("""
        {
          "id": 10,
          "quality_grade": null,
          "observed_on": null,
          "time_observed_at": null,
          "place_guess": null,
          "geoprivacy": null,
          "taxon_geoprivacy": null,
          "obscured": false,
          "taxon": null,
          "photos": null,
          "user": null
        }
        """.utf8)

        let dto = try JSONDecoder().decode(ObservationDTO.self, from: data)
        let observation = dto.toDomain()

        #expect(observation.quality == nil)
        #expect(observation.observedOn == nil)
        #expect(observation.taxon == nil)
        #expect(observation.photos.isEmpty)
        #expect(observation.author == nil)
        #expect(observation.location == nil)
    }

    @Test func privateOrObscuredLocationIsNotMappedToPresentationData() throws {
        let privateData = Data("""
        {
          "id": 10,
          "place_guess": "A sensitive place",
          "geoprivacy": "private",
          "taxon_geoprivacy": null,
          "obscured": false
        }
        """.utf8)
        let obscuredData = Data("""
        {
          "id": 11,
          "place_guess": "An obscured place",
          "geoprivacy": null,
          "taxon_geoprivacy": null,
          "obscured": true
        }
        """.utf8)

        let privateObservation = try JSONDecoder().decode(ObservationDTO.self, from: privateData).toDomain()
        let obscuredObservation = try JSONDecoder().decode(ObservationDTO.self, from: obscuredData).toDomain()

        #expect(privateObservation.location == nil)
        #expect(obscuredObservation.location == nil)
    }

    @Test func taxonAutocompleteResponseDecodesAndMapsRepresentativeFields() throws {
        let data = Data("""
        {
          "total_results": 1,
          "page": 1,
          "per_page": 3,
          "results": [
            {
              "id": 46020,
              "rank": "species",
              "rank_level": 10,
              "name": "Sciurus niger",
              "matched_term": "Fox Squirrel",
              "iconic_taxon_name": "Mammalia",
              "preferred_common_name": "Eastern Fox Squirrel",
              "default_photo": {
                "id": 337444041,
                "license_code": "cc-by-nc",
                "attribution": "(c) Tobin Brown, some rights reserved (CC BY-NC)",
                "url": "https://inaturalist-open-data.s3.amazonaws.com/photos/337444041/square.jpeg",
                "square_url": "https://inaturalist-open-data.s3.amazonaws.com/photos/337444041/square.jpeg",
                "medium_url": "https://inaturalist-open-data.s3.amazonaws.com/photos/337444041/medium.jpeg"
              }
            }
          ]
        }
        """.utf8)

        let response = try JSONDecoder().decode(PaginatedResponseDTO<TaxonDTO>.self, from: data)
        let taxon = response.results[0].toDomain()

        #expect(taxon.id == 46020)
        #expect(taxon.scientificName == "Sciurus niger")
        #expect(taxon.commonName == "Eastern Fox Squirrel")
        #expect(taxon.matchedTerm == "Fox Squirrel")
        #expect(taxon.defaultPhoto?.mediumURL?.absoluteString.hasSuffix("medium.jpeg") == true)
    }
}
