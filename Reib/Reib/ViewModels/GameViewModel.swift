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

    // Neue Events für die 4 Fleck-Typen
    case goldExpired(UUID)
    case chainProgress(groupID: UUID, index: Int)
    case chainCompleted(bonus: Int)
    case chainBroken
    case bossSpawned
    case bossDefeated(bonus: Int)
    case extraLife
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

    // Chain-Tracking
    private(set) var activeChainGroupID: UUID?
    private(set) var chainProgress: Int = 0

    // Boss-Tracking
    private(set) var isBossWave: Bool = false

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
        activeChainGroupID = nil
        chainProgress = 0
        isBossWave = false

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
        activeChainGroupID = nil
        chainProgress = 0
        isBossWave = false
        onEvent?(.stateChanged(.menu))
    }

    // MARK: - Wellen-System

    func spawnWave() {
        guard state == .playing else { return }

        let now = CACurrentMediaTime()

        // Boss-Welle? (alle N Wellen)
        if wave % config.bossWaveInterval == 0 {
            isBossWave = true
            onEvent?(.waveStarted(wave))
            onEvent?(.bossSpawned)
            let boss = createBossSmudge(at: now)
            smudges.append(boss)
            onEvent?(.smudgeSpawned(boss))
            lastWaveTime = now
            return
        }

        isBossWave = false
        onEvent?(.waveStarted(wave))

        let count = smudgesForCurrentWave()

        // Ketten-Fleck-Chance?
        var spawnChain = false
        if wave >= config.chainStartWave {
            spawnChain = Int.random(in: 1...100) <= config.chainChance
        }

        if spawnChain {
            spawnChainGroup(at: now)
            let remaining = max(0, count - config.chainSize)
            for _ in 0..<remaining {
                let smudge = createSmudge(at: now)
                smudges.append(smudge)
                onEvent?(.smudgeSpawned(smudge))
            }
        } else {
            for _ in 0..<count {
                let smudge = createSmudge(at: now)
                smudges.append(smudge)
                onEvent?(.smudgeSpawned(smudge))
            }
        }

        lastWaveTime = now
    }

    func smudgesForCurrentWave() -> Int {
        return min(smudgesPerWave + (wave - 1) / 2, config.maxSmudgesPerWave)
    }

    // MARK: - Smudge-Erzeugung

    private func createSmudge(at time: TimeInterval) -> SmudgeModel {
        // Gold-Chance prüfen (seltener Bonus-Fleck)
        if wave >= config.goldStartWave && Int.random(in: 1...100) <= config.goldChance {
            let radius = CGFloat.random(in: 30...45)
            let position = findSpawnPosition(radius: radius)
            return SmudgeModel(
                reward: .doubleStar,
                behavior: .gold,
                radius: radius,
                position: position,
                spawnTime: time
            )
        }

        var reward = randomReward()
        let behavior = randomBehavior()

        // Öl: immer star oder doubleStar (Risiko-Belohnung)
        if behavior == .oil {
            reward = Bool.random() ? .star : .doubleStar
        }

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

    private func createBossSmudge(at time: TimeInterval) -> SmudgeModel {
        let radius = CGFloat.random(in: config.bossRadiusMin...config.bossRadiusMax)
        let position = CGPoint(x: sceneSize.width / 2, y: sceneSize.height / 2)
        return SmudgeModel(
            reward: .bossReward,
            behavior: .boss,
            radius: radius,
            position: position,
            spawnTime: time,
            totalPixels: config.bossTotalPixels
        )
    }

    private func spawnChainGroup(at time: TimeInterval) {
        let groupID = UUID()

        for i in 1...config.chainSize {
            let radius = CGFloat.random(in: 30...45)
            let position = findSpawnPosition(radius: radius)
            let smudge = SmudgeModel(
                reward: .chain,
                behavior: .chain,
                radius: radius,
                position: position,
                spawnTime: time,
                chainGroupID: groupID,
                chainIndex: i
            )
            smudges.append(smudge)
            onEvent?(.smudgeSpawned(smudge))
        }
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
        let oilChance = wave >= config.oilStartWave
            ? min(5 + (wave - config.oilStartWave) * 2, 15) : 0

        if roll <= moveChance { return .moving }
        else if roll <= moveChance + growChance { return .growing }
        else if roll <= moveChance + growChance + oilChance { return .oil }
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
            guard smudges[i].containsPoint(point) else { continue }

            let wasRevealed = smudges[i].rub(at: point, intensity: intensity)

            if wasRevealed {
                // Ketten-Logik (vor processReward)
                handleChainLogic(for: smudges[i])

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

    // MARK: - Ketten-Logik

    private func handleChainLogic(for smudge: SmudgeModel) {
        // Nicht-Ketten-Fleck aufgedeckt während Kette aktiv → Kette bricht
        if smudge.reward != .chain && activeChainGroupID != nil {
            onEvent?(.chainBroken)
            activeChainGroupID = nil
            chainProgress = 0
            return
        }

        // Ketten-Fleck aufgedeckt
        guard smudge.reward == .chain, let groupID = smudge.chainGroupID else { return }

        if activeChainGroupID == groupID && smudge.chainIndex == chainProgress + 1 {
            // Richtige Reihenfolge → Fortschritt
            chainProgress += 1
            onEvent?(.chainProgress(groupID: groupID, index: chainProgress))

            if chainProgress >= config.chainSize {
                // Kette komplett → Mega-Bonus!
                let bonus = config.chainMegaBonus * wave
                score += bonus
                onEvent?(.chainCompleted(bonus: bonus))
                onEvent?(.scoreChanged(score))
                activeChainGroupID = nil
                chainProgress = 0
            }
        } else if activeChainGroupID == nil && smudge.chainIndex == 1 {
            // Neue Kette starten
            activeChainGroupID = groupID
            chainProgress = 1
            onEvent?(.chainProgress(groupID: groupID, index: 1))
        } else {
            // Falsche Reihenfolge → Kette bricht
            onEvent?(.chainBroken)
            activeChainGroupID = nil
            chainProgress = 0
        }
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
            var points = 25 * wave * combo.multiplier
            // Gold-Bonus: deutlich mehr Punkte
            if smudge.behavior == .gold {
                points = config.goldPointsBase * wave * combo.multiplier
            }
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

        case .chain:
            combo.registerHit(at: now)
            let points = 10 * wave * combo.multiplier
            score += points
            streakCount += 1
            onEvent?(.smudgeRevealed(id: smudge.id, reward: .chain, points: points))

        case .bossReward:
            let points = config.bossPointsBase * wave
            score += points
            lives += 1
            streakCount += 1
            isBossWave = false
            onEvent?(.smudgeRevealed(id: smudge.id, reward: .bossReward, points: points))
            onEvent?(.bossDefeated(bonus: points))
            onEvent?(.extraLife)
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

            // Öl-Wachstum (braucht Config-Zugriff, daher im ViewModel)
            if smudges[i].behavior == .oil {
                let elapsed = CGFloat(currentTime - smudges[i].spawnTime)
                var rate = config.oilBaseGrowthRate
                if elapsed > CGFloat(config.oilAccelerationDelay) && smudges[i].progress < config.oilAccelerationThreshold {
                    rate = config.oilAcceleratedRate
                }
                smudges[i].scaleFactor = min(1.0 + elapsed * rate, config.oilMaxScale)
            }
        }

        // Gold-Flecken Timeout prüfen (älteste zuerst)
        for i in (0..<smudges.count).reversed() {
            if smudges[i].behavior == .gold && !smudges[i].isRevealed {
                if smudges[i].age(at: currentTime) > config.goldDuration {
                    onEvent?(.goldExpired(smudges[i].id))
                    smudges.remove(at: i)
                }
            }
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

        // Boss-Welle: nur weiter wenn Boss besiegt
        if isBossWave {
            let allRevealed = !smudges.isEmpty && smudges.allSatisfy { $0.isRevealed }
            if allRevealed {
                smudges.removeAll()
                advanceWave()
                spawnWave()
            }
            return
        }

        // Normale Wellen-Check
        let allRevealed = !smudges.isEmpty && smudges.allSatisfy { $0.isRevealed }
        let timeSinceWave = CACurrentMediaTime() - lastWaveTime
        let timeForNewWave = timeSinceWave > waveDelay

        if !isFrozen && (allRevealed || (timeForNewWave && !smudges.isEmpty)) {
            for smudge in smudges where !smudge.isRevealed {
                onEvent?(.smudgeExpired(smudge.id))
            }
            // Kette bricht wenn Welle wechselt
            if activeChainGroupID != nil {
                onEvent?(.chainBroken)
                activeChainGroupID = nil
                chainProgress = 0
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
