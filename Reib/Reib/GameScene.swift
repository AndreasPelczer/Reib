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

// MARK: - Ein einzelner Dreckfleck

class Smudge: SKNode {

    let reward: SmudgeReward
    let radius: CGFloat
    var rubbedPixels: Int = 0
    let totalPixels: Int = 100  // Wie viel Reiben zum Freilegen nötig
    var isRevealed: Bool = false

    // Die sichtbare Dreckschicht
    private var dirtLayer: SKShapeNode!
    private var progressRing: SKShapeNode!
    private var rewardIcon: SKLabelNode!

    // Partikel beim Reiben
    private var lastRubPosition: CGPoint = .zero

    init(reward: SmudgeReward, radius: CGFloat = 40) {
        self.reward = reward
        self.radius = radius
        super.init()
        setupVisuals()
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

        // Dreckfleck obendrüber
        dirtLayer = SKShapeNode(circleOfRadius: radius)
        dirtLayer.fillColor = randomDirtColor()
        dirtLayer.strokeColor = .clear
        dirtLayer.alpha = 0.85
        dirtLayer.zPosition = 1
        addChild(dirtLayer)

        // Fortschrittsring (zeigt wie viel schon freigerubbelt)
        progressRing = SKShapeNode(circleOfRadius: radius + 3)
        progressRing.strokeColor = .white
        progressRing.lineWidth = 2
        progressRing.fillColor = .clear
        progressRing.alpha = 0
        progressRing.zPosition = 2
        addChild(progressRing)

        // Einblend-Animation
        self.setScale(0.1)
        let scaleUp = SKAction.scale(to: 1.0, duration: 0.3)
        let fadeIn = SKAction.fadeIn(withDuration: 0.3)
        scaleUp.timingMode = .easeOut
        run(SKAction.group([scaleUp, fadeIn]))
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
            (0.35, 0.25, 0.15),  // Braun
            (0.40, 0.35, 0.25),  // Hellbraun
            (0.30, 0.30, 0.28),  // Grau-braun
            (0.45, 0.38, 0.20),  // Sandig
            (0.32, 0.28, 0.22),  // Dunkelbraun
        ]
        let c = colors.randomElement()!
        let variation: CGFloat = 0.05
        return SKColor(
            red: c.0 + CGFloat.random(in: -variation...variation),
            green: c.1 + CGFloat.random(in: -variation...variation),
            blue: c.2 + CGFloat.random(in: -variation...variation),
            alpha: 1.0
        )
    }

    // MARK: - Reiben!

    /// Gibt true zurück wenn der Fleck gerade freigelegt wurde
    func rub(at point: CGPoint, intensity: CGFloat = 1.0) -> Bool {
        guard !isRevealed else { return false }

        // Prüfe ob der Punkt im Fleck liegt
        let localPoint = convert(point, from: parent!)
        let distance = hypot(localPoint.x, localPoint.y)
        guard distance <= radius else { return false }

        // Fortschrittsring einblenden
        if progressRing.alpha == 0 {
            progressRing.run(SKAction.fadeAlpha(to: 0.6, duration: 0.1))
        }

        // Reib-Fortschritt (Mitte gibt mehr Punkte)
        let centerBonus = 1.0 + (1.0 - distance / radius) * 0.5
        let rubAmount = Int(intensity * centerBonus * 3)
        rubbedPixels = min(rubbedPixels + rubAmount, totalPixels)

        // Visuelle Rückmeldung: Dreck wird transparenter
        let progress = CGFloat(rubbedPixels) / CGFloat(totalPixels)
        dirtLayer.alpha = 0.85 * (1.0 - progress)
        rewardIcon.alpha = progress * 0.8

        // Fortschrittsring-Farbe
        if progress > 0.7 {
            progressRing.strokeColor = .green
        } else if progress > 0.4 {
            progressRing.strokeColor = .yellow
        }

        // Kleine Dreck-Partikel beim Reiben
        spawnDirtParticle(at: localPoint)

        // Fertig freigerubbelt?
        if rubbedPixels >= totalPixels {
            reveal()
            return true
        }

        return false
    }

    private func spawnDirtParticle(at point: CGPoint) {
        let particle = SKShapeNode(circleOfRadius: CGFloat.random(in: 1.5...3.5))
        particle.fillColor = dirtLayer.fillColor
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

        // Dreck wegblasen
        dirtLayer.run(SKAction.sequence([
            SKAction.group([
                SKAction.fadeOut(withDuration: 0.2),
                SKAction.scale(to: 1.3, duration: 0.2)
            ]),
            SKAction.removeFromParent()
        ]))

        progressRing.run(SKAction.fadeOut(withDuration: 0.2))

        // Belohnung enthüllen mit Bounce
        rewardIcon.run(SKAction.sequence([
            SKAction.fadeIn(withDuration: 0.1),
            SKAction.scale(to: 1.3, duration: 0.1),
            SKAction.scale(to: 1.0, duration: 0.1)
        ]))
    }

    /// Aufräum-Animation nach dem Enthüllen
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

// MARK: - Die Spielszene

class GameScene: SKScene {

    // MARK: - Spielzustand

    enum GameState {
        case menu
        case playing
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
    var waveDelay: TimeInterval = 7.0       // Sekunden bis nächste Welle
    var lastWaveTime: TimeInterval = 0
    var isFrozen: Bool = false
    var frozenUntil: TimeInterval = 0

    // Highscore
    let highscoreKey = "ReibHighscore"
    var highscore: Int = 0

    // MARK: - UI Elemente

    var scoreLabel: SKLabelNode!
    var waveLabelNode: SKLabelNode!
    var livesNodes: [SKLabelNode] = []
    var highscoreLabel: SKLabelNode!
    var titleLabel: SKLabelNode!
    var subtitleLabel: SKLabelNode!
    var startButton: SKShapeNode!
    var gameOverContainer: SKNode!

    // Hintergrund
    var backgroundNode: SKSpriteNode!

    // MARK: - Touch Tracking

    var lastTouchPositions: [UITouch: CGPoint] = [:]

    // MARK: - Scene Lifecycle

    override func didMove(to view: SKView) {
        backgroundColor = SKColor(red: 0.12, green: 0.12, blue: 0.14, alpha: 1.0)
        highscore = UserDefaults.standard.integer(forKey: highscoreKey)

        setupBackground()
        showMenu()
    }

    // MARK: - Hintergrund (subtiles Display-Muster)

    func setupBackground() {
        // Subtiles Raster das an ein Display erinnert
        let bgSize = size
        backgroundNode = SKSpriteNode(color: .clear, size: bgSize)
        backgroundNode.position = CGPoint(x: size.width / 2, y: size.height / 2)
        backgroundNode.zPosition = -10
        addChild(backgroundNode)

        // Dezente Pixelraster-Linien
        for i in stride(from: 0, to: bgSize.width, by: 20) {
            let line = SKShapeNode(rectOf: CGSize(width: 0.5, height: bgSize.height))
            line.fillColor = SKColor(white: 1.0, alpha: 0.02)
            line.strokeColor = .clear
            line.position = CGPoint(x: i - bgSize.width / 2, y: 0)
            backgroundNode.addChild(line)
        }
        for i in stride(from: 0, to: bgSize.height, by: 20) {
            let line = SKShapeNode(rectOf: CGSize(width: bgSize.width, height: 0.5))
            line.fillColor = SKColor(white: 1.0, alpha: 0.02)
            line.strokeColor = .clear
            line.position = CGPoint(x: 0, y: i - bgSize.height / 2)
            backgroundNode.addChild(line)
        }
    }

    // MARK: - Menü

    func showMenu() {
        gameState = .menu
        removeGameUI()

        // Titel
        titleLabel = SKLabelNode(text: "REIB!")
        titleLabel.fontName = "AvenirNext-Heavy"
        titleLabel.fontSize = 72
        titleLabel.fontColor = .white
        titleLabel.position = CGPoint(x: size.width / 2, y: size.height * 0.65)
        titleLabel.zPosition = 10
        addChild(titleLabel)

        // Pulsieren
        let pulse = SKAction.sequence([
            SKAction.scale(to: 1.05, duration: 1.0),
            SKAction.scale(to: 0.95, duration: 1.0)
        ])
        titleLabel.run(SKAction.repeatForever(pulse))

        // Untertitel
        subtitleLabel = SKLabelNode(text: "Rubbel den Dreck weg!")
        subtitleLabel.fontName = "AvenirNext-Medium"
        subtitleLabel.fontSize = 20
        subtitleLabel.fontColor = SKColor(white: 0.7, alpha: 1.0)
        subtitleLabel.position = CGPoint(x: size.width / 2, y: size.height * 0.57)
        subtitleLabel.zPosition = 10
        addChild(subtitleLabel)

        // Highscore
        if highscore > 0 {
            highscoreLabel = SKLabelNode(text: "Highscore: \(highscore)")
            highscoreLabel.fontName = "AvenirNext-Regular"
            highscoreLabel.fontSize = 18
            highscoreLabel.fontColor = SKColor(white: 0.5, alpha: 1.0)
            highscoreLabel.position = CGPoint(x: size.width / 2, y: size.height * 0.52)
            highscoreLabel.zPosition = 10
            addChild(highscoreLabel)
        }

        // Start Button
        let buttonSize = CGSize(width: 200, height: 60)
        startButton = SKShapeNode(rectOf: buttonSize, cornerRadius: 12)
        startButton.fillColor = SKColor(red: 0.2, green: 0.7, blue: 0.3, alpha: 1.0)
        startButton.strokeColor = .clear
        startButton.position = CGPoint(x: size.width / 2, y: size.height * 0.35)
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

        // Demo-Flecken im Hintergrund
        spawnMenuSmudges()
    }

    func spawnMenuSmudges() {
        for _ in 0..<5 {
            let smudge = Smudge(reward: .star, radius: CGFloat.random(in: 25...50))
            smudge.position = CGPoint(
                x: CGFloat.random(in: 60...(size.width - 60)),
                y: CGFloat.random(in: size.height * 0.1...size.height * 0.3)
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

        // Menü aufräumen
        titleLabel?.removeFromParent()
        subtitleLabel?.removeFromParent()
        highscoreLabel?.removeFromParent()
        startButton?.removeFromParent()
        gameOverContainer?.removeFromParent()
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

        // Leben (Herzen oben links)
        updateLivesDisplay()
    }

    func updateLivesDisplay() {
        // Alte Herzen entfernen
        livesNodes.forEach { $0.removeFromParent() }
        livesNodes.removeAll()

        for i in 0..<lives {
            let heart = SKLabelNode(text: "❤️")
            heart.fontSize = 28
            heart.position = CGPoint(x: 30 + CGFloat(i) * 36, y: size.height - 75)
            heart.zPosition = 20
            addChild(heart)
            livesNodes.append(heart)
        }
    }

    func removeGameUI() {
        scoreLabel?.removeFromParent()
        waveLabelNode?.removeFromParent()
        livesNodes.forEach { $0.removeFromParent() }
        livesNodes.removeAll()
        activeSmudges.forEach { $0.removeFromParent() }
        activeSmudges.removeAll()
    }

    // MARK: - Wellen-System

    func spawnWave() {
        guard gameState == .playing else { return }

        waveLabelNode?.text = "Welle \(wave)"

        // Wellen-Ankündigung
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

        // Flecken spawnen mit leichter Verzögerung
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
        // Langsamer Anstieg: +1 Fleck alle 2 Wellen, max 8
        return min(smudgesPerWave + (wave - 1) / 2, 8)
    }

    func spawnSmudge() {
        guard gameState == .playing else { return }

        let reward = randomReward()
        let radius = CGFloat.random(in: 30...55)
        let smudge = Smudge(reward: reward, radius: radius)

        // Position: Nicht zu nah am Rand, nicht zu nah an anderen Flecken
        var position: CGPoint
        var attempts = 0
        repeat {
            position = CGPoint(
                x: CGFloat.random(in: (radius + 20)...(size.width - radius - 20)),
                y: CGFloat.random(in: (radius + 120)...(size.height - radius - 120))
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

        // Bomben-Chance steigt langsam mit Wellen
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

    // MARK: - Belohnung verarbeiten

    func processReward(_ smudge: Smudge) {
        switch smudge.reward {
        case .star:
            addScore(10 * wave)
            showFloatingText("+\(10 * wave)", at: smudge.position, color: .yellow)

        case .doubleStar:
            addScore(25 * wave)
            showFloatingText("+\(25 * wave)", at: smudge.position, color: .orange)

        case .bomb:
            loseLife(at: smudge.position)

        case .timeBonus:
            waveDelay += 2.0
            showFloatingText("+2s", at: smudge.position, color: .cyan)

        case .freeze:
            activateFreeze()
            showFloatingText("FREEZE!", at: smudge.position, color: .cyan)
        }

        smudgesCleared += 1
    }

    func addScore(_ points: Int) {
        score += points

        // Score-Label kurz aufleuchten
        scoreLabel?.run(SKAction.sequence([
            SKAction.scale(to: 1.2, duration: 0.1),
            SKAction.scale(to: 1.0, duration: 0.1)
        ]))
    }

    func loseLife(at position: CGPoint) {
        lives -= 1

        showFloatingText("💥", at: position, color: .red)

        // Screen-Shake
        let shake = SKAction.sequence([
            SKAction.moveBy(x: 10, y: 0, duration: 0.03),
            SKAction.moveBy(x: -20, y: 0, duration: 0.03),
            SKAction.moveBy(x: 15, y: 0, duration: 0.03),
            SKAction.moveBy(x: -10, y: 0, duration: 0.03),
            SKAction.moveBy(x: 5, y: 0, duration: 0.03),
        ])
        backgroundNode?.run(shake)

        // Roter Flash
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

        // Blaue Ränder als visueller Hinweis
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

        // Highscore prüfen
        let isNewHighscore = score > highscore
        if isNewHighscore {
            highscore = score
            UserDefaults.standard.set(highscore, forKey: highscoreKey)
        }

        // Alle Flecken explodieren lassen
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

        // Freeze-Border entfernen
        enumerateChildNodes(withName: "freezeBorder") { node, _ in
            node.removeFromParent()
        }

        // Game Over UI
        gameOverContainer = SKNode()
        gameOverContainer.zPosition = 50
        addChild(gameOverContainer)

        // Dunkler Overlay
        let overlay = SKShapeNode(rectOf: size)
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
        goLabel.position = CGPoint(x: size.width / 2, y: size.height * 0.65)
        gameOverContainer.addChild(goLabel)

        let finalScore = SKLabelNode(text: "Punkte: \(score)")
        finalScore.fontName = "AvenirNext-Bold"
        finalScore.fontSize = 28
        finalScore.fontColor = .white
        finalScore.position = CGPoint(x: size.width / 2, y: size.height * 0.55)
        gameOverContainer.addChild(finalScore)

        let waveInfo = SKLabelNode(text: "Welle \(wave) · \(smudgesCleared) Flecken geputzt")
        waveInfo.fontName = "AvenirNext-Regular"
        waveInfo.fontSize = 18
        waveInfo.fontColor = SKColor(white: 0.7, alpha: 1.0)
        waveInfo.position = CGPoint(x: size.width / 2, y: size.height * 0.48)
        gameOverContainer.addChild(waveInfo)

        if isNewHighscore {
            let newHSLabel = SKLabelNode(text: "🏆 Neuer Highscore! 🏆")
            newHSLabel.fontName = "AvenirNext-Bold"
            newHSLabel.fontSize = 24
            newHSLabel.fontColor = .yellow
            newHSLabel.position = CGPoint(x: size.width / 2, y: size.height * 0.42)
            gameOverContainer.addChild(newHSLabel)

            let glow = SKAction.sequence([
                SKAction.fadeAlpha(to: 0.5, duration: 0.4),
                SKAction.fadeAlpha(to: 1.0, duration: 0.4)
            ])
            newHSLabel.run(SKAction.repeatForever(glow))
        }

        // Neustart-Button
        let restartBtn = SKShapeNode(rectOf: CGSize(width: 200, height: 60), cornerRadius: 12)
        restartBtn.fillColor = SKColor(red: 0.2, green: 0.7, blue: 0.3, alpha: 1.0)
        restartBtn.strokeColor = .clear
        restartBtn.position = CGPoint(x: size.width / 2, y: size.height * 0.28)
        restartBtn.name = "restartButton"
        gameOverContainer.addChild(restartBtn)

        let restartLabel = SKLabelNode(text: "NOCHMAL!")
        restartLabel.fontName = "AvenirNext-Bold"
        restartLabel.fontSize = 22
        restartLabel.fontColor = .white
        restartLabel.verticalAlignmentMode = .center
        restartLabel.name = "restartButton"
        restartBtn.addChild(restartLabel)
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

        // Neue Welle wenn alle Flecken freigelegt oder Timer abgelaufen
        let allRevealed = !activeSmudges.isEmpty && activeSmudges.allSatisfy { $0.isRevealed }
        let timeSinceWave = CACurrentMediaTime() - lastWaveTime
        let timeForNewWave = timeSinceWave > waveDelay

        if !isFrozen && (allRevealed || (timeForNewWave && !activeSmudges.isEmpty)) {
            // Ungeöffnete Flecken sanft entfernen
            for smudge in activeSmudges where !smudge.isRevealed {
                smudge.run(SKAction.sequence([
                    SKAction.fadeOut(withDuration: 0.5),
                    SKAction.removeFromParent()
                ]))
            }
            activeSmudges.removeAll()

            // Nächste Welle vorbereiten
            advanceWave()
            spawnWave()
        }
    }

    /// Schwierigkeit für nächste Welle erhöhen
    private func advanceWave() {
        wave += 1

        // Mehr Flecken alle 5 Wellen
        if wave % 5 == 0 {
            smudgesPerWave += 1
        }

        // Wellen-Delay nur langsam verringern, Minimum 3.5s
        waveDelay = max(3.5, waveDelay - 0.05)
    }

    // MARK: - Touch Handling (Das Herzstück!)

    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        for touch in touches {
            let location = touch.location(in: self)
            lastTouchPositions[touch] = location

            // Button-Checks
            let touchedNode = atPoint(location)

            if gameState == .menu && touchedNode.name == "startButton" {
                startGame()
                return
            }

            if gameState == .gameOver && touchedNode.name == "restartButton" {
                removeGameUI()
                gameOverContainer?.removeFromParent()
                startGame()
                return
            }

            // Im Spiel: Reiben starten
            if gameState == .playing {
                handleRub(at: location, intensity: 1.0)
            }
        }
    }

    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard gameState == .playing else { return }

        for touch in touches {
            let location = touch.location(in: self)

            // Geschwindigkeit berechnen für Intensität
            var intensity: CGFloat = 1.0
            if let lastPos = lastTouchPositions[touch] {
                let speed = hypot(location.x - lastPos.x, location.y - lastPos.y)
                intensity = min(speed / 10.0, 3.0) // Schneller reiben = effektiver
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

                // Haptisches Feedback (visuell simuliert)
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

                break // Nur ein Fleck pro Touch-Event
            }
        }
    }
}
