//
//  ComboModel.swift
//  Reib
//
//  Created by Andreas Pelczer on 26.02.26.
//

import Foundation

struct ComboModel {
    var count: Int = 0
    var lastRevealTime: TimeInterval = 0
    let timeout: TimeInterval

    init(timeout: TimeInterval = 2.0) {
        self.timeout = timeout
    }

    var multiplier: Int {
        if count >= 6 { return 4 }
        if count >= 4 { return 3 }
        if count >= 2 { return 2 }
        return 1
    }

    mutating func registerHit(at time: TimeInterval) {
        if time - lastRevealTime < timeout && lastRevealTime > 0 {
            count += 1
        } else {
            count = 1
        }
        lastRevealTime = time
    }

    /// Returns true wenn der Combo gerade abgelaufen ist
    mutating func checkTimeout(at time: TimeInterval) -> Bool {
        if count > 0 && lastRevealTime > 0 && (time - lastRevealTime > timeout) {
            count = 0
            return true
        }
        return false
    }

    mutating func reset() {
        count = 0
    }
}
