//
//  PathStore.swift
//  Librario
//
//  Created by Frank Guglielmo on 9/6/24.
//

import Foundation
import SwiftUI

class PathStore: ObservableObject {
    @Published var path: NavigationPath = NavigationPath()

    // This array mirrors the path and will be persisted
    @Published var viewTypes: [ViewType] = [] {
        didSet {
            save()
        }
    }

    private let savePath = URL.documentsDirectory.appendingPathComponent("SavedPath")

    init() {
        load()
    }

    func appendView(_ viewType: ViewType) {
        // Prevent appending the same view if it's already in the path
        guard !viewTypes.contains(viewType) else { return }

        viewTypes.append(viewType)
        path.append(viewType)
    }

    func save() {
        guard let data = try? JSONEncoder().encode(viewTypes) else {
            print("Failed to encode viewTypes")
            return
        }

        do {
            try data.write(to: savePath)
        } catch {
            print("Failed to save navigation data to disk: \(error.localizedDescription)")
        }
    }

    func load() {
        if let data = try? Data(contentsOf: savePath),
           let decodedViewTypes = try? JSONDecoder().decode([ViewType].self, from: data) {
            viewTypes = decodedViewTypes
            // Rebuild the navigation path from the saved viewTypes
            path = NavigationPath() // Clear the path first
            for viewType in viewTypes {
                path.append(viewType)
            }
        }
    }
}





