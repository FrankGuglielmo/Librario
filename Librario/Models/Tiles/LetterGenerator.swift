//
//  LetterGenerator.swift
//  Librario
//  This class will be responsible for gathering the next letter
//  to add to the board based on a variety of factors such as what
//  is on the board, letter frequency, and difficulty level
//
//  Created by Frank Guglielmo on 8/17/24.
//

/*
    Things that affect letter generation:
        - Level: At higher levels, provide more difficult letters to make words with.
        This is so that players will have to be more wise with tiles such as vowel tiles
        to make words. A player at a high level should have the vocabulary and skill necessary
        to be efficient with their tiles, and having level impact the amount of common letters
        make it more challenging.
 
        - Previous Letter generated: For example, if an 'E' is produced, the probability of getting
        another 'E' should be decreased, and gradually re-align itself back to it's base probability
        until it is picked again. We lower the probability, but do not make it 0 so that it's still
        possible to get two in a row.
 
        - Letter Rarity: Letters will have a base probability based on how many known words exist
        with the given letter. For example, 'X' should not have an equal probability of occuring than
        'A' since there are far less use cases for the 'X' tile than the 'A' tile.
        Base probabilities: https://pi.math.cornell.edu/~mec/2003-2004/cryptography/subs/frequencies.html
 
 */

import Foundation

class LetterGenerator: Codable {
    
    private var vowels = ["A", "E", "I", "O", "U"]
    private var consonants = [
        "B", "C", "D", "F", "G", "H", "J", "K", "L", "M",
        "N", "P", "Q", "R", "S", "T", "V", "W", "X", "Y", "Z"
    ]
    
    var vowelProbabilities: [Double] = [21.36, 31.62, 19.23, 20.21, 7.58]
    var consonantProbabilities: [Double] = [
        2.32,  4.23,  6.74,  3.59,  3.16,  9.24,  1.00,  1.09,  6.21,  4.07,
        10.84, 2.84,  1.00,  9.39,  9.80, 14.20,  1.73,  3.27,  1.00,  3.29, 1.00
    ]
    
    var lastGeneratedLetter: String? = nil
    
    // Reference to PerformanceEvaluator
    private let performanceEvaluator: PerformanceEvaluator
    
    // Base vowel probability (adjustable based on performance and grid)
    private var baseVowelProbability: Double = 50.0
    
    // Original probabilities to reset after adjustments
    private let originalVowelProbabilities: [Double]
    private let originalConsonantProbabilities: [Double]
    private var originalBaseVowelProbability: Double = 55.9
    
    private var recentLetters: [String] = []
    private var maxRecentLetters: Int = 3  // Adjust this value as needed
    
    init(performanceEvaluator: PerformanceEvaluator) {
        self.performanceEvaluator = performanceEvaluator
        self.originalVowelProbabilities = vowelProbabilities
        self.originalConsonantProbabilities = consonantProbabilities
    }
    
    // Function to generate a letter based on the current probabilities
    func generateLetter(for grid: [[Tile]]) -> String {
        // Reset probabilities to base values before adjustments
        resetProbabilities()
        
        // Adjust probabilities based on performance and grid state
        adjustProbabilities()
        adjustForGridBalance(grid: grid)
        
        // Step 1: Count vowels in the grid and calculate maximum allowed vowels
        let totalTileCount = grid.count * grid[0].count
        let maxAllowedVowels = totalTileCount / 2
        var currentVowelCount = 0
        
        for row in grid {
            for tile in row {
                if vowels.contains(tile.letter) {
                    currentVowelCount += 1
                }
            }
        }
        
        // Step 2: If vowels exceed half the board, adjust the vowel probability
        if currentVowelCount >= maxAllowedVowels {
            baseVowelProbability = 0.0 // Prevent generating vowels if limit is reached
        }
        
        // Adjust probabilities based on vowel counts in the grid
        adjustForVowelFrequency(grid: grid)
        
        var vowelProbability = baseVowelProbability  // Starting vowel probability
        
        // Influence probability based on the last generated letter
        if let lastLetter = lastGeneratedLetter {
            if vowels.contains(lastLetter) {
                vowelProbability -= 10.0  // Decrease vowel chance if the last was a vowel
            } else {
                vowelProbability += 10.0  // Increase vowel chance if the last was a consonant
            }
        }
        
        // Adjust the probability of recently generated letters
        adjustForRecentLetters()
        
        // Ensure vowelProbability stays within bounds (20-80) unless the grid is full of vowels
        vowelProbability = max(0.0, min(80.0, vowelProbability))
        
        let letterTypeProbability = Double.random(in: 0..<100)
        var selectedLetter: String = ""
        
        // Helper function to select a letter
        func selectLetter(from letters: [String], with probabilities: [Double]) -> String? {
            let randomProbability = Double.random(in: 0..<100)
            var cumulativeProbability: Double = 0.0
            for (index, probability) in probabilities.enumerated() {
                cumulativeProbability += probability
                if randomProbability < cumulativeProbability {
                    if letters[index] == "Q" { // Calculate Q or Qu tile
                        return generateQorQu()
                    } else {
                        return letters[index]
                    }
                }
            }
            return nil
        }
        
        // Generate either a vowel or a consonant
        if letterTypeProbability < vowelProbability {
            selectedLetter = selectLetter(from: vowels, with: vowelProbabilities) ?? vowels[0]
        } else {
            selectedLetter = selectLetter(from: consonants, with: consonantProbabilities) ?? consonants[0]
        }
        
        // Prevent generating a duplicate letter immediately
        while recentLetters.contains(selectedLetter) {
            selectedLetter = (letterTypeProbability < vowelProbability)
                ? selectLetter(from: vowels, with: vowelProbabilities) ?? vowels[0]
                : selectLetter(from: consonants, with: consonantProbabilities) ?? consonants[0]
        }
        
        // Update the last generated letter and the recent letters list
        lastGeneratedLetter = selectedLetter
        updateRecentLetters(with: selectedLetter)
        
        return selectedLetter
    }

        
        // Adjust probabilities for recently generated letters
        private func adjustForRecentLetters() {
            for recentLetter in recentLetters {
                if let vowelIndex = vowels.firstIndex(of: recentLetter) {
                    vowelProbabilities[vowelIndex] *= 0.5  // Reduce probability for recent vowels
                } else if let consonantIndex = consonants.firstIndex(of: recentLetter) {
                    consonantProbabilities[consonantIndex] *= 0.5  // Reduce probability for recent consonants
                }
            }
            
            // Normalize probabilities after adjustment
            normalizeProbabilities(&vowelProbabilities)
            normalizeProbabilities(&consonantProbabilities)
        }
        
        // Update the recent letters list, ensuring it doesn't exceed the maxRecentLetters size
        private func updateRecentLetters(with letter: String) {
            recentLetters.append(letter)
            if recentLetters.count > maxRecentLetters {
                recentLetters.removeFirst()
            }
        }

    // Function to adjust vowel probabilities based on their frequency in the grid
    private func adjustForVowelFrequency(grid: [[Tile]]) {
        var vowelCounts: [String: Int] = ["A": 0, "E": 0, "I": 0, "O": 0, "U": 0]
        
        // Count the number of vowels in the current grid
        for row in grid {
            for tile in row {
                let letter = tile.letter  // Assuming tile.letter is a String, not an Optional
                if vowels.contains(letter) {
                    vowelCounts[letter, default: 0] += 1
                }
            }
        }
        
        // Total vowel count in the grid
        let totalVowelCount = vowelCounts.values.reduce(0, +)
        
        // Adjust probabilities based on vowel counts
        let totalProbability: Double = 100.0
        let baseProbability: Double = totalProbability / Double(vowels.count)
        
        for (index, vowel) in vowels.enumerated() {
            let count = vowelCounts[vowel, default: 0]
            
            // Calculate the reduction factor based on how many of this vowel are already on the grid
            let reductionFactor = 1.0 - (Double(count) / Double(totalVowelCount))  // The more of this vowel, the lower the probability
            
            // Adjust the vowel probability
            vowelProbabilities[index] = max(baseProbability * reductionFactor, 1.0)  // Ensure no probability goes below 1.0
        }
        
        // Normalize probabilities to make sure they sum to 100
        normalizeProbabilities(&vowelProbabilities)
    }


    // Helper function to normalize probabilities so they sum to 100
    private func normalizeProbabilities(_ probabilities: inout [Double]) {
        let total = probabilities.reduce(0, +)
        if total > 0 {
            probabilities = probabilities.map { $0 / total * 100 }
        }
    }

    // Adjust probabilities based on performance using your PerformanceEvaluator
    private func adjustProbabilities() {
        // Adjust based on hot streak
        if performanceEvaluator.isHotStreak {
            // Decrease vowel probability to increase difficulty
            baseVowelProbability -= 5.0
            adjustVowelProbabilities(factor: 0.9)
            adjustConsonantProbabilities(factor: 1.1)
        }
        
        // Ensure baseVowelProbability stays within 30% to 60%
        baseVowelProbability = max(30.0, min(60.0, baseVowelProbability))
    }
    
    private func resetProbabilities() {
        // Reset to original probabilities
        vowelProbabilities = originalVowelProbabilities
        consonantProbabilities = originalConsonantProbabilities
        baseVowelProbability = originalBaseVowelProbability
    }
    
    private func adjustVowelProbabilities(factor: Double) {
        for i in 0..<vowelProbabilities.count {
            vowelProbabilities[i] *= factor
        }
    }
    
    private func adjustConsonantProbabilities(factor: Double) {
        for i in 0..<consonantProbabilities.count {
            consonantProbabilities[i] *= factor
        }
    }
    
    // Adjustments based on the grid
    
    // 1. Balance the vowel-consonant ratio on the grid
    private func adjustForGridBalance(grid: [[Tile]]) {
        let flatGrid = grid.flatMap { $0 }
        let vowelCount = flatGrid.filter { vowels.contains($0.letter) }.count
        let consonantCount = flatGrid.filter { consonants.contains($0.letter) }.count
        
        let totalLetters = vowelCount + consonantCount
        guard totalLetters > 0 else { return } // Avoid division by zero
        
        let vowelRatio = Double(vowelCount) / Double(totalLetters)
        
        // Target vowel ratio (e.g., 40% vowels)
        let targetVowelRatio = 0.4
        
        if vowelRatio < targetVowelRatio {
            // Increase vowel probability
            baseVowelProbability += 2.0
        } else if vowelRatio > targetVowelRatio {
            // Decrease vowel probability
            baseVowelProbability -= 2.0
        }
        
        // Ensure baseVowelProbability stays within bounds
        baseVowelProbability = max(20.0, min(50.0, baseVowelProbability))
    }
    
    private func increaseProbability(for letter: String) {
        if let vowelIndex = vowels.firstIndex(of: letter) {
            vowelProbabilities[vowelIndex] *= 1.2
        } else if let consonantIndex = consonants.firstIndex(of: letter) {
            consonantProbabilities[consonantIndex] *= 1.2
        }
    }
    
    // Function to generate a collection of n letters
    func generateLetters(count: Int, grid: [[Tile]]) -> [String] {
        var generatedLetters: [String] = []
        for _ in 0..<count {
            generatedLetters.append(generateLetter(for: grid))
        }
        return generatedLetters
    }
    
    // Function to generate "Q" or "Qu" (if needed)
    func generateQorQu() -> String {
        let qProbability = Double.random(in: 0..<1.0)
        if qProbability < (1.0 / 3.0) {
            return "Q"
        } else {
            return "Qu"
        }
    }
}

