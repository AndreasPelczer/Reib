//
//  GameOverNode.swift
//  Reib
//
//  Created by Andreas Pelczer on 26.02.26.
//

import SpriteKit

class GameOverNode: SKNode {

    func setup(
        size: CGSize,
        score: Int,
        wave: Int,
        smudgesCleared: Int,
        bestStreak: Int,
        isNewHighscore: Bool,
        leaderboard: [Int]
    ) {
        self.zPosition = 50

        // Dunkler Overlay
        let overlay = SKShapeNode(rectOf: CGSize(width: size.width * 2, height: size.height * 2))
        overlay.fillColor = SKColor(red: 0, green: 0, blue: 0, alpha: 0.6)
        overlay.strokeColor = .clear
        overlay.position = CGPoint(x: size.width / 2, y: size.height / 2)
        overlay.alpha = 0
        addChild(overlay)
        overlay.run(SKAction.fadeIn(withDuration: 0.5))

        // Titel
        let goLabel = SKLabelNode(text: "VERSCHMUTZT!")
        goLabel.fontName = "AvenirNext-Heavy"
        goLabel.fontSize = 42
        goLabel.fontColor = .red
        goLabel.position = CGPoint(x: size.width / 2, y: size.height * 0.72)
        addChild(goLabel)

        // Score
        let finalScore = SKLabelNode(text: "Punkte: \(score)")
        finalScore.fontName = "AvenirNext-Bold"
        finalScore.fontSize = 28
        finalScore.fontColor = .white
        finalScore.position = CGPoint(x: size.width / 2, y: size.height * 0.64)
        addChild(finalScore)

        // Stats
        let stats = "Welle \(wave) · \(smudgesCleared) geputzt · Streak \(bestStreak)"
        let waveInfo = SKLabelNode(text: stats)
        waveInfo.fontName = "AvenirNext-Regular"
        waveInfo.fontSize = 16
        waveInfo.fontColor = SKColor(white: 0.7, alpha: 1.0)
        waveInfo.position = CGPoint(x: size.width / 2, y: size.height * 0.58)
        addChild(waveInfo)

        // Neuer Highscore
        if isNewHighscore {
            let newHSLabel = SKLabelNode(text: "🏆 Neuer Highscore! 🏆")
            newHSLabel.fontName = "AvenirNext-Bold"
            newHSLabel.fontSize = 24
            newHSLabel.fontColor = .yellow
            newHSLabel.position = CGPoint(x: size.width / 2, y: size.height * 0.52)
            addChild(newHSLabel)

            let glow = SKAction.sequence([
                SKAction.fadeAlpha(to: 0.5, duration: 0.4),
                SKAction.fadeAlpha(to: 1.0, duration: 0.4)
            ])
            newHSLabel.run(SKAction.repeatForever(glow))
        }

        // Mini-Bestenliste
        let lbY: CGFloat = isNewHighscore ? 0.46 : 0.50
        let lbTitle = SKLabelNode(text: "Top 5")
        lbTitle.fontName = "AvenirNext-Bold"
        lbTitle.fontSize = 18
        lbTitle.fontColor = SKColor(white: 0.6, alpha: 1.0)
        lbTitle.position = CGPoint(x: size.width / 2, y: size.height * lbY)
        addChild(lbTitle)

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
            addChild(label)
        }

        // Buttons
        let buttonsY = size.height * 0.18

        let restartBtn = SKShapeNode(rectOf: CGSize(width: 180, height: 55), cornerRadius: 12)
        restartBtn.fillColor = SKColor(red: 0.2, green: 0.7, blue: 0.3, alpha: 1.0)
        restartBtn.strokeColor = .clear
        restartBtn.position = CGPoint(x: size.width / 2, y: buttonsY)
        restartBtn.name = "restartButton"
        addChild(restartBtn)

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
        addChild(menuBtn)

        let menuLabel = SKLabelNode(text: "HAUPTMENÜ")
        menuLabel.fontName = "AvenirNext-Bold"
        menuLabel.fontSize = 20
        menuLabel.fontColor = .white
        menuLabel.verticalAlignmentMode = .center
        menuLabel.name = "backToMenuButton"
        menuBtn.addChild(menuLabel)
    }
}
