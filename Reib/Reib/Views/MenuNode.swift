//
//  MenuNode.swift
//  Reib
//
//  Created by Andreas Pelczer on 26.02.26.
//

import SpriteKit

class MenuNode: SKNode {

    private var demoSmudges: [SmudgeNode] = []

    /// Callback wenn der Spieler ein Theme wechselt
    var onThemeChanged: (() -> Void)?

    func setup(size: CGSize, leaderboard: [Int]) {
        self.zPosition = 10

        let theme = ThemeManager.shared.currentTheme

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

        // Theme-Auswahl
        setupThemeSelector(size: size)

        // Bestenliste
        if !leaderboard.isEmpty {
            let lbTitle = SKLabelNode(text: "Bestenliste")
            lbTitle.fontName = "AvenirNext-Bold"
            lbTitle.fontSize = 20
            lbTitle.fontColor = SKColor(white: 0.6, alpha: 1.0)
            lbTitle.position = CGPoint(x: size.width / 2, y: size.height * 0.24)
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
                label.position = CGPoint(x: size.width / 2, y: size.height * 0.20 - CGFloat(i) * 24)
                addChild(label)
            }
        }

        // Demo-Flecken mit aktuellem Theme
        for _ in 0..<5 {
            let model = SmudgeModel(
                reward: .star,
                behavior: .normal,
                radius: CGFloat.random(in: 25...50),
                position: CGPoint(
                    x: CGFloat.random(in: 60...(size.width - 60)),
                    y: CGFloat.random(in: size.height * 0.02...size.height * 0.10)
                ),
                spawnTime: 0
            )
            let node = SmudgeNode(model: model, theme: theme)
            node.alpha = 0.4
            node.zPosition = -1
            addChild(node)
            demoSmudges.append(node)
        }
    }

    // MARK: - Theme-Auswahl

    private func setupThemeSelector(size: CGSize) {
        let themes = GameTheme.allThemes
        let totalWidth: CGFloat = CGFloat(themes.count) * 100 + CGFloat(themes.count - 1) * 12
        let startX = size.width / 2 - totalWidth / 2 + 50

        for (i, theme) in themes.enumerated() {
            let x = startX + CGFloat(i) * 112
            let y = size.height * 0.38

            let unlocked = ThemeManager.shared.isUnlocked(theme)
            let isActive = ThemeManager.shared.currentTheme.id == theme.id

            // Hintergrund-Karte
            let card = SKShapeNode(rectOf: CGSize(width: 96, height: 70), cornerRadius: 10)
            card.position = CGPoint(x: x, y: y)
            card.name = "theme_\(theme.id.rawValue)"
            card.zPosition = 12

            if !unlocked {
                card.fillColor = SKColor(white: 0.15, alpha: 0.6)
                card.strokeColor = SKColor(white: 0.3, alpha: 0.5)
                card.lineWidth = 1
            } else if isActive {
                card.fillColor = SKColor(red: 0.15, green: 0.4, blue: 0.2, alpha: 0.8)
                card.strokeColor = SKColor(red: 0.3, green: 0.8, blue: 0.4, alpha: 0.9)
                card.lineWidth = 2
            } else {
                card.fillColor = SKColor(white: 0.12, alpha: 0.7)
                card.strokeColor = SKColor(white: 0.4, alpha: 0.6)
                card.lineWidth = 1.5
            }
            addChild(card)

            // Farbvorschau (3 kleine Kreise)
            let previewY: CGFloat = 10
            let previewColors = theme.dirtColors.prefix(3)
            for (j, color) in previewColors.enumerated() {
                let dot = SKShapeNode(circleOfRadius: 7)
                dot.fillColor = SKColor(red: color.0, green: color.1, blue: color.2, alpha: 1.0)
                dot.strokeColor = .clear
                dot.position = CGPoint(x: CGFloat(j - 1) * 20, y: previewY)
                dot.name = "theme_\(theme.id.rawValue)"
                card.addChild(dot)
            }

            // Name
            let nameLabel = SKLabelNode(text: theme.displayName)
            nameLabel.fontName = "AvenirNext-Bold"
            nameLabel.fontSize = 11
            nameLabel.fontColor = unlocked ? .white : SKColor(white: 0.4, alpha: 1.0)
            nameLabel.verticalAlignmentMode = .center
            nameLabel.position = CGPoint(x: 0, y: -12)
            nameLabel.name = "theme_\(theme.id.rawValue)"
            card.addChild(nameLabel)

            // Gesperrt-Hinweis oder Aktiv-Indikator
            if !unlocked {
                let lockLabel = SKLabelNode(text: "Welle \(theme.unlockWave)")
                lockLabel.fontName = "AvenirNext-Medium"
                lockLabel.fontSize = 9
                lockLabel.fontColor = SKColor(white: 0.35, alpha: 1.0)
                lockLabel.verticalAlignmentMode = .center
                lockLabel.position = CGPoint(x: 0, y: -25)
                lockLabel.name = "theme_\(theme.id.rawValue)"
                card.addChild(lockLabel)
            } else if isActive {
                let checkLabel = SKLabelNode(text: "aktiv")
                checkLabel.fontName = "AvenirNext-Medium"
                checkLabel.fontSize = 9
                checkLabel.fontColor = SKColor(red: 0.4, green: 0.9, blue: 0.5, alpha: 1.0)
                checkLabel.verticalAlignmentMode = .center
                checkLabel.position = CGPoint(x: 0, y: -25)
                checkLabel.name = "theme_\(theme.id.rawValue)"
                card.addChild(checkLabel)
            }
        }
    }

    /// Gibt die ThemeID zurück, wenn ein Theme-Button getippt wurde
    func handleThemeTap(nodeName: String?) -> Bool {
        guard let name = nodeName, name.hasPrefix("theme_") else { return false }
        let rawID = String(name.dropFirst(6))
        guard let themeID = ThemeID(rawValue: rawID) else { return false }

        let theme = GameTheme.theme(for: themeID)
        guard ThemeManager.shared.isUnlocked(theme) else { return false }
        guard ThemeManager.shared.currentTheme.id != themeID else { return true }

        ThemeManager.shared.select(themeID)
        onThemeChanged?()
        return true
    }
}
