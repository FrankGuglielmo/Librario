//
//  PathStore.swift
//  Librario
//
//  Created by Frank Guglielmo on 9/6/24.
//

import SwiftUI

@Observable class PathStore {
    
    // Store the NavigationPath
    var path: NavigationPath {
        didSet {
            save()
        }
    }

    // Path to save the navigation state
    private let savePath = URL.documentsDirectory.appending(path: "SavedPath")
    
    // Initialize the path, trying to restore it from saved data
    init() {
        if let data = try? Data(contentsOf: savePath) {
            if let decoded = try? JSONDecoder().decode(NavigationPath.CodableRepresentation.self, from: data) {
                path = NavigationPath(decoded)
                return
            }
        }
        
        // If no saved data, start with an empty path
        path = NavigationPath()
    }

    // Save the navigation state to disk
    func save() {
        guard let representation = path.codable else { return }
        
        do {
            let data = try JSONEncoder().encode(representation)
            try data.write(to: savePath)
        } catch {
            print("Failed to save navigation data")
        }
    }
}




