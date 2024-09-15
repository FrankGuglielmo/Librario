//
//  Bile.swift
//  Librario
//
//  Created by Frank Guglielmo on 9/14/24.
//

import SwiftUI

struct Bile: View {
    var isSelected: Bool

    var body: some View {
        Rectangle()
            .fill(Color.blue)
            .frame(width: 100, height: 100)
            .shadow(color: isSelected ? Color.blue.opacity(0.8) : Color.clear, radius: isSelected ? 10 : 0, x: 0, y: 0)
            .overlay(
                Rectangle()
                    .stroke(isSelected ? Color.blue : Color.clear, lineWidth: 4)
            )
            .animation(.easeInOut, value: isSelected)
    }
}



