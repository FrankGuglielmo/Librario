////
////  ControlPanelView.swift
////  Librario
////
////  Created by Frank Guglielmo on 8/18/24.
////
//
//import SwiftUI
//
//struct ControlPanelView: View {
//    @EnvironmentObject var dictionaryManager: DictionaryManager
//    @ObservedObject var gameState: GameState
//    @ObservedObject var tileManager: TileManager
//
//    var body: some View {
//        GeometryReader { geometry in
//            VStack {
//                //Header
//                VStack {
//                    Text("Librario")
//                        .font(.largeTitle)
//                        .padding()
//                    HStack{
//                        Image("nervous_sprite(1)")
//                        
//                    }
//                }
//                
//                
//                //Center
//                
//                VStack (spacing: 0){
//                    NavigationLink(destination: GameView().navigationBarBackButtonHidden(true)) {
//                        ZStack {
//                            Image("Title_Book_1")
//                            Text("Classic Game")
//                                .font(.title)
//                                .foregroundStyle(.white)
//                        }
//                    }
//                    
//                    
//                    NavigationLink(destination: SettingsView(), label: {
//                        ZStack {
//                            Image("Title_Book_1")
//                            Text("Classic Game")
//                                .font(.title)
//                                .foregroundStyle(.white)
//                        }
//                    })
//                    
//                }
//                .padding()
//                
//                //Footer
//                HStack {
//                    NavigationLink(destination: {
//                        SettingsView()
//                    }, label: {
//                        VStack{
//                            Image(systemName: "gear")
//                                .font(.title)
//                                .padding()
//                                .background(Color.white)
//                            Text("Settings")
//                                .font(.title3)
//                                .foregroundStyle(.white)
//                        }
//                    })
//                    .padding()
//                    NavigationLink(destination: StatsView(), label: {
//                        
//                        VStack {
//                            Image(systemName: "chart.line.uptrend.xyaxis")
//                                .font(.title)
//                                .padding()
//                                .background(Color.white)
//                                .foregroundStyle(.green)
//                            Text("Stats")
//                                .font(.title3)
//                                .foregroundStyle(.white)
//                        }
//                    })
//                    .padding()
//                }
//            }
//            .frame(width: geometry.size.width, height: geometry.size.height)
//            .background(Color(red: 0.55, green: 0.0, blue: 0.0))
//            
//        }
//    }
//    
//        
//}
//
//
//#Preview {
//    ControlPanelView(gameState: GameState(dictionaryManager: DictionaryManager()), tileManager: TileManager(tileGenerator: TileGenerator(letterGenerator: LetterGenerator(), tileTypeGenerator: TileTypeGenerator()), tileConverter: TileConverter(), wordChecker: WordChecker(wordStore: [:])))
//}
