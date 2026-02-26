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

    // Öl-Fleck
    var oilStartWave: Int = 4
    var oilBaseGrowthRate: CGFloat = 0.06
    var oilAcceleratedRate: CGFloat = 0.12
    var oilAccelerationThreshold: CGFloat = 0.3
    var oilAccelerationDelay: TimeInterval = 3.0
    var oilMaxScale: CGFloat = 1.8

    // Gold-Fleck
    var goldStartWave: Int = 3
    var goldChance: Int = 5
    var goldDuration: TimeInterval = 2.0
    var goldPointsBase: Int = 50

    // Ketten-Fleck
    var chainStartWave: Int = 6
    var chainChance: Int = 8
    var chainSize: Int = 3
    var chainMegaBonus: Int = 100

    // Boss-Fleck
    var bossWaveInterval: Int = 10
    var bossRadiusMin: CGFloat = 120
    var bossRadiusMax: CGFloat = 150
    var bossTotalPixels: Int = 400
    var bossPointsBase: Int = 500
}
