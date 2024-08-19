//
//  WordStore.swift
//  Librario
//
//  Created by Frank Guglielmo on 8/19/24.
//

class WordStore {
    private let validWords: Set<String>

    init() {
        // Initialize with 20 valid 3-letter words
        self.validWords = [
            "cat", "dog", "bat", "rat", "hat",
            "mat", "pat", "sat", "fat", "tan",
            "fan", "can", "man", "ran", "van",
            "cap", "nap", "map", "tap", "lap"
        ]
    }

    func isWordValid(_ word: String) -> Bool {
        return validWords.contains(word.lowercased())
    }
}
