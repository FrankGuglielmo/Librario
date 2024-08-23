//
//  DictionaryManager.swift
//  Librario
//
//  Created by Frank Guglielmo on 8/22/24.
//

import SwiftUI
import Foundation

class DictionaryManager: ObservableObject {
    @Published var wordDictionary: [String: String?] = [:]

    init() {
        loadDictionary()
    }

    func loadDictionary() {
        // Check if the dictionary has been saved to disk before
        if let loadedDictionary = loadDictionaryFromFile() {
            wordDictionary = loadedDictionary
        } else {
            // If not, load it from the JSON file in the app bundle
            if let initialDictionary = loadDictionaryFromJSON() {
                // Save to disk for future runs
                saveDictionaryToFile(initialDictionary)
                wordDictionary = initialDictionary
            }
        }
    }

    private func loadDictionaryFromJSON() -> [String: String?]? {
        guard let url = Bundle.main.url(forResource: "valid_words", withExtension: "json") else {
            print("Failed to locate valid_words.json in bundle.")
            return nil
        }

        do {
            let data = try Data(contentsOf: url)
            let dictionary = try JSONDecoder().decode([String: String?].self, from: data)
            print("Dictionary successfully loaded from words.json.")
            return dictionary
        } catch {
            print("Error loading or parsing words.json: \(error)")
            return nil
        }
    }

    private func saveDictionaryToFile(_ dictionary: [String: String?]) {
        let filePath = getDocumentsDirectory().appendingPathComponent("dictionary.dat")
        
        do {
            let data = try NSKeyedArchiver.archivedData(withRootObject: dictionary, requiringSecureCoding: false)
            try data.write(to: filePath)
            print("Dictionary successfully saved to disk.")
        } catch {
            print("Failed to save dictionary to file: \(error)")
        }
    }

    private func loadDictionaryFromFile() -> [String: String?]? {
        let filePath = getDocumentsDirectory().appendingPathComponent("dictionary.dat")
        
        do {
            let data = try Data(contentsOf: filePath)
            if let dictionary = try NSKeyedUnarchiver.unarchivedObject(ofClasses: [NSDictionary.self, NSString.self, NSNull.self], from: data) as? [String: String?] {
                print("Dictionary successfully loaded from disk.")
                return dictionary
            } else {
                print("Failed to decode dictionary from file.")
                return nil
            }
        } catch {
            print("Failed to load dictionary from file: \(error)")
            return nil
        }
    }
    
    private func getDocumentsDirectory() -> URL {
        let paths = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)
        return paths[0]
    }
    
    func getDefinition(for word: String) -> String? {
        return wordDictionary[word] ?? nil
    }
}

