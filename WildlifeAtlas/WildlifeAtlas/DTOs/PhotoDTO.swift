//
//  PhotoDTO.swift
//  WildlifeAtlas
//
//  Created by Artur Bagautdinov on 07.09.2026.
//

import Foundation

nonisolated struct PhotoDTO: Decodable {
    let id: Int
    let url: String?
    let squareURL: String?
    let mediumURL: String?
    let attribution: String?
    let licenseCode: String?

    enum CodingKeys: String, CodingKey {
        case id
        case url
        case squareURL = "square_url"
        case mediumURL = "medium_url"
        case attribution
        case licenseCode = "license_code"
    }

    func toDomain() -> ObservationPhoto {
        ObservationPhoto(
            id: id,
            squareURL: (squareURL ?? url).flatMap(URL.init(string:)),
            mediumURL: (mediumURL ?? url).flatMap(URL.init(string:)),
            attribution: attribution,
            licenseCode: licenseCode
        )
    }
}
