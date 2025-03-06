//
//  LetterGeneratorTests.swift
//  LibrarioTests
//
//  Created by Frank Guglielmo on 8/17/24.
//

//import XCTest
//@testable import Librario
//
//final class LetterGeneratorTests: XCTestCase {
//    
//    var letterGenerator: LetterGenerator!
//
//    override func setUp() {
//        super.setUp()
//        letterGenerator = LetterGenerator()
//    }
//
//    override func tearDown() {
//        letterGenerator = nil
//        super.tearDown()
//    }
//
//    func testSingleLetterGeneration() {
//        let letter = letterGenerator.generateLetter(isWeighted: false)
//        XCTAssertTrue(letterGenerator.letters.contains(letter), "Generated letter should be a valid letter from A-Z or 'Qu'")
//    }
//
//    func testMultipleLetterGeneration() {
//        let letters = letterGenerator.generateLetters(count: 10)
//        XCTAssertEqual(letters.count, 10, "Should generate exactly 10 letters.")
//        for letter in letters {
//            XCTAssertTrue(letterGenerator.letters.contains(letter), "Generated letter should be a valid letter from A-Z or 'Qu'")
//        }
//    }
//
//    func testProbabilityUpdateAfterGeneration() {
//        let initialProbabilities = letterGenerator.currentProbabilities
//        let letter = letterGenerator.generateLetter(isWeighted: true)
//        let index = letterGenerator.letters.firstIndex(of: letter)!
//        let updatedProbabilities = letterGenerator.currentProbabilities
//        XCTAssertNotEqual(initialProbabilities[index], updatedProbabilities[index], "Probability of the generated letter should be reduced.")
//    }
//
//    func testLowProbabilityLettersCanBeGenerated() {
//        let rareLetters = ["Q", "Qu", "Z", "X"]
//        var generatedLetters: [String: Int] = ["Q": 0, "Qu": 0, "Z": 0, "X": 0]
//        for _ in 0..<10000 {
//            let letter = letterGenerator.generateLetter(isWeighted: true)
//            if rareLetters.contains(letter) {
//                generatedLetters[letter]! += 1
//            }
//        }
//        for (letter, count) in generatedLetters {
//            XCTAssertGreaterThan(count, 0, "\(letter) should be generated at least once in 10,000 iterations.")
//        }
//    }
//}
