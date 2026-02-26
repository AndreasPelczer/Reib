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

    var emoji: String {
        switch self {
        case .star: return "⭐"
        case .doubleStar: return "🌟"
        case .bomb: return "💣"
        case .timeBonus: return "⏱️"
        case .freeze: return "🧊"
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
}

// MARK: - Datenmodell eines Dreckflecks

struct SmudgeModel {
    let id: UUID = UUID()
    let reward: SmudgeReward
    let behavior: SmudgeBehavior
    let radius: CGFloat
    let basePosition: CGPoint
    let spawnTime: TimeInterval
    let totalPixels: Int = 100

    // Drift-Seeds für deterministische Bewegung
    let driftSeedX: CGFloat = CGFloat.random(in: 0...(.pi * 2))
    let driftSeedY: CGFloat = CGFloat.random(in: 0...(.pi * 2))

    // Mutable State
    var rubbedPixels: Int = 0
    var position: CGPoint
    var scaleFactor: CGFloat = 1.0

    var isRevealed: Bool { rubbedPixels >= totalPixels }
    var progress: CGFloat { CGFloat(rubbedPixels) / CGFloat(totalPixels) }
    var effectiveRadius: CGFloat { radius * scaleFactor }

    init(reward: SmudgeReward, behavior: SmudgeBehavior, radius: CGFloat, position: CGPoint, spawnTime: TimeInterval) {
        self.reward = reward
        self.behavior = behavior
        self.radius = radius
        self.basePosition = position
        self.position = position
        self.spawnTime = spawnTime
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
        guard behavior == .growing else { return }
        let elapsed = CGFloat(currentTime - spawnTime)
        scaleFactor = min(1.0 + elapsed * 0.0375, 1.3)
    }
}
