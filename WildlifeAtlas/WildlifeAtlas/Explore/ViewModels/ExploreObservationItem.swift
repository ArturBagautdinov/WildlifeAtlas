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

    init(
        id: Int,
        imageURL: URL?,
        commonName: String?,
        scientificName: String?,
        observedDate: String?,
        qualityText: String?,
        qualitySymbol: String?
    ) {
        self.id = id
        self.imageURL = imageURL
        self.commonName = commonName
        self.scientificName = scientificName
        self.observedDate = observedDate
        self.qualityText = qualityText
        self.qualitySymbol = qualitySymbol
    }

    init(observation: Observation) {
        self.init(
            id: observation.id,
            imageURL: observation.photos.first?.mediumURL ?? observation.photos.first?.squareURL,
            commonName: Self.visibleText(observation.taxon?.commonName),
            scientificName: Self.visibleText(observation.taxon?.scientificName),
            observedDate: Self.formattedDate(from: observation.observedOn),
            qualityText: observation.quality?.displayText,
            qualitySymbol: observation.quality?.displaySymbol
        )
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
        case .needsID:
            return "Good"
        case .research:
            return "Excellent"
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
