//
//  Item.swift
//  FatigueDetector
//
//  Created by Navindu Premaratne on 2025-07-21.
//

import Foundation
import SwiftData

@Model
final class Item {
    var timestamp: Date
    
    init(timestamp: Date) {
        self.timestamp = timestamp
    }
}
