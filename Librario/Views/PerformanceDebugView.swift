//
//  PerformanceDebugView.swift
//  Librario
//
//  Created by Frank Guglielmo on 3/5/25.
//

import SwiftUI

struct PerformanceDebugView: View {
    @ObservedObject var tileManager: TileManager
    @State private var isExpanded: Bool = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Button(action: {
                isExpanded.toggle()
            }) {
                HStack {
                    Image(systemName: "gauge")
                        .foregroundColor(.white)
                    
                    Text("Performance")
                        .font(.caption)
                        .foregroundColor(.white)
                    
                    Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                        .foregroundColor(.white)
                        .font(.caption)
                }
                .padding(6)
                .background(Color.black.opacity(0.6))
                .cornerRadius(8)
            }
            
            if isExpanded {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Last selection: \(formatTime(tileManager.getLastSelectionTime()))")
                        .font(.caption)
                        .foregroundColor(.white)
                    
                    Text("Avg selection: \(formatTime(tileManager.getAverageSelectionTime()))")
                        .font(.caption)
                        .foregroundColor(.white)
                }
                .padding(6)
                .background(Color.black.opacity(0.6))
                .cornerRadius(8)
            }
        }
        .padding(8)
    }
    
    private func formatTime(_ time: TimeInterval) -> String {
        return String(format: "%.2f ms", time * 1000)
    }
}

#Preview {
    // Create a mock TileManager for preview
    let performanceEvaluator = PerformanceEvaluator()
    let letterGenerator = LetterGenerator(performanceEvaluator: performanceEvaluator)
    let tileTypeGenerator = TileTypeGenerator(performanceEvaluator: performanceEvaluator)
    let tileGenerator = TileGenerator(letterGenerator: letterGenerator, tileTypeGenerator: tileTypeGenerator, performanceEvaluator: performanceEvaluator)
    let tileConverter = TileConverter()
    let wordChecker = WordChecker(wordStore: [:])
    let tileManager = TileManager(tileGenerator: tileGenerator, tileConverter: tileConverter, wordChecker: wordChecker, performanceEvaluator: performanceEvaluator)
    
    return PerformanceDebugView(tileManager: tileManager)
        .background(Color.gray)
}
