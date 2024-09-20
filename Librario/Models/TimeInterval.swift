//
//  TimeInterval.swift
//  Librario
//
//  Created by Frank Guglielmo on 9/19/24.
//

import Foundation

import Foundation

extension TimeInterval {
    /// Formats the TimeInterval into a compact string "Xd:Yh:Zm:Ws".
    var formattedCompact: String {
        let totalSeconds = Int(self)
        
        let days = totalSeconds / 86400
        let hours = (totalSeconds % 86400) / 3600
        let minutes = (totalSeconds % 3600) / 60
        let seconds = totalSeconds % 60
        
        var components: [String] = []
        
        if days > 0 {
            components.append("\(days)d")
        }
        if hours > 0 || days > 0 { // Include hours if there are any days
            components.append("\(hours)h")
        }
        if minutes > 0 || hours > 0 || days > 0 { // Include minutes if there are any higher units
            components.append("\(minutes)m")
        }
        components.append("\(seconds)s")
        
        return components.joined(separator: ":")
    }
}

