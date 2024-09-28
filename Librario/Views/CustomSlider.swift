//
//  CustomSlider.swift
//  Librario
//
//  Created by Frank Guglielmo on 9/18/24.
//

import SwiftUI

struct CustomSlider: View {
    @Binding var value: Float
    let range: ClosedRange<Double>
    let borderColor: Color
    let emptyProgressColor: Color
    let fullProgressColor: Color

    var body: some View {
        GeometryReader { geometry in
            ZStack(alignment: .leading) {
                // Empty progress background
                Capsule()
                    .fill(emptyProgressColor)
                    .frame(height: geometry.size.height / 3)
                
                // Full progress foreground (based on current value)
                Capsule()
                    .fill(fullProgressColor)
                    .frame(width: geometry.size.width * CGFloat((Double(value) - range.lowerBound) / (range.upperBound - range.lowerBound)), height: geometry.size.height / 3)
                
                // Border around the slider
                Capsule()
                    .stroke(borderColor, lineWidth: 2)
                    .frame(height: geometry.size.height / 3)
                
                // Drag handle
                Circle()
                    .fill(fullProgressColor)
                    .frame(width: geometry.size.height, height: geometry.size.height)
                    .offset(x: geometry.size.width * CGFloat((Double(value) - range.lowerBound) / (range.upperBound - range.lowerBound)) - geometry.size.height / 2)
                    .gesture(
                        DragGesture(minimumDistance: 0)
                            .onChanged { gesture in
                                let newValue = min(max(0, gesture.location.x / geometry.size.width), 1)
                                self.value = Float(range.lowerBound + Double(newValue) * (range.upperBound - range.lowerBound))
                            }
                    )
            }
        }
        .frame(height: 40) // Set a fixed height for the slider
    }
}
