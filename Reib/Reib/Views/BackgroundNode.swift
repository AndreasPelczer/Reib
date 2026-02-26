//
//  BackgroundNode.swift
//  Reib
//
//  Created by Andreas Pelczer on 26.02.26.
//

import SpriteKit

class BackgroundNode: SKNode {

    func setup(size: CGSize) {
        self.zPosition = -10

        // Radialer Gradient
        let layers = 8
        for i in (0..<layers).reversed() {
            let fraction = CGFloat(i) / CGFloat(layers)
            let layerRadius = max(size.width, size.height) * fraction
            let circle = SKShapeNode(circleOfRadius: layerRadius)
            let brightness: CGFloat = 0.06 + (1.0 - fraction) * 0.04
            circle.fillColor = SKColor(white: brightness, alpha: 1.0)
            circle.strokeColor = .clear
            circle.position = CGPoint(x: size.width / 2, y: size.height / 2)
            addChild(circle)
        }

        // Pixelraster
        for i in stride(from: CGFloat(0), to: size.width, by: 20) {
            let line = SKShapeNode(rectOf: CGSize(width: 0.5, height: size.height))
            line.fillColor = SKColor(white: 1.0, alpha: 0.015)
            line.strokeColor = .clear
            line.position = CGPoint(x: i, y: size.height / 2)
            addChild(line)
        }
        for i in stride(from: CGFloat(0), to: size.height, by: 20) {
            let line = SKShapeNode(rectOf: CGSize(width: size.width, height: 0.5))
            line.fillColor = SKColor(white: 1.0, alpha: 0.015)
            line.strokeColor = .clear
            line.position = CGPoint(x: size.width / 2, y: i)
            addChild(line)
        }

        // Schwebende Lichtpartikel
        for _ in 0..<12 {
            let dot = SKShapeNode(circleOfRadius: CGFloat.random(in: 1...2.5))
            dot.fillColor = SKColor(white: 1.0, alpha: CGFloat.random(in: 0.03...0.08))
            dot.strokeColor = .clear
            dot.position = CGPoint(
                x: CGFloat.random(in: 0...size.width),
                y: CGFloat.random(in: 0...size.height)
            )
            addChild(dot)

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

    func playShake() {
        let shake = SKAction.sequence([
            SKAction.moveBy(x: 10, y: 0, duration: 0.03),
            SKAction.moveBy(x: -20, y: 0, duration: 0.03),
            SKAction.moveBy(x: 15, y: 0, duration: 0.03),
            SKAction.moveBy(x: -10, y: 0, duration: 0.03),
            SKAction.moveBy(x: 5, y: 0, duration: 0.03),
        ])
        run(shake)
    }
}
