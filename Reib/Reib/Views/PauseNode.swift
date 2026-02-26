//
//  PauseNode.swift
//  Reib
//
//  Created by Andreas Pelczer on 26.02.26.
//

import SpriteKit

class PauseNode: SKNode {

    func setup(size: CGSize) {
        self.zPosition = 60

        // Dunkler Overlay
        let overlay = SKShapeNode(rectOf: CGSize(width: size.width * 2, height: size.height * 2))
        overlay.fillColor = SKColor(red: 0, green: 0, blue: 0, alpha: 0.7)
        overlay.strokeColor = .clear
        overlay.position = CGPoint(x: size.width / 2, y: size.height / 2)
        overlay.name = "pauseOverlay"
        addChild(overlay)

        // Titel
        let pauseTitle = SKLabelNode(text: "PAUSE")
        pauseTitle.fontName = "AvenirNext-Heavy"
        pauseTitle.fontSize = 48
        pauseTitle.fontColor = .white
        pauseTitle.position = CGPoint(x: size.width / 2, y: size.height * 0.60)
        addChild(pauseTitle)

        // Weiter-Button
        let resumeBtn = SKShapeNode(rectOf: CGSize(width: 200, height: 55), cornerRadius: 12)
        resumeBtn.fillColor = SKColor(red: 0.2, green: 0.7, blue: 0.3, alpha: 1.0)
        resumeBtn.strokeColor = .clear
        resumeBtn.position = CGPoint(x: size.width / 2, y: size.height * 0.45)
        resumeBtn.name = "resumeButton"
        addChild(resumeBtn)

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
