//
//  ExploreObservationItem.swift
//  WildlifeAtlas
//
//  Created by Artur Bagautdinov on 07.09.2026.
//

import Foundation

nonisolated struct ExploreObservationItem: Hashable, Identifiable {
    let id: Int
    let imageURL: URL?
    let commonName: String?
    let scientificName: String?
    let observedDate: String?
    let qualityText: String?
    let qualitySymbol: String?
    let isFavorite: Bool

    init(observation: Observation, isFavorite: Bool = false) {
        self.id = observation.id
        self.imageURL = observation.photos.first?.mediumURL ?? observation.photos.first?.squareURL
        self.commonName = Self.visibleText(observation.taxon?.commonName)
        self.scientificName = Self.visibleText(observation.taxon?.scientificName)
        self.observedDate = Self.formattedDate(from: observation.observedOn)
        self.qualityText = observation.quality?.displayText
        self.qualitySymbol = observation.quality?.displaySymbol
        self.isFavorite = isFavorite
    }

    var accessibilityLabel: String {
        [
            commonName,
            scientificName,
            observedDate,
            qualityText
        ]
        .compactMap(Self.visibleText)
        .joined(separator: ", ")
    }

    private static func visibleText(_ text: String?) -> String? {
        guard let text = text?.trimmingCharacters(in: .whitespacesAndNewlines), !text.isEmpty else {
            return nil
        }
        return text
    }

    private static func formattedDate(from value: String?) -> String? {
        guard let value = visibleText(value) else {
            return nil
        }

        let inputFormatter = DateFormatter()
        inputFormatter.calendar = Calendar(identifier: .gregorian)
        inputFormatter.locale = Locale(identifier: "en_US_POSIX")
        inputFormatter.dateFormat = "yyyy-MM-dd"

        guard let date = inputFormatter.date(from: value) else {
            return value
        }

        let outputFormatter = DateFormatter()
        outputFormatter.calendar = Calendar(identifier: .gregorian)
        outputFormatter.locale = Locale(identifier: "en_US_POSIX")
        outputFormatter.dateFormat = "d MMM yyyy"
        return outputFormatter.string(from: date)
    }
}

private extension ObservationQuality {
    nonisolated var displayText: String {
        switch self {
        case .research:
            return "Excellent"
        case .needsID:
            return "Good"
        case .casual:
            return "Fair"
        case .unknown(let value):
            return value
        }
    }

    nonisolated var displaySymbol: String? {
        switch self {
        case .research:
            return "A"
        case .needsID:
            return "B"
        case .casual:
            return "C"
        case .unknown:
            return nil
        }
    }
}
