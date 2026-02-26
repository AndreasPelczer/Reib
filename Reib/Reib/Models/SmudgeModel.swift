//
//  SmudgeModel.swift
//  Reib
//
//  Created by Andreas Pelczer on 26.02.26.
//

import CoreGraphics

// MARK: - Was sich unter einem Fleck versteckt

enum SmudgeReward {
    case star
    case doubleStar
    case bomb
    case timeBonus
    case freeze
    case chain       // Kettenfleck-Belohnung (Mega-Bonus bei vollständiger Kette)
    case bossReward  // Boss-Belohnung (großer Bonus + Extra-Leben)

    var emoji: String {
        switch self {
        case .star: return "⭐"
        case .doubleStar: return "🌟"
        case .bomb: return "💣"
        case .timeBonus: return "⏱️"
        case .freeze: return "🧊"
        case .chain: return "🔗"
        case .bossReward: return "👑"
        }
    }

    var isPositive: Bool {
        switch self {
        case .bomb: return false
        default: return true
        }
    }
}

// MARK: - Fleck-Verhalten

enum SmudgeBehavior {
    case normal
    case moving
    case growing
    case oil    // Breitet sich aus, beschleunigt bei langsamem Rubbeln
    case gold   // Kurzzeitig sichtbar, muss sofort gerubbelt werden
    case chain  // Teil einer Dreiergruppe
    case boss   // Riesiger Boss-Fleck
}

// MARK: - Datenmodell eines Dreckflecks

struct SmudgeModel {
    let id: UUID = UUID()
    let reward: SmudgeReward
    let behavior: SmudgeBehavior
    let radius: CGFloat
    let basePosition: CGPoint
    let spawnTime: TimeInterval
    let totalPixels: Int

    // Drift-Seeds für deterministische Bewegung
    let driftSeedX: CGFloat = CGFloat.random(in: 0...(.pi * 2))
    let driftSeedY: CGFloat = CGFloat.random(in: 0...(.pi * 2))

    // Chain-Daten
    let chainGroupID: UUID?
    let chainIndex: Int  // 1, 2, 3 innerhalb der Kette (0 = kein Kettenfleck)

    // Mutable State
    var rubbedPixels: Int = 0
    var position: CGPoint
    var scaleFactor: CGFloat = 1.0

    var isRevealed: Bool { rubbedPixels >= totalPixels }
    var progress: CGFloat { CGFloat(rubbedPixels) / CGFloat(totalPixels) }
    var effectiveRadius: CGFloat { radius * scaleFactor }

    init(
        reward: SmudgeReward,
        behavior: SmudgeBehavior,
        radius: CGFloat,
        position: CGPoint,
        spawnTime: TimeInterval,
        totalPixels: Int = 100,
        chainGroupID: UUID? = nil,
        chainIndex: Int = 0
    ) {
        self.reward = reward
        self.behavior = behavior
        self.radius = radius
        self.basePosition = position
        self.position = position
        self.spawnTime = spawnTime
        self.totalPixels = totalPixels
        self.chainGroupID = chainGroupID
        self.chainIndex = chainIndex
    }

    // MARK: - Reib-Logik

    mutating func rub(at point: CGPoint, intensity: CGFloat) -> Bool {
        guard !isRevealed else { return false }

        let distance = hypot(point.x - position.x, point.y - position.y)
        guard distance <= effectiveRadius else { return false }

        let centerBonus = 1.0 + (1.0 - distance / effectiveRadius) * 0.5
        let rubAmount = Int(intensity * centerBonus * 3)
        rubbedPixels = min(rubbedPixels + rubAmount, totalPixels)
        return isRevealed
    }

    /// True wenn der Punkt innerhalb des Flecks liegt (für partielle Rub-Updates)
    func containsPoint(_ point: CGPoint) -> Bool {
        let distance = hypot(point.x - position.x, point.y - position.y)
        return distance <= effectiveRadius
    }

    // MARK: - Verhaltens-Updates (pro Frame)

    mutating func updatePosition(currentTime: TimeInterval) {
        guard behavior == .moving else { return }
        let elapsed = currentTime - spawnTime
        let dx = sin(elapsed * 0.8 + Double(driftSeedX)) * 25
        let dy = cos(elapsed * 0.6 + Double(driftSeedY)) * 20
        position = CGPoint(x: basePosition.x + dx, y: basePosition.y + dy)
    }

    mutating func updateScale(currentTime: TimeInterval) {
        switch behavior {
        case .growing:
            let elapsed = CGFloat(currentTime - spawnTime)
            scaleFactor = min(1.0 + elapsed * 0.0375, 1.3)
        default:
            break // .oil wird vom ViewModel gesteuert (braucht Config-Zugriff)
        }
    }

    /// Sekunden seit Spawn
    func age(at currentTime: TimeInterval) -> TimeInterval {
        return currentTime - spawnTime
    }
}
