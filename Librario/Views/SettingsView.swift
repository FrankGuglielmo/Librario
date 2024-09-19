//
//  SettingsPopup.swift
//  Librario
//
//  Created by Frank Guglielmo on 9/18/24.
//

import SwiftUI

import SwiftUI

struct SettingsView: View {
    @Environment(\.horizontalSizeClass) var horizontalSizeClass
    @ObservedObject var settings = Settings.shared
    @Binding var navigationPath: NavigationPath
    
    var body: some View {
        GeometryReader { geometry in
            let isCompact = horizontalSizeClass == .compact
            let popupWidth = isCompact ? geometry.size.width * 0.9 : geometry.size.width * 0.6
            let popupHeight = isCompact ? geometry.size.height * 0.9 : geometry.size.height * 0.8
            
            
            ZStack {
                // Background color filling the entire safe area
                Image("red_curtain")
                    .resizable()
                    .scaledToFill()
                    .frame(minWidth: 0)
                    .edgesIgnoringSafeArea(.all)
                
                ZStack {
                    // Background Popup Image
                    Image("SettingsPopup")
                        .resizable()
                        .scaledToFit()
                        .frame(width: popupWidth, height: popupHeight)
                    
                    // Overlay content on top of the background image
                    VStack(spacing: popupWidth * 0.1) {
                        
                        VStack {
                            // Music Slider
                            VStack(spacing: popupWidth * 0.02) {
                                Text("Music Volume")
                                    .font(.system(size: popupWidth * 0.05))
                                    .foregroundColor(.white)
                                CustomSlider(value: $settings.musicVolume,
                                                         range: 0...1,
                                                         borderColor: .yellow,
                                                         emptyProgressColor: .brown,
                                                         fullProgressColor: .red)
                                .frame(width: popupWidth * 0.8)
                            }
                            
                            // Sound Effects Slider
                            VStack(spacing: popupWidth * 0.02) {
                                Text("Sound Effects Volume")
                                    .font(.system(size: popupWidth * 0.05))
                                    .foregroundColor(.white)
                                CustomSlider(value: $settings.soundEffectsVolume,
                                                         range: 0...1,
                                                         borderColor: .yellow,
                                                         emptyProgressColor: .brown,
                                                         fullProgressColor: .red)
                                .frame(width: popupWidth * 0.8)
                            }
                        }
                        .padding(.bottom, popupHeight * 0.3)
                        .padding(.top, popupHeight * 0.1)
                        
                        Button(action: {
                            AudioManager.shared.playSoundEffect(named: "switch_view_sound")
                            navigationPath.removeLast() // Navigate back to the previous view
                        }) {
                            Image("BackButton")
                                .resizable()
                                .scaledToFit()
                                .frame(width: popupWidth * 0.6)
                        }
                        
                    }
                    .padding()
                    
                    
                    
                    
                }
                .frame(width: geometry.size.width, height: geometry.size.height)
                .position(x: geometry.size.width / 2, y: geometry.size.height / 2)
            }
        }
    }
}

