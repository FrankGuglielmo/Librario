//
//  LetterGenerator.swift
//  Librario
//  This class will be responsible for gathering the next letter
//  to add to the board based on a variety of factors such as what
//  is on the board, letter frequency, and difficulty level
//
//  Created by Frank Guglielmo on 8/17/24.
//

import Foundation


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

class LetterGenerator {
    
    // Minimum threshold for any probability to avoid extremely small values
    let minimumProbability: Double = 0.01
    
    // Base probabilities for each letter, including "Qu"
    let baseProbabilities: [Double] = [
        8.12,  // A (common)
        1.49,  // B (less common)
        2.71,  // C (less common)
        4.32,  // D (moderately common)
        12.02, // E (very common)
        2.30,  // F (less common)
        2.03,  // G (moderately common)
        5.92,  // H (common)
        7.31,  // I (common)
        0.10,  // J (rare)
        0.69,  // K (rare)
        3.98,  // L (common)
        2.61,  // M (moderately common)
        6.95,  // N (common)
        7.68,  // O (common)
        1.82,  // P (less common)
        0.12,  // Q (rare)
        6.02,  // R (common)
        6.28,  // S (common)
        9.10,  // T (common)
        2.88,  // U (moderately common)
        1.11,  // V (less common)
        2.09,  // W (less common)
        0.17,  // X (rare)
        2.11,  // Y (less common)
        0.07   // Z (rare)
    ]
    
    // These probabilities will be dynamic and change as more letters are generated
    var currentProbabilities: [Double]
    
    // Letters corresponding to the probabilities (A-Z + "Qu")
    let letters = [
        "A", "B", "C", "D", "E", "F", "G", "H", "I", "J", "K", "L", "M",
        "N", "O", "P", "Q", "R", "S", "T", "U", "V", "W", "X", "Y", "Z"
    ]
    
    // Reduction percentages for each letter (A-Z + "Qu")
    let reductionPercentages: [Double] = [
        30.0,  // A
        60.0,  // B
        55.0,  // C
        50.0,  // D
        25.0,  // E
        55.0,  // F
        50.0,  // G
        35.0,  // H
        30.0,  // I
        70.0,  // J
        65.0,  // K
        40.0,  // L
        50.0,  // M
        35.0,  // N
        30.0,  // O
        55.0,  // P
        70.0,  // Q
        40.0,  // R
        35.0,  // S
        30.0,  // T
        50.0,  // U
        60.0,  // V
        60.0,  // W
        70.0,  // X
        55.0,  // Y
        70.0   // Z
    ]
    
    init() {
        self.currentProbabilities = baseProbabilities
    }

    //TODO: Refactor isWeighted parameter. Need one that uses base probability and one that uses dynamic probabilities.
    // Function to generate a letter based on the current probabilities
    func generateLetter(isWeighted: Bool) -> String {
        // Sum of all letter probabiblities, should be ~100.0
        let totalProbability = currentProbabilities.reduce(0, +)
        let randomValue = Double.random(in: 0..<totalProbability)
        var cumulativeProbability: Double = 0.0
        
        // Increment the index and current probability until it falls within letter threshhold
        for (index, probability) in currentProbabilities.enumerated() {
            cumulativeProbability += probability
            if randomValue < cumulativeProbability {
                var selectedLetter = letters[index]
                // Special logic if letter is a Q. Returns either Q or Qu.
                if selectedLetter == "Q" {
                    selectedLetter = generateQorQu()
                }
                //TODO: Try and make this more efficient
                if isWeighted {
                    updateProbabilities(for: index)
                }
                return selectedLetter
            }
        }
        return letters[0] // Return "A" as a fallback
    }

    
    // Function to generate a collection of n letters
    func generateLetters(count: Int) -> [String] {
        var generatedLetters: [String] = []
        for _ in 0..<count {
            generatedLetters.append(generateLetter(isWeighted: true))
        }
        return generatedLetters
    }
    
    // Function to update probabilities after a letter is selected
    func updateProbabilities(for selectedIndex: Int) {
        let selectedProbability = currentProbabilities[selectedIndex]
        let reductionPercentage = reductionPercentages[selectedIndex]
        let deduction = selectedProbability * reductionPercentage / 100.0
        
        let smallestIndices = findSmallestProbabilities(limit: 6, excluding: selectedIndex)
        let redistribution = deduction / Double(smallestIndices.count)
        
        currentProbabilities[selectedIndex] -= deduction
        
        for index in smallestIndices {
            let newProbability = currentProbabilities[index] + redistribution
            currentProbabilities[index] = max(newProbability, minimumProbability)
        }
        
        normalizeProbabilities()
    }
    
    // Function to find the indices of the smallest probabilities, excluding the selected index
    private func findSmallestProbabilities(limit: Int, excluding excludedIndex: Int) -> [Int] {
        let indexedProbabilities = currentProbabilities.enumerated().filter { $0.offset != excludedIndex }
        let smallestIndices = indexedProbabilities.sorted(by: { $0.element < $1.element })
                                                .prefix(limit)
                                                .map { $0.offset }
        
        return smallestIndices
    }
    
    // Normalize the probability distribution
    private func normalizeProbabilities() {
        let total = currentProbabilities.reduce(0, +)
        for i in 0..<currentProbabilities.count {
            currentProbabilities[i] = (currentProbabilities[i] / total) * 100.0
        }
    }
    
    // Function to reset probabilities back to base
    func resetProbabilities() {
        self.currentProbabilities = baseProbabilities
    }
    
    func generateQorQu() -> String {
        let qProbability = Double.random(in: 0..<1.0)
        if qProbability < 1.0 / 3.0 {
            return "Q"
        } else {
            return "Qu"
        }
    }
}
