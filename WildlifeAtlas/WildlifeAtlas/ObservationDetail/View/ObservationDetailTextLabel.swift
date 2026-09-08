//
//  ObservationDetailTextLabel.swift
//  WildlifeAtlas
//
//  Created by Artur Bagautdinov on 08.09.2026.
//

import UIKit

final class ObservationDetailTextLabel: UILabel {
    init(font: UIFont, color: UIColor, lines: Int) {
        super.init(frame: .zero)
        self.font = font
        adjustsFontForContentSizeCategory = true
        textColor = color
        numberOfLines = lines
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("Use init(font:color:lines:) instead.")
    }

    func setDetailText(_ text: String?) {
        self.text = text
        isHidden = text == nil
    }
}
