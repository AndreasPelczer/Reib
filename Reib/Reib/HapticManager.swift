//
//  HapticManager.swift
//  Reib
//
//  Haptisches Feedback für Spielereignisse.
//  Verwendet vorbereitete Generatoren für minimale Latenz.
//

import UIKit

final class HapticManager {

    static let shared = HapticManager()

    private let lightImpact = UIImpactFeedbackGenerator(style: .light)
    private let mediumImpact = UIImpactFeedbackGenerator(style: .medium)
    private let heavyImpact = UIImpactFeedbackGenerator(style: .heavy)
    private let notification = UINotificationFeedbackGenerator()

    // Throttle: Rub-Haptik maximal ~20× pro Sekunde
    private var lastRubTime: TimeInterval = 0
    private let rubInterval: TimeInterval = 0.05

    private init() {}

    /// Generatoren vorbereiten (einmal beim Spielstart aufrufen)
    func prepare() {
        lightImpact.prepare()
        mediumImpact.prepare()
        heavyImpact.prepare()
        notification.prepare()
    }

    // MARK: - Rub (während des Wischens)

    func rub(intensity: CGFloat) {
        let now = CACurrentMediaTime()
        guard now - lastRubTime >= rubInterval else { return }
        lastRubTime = now
        lightImpact.impactOccurred(intensity: min(intensity / 2.0, 1.0))
    }

    // MARK: - Reward-spezifisch

    func star() {
        notification.feedbackOccurred(.success)
    }

    func bomb() {
        notification.feedbackOccurred(.error)
    }

    func freeze() {
        mediumImpact.impactOccurred(intensity: 0.7)
    }

    func chain() {
        mediumImpact.impactOccurred(intensity: 0.8)
    }

    func chainComplete() {
        notification.feedbackOccurred(.success)
    }

    func bossDefeated() {
        heavyImpact.impactOccurred(intensity: 1.0)
    }

    func extraLife() {
        notification.feedbackOccurred(.success)
    }

    func lifeLost() {
        heavyImpact.impactOccurred(intensity: 1.0)
    }
}
