//
//  PerformanceEvaluator.swift
//  Librario
//
//  Created by Frank Guglielmo on 9/14/24.
//

import Foundation

class PerformanceEvaluator: Codable {
    
    // Track streaks
    var hotStreakCounter: Int = 0
    var coldStreakCounter: Int = 0
    var hotStreakThreshold = 3
    var coldStreakThreshold = 3

    
    var isHotStreak: Bool {
        return hotStreakCounter >= hotStreakThreshold
    }
    
    var isColdStreak: Bool {
        return coldStreakCounter >= coldStreakThreshold
    }
    
    private enum CodingKeys: String, CodingKey {
        case hotStreakCounter, coldStreakCounter
    }
    
    init(){}
    
    required init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.hotStreakCounter = try container.decode(Int.self, forKey: .hotStreakCounter)
        self.coldStreakCounter = try container.decode(Int.self, forKey: .coldStreakCounter)
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(hotStreakCounter, forKey: .hotStreakCounter)
        try container.encode(coldStreakCounter, forKey: .coldStreakCounter)
    }
    
    func savePerformanceEvaluator() {
        let fileURL = PerformanceEvaluator.getDocumentsDirectory().appendingPathComponent("performanceEvaluator.json")
        do {
            let data = try JSONEncoder().encode(self)
            try data.write(to: fileURL)
            print("Performance Evaluator saved successfully.")
        } catch {
            print("Failed to save performance evaluator: \(error)")
        }
    }

    static func loadPerformanceEvaluator() -> PerformanceEvaluator? {
        let fileURL = getDocumentsDirectory().appendingPathComponent("performanceEvaluator.json")
        do {
            let data = try Data(contentsOf: fileURL)
            let performanceEvaluator = try JSONDecoder().decode(PerformanceEvaluator.self, from: data)
            return performanceEvaluator
        } catch {
            print("Failed to load performance evaluator: \(error)")
            return nil
        }
    }

    // Helper function to get the documents directory
    static func getDocumentsDirectory() -> URL {
        return FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
    }
    
    // Update performance based on last word submitted
    func updatePerformance(lastWord: String, lastWordScore: Int) {
        let lastWordLength = lastWord.count
        // Evaluate streaks
        evaluateStreaks(lastWordScore: lastWordScore, lastWordLength: lastWordLength)
    }

    // Evaluate whether player is on a hot/cold streak
    private func evaluateStreaks(lastWordScore: Int, lastWordLength: Int) {
        if lastWordScore > 650 || lastWordLength > 4 {
            hotStreakCounter += 1
            coldStreakCounter = 0
        } else if lastWordScore < 450 {
            coldStreakCounter += 1
            hotStreakCounter = 0
        } else {
            coldStreakCounter = 0
            hotStreakCounter = 0
        }
    }

    // Check performance trends
    func checkPerformanceTrends() -> String {
        if hotStreakCounter >= hotStreakThreshold {
            return "Hot Streak: \(hotStreakCounter)"
        } else if coldStreakCounter >= coldStreakThreshold {
            return "Cold Streak: \(coldStreakCounter)"
        }
        return "Neutral"
    }

}
