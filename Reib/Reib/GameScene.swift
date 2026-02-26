//
//  GameScene.swift
//  Reib
//
//  Created by Andreas Pelczer on 26.02.26.
//
//  Dünner Koordinator: verbindet ViewModel mit View-Nodes.
//  Enthält keine Spiellogik – nur Touch-Routing, Event-Handling und Node-Management.
//

import SpriteKit

class GameScene: SKScene {

    // MARK: - ViewModel

    private var viewModel = GameViewModel()

    // MARK: - View Nodes

    private var backgroundNode: BackgroundNode!
    private var hudNode: HUDNode?
    private var menuNode: MenuNode?
    private var pauseNode: PauseNode?
    private var gameOverNode: GameOverNode?

    // SmudgeNode-Registry (UUID → Node)
    private var smudgeNodes: [UUID: SmudgeNode] = [:]

    // Wisch-Spuren
    private var wipeTrailNodes: [SKNode] = []

    // Touch Tracking
    private var lastTouchPositions: [UITouch: CGPoint] = [:]

    // Spawn-Verzögerung (für gestaffeltes Erscheinen)
    private var pendingSpawns: [(SmudgeModel, TimeInterval)] = []

    // MARK: - Scene Lifecycle

    override func didMove(to view: SKView) {
        backgroundColor = SKColor(red: 0.08, green: 0.08, blue: 0.10, alpha: 1.0)

        viewModel.sceneSize = size
        viewModel.onEvent = { [weak self] event in
            self?.handleEvent(event)
        }

        backgroundNode = BackgroundNode()
        backgroundNode.setup(size: size)
        addChild(backgroundNode)

        showMenu()
    }

    // MARK: - State Transitions

    private func showMenu() {
        cleanupGameNodes()

        menuNode = MenuNode()
        menuNode!.setup(size: size, leaderboard: viewModel.leaderboard.entries)
        addChild(menuNode!)
    }

    private func startPlaying() {
        menuNode?.removeFromParent()
        menuNode = nil
        gameOverNode?.removeFromParent()
        gameOverNode = nil

        hudNode = HUDNode()
        hudNode!.setup(size: size)
        addChild(hudNode!)

        viewModel.startGame()
    }

    private func showPause() {
        isPaused = true

        pauseNode = PauseNode()
        pauseNode!.setup(size: size)
        addChild(pauseNode!)
    }

    private func resumeFromPause() {
        isPaused = false
        pauseNode?.removeFromParent()
        pauseNode = nil

        viewModel.togglePause()
    }

    private func showGameOver(score: Int, wave: Int, cleared: Int, bestStreak: Int, isNewHighscore: Bool) {
        gameOverNode = GameOverNode()
        gameOverNode!.setup(
            size: size,
            score: score,
            wave: wave,
            smudgesCleared: cleared,
            bestStreak: bestStreak,
            isNewHighscore: isNewHighscore,
            leaderboard: viewModel.leaderboard.entries
        )
        addChild(gameOverNode!)
    }

    private func backToMenu() {
        isPaused = false
        cleanupGameNodes()
        viewModel.backToMenu()
        showMenu()
    }

    private func cleanupGameNodes() {
        hudNode?.removeFromParent()
        hudNode = nil
        pauseNode?.removeFromParent()
        pauseNode = nil
        gameOverNode?.removeFromParent()
        gameOverNode = nil

        for (_, node) in smudgeNodes {
            node.removeFromParent()
        }
        smudgeNodes.removeAll()
        pendingSpawns.removeAll()

        clearWipeTrails()
        removeFreezeVisuals()
    }

    // MARK: - Event Handling (vom ViewModel)

    private func handleEvent(_ event: GameEvent) {
        switch event {
        case .stateChanged(let state):
            switch state {
            case .paused:
                showPause()
            case .gameOver, .menu, .playing:
                break // handled by dedicated methods
            }

        case .scoreChanged(let score):
            hudNode?.updateScore(score)

        case .livesChanged(let lives):
            hudNode?.updateLives(lives)

        case .waveStarted(let wave):
            hudNode?.updateWave(wave)
            showWaveAnnouncement(wave)

        case .smudgeSpawned(let model):
            let delay = Double(pendingSpawns.count) * 0.3
            pendingSpawns.append((model, CACurrentMediaTime() + delay))

        case .smudgeRevealed(let id, let reward, let points):
            guard let node = smudgeNodes[id] else { return }
            node.playRevealAnimation()

            switch reward {
            case .star:
                let comboText = viewModel.combo.multiplier > 1 ? " (x\(viewModel.combo.multiplier))" : ""
                showFloatingText("+\(points)\(comboText)", at: node.position, color: .yellow)
            case .doubleStar:
                let comboText = viewModel.combo.multiplier > 1 ? " (x\(viewModel.combo.multiplier))" : ""
                showFloatingText("+\(points)\(comboText)", at: node.position, color: .orange)
            case .bomb:
                showFloatingText("💥", at: node.position, color: .red)
            case .timeBonus:
                showFloatingText("+2s", at: node.position, color: .cyan)
            case .freeze:
                showFloatingText("FREEZE!", at: node.position, color: .cyan)
            }

            node.playCollectionAnimation { [weak self] in
                self?.smudgeNodes.removeValue(forKey: id)
                self?.viewModel.removeSmudge(id: id)
            }

            spawnRevealPulse(at: node.position)

        case .smudgeExpired(let id):
            guard let node = smudgeNodes[id] else { return }
            node.playExpireAnimation()
            smudgeNodes.removeValue(forKey: id)

        case .comboChanged(let multiplier):
            hudNode?.updateCombo(multiplier: multiplier)

        case .streakChanged(let count):
            hudNode?.updateStreak(count)

        case .freezeActivated:
            showFreezeVisuals()

        case .freezeEnded:
            removeFreezeVisuals()

        case .lifeLost:
            backgroundNode?.playShake()
            showRedFlash()

        case .waveDelayBonus:
            break

        case .gameOver(let score, let wave, let cleared, let bestStreak, let isNewHighscore):
            for (id, node) in smudgeNodes {
                node.run(SKAction.sequence([
                    SKAction.group([
                        SKAction.scale(to: 0.0, duration: 0.3),
                        SKAction.fadeOut(withDuration: 0.3)
                    ]),
                    SKAction.removeFromParent()
                ]))
                smudgeNodes.removeValue(forKey: id)
            }
            clearWipeTrails()
            removeFreezeVisuals()

            showGameOver(
                score: score,
                wave: wave,
                cleared: cleared,
                bestStreak: bestStreak,
                isNewHighscore: isNewHighscore
            )
        }
    }

    // MARK: - Update Loop

    override func update(_ currentTime: TimeInterval) {
        guard viewModel.state == .playing else { return }

        // Gestaffelte Spawns verarbeiten
        let now = CACurrentMediaTime()
        let readySpawns = pendingSpawns.filter { $0.1 <= now }
        for spawn in readySpawns {
            let node = SmudgeNode(model: spawn.0)
            node.zPosition = 5
            addChild(node)
            smudgeNodes[spawn.0.id] = node
        }
        pendingSpawns.removeAll { $0.1 <= now }

        // ViewModel updaten
        viewModel.update(currentTime: currentTime)

        // Smudge-Nodes mit Model synchronisieren
        for smudge in viewModel.smudges {
            smudgeNodes[smudge.id]?.syncWithModel(smudge)
        }
    }

    // MARK: - Touch Handling

    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        for touch in touches {
            let location = touch.location(in: self)
            lastTouchPositions[touch] = location

            let touchedNode = atPoint(location)

            if viewModel.state == .menu && touchedNode.name == "startButton" {
                startPlaying()
                return
            }

            if viewModel.state == .gameOver {
                if touchedNode.name == "restartButton" {
                    cleanupGameNodes()
                    hudNode = HUDNode()
                    hudNode!.setup(size: size)
                    addChild(hudNode!)
                    viewModel.startGame()
                    return
                }
                if touchedNode.name == "backToMenuButton" {
                    backToMenu()
                    return
                }
            }

            if viewModel.state == .playing && touchedNode.name == "pauseButton" {
                viewModel.togglePause()
                return
            }

            if viewModel.state == .paused {
                if touchedNode.name == "resumeButton" {
                    resumeFromPause()
                    return
                }
                if touchedNode.name == "backToMenuButton" {
                    backToMenu()
                    return
                }
                return
            }

            if viewModel.state == .playing {
                processRub(at: location, intensity: 1.0)
            }
        }
    }

    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard viewModel.state == .playing else { return }

        for touch in touches {
            let location = touch.location(in: self)

            var intensity: CGFloat = 1.0
            if let lastPos = lastTouchPositions[touch] {
                let speed = hypot(location.x - lastPos.x, location.y - lastPos.y)
                intensity = min(speed / 10.0, 3.0)

                if speed > 3.0 {
                    addWipeTrail(from: lastPos, to: location)
                }
            }

            lastTouchPositions[touch] = location
            processRub(at: location, intensity: intensity)
        }
    }

    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        for touch in touches { lastTouchPositions.removeValue(forKey: touch) }
    }

    override func touchesCancelled(_ touches: Set<UITouch>, with event: UIEvent?) {
        for touch in touches { lastTouchPositions.removeValue(forKey: touch) }
    }

    // MARK: - Rub → ViewModel → Visual Feedback

    private func processRub(at point: CGPoint, intensity: CGFloat) {
        guard let result = viewModel.handleRub(at: point, intensity: intensity) else { return }

        if let node = smudgeNodes[result.smudgeID] {
            node.updateRubProgress(result.progress)
            node.spawnDirtParticle(at: point)
        }
    }

    // MARK: - Visuelle Effekte

    private func showWaveAnnouncement(_ wave: Int) {
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
    }

    private func showFloatingText(_ text: String, at position: CGPoint, color: SKColor) {
        let label = SKLabelNode(text: text)
        label.fontName = "AvenirNext-Bold"
        label.fontSize = 28
        label.fontColor = color
        label.position = position
        label.zPosition = 30
        addChild(label)

        label.run(SKAction.sequence([
            SKAction.group([
                SKAction.moveBy(x: 0, y: 60, duration: 0.8),
                SKAction.fadeOut(withDuration: 0.8)
            ]),
            SKAction.removeFromParent()
        ]))
    }

    private func spawnRevealPulse(at point: CGPoint) {
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
    }

    private func showRedFlash() {
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
    }

    private func showFreezeVisuals() {
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

    private func removeFreezeVisuals() {
        enumerateChildNodes(withName: "freezeBorder") { node, _ in
            node.run(SKAction.sequence([
                SKAction.fadeOut(withDuration: 0.3),
                SKAction.removeFromParent()
            ]))
        }
    }

    // MARK: - Wisch-Spuren

    private func addWipeTrail(from: CGPoint, to: CGPoint) {
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

        trail.run(SKAction.sequence([
            SKAction.wait(forDuration: 3.0),
            SKAction.fadeOut(withDuration: 1.0),
            SKAction.removeFromParent()
        ])) { [weak self] in
            self?.wipeTrailNodes.removeAll { $0 === trail }
        }
    }

    private func clearWipeTrails() {
        wipeTrailNodes.forEach { $0.removeFromParent() }
        wipeTrailNodes.removeAll()
        enumerateChildNodes(withName: "wipeTrail") { node, _ in
            node.removeFromParent()
        }
    }
}
