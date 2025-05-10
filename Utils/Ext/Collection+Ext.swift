//
//  Collection+Ext.swift
//  Utils
//
//  Created by Andriy Biguniak on 10.05.2025.
//

import Foundation


public extension Collection
{
    /// Returns the element at the specified index if it is within bounds, otherwise nil.
    subscript (safe index: Index) -> Element? {
        return indices.contains(index) ? self[index] : nil
    }
}
