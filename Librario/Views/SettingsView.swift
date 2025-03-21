//
//  SettingsPopup.swift
//  Librario
//
//  Created by Frank Guglielmo on 9/18/24.
//

import SwiftUI

struct SettingsView: View {
    @Environment(\.horizontalSizeClass) var horizontalSizeClass
    @Bindable var settings = Settings.shared
    @Binding var navigationPath: NavigationPath

    var body: some View {
        let settingsCard = Card(
            title: "Settings",
            subtitle: "Adjust your game preferences",
            cardColor: .crimson
        ) {
            VStack(spacing: 48) {
                // Music Slider
                VStack(spacing: 12) {
                    Text("Music Volume")
                        .font(.headline)
                        .foregroundColor(.white)
                    CustomSlider(value: $settings.musicVolume,
                                 range: 0...1,
                                 borderColor: CardColor.crimson.borderColor,
                                 emptyProgressColor: .brown,
                                 fullProgressColor: CardColor.crimson.complementaryColor)
                }
                
                // Sound Effects Slider
                VStack(spacing: 12) {
                    Text("Sound Effects Volume")
                        .font(.headline)
                        .foregroundColor(.white)
                    CustomSlider(value: $settings.soundEffectsVolume,
                                 range: 0...1,
                                 borderColor: CardColor.crimson.borderColor,
                                 emptyProgressColor: .brown,
                                 fullProgressColor: CardColor.crimson.complementaryColor)
                }
            }
            .padding(.horizontal)
        }
        
        ZStack {
            // Background image filling the entire safe area
            Image("Background_Image_2")
                .resizable()
                .edgesIgnoringSafeArea(.all)
            
            CardView(cards: [settingsCard])
        }
    }
}

struct SettingsView_Previews: PreviewProvider {
    static var previews: some View {
        SettingsView(navigationPath: .constant(NavigationPath()))
    }
}
