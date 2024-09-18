//
//  TextBubbleView.swift
//  Librario
//
//  Created by Frank Guglielmo on 9/17/24.
//

import SwiftUI

struct TextBubbleView: View {
    let text: String

    var body: some View {
        Text(text)
            .font(.headline)
            .padding(10)
            .background(Color.white)
            .cornerRadius(10)
            .shadow(radius: 5)
            .foregroundColor(.black)
    }
}
