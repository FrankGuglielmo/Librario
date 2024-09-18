//
//  StrokedText.swift
//  Librario
//
//  Created by Frank Guglielmo on 9/17/24.
//

import SwiftUI

import SwiftUI

struct StrokedText: UIViewRepresentable {
    var text: String
    var fontName: String
    var fontSize: CGFloat
    var strokeColor: UIColor
    var strokeWidth: CGFloat
    var foregroundColor: UIColor

    func makeUIView(context: Context) -> UILabel {
        let label = UILabel()
        label.numberOfLines = 0
        label.attributedText = attributedString
        return label
    }

    func updateUIView(_ uiView: UILabel, context: Context) {
        uiView.attributedText = attributedString
    }

    var attributedString: NSAttributedString {
        let font = UIFont(name: fontName, size: fontSize) ?? UIFont.systemFont(ofSize: fontSize)
        let attributes: [NSAttributedString.Key: Any] = [
            .font: font,
            .foregroundColor: foregroundColor,
            .strokeColor: strokeColor,
            .strokeWidth: strokeWidth
        ]
        return NSAttributedString(string: text, attributes: attributes)
    }
}

