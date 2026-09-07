//
//  ObservationDTO.swift
//  WildlifeAtlas
//
//  Created by Artur Bagautdinov on 07.09.2026.
//

import Foundation

nonisolated struct ObservationDTO: Decodable {
    let id: Int
    let uri: String?
    let qualityGrade: String?
    let observedOn: String?
    let timeObservedAt: String?
    let placeGuess: String?
    let geoprivacy: String?
    let taxonGeoprivacy: String?
    let obscured: Bool?
    let taxon: TaxonDTO?
    let photos: [PhotoDTO]?
    let user: UserDTO?

    enum CodingKeys: String, CodingKey {
        case id
        case uri
        case qualityGrade = "quality_grade"
        case observedOn = "observed_on"
        case timeObservedAt = "time_observed_at"
        case placeGuess = "place_guess"
        case geoprivacy
        case taxonGeoprivacy = "taxon_geoprivacy"
        case obscured
        case taxon
        case photos
        case user
    }

    func toDomain() -> Observation {
        Observation(
            id: id,
            uri: uri.flatMap(URL.init(string:)),
            quality: qualityGrade.map(ObservationQuality.init(apiValue:)),
            observedOn: observedOn,
            observedAt: timeObservedAt,
            taxon: taxon?.toDomain(),
            photos: photos?.map { $0.toDomain() } ?? [],
            author: user?.toDomain(),
            location: makeLocationSummary()
        )
    }

    private func makeLocationSummary() -> ObservationLocationSummary? {
        guard obscured != true else { return nil }
        guard geoprivacy == nil else { return nil }
        guard taxonGeoprivacy == nil else { return nil }
        guard let placeGuess, !placeGuess.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            return nil
        }

        return ObservationLocationSummary(placeName: placeGuess)
    }
}

nonisolated struct UserDTO: Decodable {
    let id: Int
    let login: String?
    let name: String?
    let iconURL: String?

    enum CodingKeys: String, CodingKey {
        case id
        case login
        case name
        case iconURL = "icon_url"
    }

    func toDomain() -> ObservationAuthor {
        ObservationAuthor(
            id: id,
            login: login,
            displayName: name,
            iconURL: iconURL.flatMap(URL.init(string:))
        )
    }
}
