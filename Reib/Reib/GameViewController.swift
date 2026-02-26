//
//  GameViewController.swift
//  Reib
//
//  Created by Andreas Pelczer on 26.02.26.
//

import UIKit
import SpriteKit

class GameViewController: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()

        if let view = self.view as! SKView? {
            // Scene programmatisch erstellen (keine .sks Datei nötig)
            let scene = GameScene(size: view.bounds.size)
            scene.scaleMode = .resizeFill

            view.presentScene(scene)
            view.ignoresSiblingOrder = true
            view.isMultipleTouchEnabled = true // Wichtig fürs Reiben!

            // Debug-Infos (später ausschalten)
            view.showsFPS = true
            view.showsNodeCount = true
        }
    }

    override var supportedInterfaceOrientations: UIInterfaceOrientationMask {
        return .portrait // Hochformat – so hält man das Telefon beim Reiben
    }

    override var prefersStatusBarHidden: Bool {
        return true
    }
}
