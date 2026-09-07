//
//  Observation.swift
//  WildlifeAtlas
//
//  Created by Artur Bagautdinov on 07.09.2026.
//

import Foundation

nonisolated struct Observation: Equatable, Identifiable {
    let id: Int
    let uri: URL?
    let quality: ObservationQuality?
    let observedOn: String?
    let observedAt: String?
    let taxon: Taxon?
    let photos: [ObservationPhoto]
    let author: ObservationAuthor?
    let location: ObservationLocationSummary?
}

nonisolated enum ObservationQuality: Equatable {
    case needsID
    case research
    case casual
    case unknown(String)

    init(apiValue: String) {
        switch apiValue {
        case "needs_id":
            self = .needsID
        case "research":
            self = .research
        case "casual":
            self = .casual
        default:
            self = .unknown(apiValue)
        }
    }
}

nonisolated struct ObservationPhoto: Equatable, Identifiable {
    let id: Int
    let squareURL: URL?
    let mediumURL: URL?
    let attribution: String?
    let licenseCode: String?
}

nonisolated struct ObservationAuthor: Equatable, Identifiable {
    let id: Int
    let login: String?
    let displayName: String?
    let iconURL: URL?
}

nonisolated struct ObservationLocationSummary: Equatable {
    let placeName: String
}
