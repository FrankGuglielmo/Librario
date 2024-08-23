////
////  WordStore.swift
////  Librario
////
////  Created by Frank Guglielmo on 8/19/24.
////
//
//import SwiftData
//import SwiftUI
//import Foundation
//
//class WordStore: ObservableObject {
//    @Query var words: [Word]
//    @Environment(\.modelContext) private var modelContext
//
//    init() {
//        self._words = Query()
//        if words.isEmpty {
//            loadWordsFromJSONIfNeeded(fileName: "valid_words") // Replace with your actual file name
//        }
////    }
//
//    func addWord(_ word: String, definition: String?) {
//        let newWord = Word(text: word, definition: definition)
//        modelContext.insert(newWord)
//    }
//
//    func deleteWord(_ word: Word) {
//        modelContext.delete(word)
//    }
//
//    func updateWord(_ word: Word, newText: String, newDefinition: String?) {
//        word.text = newText.lowercased()
//        word.definition = newDefinition
//        // SwiftData automatically tracks changes and will persist them
//    }
//    
//    private func loadWordsFromJSONIfNeeded(fileName: String) {
//        let wordsFromFile = loadWordsFromJSON(named: fileName)
//        for (word, definition) in wordsFromFile {
//            addWord(word, definition: definition.isEmpty ? nil : definition)
//        }
//    }
//
//    private func loadWordsFromJSON(named fileName: String) -> [String: String] {
//        guard let url = Bundle.main.url(forResource: fileName, withExtension: "json") else {
//            print("File not found")
//            return [:]
//        }
//        
//        do {
//            let data = try Data(contentsOf: url)
//            let words = try JSONDecoder().decode([String: String].self, from: data)
//            return words
//        } catch {
//            print("Failed to read or decode file: \(error.localizedDescription)")
//            return [:]
//        }
//    }
//
//    func isValidWord(_ word: String) -> Bool {
//        return words.contains { $0.text == word.lowercased() }
//    }
//}
