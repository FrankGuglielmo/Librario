//
//  FlexibleImageView.swift
//  Librario
//
//  Created by Frank Guglielmo on 3/11/25.
//

import SwiftUI

// A view that can display either a system icon or an asset image
struct FlexibleImageView: View {
    let iconName: String
    let foregroundColor: Color
    let fontSize: Font
    
    init(iconName: String, foregroundColor: Color = .primary, fontSize: Font = .body) {
        self.iconName = iconName
        self.foregroundColor = foregroundColor
        self.fontSize = fontSize
    }
    
    var body: some View {
        Group {
            if UIImage(systemName: iconName) != nil {
                // If a system icon exists with this name, use it
                Image(systemName: iconName)
                    .font(fontSize)
                    .foregroundColor(foregroundColor)
            } else {
                // Otherwise, use it as an asset name
                Image(iconName)
                    .resizable()
                    .scaledToFit()
                    .foregroundColor(foregroundColor)
            }
        }
    }
}

