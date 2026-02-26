//
//  GameViewModel.swift
//  Reib
//
//  Created by Andreas Pelczer on 26.02.26.
//

import CoreGraphics
import QuartzCore

// MARK: - Events die das ViewModel an die View feuert

enum GameEvent {
    case stateChanged(GameState)
    case scoreChanged(Int)
    case livesChanged(Int)
    case waveStarted(Int)
    case smudgeSpawned(SmudgeModel)
    case smudgeRevealed(id: UUID, reward: SmudgeReward, points: Int)
    case smudgeExpired(UUID)
    case comboChanged(multiplier: Int)
    case streakChanged(Int)
    case freezeActivated
    case freezeEnded
    case lifeLost(CGPoint)
    case waveDelayBonus
    case gameOver(score: Int, wave: Int, cleared: Int, bestStreak: Int, isNewHighscore: Bool)
}

// MARK: - Ergebnis einer Reib-Aktion

struct RubResult {
    let smudgeID: UUID
    let wasRevealed: Bool
    let progress: CGFloat
    let touchPoint: CGPoint
}

// MARK: - GameViewModel – Die gesamte Spiellogik

class GameViewModel {

    let config: GameConfig

    // State
    private(set) var state: GameState = .menu
    private(set) var score: Int = 0
    private(set) var lives: Int = 3
    private(set) var wave: Int = 1
    private(set) var smudgesCleared: Int = 0
    private(set) var smudgesPerWave: Int = 3
    private(set) var waveDelay: TimeInterval = 7.0
    private(set) var isFrozen: Bool = false
    private(set) var frozenUntil: TimeInterval = 0
    private(set) var streakCount: Int = 0
    private(set) var bestStreak: Int = 0

    // Sub-Models
    private(set) var combo: ComboModel
    let leaderboard: LeaderboardModel

    // Aktive Flecken
    private(set) var smudges: [SmudgeModel] = []

    // Timing
    private(set) var lastWaveTime: TimeInterval = 0

    // Scene-Größe (für Positionierung)
    var sceneSize: CGSize = .zero

    // Event-Callback
    var onEvent: ((GameEvent) -> Void)?

    // MARK: - Init

    init(config: GameConfig = GameConfig()) {
        self.config = config
        self.combo = ComboModel(timeout: config.comboTimeout)
        self.leaderboard = LeaderboardModel()
    }

    // MARK: - Spiel-Lifecycle

    func startGame() {
        state = .playing
        score = 0
        lives = config.initialLives
        wave = 1
        smudgesCleared = 0
        smudgesPerWave = config.initialSmudgesPerWave
        waveDelay = config.initialWaveDelay
        isFrozen = false
        combo = ComboModel(timeout: config.comboTimeout)
        streakCount = 0
        bestStreak = 0
        smudges = []

        onEvent?(.stateChanged(.playing))
        onEvent?(.scoreChanged(0))
        onEvent?(.livesChanged(lives))
        spawnWave()
    }

    func togglePause() {
        if state == .playing {
            state = .paused
            onEvent?(.stateChanged(.paused))
        } else if state == .paused {
            state = .playing
            lastWaveTime = CACurrentMediaTime()
            onEvent?(.stateChanged(.playing))
        }
    }

    func backToMenu() {
        state = .menu
        smudges = []
        onEvent?(.stateChanged(.menu))
    }

    // MARK: - Wellen-System

    func spawnWave() {
        guard state == .playing else { return }

        onEvent?(.waveStarted(wave))

        let count = smudgesForCurrentWave()
        let now = CACurrentMediaTime()

        for _ in 0..<count {
            let smudge = createSmudge(at: now)
            smudges.append(smudge)
            onEvent?(.smudgeSpawned(smudge))
        }

        lastWaveTime = now
    }

    func smudgesForCurrentWave() -> Int {
        return min(smudgesPerWave + (wave - 1) / 2, config.maxSmudgesPerWave)
    }

    private func createSmudge(at time: TimeInterval) -> SmudgeModel {
        let reward = randomReward()
        let behavior = randomBehavior()
        let radius = CGFloat.random(in: 30...55)
        let position = findSpawnPosition(radius: radius)

        return SmudgeModel(
            reward: reward,
            behavior: behavior,
            radius: radius,
            position: position,
            spawnTime: time
        )
    }

    private func findSpawnPosition(radius: CGFloat) -> CGPoint {
        var position: CGPoint
        var attempts = 0
        repeat {
            position = CGPoint(
                x: CGFloat.random(in: (radius + 20)...(sceneSize.width - radius - 20)),
                y: CGFloat.random(in: (radius + 140)...(sceneSize.height - radius - 120))
            )
            attempts += 1
        } while isTooClose(position, minDistance: radius * 2.5) && attempts < 20
        return position
    }

    private func isTooClose(_ point: CGPoint, minDistance: CGFloat) -> Bool {
        for smudge in smudges where !smudge.isRevealed {
            let dist = hypot(smudge.position.x - point.x, smudge.position.y - point.y)
            if dist < minDistance { return true }
        }
        return false
    }

    private func randomReward() -> SmudgeReward {
        let roll = Int.random(in: 1...100)
        let bombChance = min(config.baseBombChance + wave * config.bombChancePerWave, config.maxBombChance)

        if roll <= bombChance { return .bomb }
        else if roll <= bombChance + 5 { return .freeze }
        else if roll <= bombChance + 10 { return .timeBonus }
        else if roll <= bombChance + 20 { return .doubleStar }
        else { return .star }
    }

    private func randomBehavior() -> SmudgeBehavior {
        if wave < config.movingSmudgeStartWave { return .normal }

        let roll = Int.random(in: 1...100)
        let moveChance = min(10 + (wave - config.movingSmudgeStartWave) * 3, 30)
        let growChance = wave >= config.growingSmudgeStartWave
            ? min(8 + (wave - config.growingSmudgeStartWave) * 2, 20) : 0

        if roll <= moveChance { return .moving }
        else if roll <= moveChance + growChance { return .growing }
        return .normal
    }

    private func advanceWave() {
        wave += 1
        if wave % config.smudgesPerWaveIncreaseInterval == 0 {
            smudgesPerWave += 1
        }
        waveDelay = max(config.minWaveDelay, waveDelay - config.waveDelayReduction)
    }

    // MARK: - Reib-Handling

    func handleRub(at point: CGPoint, intensity: CGFloat) -> RubResult? {
        guard state == .playing else { return nil }

        for i in 0..<smudges.count {
            guard !smudges[i].isRevealed else { continue }

            // Erst prüfen ob Punkt im Fleck liegt
            guard smudges[i].containsPoint(point) else { continue }

            let wasRevealed = smudges[i].rub(at: point, intensity: intensity)

            if wasRevealed {
                processReward(for: smudges[i])
            }

            return RubResult(
                smudgeID: smudges[i].id,
                wasRevealed: wasRevealed,
                progress: smudges[i].progress,
                touchPoint: point
            )
        }
        return nil
    }

    // MARK: - Belohnung verarbeiten

    private func processReward(for smudge: SmudgeModel) {
        let now = CACurrentMediaTime()

        switch smudge.reward {
        case .star:
            combo.registerHit(at: now)
            let points = 10 * wave * combo.multiplier
            score += points
            streakCount += 1
            onEvent?(.smudgeRevealed(id: smudge.id, reward: .star, points: points))

        case .doubleStar:
            combo.registerHit(at: now)
            let points = 25 * wave * combo.multiplier
            score += points
            streakCount += 1
            onEvent?(.smudgeRevealed(id: smudge.id, reward: .doubleStar, points: points))

        case .bomb:
            lives -= 1
            combo.reset()
            if streakCount > bestStreak { bestStreak = streakCount }
            streakCount = 0
            onEvent?(.smudgeRevealed(id: smudge.id, reward: .bomb, points: 0))
            onEvent?(.lifeLost(smudge.position))
            if lives <= 0 {
                triggerGameOver()
                return
            }

        case .timeBonus:
            waveDelay += 2.0
            streakCount += 1
            onEvent?(.smudgeRevealed(id: smudge.id, reward: .timeBonus, points: 0))
            onEvent?(.waveDelayBonus)

        case .freeze:
            isFrozen = true
            frozenUntil = now + 3.0
            streakCount += 1
            onEvent?(.smudgeRevealed(id: smudge.id, reward: .freeze, points: 0))
            onEvent?(.freezeActivated)
        }

        smudgesCleared += 1
        onEvent?(.scoreChanged(score))
        onEvent?(.livesChanged(lives))
        onEvent?(.comboChanged(multiplier: combo.multiplier))
        onEvent?(.streakChanged(streakCount))
    }

    // MARK: - Frame Update

    func update(currentTime: TimeInterval) {
        guard state == .playing else { return }

        // Smudge-Positionen und Skalierung aktualisieren
        for i in 0..<smudges.count {
            smudges[i].updatePosition(currentTime: currentTime)
            smudges[i].updateScale(currentTime: currentTime)
        }

        // Freeze prüfen
        if isFrozen && currentTime > frozenUntil {
            isFrozen = false
            onEvent?(.freezeEnded)
        }

        // Combo-Timeout
        if combo.checkTimeout(at: currentTime) {
            onEvent?(.comboChanged(multiplier: 1))
        }

        // Wellen-Check
        let allRevealed = !smudges.isEmpty && smudges.allSatisfy { $0.isRevealed }
        let timeSinceWave = CACurrentMediaTime() - lastWaveTime
        let timeForNewWave = timeSinceWave > waveDelay

        if !isFrozen && (allRevealed || (timeForNewWave && !smudges.isEmpty)) {
            for smudge in smudges where !smudge.isRevealed {
                onEvent?(.smudgeExpired(smudge.id))
            }
            smudges.removeAll()
            advanceWave()
            spawnWave()
        }
    }

    // MARK: - Game Over

    private func triggerGameOver() {
        state = .gameOver
        if streakCount > bestStreak { bestStreak = streakCount }

        let isNew = leaderboard.isNewHighscore(score)
        leaderboard.save(score)

        onEvent?(.gameOver(
            score: score,
            wave: wave,
            cleared: smudgesCleared,
            bestStreak: bestStreak,
            isNewHighscore: isNew
        ))
        onEvent?(.stateChanged(.gameOver))
    }

    // MARK: - Smudge-Verwaltung

    func removeSmudge(id: UUID) {
        smudges.removeAll { $0.id == id }
    }
}
