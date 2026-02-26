//
//  LeaderboardModel.swift
//  Reib
//
//  Created by Andreas Pelczer on 26.02.26.
//

import Foundation

class LeaderboardModel {
    private let key: String
    let maxEntries: Int
    private(set) var entries: [Int]

    var highscore: Int { entries.first ?? 0 }

    init(key: String = "ReibLeaderboard", maxEntries: Int = 5) {
        self.key = key
        self.maxEntries = maxEntries
        self.entries = UserDefaults.standard.array(forKey: key) as? [Int] ?? []
    }

    func save(_ score: Int) {
        entries.append(score)
        entries.sort(by: >)
        if entries.count > maxEntries {
            entries = Array(entries.prefix(maxEntries))
        }
        UserDefaults.standard.set(entries, forKey: key)
    }

    func isNewHighscore(_ score: Int) -> Bool {
        return score > 0 && score >= highscore
    }
}
