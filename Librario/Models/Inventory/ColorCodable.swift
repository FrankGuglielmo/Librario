//
//  ColorCodable.swift
//  Librario
//
//  Created on 3/11/2025.
//

import SwiftUI

// Extension to make Color Codable
extension Color: Codable {
    enum CodingKeys: String, CodingKey {
        case red, green, blue, alpha
    }
    
    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let r = try container.decode(Double.self, forKey: .red)
        let g = try container.decode(Double.self, forKey: .green)
        let b = try container.decode(Double.self, forKey: .blue)
        let a = try container.decode(Double.self, forKey: .alpha)
        
        self.init(.sRGB, red: r, green: g, blue: b, opacity: a)
    }
    
    public func encode(to encoder: Encoder) throws {
        guard let colorComponents = UIColor(self).cgColor.components else {
            throw EncodingError.invalidValue(self, EncodingError.Context(
                codingPath: encoder.codingPath,
                debugDescription: "Color could not be encoded due to invalid components"
            ))
        }
        
        var container = encoder.container(keyedBy: CodingKeys.self)
        
        // Extract components (defaulting to 0 if not enough components)
        let r = colorComponents.count > 0 ? colorComponents[0] : 0
        let g = colorComponents.count > 1 ? colorComponents[1] : 0
        let b = colorComponents.count > 2 ? colorComponents[2] : 0
        let a = colorComponents.count > 3 ? colorComponents[3] : 1
        
        try container.encode(r, forKey: .red)
        try container.encode(g, forKey: .green)
        try container.encode(b, forKey: .blue)
        try container.encode(a, forKey: .alpha)
    }
}
