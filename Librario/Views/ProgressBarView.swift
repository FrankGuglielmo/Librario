//
//  ProgressBarView.swift
//  Librario
//
//  Created by Frank Guglielmo on 9/5/24.
//

import SwiftUI

struct ProgressBarView: View {
    var progress: CGFloat = 0.5 // A value between 0 and 1
    let totalWidth: CGFloat = 280 // Known width of the progress bar
    let totalHeight: CGFloat = 70  // Known height of the progress bar

    var body: some View {
        ZStack(alignment: .leading) {
            // Background image (for the unfilled part of the progress bar)
            Image("faded_progress_bar") // Your background image here
                .resizable()
                .scaledToFill()
                .frame(width: totalWidth, height: totalHeight)
                .cornerRadius(0)

            // Foreground image (for the filled part of the progress bar)
            Image("progress_bar") // Your foreground image here
                .resizable()
                .scaledToFill()
                .frame(width: totalWidth * progress, height: totalHeight) // Adjust width based on progress
                .clipped() // Clip to the progress
                .cornerRadius(0) // Match the corner radius if necessary
        }
        .frame(width: totalWidth, height: totalHeight) // Fixed frame size
    }
}

