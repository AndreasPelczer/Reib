//
//  HUDNode.swift
//  Reib
//
//  Created by Andreas Pelczer on 26.02.26.
//

import SpriteKit

class HUDNode: SKNode {

    private var scoreLabel: SKLabelNode!
    private var waveLabelNode: SKLabelNode!
    private var comboLabel: SKLabelNode!
    private var streakLabel: SKLabelNode!
    private var pauseButton: SKNode!
    private var livesNodes: [SKLabelNode] = []

    private var sceneSize: CGSize = .zero

    func setup(size: CGSize) {
        self.sceneSize = size
        self.zPosition = 20

        // Score oben mittig
        scoreLabel = SKLabelNode(text: "0")
        scoreLabel.fontName = "AvenirNext-Heavy"
        scoreLabel.fontSize = 48
        scoreLabel.fontColor = .white
        scoreLabel.position = CGPoint(x: size.width / 2, y: size.height - 80)
        addChild(scoreLabel)

        // Welle
        waveLabelNode = SKLabelNode(text: "Welle 1")
        waveLabelNode.fontName = "AvenirNext-Medium"
        waveLabelNode.fontSize = 16
        waveLabelNode.fontColor = SKColor(white: 0.5, alpha: 1.0)
        waveLabelNode.position = CGPoint(x: size.width / 2, y: size.height - 100)
        addChild(waveLabelNode)

        // Combo
        comboLabel = SKLabelNode(text: "")
        comboLabel.fontName = "AvenirNext-Bold"
        comboLabel.fontSize = 18
        comboLabel.fontColor = .orange
        comboLabel.position = CGPoint(x: size.width / 2, y: size.height - 120)
        addChild(comboLabel)

        // Streak
        streakLabel = SKLabelNode(text: "")
        streakLabel.fontName = "AvenirNext-DemiBold"
        streakLabel.fontSize = 14
        streakLabel.fontColor = SKColor(white: 0.6, alpha: 1.0)
        streakLabel.horizontalAlignmentMode = .right
        streakLabel.position = CGPoint(x: size.width - 60, y: size.height - 75)
        addChild(streakLabel)

        // Pause-Button
        pauseButton = SKNode()
        pauseButton.position = CGPoint(x: size.width - 30, y: size.height - 40)
        pauseButton.zPosition = 5
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
    }

    // MARK: - Updates

    func updateScore(_ score: Int) {
        scoreLabel?.text = "\(score)"
        scoreLabel?.run(SKAction.sequence([
            SKAction.scale(to: 1.2, duration: 0.1),
            SKAction.scale(to: 1.0, duration: 0.1)
        ]))
    }

    func updateWave(_ wave: Int) {
        waveLabelNode?.text = "Welle \(wave)"
    }

    func updateCombo(multiplier: Int) {
        if multiplier > 1 {
            comboLabel?.text = "COMBO x\(multiplier)!"
            comboLabel?.fontColor = multiplier >= 4 ? .red :
                                    multiplier >= 3 ? .orange : .yellow
            comboLabel?.run(SKAction.sequence([
                SKAction.scale(to: 1.3, duration: 0.08),
                SKAction.scale(to: 1.0, duration: 0.08)
            ]))
        } else {
            comboLabel?.text = ""
        }
    }

    func updateStreak(_ count: Int) {
        streakLabel?.text = count >= 3 ? "Streak: \(count)" : ""
    }

    func updateLives(_ lives: Int) {
        livesNodes.forEach { $0.removeFromParent() }
        livesNodes.removeAll()

        for i in 0..<lives {
            let heart = SKLabelNode(text: "❤️")
            heart.fontSize = 28
            heart.position = CGPoint(x: 30 + CGFloat(i) * 36, y: sceneSize.height - 50)
            addChild(heart)
            livesNodes.append(heart)
        }
    }
}
