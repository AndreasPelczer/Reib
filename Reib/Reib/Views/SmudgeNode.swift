//
//  SmudgeNode.swift
//  Reib
//
//  Created by Andreas Pelczer on 26.02.26.
//

import SpriteKit
import QuartzCore

// MARK: - Visuelle Darstellung eines Dreckflecks (nur View, keine Logik)

class SmudgeNode: SKNode {

    let smudgeID: UUID
    let reward: SmudgeReward
    let behavior: SmudgeBehavior
    let radius: CGFloat
    let chainGroupID: UUID?
    let chainIndex: Int
    let totalPixels: Int

    // Standard-Nodes
    private var dirtLayer: SKShapeNode!
    private var fingerprintContainer: SKNode!
    private var progressRing: SKShapeNode!
    private var rewardIcon: SKLabelNode!
    private var behaviorIcon: SKLabelNode?
    private var dirtColor: SKColor = .brown

    // Typ-spezifische Nodes
    private var oilGlossNode: SKShapeNode?
    private var goldShimmerNode: SKShapeNode?
    private var goldTimerRing: SKShapeNode?
    private var chainRingNode: SKShapeNode?
    private var chainNumberLabel: SKLabelNode?
    private var bossHealthBarBg: SKShapeNode?
    private var bossHealthBarFill: SKShapeNode?

    init(model: SmudgeModel) {
        self.smudgeID = model.id
        self.reward = model.reward
        self.behavior = model.behavior
        self.radius = model.radius
        self.chainGroupID = model.chainGroupID
        self.chainIndex = model.chainIndex
        self.totalPixels = model.totalPixels
        super.init()
        self.position = model.position
        setupVisuals()
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - Setup

    private func setupVisuals() {
        // Belohnungs-Icon (zunächst versteckt)
        rewardIcon = SKLabelNode(text: reward.emoji)
        rewardIcon.fontSize = radius * 0.9
        rewardIcon.verticalAlignmentMode = .center
        rewardIcon.horizontalAlignmentMode = .center
        rewardIcon.alpha = 0
        rewardIcon.zPosition = 0
        addChild(rewardIcon)

        // Dreckfleck-Basis – Farbe je nach Typ
        switch behavior {
        case .oil:  dirtColor = Self.oilColor()
        case .gold: dirtColor = Self.goldColor()
        case .boss: dirtColor = Self.bossColor()
        default:    dirtColor = Self.randomDirtColor()
        }

        dirtLayer = SKShapeNode(circleOfRadius: radius)
        dirtLayer.fillColor = dirtColor
        dirtLayer.strokeColor = .clear
        dirtLayer.alpha = behavior == .oil ? 0.75 : 0.88
        dirtLayer.zPosition = 1
        addChild(dirtLayer)

        // Textur
        fingerprintContainer = SKNode()
        fingerprintContainer.zPosition = 1.5
        addChild(fingerprintContainer)

        if behavior == .oil {
            drawOilSwirls()
        } else if behavior == .boss {
            drawBossCracks()
        } else {
            drawFingerprint()
        }

        // Fortschrittsring
        progressRing = SKShapeNode(circleOfRadius: radius + 3)
        progressRing.strokeColor = .white
        progressRing.lineWidth = 2
        progressRing.fillColor = .clear
        progressRing.alpha = 0
        progressRing.zPosition = 2
        addChild(progressRing)

        // Typ-spezifische Overlays
        switch behavior {
        case .oil:   setupOilGloss()
        case .gold:  setupGoldShimmer()
        case .chain: setupChainRing()
        case .boss:  setupBossHealthBar()
        default: break
        }

        // Verhaltens-Indikator
        setupBehaviorIcon()

        // Einblend-Animation
        self.setScale(0.1)
        let scaleUp = SKAction.scale(to: 1.0, duration: behavior == .boss ? 0.6 : 0.3)
        scaleUp.timingMode = .easeOut
        run(SKAction.group([scaleUp, SKAction.fadeIn(withDuration: 0.3)]))
    }

    private func setupBehaviorIcon() {
        let iconText: String?
        switch behavior {
        case .moving:  iconText = "~"
        case .growing: iconText = "+"
        case .oil:     iconText = "💧"
        case .gold:    iconText = "⚡"
        case .boss:    iconText = nil // Boss braucht kein kleines Icon
        case .chain:   iconText = nil // Chain hat Nummern
        case .normal:  iconText = nil
        }

        guard let text = iconText else { return }
        behaviorIcon = SKLabelNode(text: text)
        behaviorIcon!.fontName = "AvenirNext-Bold"
        behaviorIcon!.fontSize = 12
        behaviorIcon!.fontColor = SKColor(white: 1.0, alpha: 0.5)
        behaviorIcon!.position = CGPoint(x: radius * 0.6, y: -radius * 0.6)
        behaviorIcon!.zPosition = 2.5
        addChild(behaviorIcon!)
    }

    // MARK: - Öl-Visuals

    private func drawOilSwirls() {
        let swirlCount = Int(radius / 6)
        for i in 0..<swirlCount {
            let r = CGFloat(i + 1) * (radius * 0.8) / CGFloat(swirlCount)
            guard r < radius * 0.85 else { continue }

            let path = CGMutablePath()
            let startAngle = CGFloat.random(in: 0...(.pi * 2))
            let arcLength = CGFloat.random(in: (.pi * 0.6)...(.pi * 1.5))
            path.addArc(center: .zero, radius: r, startAngle: startAngle,
                        endAngle: startAngle + arcLength, clockwise: Bool.random())

            let swirl = SKShapeNode(path: path)
            swirl.strokeColor = SKColor(white: 0.15, alpha: CGFloat.random(in: 0.2...0.5))
            swirl.lineWidth = CGFloat.random(in: 1.0...2.5)
            swirl.fillColor = .clear
            swirl.glowWidth = 0.5
            fingerprintContainer.addChild(swirl)
        }
    }

    private func setupOilGloss() {
        // Glanz-Highlight (versetzter heller Kreis)
        let glossRadius = radius * 0.35
        oilGlossNode = SKShapeNode(circleOfRadius: glossRadius)
        oilGlossNode!.fillColor = SKColor(white: 1.0, alpha: 0.12)
        oilGlossNode!.strokeColor = .clear
        oilGlossNode!.position = CGPoint(x: -radius * 0.2, y: radius * 0.2)
        oilGlossNode!.zPosition = 1.8
        addChild(oilGlossNode!)
    }

    // MARK: - Gold-Visuals

    private func setupGoldShimmer() {
        // Goldener Schimmer-Ring
        goldShimmerNode = SKShapeNode(circleOfRadius: radius + 6)
        goldShimmerNode!.strokeColor = SKColor(red: 1.0, green: 0.84, blue: 0.0, alpha: 0.6)
        goldShimmerNode!.lineWidth = 3
        goldShimmerNode!.fillColor = .clear
        goldShimmerNode!.glowWidth = 4
        goldShimmerNode!.zPosition = 2.5
        addChild(goldShimmerNode!)

        // Pulsier-Animation
        let pulse = SKAction.sequence([
            SKAction.scale(to: 1.1, duration: 0.3),
            SKAction.scale(to: 0.95, duration: 0.3)
        ])
        goldShimmerNode!.run(SKAction.repeatForever(pulse))

        // Timer-Ring (schrumpft über 2 Sekunden)
        goldTimerRing = SKShapeNode(circleOfRadius: radius + 10)
        goldTimerRing!.strokeColor = SKColor(red: 1.0, green: 0.84, blue: 0.0, alpha: 0.4)
        goldTimerRing!.lineWidth = 2
        goldTimerRing!.fillColor = .clear
        goldTimerRing!.zPosition = 2.8
        addChild(goldTimerRing!)

        // Ganzer Node pulsiert leicht
        let nodePulse = SKAction.sequence([
            SKAction.scale(to: 1.05, duration: 0.25),
            SKAction.scale(to: 0.95, duration: 0.25)
        ])
        run(SKAction.repeatForever(nodePulse))
    }

    // MARK: - Ketten-Visuals

    private func setupChainRing() {
        guard let groupID = chainGroupID else { return }

        let ringColor = Self.chainColor(for: groupID)

        // Farbiger Ring
        chainRingNode = SKShapeNode(circleOfRadius: radius + 5)
        chainRingNode!.strokeColor = ringColor
        chainRingNode!.lineWidth = 3
        chainRingNode!.fillColor = .clear
        chainRingNode!.glowWidth = 2
        chainRingNode!.zPosition = 2.5
        addChild(chainRingNode!)

        // Nummer
        chainNumberLabel = SKLabelNode(text: "\(chainIndex)")
        chainNumberLabel!.fontName = "AvenirNext-Heavy"
        chainNumberLabel!.fontSize = 16
        chainNumberLabel!.fontColor = ringColor
        chainNumberLabel!.verticalAlignmentMode = .center
        chainNumberLabel!.horizontalAlignmentMode = .center
        chainNumberLabel!.position = CGPoint(x: 0, y: radius + 14)
        chainNumberLabel!.zPosition = 3
        addChild(chainNumberLabel!)

        // Hintergrund-Kreis für Nummer
        let numBg = SKShapeNode(circleOfRadius: 11)
        numBg.fillColor = SKColor(white: 0.1, alpha: 0.8)
        numBg.strokeColor = ringColor
        numBg.lineWidth = 1.5
        numBg.position = chainNumberLabel!.position
        numBg.zPosition = 2.9
        addChild(numBg)
    }

    // MARK: - Boss-Visuals

    private func drawBossCracks() {
        // Risse statt Fingerabdrücke
        let crackCount = 8
        for _ in 0..<crackCount {
            let path = CGMutablePath()
            let startAngle = CGFloat.random(in: 0...(.pi * 2))
            let startR = CGFloat.random(in: 0...radius * 0.3)
            let endR = CGFloat.random(in: radius * 0.5...radius * 0.85)

            var x = cos(startAngle) * startR
            var y = sin(startAngle) * startR
            path.move(to: CGPoint(x: x, y: y))

            let segments = Int.random(in: 3...6)
            for s in 0..<segments {
                let progress = CGFloat(s + 1) / CGFloat(segments)
                let r = startR + (endR - startR) * progress
                let angle = startAngle + CGFloat.random(in: -0.4...0.4)
                x = cos(angle) * r
                y = sin(angle) * r
                path.addLine(to: CGPoint(x: x, y: y))
            }

            let crack = SKShapeNode(path: path)
            crack.strokeColor = SKColor(red: 0.6, green: 0.1, blue: 0.1, alpha: CGFloat.random(in: 0.3...0.6))
            crack.lineWidth = CGFloat.random(in: 1.0...2.5)
            crack.fillColor = .clear
            fingerprintContainer.addChild(crack)
        }
    }

    private func setupBossHealthBar() {
        let barWidth = radius * 1.6
        let barHeight: CGFloat = 10
        let barY = -radius - 20

        // Hintergrund
        bossHealthBarBg = SKShapeNode(rectOf: CGSize(width: barWidth, height: barHeight), cornerRadius: 4)
        bossHealthBarBg!.fillColor = SKColor(white: 0.15, alpha: 0.8)
        bossHealthBarBg!.strokeColor = SKColor(white: 0.4, alpha: 0.5)
        bossHealthBarBg!.lineWidth = 1
        bossHealthBarBg!.position = CGPoint(x: 0, y: barY)
        bossHealthBarBg!.zPosition = 3
        addChild(bossHealthBarBg!)

        // Füllung (startet voll)
        bossHealthBarFill = SKShapeNode(rectOf: CGSize(width: barWidth - 4, height: barHeight - 4), cornerRadius: 3)
        bossHealthBarFill!.fillColor = .red
        bossHealthBarFill!.strokeColor = .clear
        bossHealthBarFill!.position = CGPoint(x: 0, y: barY)
        bossHealthBarFill!.zPosition = 3.1
        addChild(bossHealthBarFill!)

        // Bedrohliches Pulsieren
        let bossPulse = SKAction.sequence([
            SKAction.scale(to: 1.03, duration: 0.8),
            SKAction.scale(to: 0.97, duration: 0.8)
        ])
        run(SKAction.repeatForever(bossPulse))

        // Rauch-Partikel um den Boss
        spawnBossParticles()
    }

    private func spawnBossParticles() {
        let spawnAction = SKAction.run { [weak self] in
            guard let self = self else { return }
            let angle = CGFloat.random(in: 0...(.pi * 2))
            let dist = self.radius * CGFloat.random(in: 0.8...1.2)
            let particle = SKShapeNode(circleOfRadius: CGFloat.random(in: 2...5))
            particle.fillColor = SKColor(red: 0.4, green: 0.05, blue: 0.05, alpha: 0.5)
            particle.strokeColor = .clear
            particle.position = CGPoint(x: cos(angle) * dist, y: sin(angle) * dist)
            particle.zPosition = 0.5
            self.addChild(particle)

            particle.run(SKAction.sequence([
                SKAction.group([
                    SKAction.moveBy(x: CGFloat.random(in: -10...10), y: CGFloat.random(in: 10...25), duration: 1.0),
                    SKAction.fadeOut(withDuration: 1.0)
                ]),
                SKAction.removeFromParent()
            ]))
        }

        run(SKAction.repeatForever(SKAction.sequence([spawnAction, SKAction.wait(forDuration: 0.15)])),
            withKey: "bossParticles")
    }

    // MARK: - Fingerabdruck zeichnen (Standard)

    private func drawFingerprint() {
        let lighterColor = dirtColor.blended(withFraction: 0.15, of: SKColor(white: 0.6, alpha: 1.0))
        let darkerColor = dirtColor.blended(withFraction: 0.12, of: .black)

        let lineCount = Int(radius / 5)
        let centerOffset = CGPoint(
            x: CGFloat.random(in: -radius * 0.15...radius * 0.15),
            y: CGFloat.random(in: -radius * 0.15...radius * 0.15)
        )

        for i in 0..<lineCount {
            let arcRadius = CGFloat(i + 1) * (radius * 0.85) / CGFloat(lineCount)
            guard arcRadius < radius * 0.9 else { continue }

            let startAngle = CGFloat.random(in: 0...(.pi * 0.5))
            let arcLength = CGFloat.random(in: (.pi * 0.4)...(.pi * 1.2))

            let path = CGMutablePath()
            path.addArc(
                center: CGPoint(x: centerOffset.x, y: centerOffset.y),
                radius: arcRadius,
                startAngle: startAngle,
                endAngle: startAngle + arcLength,
                clockwise: Bool.random()
            )

            let arc = SKShapeNode(path: path)
            arc.strokeColor = (i % 2 == 0) ? (lighterColor ?? dirtColor) : (darkerColor ?? dirtColor)
            arc.lineWidth = CGFloat.random(in: 0.6...1.4)
            arc.fillColor = .clear
            arc.alpha = CGFloat.random(in: 0.3...0.6)
            fingerprintContainer.addChild(arc)
        }

        for _ in 0..<3 {
            let x1 = CGFloat.random(in: -radius * 0.5...radius * 0.5)
            let y1 = CGFloat.random(in: -radius * 0.3...radius * 0.3)
            let path = CGMutablePath()
            path.move(to: CGPoint(x: x1, y: y1))
            path.addLine(to: CGPoint(x: x1 + CGFloat.random(in: 5...15), y: y1 + CGFloat.random(in: -3...3)))
            let line = SKShapeNode(path: path)
            line.strokeColor = (darkerColor ?? dirtColor)
            line.lineWidth = 0.5
            line.alpha = 0.3
            fingerprintContainer.addChild(line)
        }
    }

    // MARK: - Model-Sync (pro Frame vom Scene aufgerufen)

    func syncWithModel(_ model: SmudgeModel) {
        self.position = model.position

        // Scale für wachsende/ölige Flecken
        if (model.behavior == .growing || model.behavior == .oil) && model.scaleFactor > 1.0 {
            dirtLayer?.setScale(model.scaleFactor)
            fingerprintContainer?.setScale(model.scaleFactor)
            progressRing?.setScale(model.scaleFactor)
            oilGlossNode?.setScale(model.scaleFactor)
        }

        // Boss-Lebensbalken
        if model.behavior == .boss {
            updateBossHealthBar(progress: model.progress)
        }

        // Gold-Countdown
        if model.behavior == .gold {
            let age = model.age(at: CACurrentMediaTime())
            let remaining = max(0, 1.0 - CGFloat(age / 2.0))
            goldTimerRing?.setScale(remaining)
            goldTimerRing?.alpha = remaining * 0.6
        }
    }

    private func updateBossHealthBar(progress: CGFloat) {
        let remaining = 1.0 - progress
        let barWidth = radius * 1.6 - 4
        bossHealthBarFill?.xScale = max(remaining, 0.001)

        // Farbe: rot → gelb → grün
        if remaining > 0.6 {
            bossHealthBarFill?.fillColor = .red
        } else if remaining > 0.3 {
            bossHealthBarFill?.fillColor = .orange
        } else {
            bossHealthBarFill?.fillColor = .green
        }
    }

    // MARK: - Reib-Feedback (visuell)

    func updateRubProgress(_ progress: CGFloat) {
        let baseAlpha: CGFloat = behavior == .oil ? 0.75 : 0.88
        dirtLayer?.alpha = baseAlpha * (1.0 - progress)
        fingerprintContainer?.alpha = 1.0 - progress
        rewardIcon?.alpha = progress * 0.8
        oilGlossNode?.alpha = 0.12 * (1.0 - progress)

        if progress > 0 && (progressRing?.alpha ?? 0) == 0 {
            progressRing?.run(SKAction.fadeAlpha(to: 0.6, duration: 0.1))
        }

        if progress > 0.7 {
            progressRing?.strokeColor = .green
        } else if progress > 0.4 {
            progressRing?.strokeColor = .yellow
        }
    }

    func spawnDirtParticle(at scenePoint: CGPoint) {
        guard let parentNode = parent else { return }
        let localPoint = convert(scenePoint, from: parentNode)
        let particle = SKShapeNode(circleOfRadius: CGFloat.random(in: 1.5...3.5))
        particle.fillColor = dirtColor
        particle.strokeColor = .clear
        particle.position = localPoint
        particle.zPosition = 3
        addChild(particle)

        let drift = SKAction.moveBy(
            x: CGFloat.random(in: -20...20),
            y: CGFloat.random(in: -20...20),
            duration: 0.4
        )
        particle.run(SKAction.sequence([
            SKAction.group([drift, SKAction.fadeOut(withDuration: 0.4)]),
            SKAction.removeFromParent()
        ]))
    }

    // MARK: - Animationen

    func playRevealAnimation() {
        removeAction(forKey: "bossParticles")

        dirtLayer?.run(SKAction.sequence([
            SKAction.group([
                SKAction.fadeOut(withDuration: 0.2),
                SKAction.scale(to: 1.3, duration: 0.2)
            ]),
            SKAction.removeFromParent()
        ]))

        fingerprintContainer?.run(SKAction.sequence([
            SKAction.fadeOut(withDuration: 0.15),
            SKAction.removeFromParent()
        ]))

        progressRing?.run(SKAction.fadeOut(withDuration: 0.2))
        behaviorIcon?.run(SKAction.fadeOut(withDuration: 0.1))
        oilGlossNode?.run(SKAction.fadeOut(withDuration: 0.15))
        goldShimmerNode?.run(SKAction.fadeOut(withDuration: 0.15))
        goldTimerRing?.run(SKAction.fadeOut(withDuration: 0.15))
        chainRingNode?.run(SKAction.fadeOut(withDuration: 0.15))
        chainNumberLabel?.run(SKAction.fadeOut(withDuration: 0.15))
        bossHealthBarBg?.run(SKAction.fadeOut(withDuration: 0.2))
        bossHealthBarFill?.run(SKAction.fadeOut(withDuration: 0.2))

        rewardIcon?.run(SKAction.sequence([
            SKAction.fadeIn(withDuration: 0.1),
            SKAction.scale(to: 1.3, duration: 0.1),
            SKAction.scale(to: 1.0, duration: 0.1)
        ]))
    }

    func playCollectionAnimation(completion: @escaping () -> Void) {
        let shrink = SKAction.scale(to: 0.0, duration: 0.3)
        shrink.timingMode = .easeIn

        run(SKAction.sequence([
            SKAction.wait(forDuration: behavior == .boss ? 0.8 : 0.4),
            SKAction.group([shrink, SKAction.fadeOut(withDuration: 0.3)]),
            SKAction.removeFromParent(),
            SKAction.run(completion)
        ]))
    }

    func playExpireAnimation() {
        run(SKAction.sequence([
            SKAction.fadeOut(withDuration: 0.5),
            SKAction.removeFromParent()
        ]))
    }

    func playGoldExpireAnimation() {
        // Gold verschwindet mit Glitzer-Effekt
        for _ in 0..<8 {
            let spark = SKShapeNode(circleOfRadius: CGFloat.random(in: 2...4))
            spark.fillColor = SKColor(red: 1.0, green: 0.84, blue: 0.0, alpha: 0.8)
            spark.strokeColor = .clear
            spark.glowWidth = 2
            spark.position = .zero
            spark.zPosition = 4
            addChild(spark)

            spark.run(SKAction.sequence([
                SKAction.group([
                    SKAction.moveBy(
                        x: CGFloat.random(in: -40...40),
                        y: CGFloat.random(in: -40...40),
                        duration: 0.5
                    ),
                    SKAction.fadeOut(withDuration: 0.5)
                ]),
                SKAction.removeFromParent()
            ]))
        }

        run(SKAction.sequence([
            SKAction.group([
                SKAction.scale(to: 0.0, duration: 0.4),
                SKAction.fadeOut(withDuration: 0.4)
            ]),
            SKAction.removeFromParent()
        ]))
    }

    // MARK: - Chain-Highlight (wenn richtig aufgedeckt)

    func playChainProgressAnimation() {
        chainRingNode?.run(SKAction.sequence([
            SKAction.scale(to: 1.3, duration: 0.1),
            SKAction.scale(to: 1.0, duration: 0.1)
        ]))
    }

    // MARK: - Helpers

    private static func randomDirtColor() -> SKColor {
        let colors: [(CGFloat, CGFloat, CGFloat)] = [
            (0.35, 0.25, 0.15),
            (0.40, 0.35, 0.25),
            (0.30, 0.30, 0.28),
            (0.45, 0.38, 0.20),
            (0.32, 0.28, 0.22),
        ]
        let c = colors.randomElement()!
        let v: CGFloat = 0.05
        return SKColor(
            red: c.0 + CGFloat.random(in: -v...v),
            green: c.1 + CGFloat.random(in: -v...v),
            blue: c.2 + CGFloat.random(in: -v...v),
            alpha: 1.0
        )
    }

    private static func oilColor() -> SKColor {
        return SKColor(
            red: CGFloat.random(in: 0.08...0.15),
            green: CGFloat.random(in: 0.06...0.12),
            blue: CGFloat.random(in: 0.05...0.10),
            alpha: 1.0
        )
    }

    private static func goldColor() -> SKColor {
        return SKColor(
            red: CGFloat.random(in: 0.75...0.85),
            green: CGFloat.random(in: 0.60...0.70),
            blue: CGFloat.random(in: 0.10...0.20),
            alpha: 1.0
        )
    }

    private static func bossColor() -> SKColor {
        return SKColor(
            red: CGFloat.random(in: 0.25...0.35),
            green: CGFloat.random(in: 0.02...0.08),
            blue: CGFloat.random(in: 0.02...0.08),
            alpha: 1.0
        )
    }

    static func chainColor(for groupID: UUID) -> SKColor {
        let hash = abs(groupID.hashValue)
        let hue = CGFloat(hash % 360) / 360.0
        return SKColor(hue: hue, saturation: 0.7, brightness: 0.9, alpha: 1.0)
    }
}

// MARK: - SKColor Extension

extension SKColor {
    func blended(withFraction fraction: CGFloat, of color: SKColor) -> SKColor? {
        var r1: CGFloat = 0, g1: CGFloat = 0, b1: CGFloat = 0, a1: CGFloat = 0
        var r2: CGFloat = 0, g2: CGFloat = 0, b2: CGFloat = 0, a2: CGFloat = 0
        getRed(&r1, green: &g1, blue: &b1, alpha: &a1)
        color.getRed(&r2, green: &g2, blue: &b2, alpha: &a2)
        return SKColor(
            red: r1 + (r2 - r1) * fraction,
            green: g1 + (g2 - g1) * fraction,
            blue: b1 + (b2 - b1) * fraction,
            alpha: a1 + (a2 - a1) * fraction
        )
    }
}
