//
//  LocalizedStringResource+Ext.swift
//  Utils
//
//  Created by Andriy Biguniak on 30.07.2025.
//

import Foundation


extension LocalizedStringResource
{
    func toString() -> String {
        String(localized: self)
    }
}
