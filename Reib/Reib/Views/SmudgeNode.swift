//
//  SmudgeNode.swift
//  Reib
//
//  Created by Andreas Pelczer on 26.02.26.
//

import SpriteKit

// MARK: - Visuelle Darstellung eines Dreckflecks (nur View, keine Logik)

class SmudgeNode: SKNode {

    let smudgeID: UUID
    let reward: SmudgeReward
    let behavior: SmudgeBehavior
    let radius: CGFloat

    private var dirtLayer: SKShapeNode!
    private var fingerprintContainer: SKNode!
    private var progressRing: SKShapeNode!
    private var rewardIcon: SKLabelNode!
    private var behaviorIcon: SKLabelNode?
    private var dirtColor: SKColor = .brown

    init(model: SmudgeModel) {
        self.smudgeID = model.id
        self.reward = model.reward
        self.behavior = model.behavior
        self.radius = model.radius
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

        // Dreckfleck-Basis
        dirtColor = Self.randomDirtColor()
        dirtLayer = SKShapeNode(circleOfRadius: radius)
        dirtLayer.fillColor = dirtColor
        dirtLayer.strokeColor = .clear
        dirtLayer.alpha = 0.88
        dirtLayer.zPosition = 1
        addChild(dirtLayer)

        // Fingerabdruck-Textur
        fingerprintContainer = SKNode()
        fingerprintContainer.zPosition = 1.5
        addChild(fingerprintContainer)
        drawFingerprint()

        // Fortschrittsring
        progressRing = SKShapeNode(circleOfRadius: radius + 3)
        progressRing.strokeColor = .white
        progressRing.lineWidth = 2
        progressRing.fillColor = .clear
        progressRing.alpha = 0
        progressRing.zPosition = 2
        addChild(progressRing)

        // Verhaltens-Indikator
        if behavior != .normal {
            behaviorIcon = SKLabelNode(text: behavior == .moving ? "~" : "+")
            behaviorIcon!.fontName = "AvenirNext-Bold"
            behaviorIcon!.fontSize = 12
            behaviorIcon!.fontColor = SKColor(white: 1.0, alpha: 0.5)
            behaviorIcon!.position = CGPoint(x: radius * 0.6, y: -radius * 0.6)
            behaviorIcon!.zPosition = 2.5
            addChild(behaviorIcon!)
        }

        // Einblend-Animation
        self.setScale(0.1)
        let scaleUp = SKAction.scale(to: 1.0, duration: 0.3)
        scaleUp.timingMode = .easeOut
        run(SKAction.group([scaleUp, SKAction.fadeIn(withDuration: 0.3)]))
    }

    // MARK: - Fingerabdruck zeichnen

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

        // Querlinien
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

        // Scale für wachsende Flecken (nicht die Einblend-Animation überschreiben)
        if model.behavior == .growing && model.scaleFactor > 1.0 {
            // Nur die Inhalte skalieren, nicht den Node selbst
            dirtLayer?.setScale(model.scaleFactor)
            fingerprintContainer?.setScale(model.scaleFactor)
            progressRing?.setScale(model.scaleFactor)
        }
    }

    // MARK: - Reib-Feedback (visuell)

    func updateRubProgress(_ progress: CGFloat) {
        dirtLayer?.alpha = 0.88 * (1.0 - progress)
        fingerprintContainer?.alpha = 1.0 - progress
        rewardIcon?.alpha = progress * 0.8

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
        let localPoint = convert(scenePoint, from: parent!)
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
            SKAction.wait(forDuration: 0.4),
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
