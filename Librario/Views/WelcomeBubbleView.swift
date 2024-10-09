//
//  WelcomeBubbleView.swift
//  Librario
//
//  Created by Frank Guglielmo on 10/3/24.
//

import SwiftUI

struct WelcomeBubbleView: View {
    @Environment(\.horizontalSizeClass) var horizontalSizeClass
    let name: String
    
    var body: some View {
        let isCompact = horizontalSizeClass == .compact
        let titleFontSize: CGFloat = isCompact ? 24 : 36
        
        ZStack {
            // Background of the text bubble
            RoundedRectangle(cornerRadius: 10)
                .fill(Color.white)
                .shadow(radius: 5)
            
            // Text inside the bubble
            Text("Hello, \(name)!")
                .font(Font.custom("NerkoOne-Regular", size: titleFontSize, relativeTo: .title))
                .foregroundColor(.black)
                .padding(10)
        }
    }
}

#Preview {
    WelcomeBubbleView(name: "Frank")
}
