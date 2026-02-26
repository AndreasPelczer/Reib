//
//  GameScene.swift
//  Reib
//
//  Created by Andreas Pelczer on 26.02.26.
//
//  Reib! – Das Freirubbel-Spiel
//  Menschen reiben an ihren Displays. Jetzt ist das ein Spiel.
//

import SpriteKit

// MARK: - Was sich unter einem Fleck versteckt

enum SmudgeReward {
    case star           // ⭐ Punkte
    case doubleStar     // 🌟 Doppelte Punkte
    case bomb           // 💣 Leben verlieren
    case timeBonus      // ⏱️ Verlangsamt nächste Welle
    case freeze         // 🧊 Friert alle Flecken ein (keine neuen für 3s)
}

// MARK: - Fleck-Verhalten

enum SmudgeBehavior {
    case normal         // Bleibt stehen
    case moving         // Driftet langsam umher
    case growing        // Wächst mit der Zeit
}

// MARK: - Ein einzelner Dreckfleck

class Smudge: SKNode {

    let reward: SmudgeReward
    let behavior: SmudgeBehavior
    let radius: CGFloat
    var rubbedPixels: Int = 0
    let totalPixels: Int = 100
    var isRevealed: Bool = false
    var currentRadius: CGFloat

    // Die sichtbare Dreckschicht
    private var dirtLayer: SKShapeNode!
    private var fingerprintContainer: SKNode!
    private var progressRing: SKShapeNode!
    private var rewardIcon: SKLabelNode!
    private var behaviorIcon: SKLabelNode?
    private var dirtColor: SKColor = .brown

    init(reward: SmudgeReward, radius: CGFloat = 40, behavior: SmudgeBehavior = .normal) {
        self.reward = reward
        self.behavior = behavior
        self.radius = radius
        self.currentRadius = radius
        super.init()
        setupVisuals()
        setupBehavior()
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setupVisuals() {
        // Belohnungs-Icon (zunächst versteckt)
        rewardIcon = SKLabelNode(text: rewardEmoji)
        rewardIcon.fontSize = radius * 0.9
        rewardIcon.verticalAlignmentMode = .center
        rewardIcon.horizontalAlignmentMode = .center
        rewardIcon.alpha = 0
        rewardIcon.zPosition = 0
        addChild(rewardIcon)

        // Dreckfleck-Basis
        dirtColor = randomDirtColor()
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
        let fadeIn = SKAction.fadeIn(withDuration: 0.3)
        run(SKAction.group([scaleUp, fadeIn]))
    }

    private func drawFingerprint() {
        let lighterColor = dirtColor.blended(withFraction: 0.15, of: SKColor(white: 0.6, alpha: 1.0))
        let darkerColor = dirtColor.blended(withFraction: 0.12, of: .black)

        // Konzentrische Bögen wie ein Fingerabdruck
        let lineCount = Int(radius / 5)
        let centerOffset = CGPoint(
            x: CGFloat.random(in: -radius * 0.15...radius * 0.15),
            y: CGFloat.random(in: -radius * 0.15...radius * 0.15)
        )

        for i in 0..<lineCount {
            let arcRadius = CGFloat(i + 1) * (radius * 0.85) / CGFloat(lineCount)
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

            // Clip: nur innerhalb des Kreises sichtbar
            if arcRadius < radius * 0.9 {
                fingerprintContainer.addChild(arc)
            }
        }

        // Einige kurze Querlinien für Realismus
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

    private func setupBehavior() {
        switch behavior {
        case .moving:
            let drift = SKAction.sequence([
                SKAction.moveBy(
                    x: CGFloat.random(in: -30...30),
                    y: CGFloat.random(in: -30...30),
                    duration: TimeInterval.random(in: 1.5...3.0)
                ),
                SKAction.moveBy(
                    x: CGFloat.random(in: -30...30),
                    y: CGFloat.random(in: -30...30),
                    duration: TimeInterval.random(in: 1.5...3.0)
                )
            ])
            run(SKAction.repeatForever(drift), withKey: "drift")

        case .growing:
            let grow = SKAction.scale(to: 1.3, duration: 8.0)
            grow.timingMode = .easeIn
            run(grow, withKey: "grow")

        case .normal:
            break
        }
    }

    private var rewardEmoji: String {
        switch reward {
        case .star: return "⭐"
        case .doubleStar: return "🌟"
        case .bomb: return "💣"
        case .timeBonus: return "⏱️"
        case .freeze: return "🧊"
        }
    }

    private func randomDirtColor() -> SKColor {
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

    // MARK: - Reiben!

    func rub(at point: CGPoint, intensity: CGFloat = 1.0) -> Bool {
        guard !isRevealed else { return false }

        let localPoint = convert(point, from: parent!)
        let distance = hypot(localPoint.x, localPoint.y)
        let effectiveRadius = radius * xScale  // Berücksichtige Wachstum
        guard distance <= effectiveRadius else { return false }

        if progressRing.alpha == 0 {
            progressRing.run(SKAction.fadeAlpha(to: 0.6, duration: 0.1))
        }

        let centerBonus = 1.0 + (1.0 - distance / effectiveRadius) * 0.5
        let rubAmount = Int(intensity * centerBonus * 3)
        rubbedPixels = min(rubbedPixels + rubAmount, totalPixels)

        let progress = CGFloat(rubbedPixels) / CGFloat(totalPixels)
        dirtLayer.alpha = 0.88 * (1.0 - progress)
        fingerprintContainer.alpha = 1.0 - progress
        rewardIcon.alpha = progress * 0.8

        if progress > 0.7 {
            progressRing.strokeColor = .green
        } else if progress > 0.4 {
            progressRing.strokeColor = .yellow
        }

        spawnDirtParticle(at: localPoint)

        if rubbedPixels >= totalPixels {
            reveal()
            return true
        }

        return false
    }

    private func spawnDirtParticle(at point: CGPoint) {
        let particle = SKShapeNode(circleOfRadius: CGFloat.random(in: 1.5...3.5))
        particle.fillColor = dirtColor
        particle.strokeColor = .clear
        particle.position = point
        particle.zPosition = 3
        addChild(particle)

        let drift = SKAction.moveBy(
            x: CGFloat.random(in: -20...20),
            y: CGFloat.random(in: -20...20),
            duration: 0.4
        )
        let fadeOut = SKAction.fadeOut(withDuration: 0.4)
        let remove = SKAction.removeFromParent()
        particle.run(SKAction.sequence([SKAction.group([drift, fadeOut]), remove]))
    }

    private func reveal() {
        isRevealed = true
        removeAction(forKey: "drift")
        removeAction(forKey: "grow")

        dirtLayer.run(SKAction.sequence([
            SKAction.group([
                SKAction.fadeOut(withDuration: 0.2),
                SKAction.scale(to: 1.3, duration: 0.2)
            ]),
            SKAction.removeFromParent()
        ]))

        fingerprintContainer.run(SKAction.sequence([
            SKAction.fadeOut(withDuration: 0.15),
            SKAction.removeFromParent()
        ]))

        progressRing.run(SKAction.fadeOut(withDuration: 0.2))
        behaviorIcon?.run(SKAction.fadeOut(withDuration: 0.1))

        rewardIcon.run(SKAction.sequence([
            SKAction.fadeIn(withDuration: 0.1),
            SKAction.scale(to: 1.3, duration: 0.1),
            SKAction.scale(to: 1.0, duration: 0.1)
        ]))
    }

    func animateCollection(completion: @escaping () -> Void) {
        let shrink = SKAction.scale(to: 0.0, duration: 0.3)
        let fade = SKAction.fadeOut(withDuration: 0.3)
        shrink.timingMode = .easeIn

        run(SKAction.sequence([
            SKAction.wait(forDuration: 0.4),
            SKAction.group([shrink, fade]),
            SKAction.removeFromParent(),
            SKAction.run(completion)
        ]))
    }
}

// MARK: - SKColor Hilfsfunktion

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

// MARK: - Die Spielszene

class GameScene: SKScene {

    // MARK: - Spielzustand

    enum GameState {
        case menu
        case playing
        case paused
        case gameOver
    }

    var gameState: GameState = .menu

    // MARK: - Spielwerte

    var score: Int = 0 {
        didSet { scoreLabel?.text = "\(score)" }
    }
    var lives: Int = 3 {
        didSet { updateLivesDisplay() }
    }
    var wave: Int = 1
    var smudgesCleared: Int = 0
    var smudgesPerWave: Int = 3
    var activeSmudges: [Smudge] = []

    // Timing
    var waveDelay: TimeInterval = 7.0
    var lastWaveTime: TimeInterval = 0
    var isFrozen: Bool = false
    var frozenUntil: TimeInterval = 0

    // Combo-System
    var comboCount: Int = 0
    var lastRevealTime: TimeInterval = 0
    let comboTimeout: TimeInterval = 2.0
    var comboMultiplier: Int {
        if comboCount >= 6 { return 4 }
        if comboCount >= 4 { return 3 }
        if comboCount >= 2 { return 2 }
        return 1
    }

    // Putz-Streak
    var streakCount: Int = 0
    var bestStreak: Int = 0

    // Bestenliste
    let leaderboardKey = "ReibLeaderboard"
    var leaderboard: [Int] = []

    // MARK: - UI Elemente

    var scoreLabel: SKLabelNode!
    var waveLabelNode: SKLabelNode!
    var livesNodes: [SKLabelNode] = []
    var comboLabel: SKLabelNode!
    var streakLabel: SKLabelNode!
    var pauseButton: SKNode!
    var pauseContainer: SKNode?
    var highscoreLabel: SKLabelNode!
    var leaderboardContainer: SKNode?
    var titleLabel: SKLabelNode!
    var subtitleLabel: SKLabelNode!
    var startButton: SKShapeNode!
    var gameOverContainer: SKNode!

    // Hintergrund
    var backgroundNode: SKNode!

    // Wisch-Spuren
    var wipeTrailNodes: [SKNode] = []

    // MARK: - Touch Tracking

    var lastTouchPositions: [UITouch: CGPoint] = [:]

    // MARK: - Scene Lifecycle

    override func didMove(to view: SKView) {
        backgroundColor = SKColor(red: 0.08, green: 0.08, blue: 0.10, alpha: 1.0)
        loadLeaderboard()
        setupBackground()
        showMenu()
    }

    // MARK: - Hintergrund

    func setupBackground() {
        backgroundNode = SKNode()
        backgroundNode.zPosition = -10
        addChild(backgroundNode)

        // Subtiler radialer Gradient (von Mitte heller nach Rand dunkler)
        let layers = 8
        for i in (0..<layers).reversed() {
            let fraction = CGFloat(i) / CGFloat(layers)
            let layerRadius = max(size.width, size.height) * fraction
            let circle = SKShapeNode(circleOfRadius: layerRadius)
            let brightness: CGFloat = 0.06 + (1.0 - fraction) * 0.04
            circle.fillColor = SKColor(white: brightness, alpha: 1.0)
            circle.strokeColor = .clear
            circle.position = CGPoint(x: size.width / 2, y: size.height / 2)
            backgroundNode.addChild(circle)
        }

        // Dezente Pixelraster-Linien
        for i in stride(from: CGFloat(0), to: size.width, by: 20) {
            let line = SKShapeNode(rectOf: CGSize(width: 0.5, height: size.height))
            line.fillColor = SKColor(white: 1.0, alpha: 0.015)
            line.strokeColor = .clear
            line.position = CGPoint(x: i, y: size.height / 2)
            backgroundNode.addChild(line)
        }
        for i in stride(from: CGFloat(0), to: size.height, by: 20) {
            let line = SKShapeNode(rectOf: CGSize(width: size.width, height: 0.5))
            line.fillColor = SKColor(white: 1.0, alpha: 0.015)
            line.strokeColor = .clear
            line.position = CGPoint(x: size.width / 2, y: i)
            backgroundNode.addChild(line)
        }

        // Schwach leuchtende Partikel im Hintergrund
        for _ in 0..<12 {
            let dot = SKShapeNode(circleOfRadius: CGFloat.random(in: 1...2.5))
            dot.fillColor = SKColor(white: 1.0, alpha: CGFloat.random(in: 0.03...0.08))
            dot.strokeColor = .clear
            dot.position = CGPoint(
                x: CGFloat.random(in: 0...size.width),
                y: CGFloat.random(in: 0...size.height)
            )
            backgroundNode.addChild(dot)

            let drift = SKAction.sequence([
                SKAction.moveBy(
                    x: CGFloat.random(in: -15...15),
                    y: CGFloat.random(in: -15...15),
                    duration: TimeInterval.random(in: 4...8)
                ),
                SKAction.moveBy(
                    x: CGFloat.random(in: -15...15),
                    y: CGFloat.random(in: -15...15),
                    duration: TimeInterval.random(in: 4...8)
                )
            ])
            dot.run(SKAction.repeatForever(drift))
        }
    }

    // MARK: - Bestenliste (UserDefaults)

    func loadLeaderboard() {
        leaderboard = UserDefaults.standard.array(forKey: leaderboardKey) as? [Int] ?? []
    }

    func saveToLeaderboard(_ newScore: Int) {
        leaderboard.append(newScore)
        leaderboard.sort(by: >)
        if leaderboard.count > 5 { leaderboard = Array(leaderboard.prefix(5)) }
        UserDefaults.standard.set(leaderboard, forKey: leaderboardKey)
    }

    var highscore: Int {
        return leaderboard.first ?? 0
    }

    // MARK: - Menü

    func showMenu() {
        gameState = .menu
        removeGameUI()

        titleLabel = SKLabelNode(text: "REIB!")
        titleLabel.fontName = "AvenirNext-Heavy"
        titleLabel.fontSize = 72
        titleLabel.fontColor = .white
        titleLabel.position = CGPoint(x: size.width / 2, y: size.height * 0.70)
        titleLabel.zPosition = 10
        addChild(titleLabel)

        let pulse = SKAction.sequence([
            SKAction.scale(to: 1.05, duration: 1.0),
            SKAction.scale(to: 0.95, duration: 1.0)
        ])
        titleLabel.run(SKAction.repeatForever(pulse))

        subtitleLabel = SKLabelNode(text: "Rubbel den Dreck weg!")
        subtitleLabel.fontName = "AvenirNext-Medium"
        subtitleLabel.fontSize = 20
        subtitleLabel.fontColor = SKColor(white: 0.7, alpha: 1.0)
        subtitleLabel.position = CGPoint(x: size.width / 2, y: size.height * 0.62)
        subtitleLabel.zPosition = 10
        addChild(subtitleLabel)

        // Start Button
        let buttonSize = CGSize(width: 200, height: 60)
        startButton = SKShapeNode(rectOf: buttonSize, cornerRadius: 12)
        startButton.fillColor = SKColor(red: 0.2, green: 0.7, blue: 0.3, alpha: 1.0)
        startButton.strokeColor = .clear
        startButton.position = CGPoint(x: size.width / 2, y: size.height * 0.50)
        startButton.zPosition = 10
        startButton.name = "startButton"
        addChild(startButton)

        let buttonLabel = SKLabelNode(text: "LOS REIBEN!")
        buttonLabel.fontName = "AvenirNext-Bold"
        buttonLabel.fontSize = 22
        buttonLabel.fontColor = .white
        buttonLabel.verticalAlignmentMode = .center
        buttonLabel.name = "startButton"
        startButton.addChild(buttonLabel)

        // Bestenliste im Menü
        if !leaderboard.isEmpty {
            leaderboardContainer = SKNode()
            leaderboardContainer!.zPosition = 10
            addChild(leaderboardContainer!)

            let lbTitle = SKLabelNode(text: "Bestenliste")
            lbTitle.fontName = "AvenirNext-Bold"
            lbTitle.fontSize = 20
            lbTitle.fontColor = SKColor(white: 0.6, alpha: 1.0)
            lbTitle.position = CGPoint(x: size.width / 2, y: size.height * 0.38)
            leaderboardContainer!.addChild(lbTitle)

            for (i, entry) in leaderboard.prefix(5).enumerated() {
                let medal: String
                switch i {
                case 0: medal = "🥇"
                case 1: medal = "🥈"
                case 2: medal = "🥉"
                default: medal = "  \(i + 1)."
                }
                let label = SKLabelNode(text: "\(medal) \(entry)")
                label.fontName = "AvenirNext-Medium"
                label.fontSize = 16
                label.fontColor = SKColor(white: 0.5, alpha: 1.0)
                label.position = CGPoint(x: size.width / 2, y: size.height * 0.34 - CGFloat(i) * 24)
                leaderboardContainer!.addChild(label)
            }
        }

        // Demo-Flecken
        spawnMenuSmudges()
    }

    func spawnMenuSmudges() {
        for _ in 0..<5 {
            let smudge = Smudge(reward: .star, radius: CGFloat.random(in: 25...50))
            smudge.position = CGPoint(
                x: CGFloat.random(in: 60...(size.width - 60)),
                y: CGFloat.random(in: size.height * 0.05...size.height * 0.18)
            )
            smudge.zPosition = 5
            smudge.alpha = 0.4
            smudge.name = "menuSmudge"
            addChild(smudge)
        }
    }

    // MARK: - Spiel starten

    func startGame() {
        gameState = .playing
        score = 0
        lives = 3
        wave = 1
        smudgesCleared = 0
        smudgesPerWave = 3
        waveDelay = 7.0
        activeSmudges = []
        isFrozen = false
        comboCount = 0
        streakCount = 0
        bestStreak = 0
        lastRevealTime = 0

        // Menü aufräumen
        titleLabel?.removeFromParent()
        subtitleLabel?.removeFromParent()
        highscoreLabel?.removeFromParent()
        startButton?.removeFromParent()
        gameOverContainer?.removeFromParent()
        leaderboardContainer?.removeFromParent()
        leaderboardContainer = nil
        enumerateChildNodes(withName: "menuSmudge") { node, _ in
            node.removeFromParent()
        }

        setupGameUI()
        spawnWave()
    }

    // MARK: - Spiel UI

    func setupGameUI() {
        // Score oben mittig
        scoreLabel = SKLabelNode(text: "0")
        scoreLabel.fontName = "AvenirNext-Heavy"
        scoreLabel.fontSize = 48
        scoreLabel.fontColor = .white
        scoreLabel.position = CGPoint(x: size.width / 2, y: size.height - 80)
        scoreLabel.zPosition = 20
        addChild(scoreLabel)

        // Welle
        waveLabelNode = SKLabelNode(text: "Welle 1")
        waveLabelNode.fontName = "AvenirNext-Medium"
        waveLabelNode.fontSize = 16
        waveLabelNode.fontColor = SKColor(white: 0.5, alpha: 1.0)
        waveLabelNode.position = CGPoint(x: size.width / 2, y: size.height - 100)
        waveLabelNode.zPosition = 20
        addChild(waveLabelNode)

        // Combo-Anzeige (unter Score)
        comboLabel = SKLabelNode(text: "")
        comboLabel.fontName = "AvenirNext-Bold"
        comboLabel.fontSize = 18
        comboLabel.fontColor = .orange
        comboLabel.position = CGPoint(x: size.width / 2, y: size.height - 120)
        comboLabel.zPosition = 20
        addChild(comboLabel)

        // Streak-Anzeige (oben rechts)
        streakLabel = SKLabelNode(text: "")
        streakLabel.fontName = "AvenirNext-DemiBold"
        streakLabel.fontSize = 14
        streakLabel.fontColor = SKColor(white: 0.6, alpha: 1.0)
        streakLabel.horizontalAlignmentMode = .right
        streakLabel.position = CGPoint(x: size.width - 60, y: size.height - 75)
        streakLabel.zPosition = 20
        addChild(streakLabel)

        // Pause-Button (oben rechts)
        pauseButton = SKNode()
        pauseButton.position = CGPoint(x: size.width - 30, y: size.height - 40)
        pauseButton.zPosition = 25
        pauseButton.name = "pauseButton"

        let pauseBg = SKShapeNode(circleOfRadius: 18)
        pauseBg.fillColor = SKColor(white: 0.2, alpha: 0.6)
        pauseBg.strokeColor = SKColor(white: 0.5, alpha: 0.4)
        pauseBg.lineWidth = 1
        pauseBg.name = "pauseButton"
        pauseButton.addChild(pauseBg)

        let pauseIcon = SKLabelNode(text: "⏸")
        pauseIcon.fontSize = 18
        pauseIcon.verticalAlignmentMode = .center
        pauseIcon.horizontalAlignmentMode = .center
        pauseIcon.name = "pauseButton"
        pauseButton.addChild(pauseIcon)

        addChild(pauseButton)

        updateLivesDisplay()
    }

    func updateLivesDisplay() {
        livesNodes.forEach { $0.removeFromParent() }
        livesNodes.removeAll()

        for i in 0..<lives {
            let heart = SKLabelNode(text: "❤️")
            heart.fontSize = 28
            heart.position = CGPoint(x: 30 + CGFloat(i) * 36, y: size.height - 50)
            heart.zPosition = 20
            addChild(heart)
            livesNodes.append(heart)
        }
    }

    func updateComboDisplay() {
        if comboMultiplier > 1 {
            comboLabel?.text = "COMBO x\(comboMultiplier)!"
            comboLabel?.fontColor = comboMultiplier >= 4 ? .red :
                                    comboMultiplier >= 3 ? .orange : .yellow
            comboLabel?.run(SKAction.sequence([
                SKAction.scale(to: 1.3, duration: 0.08),
                SKAction.scale(to: 1.0, duration: 0.08)
            ]))
        } else {
            comboLabel?.text = ""
        }
    }

    func updateStreakDisplay() {
        if streakCount >= 3 {
            streakLabel?.text = "Streak: \(streakCount)"
        } else {
            streakLabel?.text = ""
        }
    }

    func removeGameUI() {
        scoreLabel?.removeFromParent()
        waveLabelNode?.removeFromParent()
        comboLabel?.removeFromParent()
        streakLabel?.removeFromParent()
        pauseButton?.removeFromParent()
        pauseContainer?.removeFromParent()
        pauseContainer = nil
        livesNodes.forEach { $0.removeFromParent() }
        livesNodes.removeAll()
        activeSmudges.forEach { $0.removeFromParent() }
        activeSmudges.removeAll()
        clearWipeTrails()
    }

    // MARK: - Wisch-Spuren

    func addWipeTrail(from: CGPoint, to: CGPoint) {
        let path = CGMutablePath()
        path.move(to: from)
        path.addLine(to: to)

        let trail = SKShapeNode(path: path)
        trail.strokeColor = SKColor(white: 0.3, alpha: 0.15)
        trail.lineWidth = CGFloat.random(in: 8...16)
        trail.lineCap = .round
        trail.zPosition = 1
        trail.name = "wipeTrail"
        addChild(trail)
        wipeTrailNodes.append(trail)

        // Verblassen nach 3 Sekunden
        trail.run(SKAction.sequence([
            SKAction.wait(forDuration: 3.0),
            SKAction.fadeOut(withDuration: 1.0),
            SKAction.removeFromParent()
        ])) { [weak self] in
            self?.wipeTrailNodes.removeAll { $0 === trail }
        }
    }

    func clearWipeTrails() {
        wipeTrailNodes.forEach { $0.removeFromParent() }
        wipeTrailNodes.removeAll()
        enumerateChildNodes(withName: "wipeTrail") { node, _ in
            node.removeFromParent()
        }
    }

    // MARK: - Pause

    func togglePause() {
        if gameState == .playing {
            showPause()
        } else if gameState == .paused {
            resumeGame()
        }
    }

    func showPause() {
        gameState = .paused
        isPaused = true

        pauseContainer = SKNode()
        pauseContainer!.zPosition = 60
        addChild(pauseContainer!)

        // Dunkler Overlay
        let overlay = SKShapeNode(rectOf: CGSize(width: size.width * 2, height: size.height * 2))
        overlay.fillColor = SKColor(red: 0, green: 0, blue: 0, alpha: 0.7)
        overlay.strokeColor = .clear
        overlay.position = CGPoint(x: size.width / 2, y: size.height / 2)
        overlay.name = "pauseOverlay"
        pauseContainer!.addChild(overlay)

        let pauseTitle = SKLabelNode(text: "PAUSE")
        pauseTitle.fontName = "AvenirNext-Heavy"
        pauseTitle.fontSize = 48
        pauseTitle.fontColor = .white
        pauseTitle.position = CGPoint(x: size.width / 2, y: size.height * 0.60)
        pauseContainer!.addChild(pauseTitle)

        // Weiter-Button
        let resumeBtn = SKShapeNode(rectOf: CGSize(width: 200, height: 55), cornerRadius: 12)
        resumeBtn.fillColor = SKColor(red: 0.2, green: 0.7, blue: 0.3, alpha: 1.0)
        resumeBtn.strokeColor = .clear
        resumeBtn.position = CGPoint(x: size.width / 2, y: size.height * 0.45)
        resumeBtn.name = "resumeButton"
        pauseContainer!.addChild(resumeBtn)

        let resumeLabel = SKLabelNode(text: "WEITER")
        resumeLabel.fontName = "AvenirNext-Bold"
        resumeLabel.fontSize = 22
        resumeLabel.fontColor = .white
        resumeLabel.verticalAlignmentMode = .center
        resumeLabel.name = "resumeButton"
        resumeBtn.addChild(resumeLabel)

        // Zurück zum Menü
        let menuBtn = SKShapeNode(rectOf: CGSize(width: 200, height: 55), cornerRadius: 12)
        menuBtn.fillColor = SKColor(white: 0.3, alpha: 0.8)
        menuBtn.strokeColor = .clear
        menuBtn.position = CGPoint(x: size.width / 2, y: size.height * 0.35)
        menuBtn.name = "backToMenuButton"
        pauseContainer!.addChild(menuBtn)

        let menuLabel = SKLabelNode(text: "HAUPTMENÜ")
        menuLabel.fontName = "AvenirNext-Bold"
        menuLabel.fontSize = 20
        menuLabel.fontColor = .white
        menuLabel.verticalAlignmentMode = .center
        menuLabel.name = "backToMenuButton"
        menuBtn.addChild(menuLabel)
    }

    func resumeGame() {
        gameState = .playing
        isPaused = false
        pauseContainer?.removeFromParent()
        pauseContainer = nil

        // lastWaveTime anpassen damit nicht sofort neue Welle kommt
        lastWaveTime = CACurrentMediaTime()
    }

    func backToMenu() {
        isPaused = false
        removeGameUI()
        gameOverContainer?.removeFromParent()
        showMenu()
    }

    // MARK: - Wellen-System

    func spawnWave() {
        guard gameState == .playing else { return }

        waveLabelNode?.text = "Welle \(wave)"

        let announcement = SKLabelNode(text: "Welle \(wave)")
        announcement.fontName = "AvenirNext-Heavy"
        announcement.fontSize = 36
        announcement.fontColor = SKColor(white: 1.0, alpha: 0.8)
        announcement.position = CGPoint(x: size.width / 2, y: size.height / 2)
        announcement.zPosition = 30
        addChild(announcement)

        announcement.run(SKAction.sequence([
            SKAction.group([
                SKAction.scale(to: 1.5, duration: 0.6),
                SKAction.fadeOut(withDuration: 0.6)
            ]),
            SKAction.removeFromParent()
        ]))

        let count = smudgesForCurrentWave()
        for i in 0..<count {
            let delay = SKAction.wait(forDuration: Double(i) * 0.3)
            run(SKAction.sequence([delay, SKAction.run { [weak self] in
                self?.spawnSmudge()
            }]))
        }

        lastWaveTime = CACurrentMediaTime()
    }

    func smudgesForCurrentWave() -> Int {
        return min(smudgesPerWave + (wave - 1) / 2, 8)
    }

    func spawnSmudge() {
        guard gameState == .playing else { return }

        let reward = randomReward()
        let behavior = randomBehavior()
        let radius = CGFloat.random(in: 30...55)
        let smudge = Smudge(reward: reward, radius: radius, behavior: behavior)

        var position: CGPoint
        var attempts = 0
        repeat {
            position = CGPoint(
                x: CGFloat.random(in: (radius + 20)...(size.width - radius - 20)),
                y: CGFloat.random(in: (radius + 140)...(size.height - radius - 120))
            )
            attempts += 1
        } while isTooCloseToOtherSmudges(position, minDistance: radius * 2.5) && attempts < 20

        smudge.position = position
        smudge.zPosition = 5
        addChild(smudge)
        activeSmudges.append(smudge)
    }

    func isTooCloseToOtherSmudges(_ point: CGPoint, minDistance: CGFloat) -> Bool {
        for smudge in activeSmudges {
            let dist = hypot(smudge.position.x - point.x, smudge.position.y - point.y)
            if dist < minDistance { return true }
        }
        return false
    }

    func randomReward() -> SmudgeReward {
        let roll = Int.random(in: 1...100)
        let bombChance = min(10 + wave * 2, 25)

        if roll <= bombChance {
            return .bomb
        } else if roll <= bombChance + 5 {
            return .freeze
        } else if roll <= bombChance + 10 {
            return .timeBonus
        } else if roll <= bombChance + 20 {
            return .doubleStar
        } else {
            return .star
        }
    }

    func randomBehavior() -> SmudgeBehavior {
        if wave < 3 { return .normal }

        let roll = Int.random(in: 1...100)
        let moveChance = min(10 + (wave - 3) * 3, 30)
        let growChance = wave >= 5 ? min(8 + (wave - 5) * 2, 20) : 0

        if roll <= moveChance {
            return .moving
        } else if roll <= moveChance + growChance {
            return .growing
        }
        return .normal
    }

    // MARK: - Belohnung verarbeiten

    func processReward(_ smudge: Smudge) {
        let now = CACurrentMediaTime()

        switch smudge.reward {
        case .star:
            // Combo prüfen
            if now - lastRevealTime < comboTimeout && lastRevealTime > 0 {
                comboCount += 1
            } else {
                comboCount = 1
            }
            lastRevealTime = now

            let basePoints = 10 * wave
            let totalPoints = basePoints * comboMultiplier
            addScore(totalPoints)
            let comboText = comboMultiplier > 1 ? " (x\(comboMultiplier))" : ""
            showFloatingText("+\(totalPoints)\(comboText)", at: smudge.position, color: .yellow)
            streakCount += 1

        case .doubleStar:
            if now - lastRevealTime < comboTimeout && lastRevealTime > 0 {
                comboCount += 1
            } else {
                comboCount = 1
            }
            lastRevealTime = now

            let basePoints = 25 * wave
            let totalPoints = basePoints * comboMultiplier
            addScore(totalPoints)
            let comboText = comboMultiplier > 1 ? " (x\(comboMultiplier))" : ""
            showFloatingText("+\(totalPoints)\(comboText)", at: smudge.position, color: .orange)
            streakCount += 1

        case .bomb:
            loseLife(at: smudge.position)
            comboCount = 0
            if streakCount > bestStreak { bestStreak = streakCount }
            streakCount = 0

        case .timeBonus:
            waveDelay += 2.0
            showFloatingText("+2s", at: smudge.position, color: .cyan)
            streakCount += 1

        case .freeze:
            activateFreeze()
            showFloatingText("FREEZE!", at: smudge.position, color: .cyan)
            streakCount += 1
        }

        smudgesCleared += 1
        updateComboDisplay()
        updateStreakDisplay()
    }

    func addScore(_ points: Int) {
        score += points
        scoreLabel?.run(SKAction.sequence([
            SKAction.scale(to: 1.2, duration: 0.1),
            SKAction.scale(to: 1.0, duration: 0.1)
        ]))
    }

    func loseLife(at position: CGPoint) {
        lives -= 1
        showFloatingText("💥", at: position, color: .red)

        let shake = SKAction.sequence([
            SKAction.moveBy(x: 10, y: 0, duration: 0.03),
            SKAction.moveBy(x: -20, y: 0, duration: 0.03),
            SKAction.moveBy(x: 15, y: 0, duration: 0.03),
            SKAction.moveBy(x: -10, y: 0, duration: 0.03),
            SKAction.moveBy(x: 5, y: 0, duration: 0.03),
        ])
        backgroundNode?.run(shake)

        let flash = SKShapeNode(rectOf: size)
        flash.fillColor = SKColor(red: 1, green: 0, blue: 0, alpha: 0.3)
        flash.strokeColor = .clear
        flash.position = CGPoint(x: size.width / 2, y: size.height / 2)
        flash.zPosition = 50
        addChild(flash)
        flash.run(SKAction.sequence([
            SKAction.fadeOut(withDuration: 0.3),
            SKAction.removeFromParent()
        ]))

        if lives <= 0 {
            gameOver()
        }
    }

    func activateFreeze() {
        isFrozen = true
        frozenUntil = CACurrentMediaTime() + 3.0

        let border = SKShapeNode(rectOf: CGSize(width: size.width - 4, height: size.height - 4), cornerRadius: 8)
        border.strokeColor = .cyan
        border.lineWidth = 4
        border.fillColor = .clear
        border.position = CGPoint(x: size.width / 2, y: size.height / 2)
        border.zPosition = 40
        border.name = "freezeBorder"
        addChild(border)

        let pulse = SKAction.sequence([
            SKAction.fadeAlpha(to: 0.3, duration: 0.5),
            SKAction.fadeAlpha(to: 0.8, duration: 0.5)
        ])
        border.run(SKAction.repeatForever(pulse))
    }

    func showFloatingText(_ text: String, at position: CGPoint, color: SKColor) {
        let label = SKLabelNode(text: text)
        label.fontName = "AvenirNext-Bold"
        label.fontSize = 28
        label.fontColor = color
        label.position = position
        label.zPosition = 30
        addChild(label)

        let moveUp = SKAction.moveBy(x: 0, y: 60, duration: 0.8)
        let fade = SKAction.fadeOut(withDuration: 0.8)
        let remove = SKAction.removeFromParent()
        label.run(SKAction.sequence([SKAction.group([moveUp, fade]), remove]))
    }

    // MARK: - Game Over

    func gameOver() {
        gameState = .gameOver

        if streakCount > bestStreak { bestStreak = streakCount }

        // In Bestenliste speichern
        saveToLeaderboard(score)
        let isNewHighscore = score == leaderboard.first

        // Alle Flecken entfernen
        for smudge in activeSmudges {
            smudge.run(SKAction.sequence([
                SKAction.group([
                    SKAction.scale(to: 0.0, duration: 0.3),
                    SKAction.fadeOut(withDuration: 0.3)
                ]),
                SKAction.removeFromParent()
            ]))
        }
        activeSmudges.removeAll()
        clearWipeTrails()

        enumerateChildNodes(withName: "freezeBorder") { node, _ in
            node.removeFromParent()
        }

        // Game Over UI
        gameOverContainer = SKNode()
        gameOverContainer.zPosition = 50
        addChild(gameOverContainer)

        let overlay = SKShapeNode(rectOf: CGSize(width: size.width * 2, height: size.height * 2))
        overlay.fillColor = SKColor(red: 0, green: 0, blue: 0, alpha: 0.6)
        overlay.strokeColor = .clear
        overlay.position = CGPoint(x: size.width / 2, y: size.height / 2)
        overlay.alpha = 0
        gameOverContainer.addChild(overlay)
        overlay.run(SKAction.fadeIn(withDuration: 0.5))

        let goLabel = SKLabelNode(text: "VERSCHMUTZT!")
        goLabel.fontName = "AvenirNext-Heavy"
        goLabel.fontSize = 42
        goLabel.fontColor = .red
        goLabel.position = CGPoint(x: size.width / 2, y: size.height * 0.72)
        gameOverContainer.addChild(goLabel)

        let finalScore = SKLabelNode(text: "Punkte: \(score)")
        finalScore.fontName = "AvenirNext-Bold"
        finalScore.fontSize = 28
        finalScore.fontColor = .white
        finalScore.position = CGPoint(x: size.width / 2, y: size.height * 0.64)
        gameOverContainer.addChild(finalScore)

        let stats = "Welle \(wave) · \(smudgesCleared) geputzt · Streak \(bestStreak)"
        let waveInfo = SKLabelNode(text: stats)
        waveInfo.fontName = "AvenirNext-Regular"
        waveInfo.fontSize = 16
        waveInfo.fontColor = SKColor(white: 0.7, alpha: 1.0)
        waveInfo.position = CGPoint(x: size.width / 2, y: size.height * 0.58)
        gameOverContainer.addChild(waveInfo)

        if isNewHighscore && score > 0 {
            let newHSLabel = SKLabelNode(text: "🏆 Neuer Highscore! 🏆")
            newHSLabel.fontName = "AvenirNext-Bold"
            newHSLabel.fontSize = 24
            newHSLabel.fontColor = .yellow
            newHSLabel.position = CGPoint(x: size.width / 2, y: size.height * 0.52)
            gameOverContainer.addChild(newHSLabel)

            let glow = SKAction.sequence([
                SKAction.fadeAlpha(to: 0.5, duration: 0.4),
                SKAction.fadeAlpha(to: 1.0, duration: 0.4)
            ])
            newHSLabel.run(SKAction.repeatForever(glow))
        }

        // Mini-Bestenliste im Game Over
        let lbY: CGFloat = isNewHighscore && score > 0 ? 0.46 : 0.50
        let lbTitle = SKLabelNode(text: "Top 5")
        lbTitle.fontName = "AvenirNext-Bold"
        lbTitle.fontSize = 18
        lbTitle.fontColor = SKColor(white: 0.6, alpha: 1.0)
        lbTitle.position = CGPoint(x: size.width / 2, y: size.height * lbY)
        gameOverContainer.addChild(lbTitle)

        for (i, entry) in leaderboard.prefix(5).enumerated() {
            let medal: String
            switch i {
            case 0: medal = "🥇"
            case 1: medal = "🥈"
            case 2: medal = "🥉"
            default: medal = "  \(i + 1)."
            }
            let isCurrentScore = entry == score && i == (leaderboard.firstIndex(of: score) ?? -1)
            let label = SKLabelNode(text: "\(medal) \(entry)")
            label.fontName = isCurrentScore ? "AvenirNext-Bold" : "AvenirNext-Medium"
            label.fontSize = 15
            label.fontColor = isCurrentScore ? .yellow : SKColor(white: 0.5, alpha: 1.0)
            label.position = CGPoint(x: size.width / 2, y: size.height * lbY - CGFloat(i + 1) * 22)
            gameOverContainer.addChild(label)
        }

        // Buttons
        let buttonsY = size.height * 0.18

        let restartBtn = SKShapeNode(rectOf: CGSize(width: 180, height: 55), cornerRadius: 12)
        restartBtn.fillColor = SKColor(red: 0.2, green: 0.7, blue: 0.3, alpha: 1.0)
        restartBtn.strokeColor = .clear
        restartBtn.position = CGPoint(x: size.width / 2, y: buttonsY)
        restartBtn.name = "restartButton"
        gameOverContainer.addChild(restartBtn)

        let restartLabel = SKLabelNode(text: "NOCHMAL!")
        restartLabel.fontName = "AvenirNext-Bold"
        restartLabel.fontSize = 22
        restartLabel.fontColor = .white
        restartLabel.verticalAlignmentMode = .center
        restartLabel.name = "restartButton"
        restartBtn.addChild(restartLabel)

        let menuBtn = SKShapeNode(rectOf: CGSize(width: 180, height: 55), cornerRadius: 12)
        menuBtn.fillColor = SKColor(white: 0.3, alpha: 0.8)
        menuBtn.strokeColor = .clear
        menuBtn.position = CGPoint(x: size.width / 2, y: buttonsY - 68)
        menuBtn.name = "backToMenuButton"
        gameOverContainer.addChild(menuBtn)

        let menuLabel = SKLabelNode(text: "HAUPTMENÜ")
        menuLabel.fontName = "AvenirNext-Bold"
        menuLabel.fontSize = 20
        menuLabel.fontColor = .white
        menuLabel.verticalAlignmentMode = .center
        menuLabel.name = "backToMenuButton"
        menuBtn.addChild(menuLabel)
    }

    // MARK: - Update Loop

    override func update(_ currentTime: TimeInterval) {
        guard gameState == .playing else { return }

        // Freeze prüfen
        if isFrozen && currentTime > frozenUntil {
            isFrozen = false
            enumerateChildNodes(withName: "freezeBorder") { node, _ in
                node.run(SKAction.sequence([
                    SKAction.fadeOut(withDuration: 0.3),
                    SKAction.removeFromParent()
                ]))
            }
        }

        // Combo-Timeout prüfen
        if comboCount > 0 && lastRevealTime > 0 && (currentTime - lastRevealTime > comboTimeout) {
            comboCount = 0
            updateComboDisplay()
        }

        // Neue Welle
        let allRevealed = !activeSmudges.isEmpty && activeSmudges.allSatisfy { $0.isRevealed }
        let timeSinceWave = CACurrentMediaTime() - lastWaveTime
        let timeForNewWave = timeSinceWave > waveDelay

        if !isFrozen && (allRevealed || (timeForNewWave && !activeSmudges.isEmpty)) {
            for smudge in activeSmudges where !smudge.isRevealed {
                smudge.run(SKAction.sequence([
                    SKAction.fadeOut(withDuration: 0.5),
                    SKAction.removeFromParent()
                ]))
            }
            activeSmudges.removeAll()
            advanceWave()
            spawnWave()
        }
    }

    private func advanceWave() {
        wave += 1
        if wave % 5 == 0 {
            smudgesPerWave += 1
        }
        waveDelay = max(3.5, waveDelay - 0.05)
    }

    // MARK: - Touch Handling

    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        for touch in touches {
            let location = touch.location(in: self)
            lastTouchPositions[touch] = location

            let touchedNode = atPoint(location)

            // Menü
            if gameState == .menu && touchedNode.name == "startButton" {
                startGame()
                return
            }

            // Game Over
            if gameState == .gameOver {
                if touchedNode.name == "restartButton" {
                    removeGameUI()
                    gameOverContainer?.removeFromParent()
                    startGame()
                    return
                }
                if touchedNode.name == "backToMenuButton" {
                    backToMenu()
                    return
                }
            }

            // Pause-Button
            if gameState == .playing && touchedNode.name == "pauseButton" {
                togglePause()
                return
            }

            // Pause-Overlay Buttons
            if gameState == .paused {
                if touchedNode.name == "resumeButton" {
                    resumeGame()
                    return
                }
                if touchedNode.name == "backToMenuButton" {
                    backToMenu()
                    return
                }
                return // Keine Touch-Events im Pause-Modus
            }

            // Im Spiel: Reiben
            if gameState == .playing {
                handleRub(at: location, intensity: 1.0)
            }
        }
    }

    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard gameState == .playing else { return }

        for touch in touches {
            let location = touch.location(in: self)

            var intensity: CGFloat = 1.0
            if let lastPos = lastTouchPositions[touch] {
                let speed = hypot(location.x - lastPos.x, location.y - lastPos.y)
                intensity = min(speed / 10.0, 3.0)

                // Wisch-Spur hinterlassen
                if speed > 3.0 {
                    addWipeTrail(from: lastPos, to: location)
                }
            }

            lastTouchPositions[touch] = location
            handleRub(at: location, intensity: intensity)
        }
    }

    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        for touch in touches {
            lastTouchPositions.removeValue(forKey: touch)
        }
    }

    override func touchesCancelled(_ touches: Set<UITouch>, with event: UIEvent?) {
        for touch in touches {
            lastTouchPositions.removeValue(forKey: touch)
        }
    }

    func handleRub(at point: CGPoint, intensity: CGFloat) {
        for smudge in activeSmudges {
            let wasRevealed = smudge.rub(at: point, intensity: intensity)
            if wasRevealed {
                processReward(smudge)
                smudge.animateCollection { [weak self] in
                    self?.activeSmudges.removeAll { $0 === smudge }
                }

                // Visueller Pulse
                let pulse = SKShapeNode(circleOfRadius: 30)
                pulse.strokeColor = .white
                pulse.fillColor = .clear
                pulse.lineWidth = 2
                pulse.position = point
                pulse.zPosition = 25
                addChild(pulse)
                pulse.run(SKAction.sequence([
                    SKAction.group([
                        SKAction.scale(to: 2.0, duration: 0.3),
                        SKAction.fadeOut(withDuration: 0.3)
                    ]),
                    SKAction.removeFromParent()
                ]))

                break
            }
        }
    }
}
