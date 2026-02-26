//
//  GameModel.swift
//  Reib
//
//  Created by Andreas Pelczer on 26.02.26.
//

import Foundation

// MARK: - Spielzustand

enum GameState {
    case menu
    case playing
    case paused
    case gameOver
}

// MARK: - Spielkonfiguration (Tuning-Werte)

struct GameConfig {
    var initialLives: Int = 3
    var initialWaveDelay: TimeInterval = 7.0
    var initialSmudgesPerWave: Int = 3
    var minWaveDelay: TimeInterval = 3.5
    var waveDelayReduction: TimeInterval = 0.05
    var maxSmudgesPerWave: Int = 8
    var comboTimeout: TimeInterval = 2.0
    var smudgesPerWaveIncreaseInterval: Int = 5
    var movingSmudgeStartWave: Int = 3
    var growingSmudgeStartWave: Int = 5
    var baseBombChance: Int = 10
    var bombChancePerWave: Int = 2
    var maxBombChance: Int = 25
}
