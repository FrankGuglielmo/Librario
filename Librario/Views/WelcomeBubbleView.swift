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
        
        ZStack {
            // Background of the text bubble
            RoundedRectangle(cornerRadius: 10)
                .fill(Color.white)
                .shadow(radius: 5)
            
            // Text inside the bubble
            Text("Hello, \(name)!")
                .font(.title2)
                .foregroundStyle(.black)
                .fontWeight(.bold)
                .padding(10)
        }
    }
}

#Preview {
    WelcomeBubbleView(name: "Frank")
}
