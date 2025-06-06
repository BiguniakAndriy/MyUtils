//
//  Array+Ext.swift
//  Utils
//
//  Created by Andriy Biguniak on 10.05.2025.
//

import Foundation
import SwiftUI

public extension Array where Element: Hashable
{
    func uniqued() -> [Element] {
        var seen = Set<Element>()
        return filter { seen.insert($0).inserted }
    }
    
    /// Returns the element at the specified index if it is within bounds, otherwise nil.
    subscript (safe index: Index) -> Element? {
        return indices.contains(index) ? self[index] : nil
    }
}


public extension Array where Element: UIColor
{
    func intermediate(percentage: CGFloat) -> UIColor {
        switch percentage {
            case 0: return first ?? .clear
            case 1: return last ?? .clear
            default:
                let approxIndex = percentage / (1 / CGFloat(count - 1))
                let firstIndex = Int(approxIndex.rounded(.down))
                let secondIndex = Int(approxIndex.rounded(.up))
                let fallbackIndex = Int(approxIndex.rounded())
                
                let firstColor = firstIndex < self.count ? self[firstIndex] : (self.last ?? .clear)
                let secondColor = secondIndex < self.count ? self[secondIndex] : (self.last ?? .clear)
                let fallbackColor = fallbackIndex < self.count ? self[fallbackIndex] : (self.last ?? .clear)
                
                var (r1, g1, b1, a1): (CGFloat, CGFloat, CGFloat, CGFloat) = (0, 0, 0, 0)
                var (r2, g2, b2, a2): (CGFloat, CGFloat, CGFloat, CGFloat) = (0, 0, 0, 0)
                guard firstColor.getRed(&r1, green: &g1, blue: &b1, alpha: &a1) else { return fallbackColor }
                guard secondColor.getRed(&r2, green: &g2, blue: &b2, alpha: &a2) else { return fallbackColor }
                
                let intermediatePercentage = approxIndex - CGFloat(firstIndex)
                return UIColor(
                    red: CGFloat(r1 + (r2 - r1) * intermediatePercentage),
                    green: CGFloat(g1 + (g2 - g1) * intermediatePercentage),
                    blue: CGFloat(b1 + (b2 - b1) * intermediatePercentage),
                    alpha: CGFloat(a1 + (a2 - a1) * intermediatePercentage)
                )
        }
    }
}
