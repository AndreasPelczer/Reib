//
//  GameTheme.swift
//  Reib
//
//  Visuelle Themes: Küchenfett, Baustaub, Fingerfarbe.
//  Jedes Theme definiert Farben, Partikel-Stil und Hintergrund.
//

import SpriteKit

// MARK: - Theme-Definitionen

enum ThemeID: String, CaseIterable, Codable {
    case kuechenfett
    case baustaub
    case fingerfarbe
}

struct GameTheme {

    let id: ThemeID
    let displayName: String
    let subtitle: String
    let unlockWave: Int               // Ab welcher höchsten erreichten Welle freigeschaltet

    // Hintergrund
    let bgCenterBrightness: CGFloat   // Dunkelster Punkt (Mitte)
    let bgEdgeBrightness: CGFloat     // Hellster Punkt (Rand)
    let bgTint: SKColor               // Farbstich (multipliziert mit Graustufe)
    let gridAlpha: CGFloat            // Rasterlinien-Sichtbarkeit
    let ambientParticleColor: SKColor
    let ambientParticleAlpha: ClosedRange<CGFloat>

    // Fleck-Farben
    let dirtColors: [(CGFloat, CGFloat, CGFloat)]
    let dirtColorVariance: CGFloat
    let dirtAlpha: CGFloat
    let oilColorRange: (r: ClosedRange<CGFloat>, g: ClosedRange<CGFloat>, b: ClosedRange<CGFloat>)
    let bossColorRange: (r: ClosedRange<CGFloat>, g: ClosedRange<CGFloat>, b: ClosedRange<CGFloat>)
    let bossCrackColor: SKColor

    // Textur-Stil
    let fingerprintLighterBlend: CGFloat
    let fingerprintDarkerBlend: CGFloat
    let oilSwirlColor: SKColor
    let oilGlossAlpha: CGFloat

    // Partikel
    let dirtParticleRadiusRange: ClosedRange<CGFloat>
    let bossParticleColor: SKColor

    // Wisch-Spuren
    let wipeTrailColor: SKColor
    let wipeTrailAlpha: CGFloat

    // Scene-Hintergrundfarbe
    let sceneBackgroundColor: SKColor
}

// MARK: - Vordefinierte Themes

extension GameTheme {

    static let kuechenfett = GameTheme(
        id: .kuechenfett,
        displayName: "Küchenfett",
        subtitle: "Fettige Gastro-Arbeitsfläche",
        unlockWave: 0,

        bgCenterBrightness: 0.06,
        bgEdgeBrightness: 0.10,
        bgTint: SKColor(red: 0.9, green: 0.85, blue: 0.7, alpha: 1.0),
        gridAlpha: 0.015,
        ambientParticleColor: SKColor(white: 1.0, alpha: 1.0),
        ambientParticleAlpha: 0.03...0.08,

        dirtColors: [
            (0.35, 0.25, 0.15),
            (0.40, 0.35, 0.25),
            (0.30, 0.30, 0.28),
            (0.45, 0.38, 0.20),
            (0.32, 0.28, 0.22),
        ],
        dirtColorVariance: 0.05,
        dirtAlpha: 0.88,
        oilColorRange: (r: 0.08...0.15, g: 0.06...0.12, b: 0.05...0.10),
        bossColorRange: (r: 0.25...0.35, g: 0.02...0.08, b: 0.02...0.08),
        bossCrackColor: SKColor(red: 0.6, green: 0.1, blue: 0.1, alpha: 1.0),

        fingerprintLighterBlend: 0.15,
        fingerprintDarkerBlend: 0.12,
        oilSwirlColor: SKColor(white: 0.15, alpha: 1.0),
        oilGlossAlpha: 0.12,

        dirtParticleRadiusRange: 1.5...3.5,
        bossParticleColor: SKColor(red: 0.4, green: 0.05, blue: 0.05, alpha: 0.5),

        wipeTrailColor: SKColor(white: 0.3, alpha: 1.0),
        wipeTrailAlpha: 0.15,

        sceneBackgroundColor: SKColor(red: 0.08, green: 0.08, blue: 0.10, alpha: 1.0)
    )

    static let baustaub = GameTheme(
        id: .baustaub,
        displayName: "Baustaub",
        subtitle: "Kreidiger Beton-Dreck",
        unlockWave: 15,

        bgCenterBrightness: 0.12,
        bgEdgeBrightness: 0.18,
        bgTint: SKColor(red: 0.85, green: 0.83, blue: 0.80, alpha: 1.0),
        gridAlpha: 0.025,
        ambientParticleColor: SKColor(white: 0.8, alpha: 1.0),
        ambientParticleAlpha: 0.05...0.12,

        dirtColors: [
            (0.55, 0.53, 0.50),   // Betongrau
            (0.48, 0.46, 0.43),   // Zementgrau
            (0.60, 0.57, 0.52),   // Sandstein
            (0.42, 0.40, 0.38),   // Schiefergrau
            (0.50, 0.48, 0.44),   // Putz
        ],
        dirtColorVariance: 0.04,
        dirtAlpha: 0.82,
        oilColorRange: (r: 0.15...0.22, g: 0.14...0.20, b: 0.12...0.18),
        bossColorRange: (r: 0.30...0.38, g: 0.28...0.34, b: 0.25...0.30),
        bossCrackColor: SKColor(red: 0.35, green: 0.32, blue: 0.28, alpha: 1.0),

        fingerprintLighterBlend: 0.20,
        fingerprintDarkerBlend: 0.10,
        oilSwirlColor: SKColor(white: 0.25, alpha: 1.0),
        oilGlossAlpha: 0.08,

        dirtParticleRadiusRange: 1.0...4.0,
        bossParticleColor: SKColor(red: 0.35, green: 0.33, blue: 0.30, alpha: 0.4),

        wipeTrailColor: SKColor(white: 0.5, alpha: 1.0),
        wipeTrailAlpha: 0.12,

        sceneBackgroundColor: SKColor(red: 0.14, green: 0.13, blue: 0.12, alpha: 1.0)
    )

    static let fingerfarbe = GameTheme(
        id: .fingerfarbe,
        displayName: "Fingerfarbe",
        subtitle: "Bunt auf weißem Papier",
        unlockWave: 25,

        bgCenterBrightness: 0.88,
        bgEdgeBrightness: 0.94,
        bgTint: SKColor(white: 1.0, alpha: 1.0),
        gridAlpha: 0.04,
        ambientParticleColor: SKColor(red: 1.0, green: 0.8, blue: 0.3, alpha: 1.0),
        ambientParticleAlpha: 0.04...0.10,

        dirtColors: [
            (0.85, 0.20, 0.15),   // Rot
            (0.15, 0.45, 0.80),   // Blau
            (0.20, 0.70, 0.25),   // Grün
            (0.90, 0.75, 0.10),   // Gelb
            (0.70, 0.25, 0.70),   // Lila
        ],
        dirtColorVariance: 0.06,
        dirtAlpha: 0.90,
        oilColorRange: (r: 0.60...0.80, g: 0.10...0.25, b: 0.50...0.70),
        bossColorRange: (r: 0.70...0.85, g: 0.05...0.15, b: 0.10...0.20),
        bossCrackColor: SKColor(red: 0.9, green: 0.2, blue: 0.1, alpha: 1.0),

        fingerprintLighterBlend: 0.20,
        fingerprintDarkerBlend: 0.15,
        oilSwirlColor: SKColor(white: 0.85, alpha: 1.0),
        oilGlossAlpha: 0.18,

        dirtParticleRadiusRange: 2.0...4.5,
        bossParticleColor: SKColor(red: 0.8, green: 0.15, blue: 0.1, alpha: 0.5),

        wipeTrailColor: SKColor(white: 0.7, alpha: 1.0),
        wipeTrailAlpha: 0.10,

        sceneBackgroundColor: SKColor(red: 0.92, green: 0.90, blue: 0.87, alpha: 1.0)
    )

    static func theme(for id: ThemeID) -> GameTheme {
        switch id {
        case .kuechenfett: return .kuechenfett
        case .baustaub:    return .baustaub
        case .fingerfarbe: return .fingerfarbe
        }
    }

    static var allThemes: [GameTheme] {
        [.kuechenfett, .baustaub, .fingerfarbe]
    }
}

// MARK: - Theme-Persistenz & Freischaltung

final class ThemeManager {

    static let shared = ThemeManager()

    private let selectedKey = "selectedTheme"
    private let bestWaveKey = "bestWaveReached"

    private(set) var currentTheme: GameTheme

    private init() {
        let savedID = UserDefaults.standard.string(forKey: selectedKey)
            .flatMap { ThemeID(rawValue: $0) } ?? .kuechenfett
        currentTheme = GameTheme.theme(for: savedID)
    }

    var bestWaveReached: Int {
        get { UserDefaults.standard.integer(forKey: bestWaveKey) }
        set {
            if newValue > UserDefaults.standard.integer(forKey: bestWaveKey) {
                UserDefaults.standard.set(newValue, forKey: bestWaveKey)
            }
        }
    }

    func isUnlocked(_ theme: GameTheme) -> Bool {
        return bestWaveReached >= theme.unlockWave
    }

    func select(_ id: ThemeID) {
        let theme = GameTheme.theme(for: id)
        guard isUnlocked(theme) else { return }
        currentTheme = theme
        UserDefaults.standard.set(id.rawValue, forKey: selectedKey)
    }

    func reportWave(_ wave: Int) {
        bestWaveReached = wave
    }
}
