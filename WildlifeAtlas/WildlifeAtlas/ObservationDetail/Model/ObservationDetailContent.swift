//
//  ObservationDetailContent.swift
//  WildlifeAtlas
//
//  Created by Artur Bagautdinov on 08.09.2026.
//

import Foundation

nonisolated struct ObservationDetailContent: Equatable {
    struct InfoRow: Equatable, Identifiable {
        let id: String
        let title: String
        let value: String
    }

    let id: Int
    let imageURL: URL?
    let commonName: String?
    let scientificName: String?
    let qualityText: String?
    let qualitySymbol: String?
    let observedDate: String?
    let taxonRows: [InfoRow]
    let locationName: String?
    let authorName: String?
    let photoAttribution: String?
    let photoLicense: String?

    init(observation: Observation) {
        let primaryPhoto = observation.photos.first
        self.id = observation.id
        self.imageURL = primaryPhoto?.mediumURL ?? primaryPhoto?.squareURL
        self.commonName = Self.visibleText(observation.taxon?.commonName)
        self.scientificName = Self.visibleText(observation.taxon?.scientificName)
        self.qualityText = observation.quality?.detailDisplayText
        self.qualitySymbol = observation.quality?.detailDisplaySymbol
        self.observedDate = Self.formattedObservedDate(observedOn: observation.observedOn, observedAt: observation.observedAt)
        self.taxonRows = Self.taxonRows(from: observation.taxon)
        self.locationName = Self.visibleText(observation.location?.placeName)
        self.authorName = Self.authorName(from: observation.author)
        self.photoAttribution = Self.visibleText(primaryPhoto?.attribution)
        self.photoLicense = Self.formattedLicense(primaryPhoto?.licenseCode)
    }

    var accessibilityLabel: String {
        [
            commonName,
            scientificName,
            qualityText,
            observedDate,
            locationName,
            authorName.map { "Photographed by \($0)" }
        ]
        .compactMap(Self.visibleText)
        .joined(separator: ", ")
    }

    private static func taxonRows(from taxon: Taxon?) -> [InfoRow] {
        guard let taxon else { return [] }

        var rows: [InfoRow] = []
        appendRow(id: "rank", title: "Rank", value: taxon.rank, to: &rows)
        appendRow(id: "group", title: "Group", value: taxon.iconicTaxonName, to: &rows)
        appendRow(id: "summary", title: "About", value: plainText(fromHTML: taxon.wikipediaSummary), to: &rows)
        return rows
    }

    private static func appendRow(id: String, title: String, value: String?, to rows: inout [InfoRow]) {
        guard let value = visibleText(value) else { return }
        rows.append(InfoRow(id: id, title: title, value: value))
    }

    private static func authorName(from author: ObservationAuthor?) -> String? {
        guard let author else { return nil }
        return visibleText(author.displayName) ?? visibleText(author.login)
    }

    private static func formattedLicense(_ licenseCode: String?) -> String? {
        guard let licenseCode = visibleText(licenseCode) else { return nil }
        return licenseCode
            .replacingOccurrences(of: "-", with: " ")
            .uppercased()
    }

    private static func formattedObservedDate(observedOn: String?, observedAt: String?) -> String? {
        if let observedAt = visibleText(observedAt), let dateTime = Self.dateTimeParts(from: observedAt) {
            return "\(dateTime.date) at \(dateTime.time)"
        }

        guard let observedOn = visibleText(observedOn) else { return nil }

        guard let date = Self.observedOnFormatter.date(from: observedOn) else {
            return observedOn
        }

        return Self.dateFormatter.string(from: date)
    }

    private static func dateTimeParts(from value: String) -> (date: String, time: String)? {
        guard value.count >= 16 else { return nil }

        let dateEndIndex = value.index(value.startIndex, offsetBy: 10)
        let timeStartIndex = value.index(value.startIndex, offsetBy: 11)
        let timeEndIndex = value.index(value.startIndex, offsetBy: 16)
        guard value[dateEndIndex] == "T" else { return nil }

        let dateValue = String(value[..<dateEndIndex])
        guard let date = Self.observedOnFormatter.date(from: dateValue) else { return nil }

        return (
            date: Self.dateFormatter.string(from: date),
            time: String(value[timeStartIndex..<timeEndIndex])
        )
    }

    private static func visibleText(_ text: String?) -> String? {
        guard let text = text?.trimmingCharacters(in: .whitespacesAndNewlines), !text.isEmpty else {
            return nil
        }
        return text
    }

    private static func plainText(fromHTML html: String?) -> String? {
        guard let html = visibleText(html) else { return nil }
        guard html.contains("<") || html.contains("&") else { return html }

        let withoutParagraphBreaks = html
            .replacingOccurrences(of: #"<br\s*/?>"#, with: " ", options: .regularExpression)
            .replacingOccurrences(of: #"</p>"#, with: " ", options: .regularExpression)
        let withoutTags = withoutParagraphBreaks.replacingOccurrences(
            of: #"<[^>]+>"#,
            with: "",
            options: .regularExpression
        )
        let decodedEntities = withoutTags
            .replacingOccurrences(of: "&amp;", with: "&")
            .replacingOccurrences(of: "&quot;", with: "\"")
            .replacingOccurrences(of: "&#39;", with: "'")
            .replacingOccurrences(of: "&apos;", with: "'")
            .replacingOccurrences(of: "&lt;", with: "<")
            .replacingOccurrences(of: "&gt;", with: ">")
            .replacingOccurrences(of: "&nbsp;", with: " ")

        let normalizedWhitespace = decodedEntities
            .components(separatedBy: .whitespacesAndNewlines)
            .filter { $0.isEmpty == false }
            .joined(separator: " ")

        return visibleText(normalizedWhitespace)
    }

    private static let observedOnFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.calendar = Calendar(identifier: .gregorian)
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter
    }()

    private static let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.calendar = Calendar(identifier: .gregorian)
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.dateFormat = "d MMM yyyy"
        return formatter
    }()

}

private extension ObservationQuality {
    nonisolated var detailDisplayText: String {
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

    nonisolated var detailDisplaySymbol: String? {
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
