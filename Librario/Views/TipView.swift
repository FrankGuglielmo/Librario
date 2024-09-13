//
//  TipView.swift
//  Librario
//
//  Created by Frank Guglielmo on 9/10/24.
//

import SwiftUI

struct TipView: View {
    @Binding var navigationPath: NavigationPath
    
    var body: some View {
        
        ZStack {
            // Background color filling the entire safe area
            Image("red_curtain")
                .resizable()
                .scaledToFill()
                .frame(minWidth: 0)
                .edgesIgnoringSafeArea(.all)
            
            VStack(spacing: 20) {
                Text("Game Tips")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .padding()
                
                VStack(alignment: .leading, spacing: 15) {
                    
                    // Word Linking Section
                    HStack {
                        Image(systemName: "rectangle.grid.2x2.fill")
                            .resizable()
                            .foregroundStyle(Color.orange)
                            .frame(width: 50, height: 50)
                        
                        VStack(alignment: .leading) {
                            Text("Link Letters")
                                .font(.headline)
                                .foregroundStyle(.black)
                            Text("Click on the letters to link them into words. The longer the word, the higher the score.")
                                .font(.body)
                                .foregroundStyle(.gray)
                        }
                    }
                    
                    // Submit Button Section
                    HStack {
                        Image(systemName: "checkmark.square")
                            .resizable()
                            .foregroundStyle(Color.green)
                            .frame(width: 50, height: 50)
                        
                        VStack(alignment: .leading) {
                            Text("Submit Words")
                                .font(.headline)
                                .foregroundStyle(.black)
                            Text("Click on 'Submit' to confirm your word. You earn points based on the word length and tile values.")
                                .font(.body)
                                .foregroundStyle(.gray)
                        }
                    }
                    
                    // Burning Tile Section
                    HStack {
                        Image(systemName: "flame.fill")
                            .resizable()
                            .foregroundStyle(Color.red)
                            .frame(width: 50, height: 50)
                        
                        VStack(alignment: .leading) {
                            Text("Beware of Burning Tiles")
                                .font(.headline)
                                .foregroundStyle(.black)
                            Text("Burning tiles will appear occasionally. If they reach the bottom, it's game over!")
                                .font(.body)
                                .foregroundStyle(.gray)
                        }
                    }
                    
                    // Scramble Feature Section
                    HStack {
                        Image(systemName: "arrow.3.trianglepath")
                            .resizable()
                            .foregroundStyle(Color.yellow)
                            .frame(width: 50, height: 50)
                        
                        VStack(alignment: .leading) {
                            Text("Scramble Letters")
                                .font(.headline)
                                .foregroundStyle(.black)
                            Text("Scramble letters if you can't make a word, but beware, this comes at a cost!")
                                .font(.body)
                                .foregroundStyle(.gray)
                        }
                    }
                    
                    // Reward Tiles Section
                    HStack {
                        Image(systemName: "diamond.fill")
                            .resizable()
                            .foregroundStyle(Color.mint)
                            .frame(width: 50, height: 50)
                        
                        VStack(alignment: .leading) {
                            Text("Special Reward Tiles")
                                .font(.headline)
                                .foregroundStyle(.black)
                            Text("Green, Gold, and Diaomnd tiles appear when making good words. Use them in words for bonus points!")
                                .font(.body)
                                .foregroundStyle(.gray)
                        }
                    }
                }
                .padding()
                
                Button(action: {
                    navigationPath.removeLast()
                }, label: {
                    HStack {
                        Image(systemName: "arrow.left")
                            .font(.title)
                        Text("Back")
                            .font(.headline)
                    }
                    .foregroundStyle(.gray)
                })
                .padding()
                
            }
            .padding()
            .background(Color(.white).cornerRadius(15))
            .shadow(radius: 10)
        }
    }
}


#Preview {
    TipView(navigationPath: .constant(NavigationPath()))
}
