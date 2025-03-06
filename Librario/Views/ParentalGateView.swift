//
//  ParentalGateView.swift
//  Librario
//
//  Created by Frank Guglielmo on 10/16/24.
//
import SwiftUI
import GameKit

struct ParentalGateView: View {
    @Binding var isParentalGatePassed: Bool
    @Environment(\.presentationMode) var presentationMode
    @Environment(\.horizontalSizeClass) var horizontalSizeClass
    @State private var selectedAnswer: String? = nil
    @State private var question: String = ""
    @State private var answers: [String] = []
    @State private var correctAnswer: String = ""
    @State private var showError = false

    // Reference to the Game Center dashboard function
    var presentGameCenterDashboard: () -> Void

    // List of questions and answers
    let questionsAndAnswers = [
        ("What is the capital city of France?", ["Berlin", "Madrid", "Paris", "Rome"], "Paris"),
        ("What is the square root of 64?", ["6", "7", "8", "9"], "8"),
        ("Who wrote 'Romeo and Juliet'?", ["Charles Dickens", "William Shakespeare", "Mark Twain", "Jane Austen"], "William Shakespeare"),
        ("What is the chemical symbol for water?", ["O2", "CO2", "H2O", "H2O2"], "H2O"),
        ("How many continents are there?", ["6", "7", "8", "5"], "7"),
        ("Who painted the 'Mona Lisa'?", ["Pablo Picasso", "Leonardo da Vinci", "Vincent van Gogh", "Claude Monet"], "Leonardo da Vinci"),
        ("What is the tallest mountain in the world?", ["Mount Kilimanjaro", "Mount Everest", "Mount Fuji", "K2"], "Mount Everest")
    ]

    var body: some View {
        VStack {
            Spacer()

            Text("Parental Gate")
                .font(.system(size: horizontalSizeClass == .compact ? 30 : 40))
                .padding()

            Text("You're about to access the Game Center leaderboards, which may allow you to visit the App Store. To ensure you're browsing safely, we need to confirm you have parental permission before viewing external content from the Librario app.")
                .font(.system(size: horizontalSizeClass == .compact ? 16 : 20))
                .padding()

            Text(question)
                .font(.system(size: horizontalSizeClass == .compact ? 20 : 25))
                .multilineTextAlignment(.center)
                .padding()

            Spacer()

            // List of answers as buttons
            ForEach(answers, id: \.self) { answer in
                Button(action: {
                    selectedAnswer = answer
                }) {
                    Text(answer)
                        .font(.system(size: horizontalSizeClass == .compact ? 18 : 22))
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(selectedAnswer == answer ? Color.blue.opacity(0.2) : Color.white)
                        .foregroundColor(.black)
                        .cornerRadius(10)
                        .overlay(
                            RoundedRectangle(cornerRadius: 10)
                                .stroke(selectedAnswer == answer ? Color.blue : Color.gray, lineWidth: 2)
                        )
                        .padding(.horizontal)
                }
            }

            Spacer()

            if showError {
                Text("Incorrect answer, try again.")
                    .foregroundColor(.red)
                    .padding()
            }

            Button("Submit") {
                if selectedAnswer == correctAnswer {
                    // Mark parental gate as passed
                    isParentalGatePassed = true

                    // Dismiss the ParentalGateView first
                    self.presentationMode.wrappedValue.dismiss()

                    // Delay the presentation of Game Center to allow time for sheet to dismiss
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                        presentGameCenterDashboard()
                    }
                } else {
                    showError = true
                }
            }
            .font(.system(size: horizontalSizeClass == .compact ? 20 : 24, weight: .bold))
            .padding()
            .background(Color.blue)
            .foregroundColor(.white)
            .cornerRadius(10)

            Spacer()
        }
        .padding()
        .onAppear {
            setupQuestion()
        }
    }

    // Function to set up a question and its answers when the view appears
    func setupQuestion() {
        let selectedQA = questionsAndAnswers.randomElement()!
        self.question = selectedQA.0
        self.answers = selectedQA.1.shuffled() // Shuffle the answers to randomize the order
        self.correctAnswer = selectedQA.2
    }
}

#Preview {
    ParentalGateView(isParentalGatePassed: .constant(false), presentGameCenterDashboard: {})
}
