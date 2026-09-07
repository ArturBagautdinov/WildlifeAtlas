//
//  ImageLoader.swift
//  WildlifeAtlas
//
//  Created by Artur Bagautdinov on 07.09.2026.
//

import UIKit

nonisolated protocol ImageLoader {
    func image(from url: URL) async throws -> UIImage
}
