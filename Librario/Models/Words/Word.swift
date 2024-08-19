//
//  Word.swift
//  Librario
//
//  Created by Frank Guglielmo on 8/19/24.
//

import SwiftData

@Model
final class Word {
    @Attribute(.unique) var text: String

    init(text: String) {
        self.text = text.lowercased() // Store words in lowercase for consistent validation
    }
}

