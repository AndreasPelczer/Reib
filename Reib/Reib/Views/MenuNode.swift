//
//  MenuNode.swift
//  Reib
//
//  Created by Andreas Pelczer on 26.02.26.
//

import SpriteKit

class MenuNode: SKNode {

    private var demoSmudges: [SmudgeNode] = []

    func setup(size: CGSize, leaderboard: [Int]) {
        self.zPosition = 10

        // Titel
        let titleLabel = SKLabelNode(text: "REIB!")
        titleLabel.fontName = "AvenirNext-Heavy"
        titleLabel.fontSize = 72
        titleLabel.fontColor = .white
        titleLabel.position = CGPoint(x: size.width / 2, y: size.height * 0.70)
        addChild(titleLabel)

        let pulse = SKAction.sequence([
            SKAction.scale(to: 1.05, duration: 1.0),
            SKAction.scale(to: 0.95, duration: 1.0)
        ])
        titleLabel.run(SKAction.repeatForever(pulse))

        // Untertitel
        let subtitleLabel = SKLabelNode(text: "Rubbel den Dreck weg!")
        subtitleLabel.fontName = "AvenirNext-Medium"
        subtitleLabel.fontSize = 20
        subtitleLabel.fontColor = SKColor(white: 0.7, alpha: 1.0)
        subtitleLabel.position = CGPoint(x: size.width / 2, y: size.height * 0.62)
        addChild(subtitleLabel)

        // Start Button
        let startButton = SKShapeNode(rectOf: CGSize(width: 200, height: 60), cornerRadius: 12)
        startButton.fillColor = SKColor(red: 0.2, green: 0.7, blue: 0.3, alpha: 1.0)
        startButton.strokeColor = .clear
        startButton.position = CGPoint(x: size.width / 2, y: size.height * 0.50)
        startButton.name = "startButton"
        addChild(startButton)

        let buttonLabel = SKLabelNode(text: "LOS REIBEN!")
        buttonLabel.fontName = "AvenirNext-Bold"
        buttonLabel.fontSize = 22
        buttonLabel.fontColor = .white
        buttonLabel.verticalAlignmentMode = .center
        buttonLabel.name = "startButton"
        startButton.addChild(buttonLabel)

        // Bestenliste
        if !leaderboard.isEmpty {
            let lbTitle = SKLabelNode(text: "Bestenliste")
            lbTitle.fontName = "AvenirNext-Bold"
            lbTitle.fontSize = 20
            lbTitle.fontColor = SKColor(white: 0.6, alpha: 1.0)
            lbTitle.position = CGPoint(x: size.width / 2, y: size.height * 0.38)
            addChild(lbTitle)

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
                addChild(label)
            }
        }

        // Demo-Flecken
        for _ in 0..<5 {
            let model = SmudgeModel(
                reward: .star,
                behavior: .normal,
                radius: CGFloat.random(in: 25...50),
                position: CGPoint(
                    x: CGFloat.random(in: 60...(size.width - 60)),
                    y: CGFloat.random(in: size.height * 0.05...size.height * 0.18)
                ),
                spawnTime: 0
            )
            let node = SmudgeNode(model: model)
            node.alpha = 0.4
            node.zPosition = -1
            addChild(node)
            demoSmudges.append(node)
        }
    }
}
