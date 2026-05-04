//
//  Item.swift
//  ThreatWatch
//
//  Created by  infopro on 2026/5/4.
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
