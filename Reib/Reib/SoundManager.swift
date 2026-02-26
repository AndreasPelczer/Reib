//
//  SoundManager.swift
//  Reib
//
//  Synthetisierte Sound-Effekte ohne externe Audio-Dateien.
//  Verwendet AVAudioEngine mit vorgenerierten PCM-Buffern.
//

import AVFoundation

final class SoundManager {

    static let shared = SoundManager()

    private let engine = AVAudioEngine()
    private let format: AVAudioFormat
    private let sampleRate: Double = 44100

    // Pool für gleichzeitige One-Shot-Sounds
    private var players: [AVAudioPlayerNode] = []
    private var playerIndex = 0
    private let poolSize = 6

    // Wisch-Sound (Endlosschleife, lautstärkegesteuert)
    private let wipePlayer = AVAudioPlayerNode()
    private var isWipePlaying = false

    // Vorgenerierte Buffer
    private var wipeBuffer: AVAudioPCMBuffer?
    private var plingBuffer: AVAudioPCMBuffer?
    private var doublePlingBuffer: AVAudioPCMBuffer?
    private var boomBuffer: AVAudioPCMBuffer?
    private var freezeBuffer: AVAudioPCMBuffer?
    private var chainPlingBuffer: AVAudioPCMBuffer?
    private var fanfareBuffer: AVAudioPCMBuffer?
    private var lifeUpBuffer: AVAudioPCMBuffer?

    private var isReady = false

    private init() {
        format = AVAudioFormat(standardFormatWithSampleRate: sampleRate, channels: 1)!
    }

    // MARK: - Setup

    func prepare() {
        guard !isReady else { return }

        configureAudioSession()

        // Wipe-Player
        engine.attach(wipePlayer)
        engine.connect(wipePlayer, to: engine.mainMixerNode, format: format)
        wipePlayer.volume = 0

        // One-Shot-Pool
        for _ in 0..<poolSize {
            let player = AVAudioPlayerNode()
            engine.attach(player)
            engine.connect(player, to: engine.mainMixerNode, format: format)
            players.append(player)
        }

        engine.mainMixerNode.outputVolume = 0.6

        // Buffer generieren
        wipeBuffer = generateWipe()
        plingBuffer = generatePling(freq1: 880, freq2: 1320, duration: 0.25)
        doublePlingBuffer = generateDoublePling()
        boomBuffer = generateBoom()
        freezeBuffer = generateFreeze()
        chainPlingBuffer = generatePling(freq1: 1046, freq2: 1568, duration: 0.2)
        fanfareBuffer = generateFanfare()
        lifeUpBuffer = generatePling(freq1: 660, freq2: 990, duration: 0.3)

        do {
            try engine.start()
            isReady = true
        } catch {
            print("SoundManager: Engine start failed – \(error)")
        }
    }

    private func configureAudioSession() {
        let session = AVAudioSession.sharedInstance()
        try? session.setCategory(.ambient, options: .mixWithOthers)
        try? session.setActive(true)
    }

    // MARK: - Wisch-Sound (Endlosschleife)

    func updateWipe(intensity: CGFloat) {
        guard isReady, let buffer = wipeBuffer else { return }

        if !isWipePlaying {
            wipePlayer.scheduleBuffer(buffer, at: nil, options: .loops)
            wipePlayer.play()
            isWipePlaying = true
        }
        // Lautstärke = Wisch-Intensität, sanft begrenzt
        wipePlayer.volume = Float(min(intensity / 2.5, 1.0)) * 0.35
    }

    func stopWipe() {
        guard isWipePlaying else { return }
        wipePlayer.volume = 0
        wipePlayer.stop()
        isWipePlaying = false
    }

    // MARK: - One-Shot Sounds

    func playStar()         { playOneShot(plingBuffer, volume: 0.5) }
    func playDoubleStar()   { playOneShot(doublePlingBuffer, volume: 0.6) }
    func playBomb()         { playOneShot(boomBuffer, volume: 0.7) }
    func playFreeze()       { playOneShot(freezeBuffer, volume: 0.45) }
    func playChain()        { playOneShot(chainPlingBuffer, volume: 0.5) }
    func playBossDefeated() { playOneShot(fanfareBuffer, volume: 0.6) }
    func playExtraLife()    { playOneShot(lifeUpBuffer, volume: 0.5) }

    private func playOneShot(_ buffer: AVAudioPCMBuffer?, volume: Float) {
        guard isReady, let buffer = buffer else { return }
        let player = players[playerIndex]
        playerIndex = (playerIndex + 1) % poolSize
        player.stop()
        player.volume = volume
        player.scheduleBuffer(buffer, at: nil, options: [])
        player.play()
    }

    // MARK: - Sound-Synthese

    /// Wisch-Geräusch: bandpass-gefiltertes Rauschen (~0.15s Loop)
    private func generateWipe() -> AVAudioPCMBuffer {
        let duration = 0.15
        let frameCount = AVAudioFrameCount(sampleRate * duration)
        let buffer = AVAudioPCMBuffer(pcmFormat: format, frameCapacity: frameCount)!
        buffer.frameLength = frameCount
        let data = buffer.floatChannelData![0]

        // Einfacher IIR-Bandpass um ~3kHz
        var prev1: Float = 0
        var prev2: Float = 0
        let f0: Float = 3000.0 / Float(sampleRate)
        let bw: Float = 0.4
        let r: Float = 1.0 - .pi * bw * f0
        let cosF: Float = cos(2.0 * .pi * f0)

        for i in 0..<Int(frameCount) {
            let noise = Float.random(in: -1...1)
            let filtered = noise - 2.0 * r * cosF * prev1 + r * r * prev2
            prev2 = prev1
            prev1 = filtered

            // Envelope: sanfter Ein-/Ausstieg für Loop
            let t = Float(i) / Float(frameCount)
            let env = sin(t * .pi) // Halbe Sinuswelle → nahtloser Loop
            data[i] = filtered * env * 0.4
        }
        return buffer
    }

    /// Pling: Zwei Sinuswellen mit schnellem Decay
    private func generatePling(freq1: Double, freq2: Double, duration: Double) -> AVAudioPCMBuffer {
        let frameCount = AVAudioFrameCount(sampleRate * duration)
        let buffer = AVAudioPCMBuffer(pcmFormat: format, frameCapacity: frameCount)!
        buffer.frameLength = frameCount
        let data = buffer.floatChannelData![0]

        for i in 0..<Int(frameCount) {
            let t = Double(i) / sampleRate
            let env = exp(-t * 14.0)
            let sig1 = sin(2.0 * .pi * freq1 * t)
            let sig2 = sin(2.0 * .pi * freq2 * t) * 0.45
            data[i] = Float((sig1 + sig2) * env * 0.35)
        }
        return buffer
    }

    /// Doppel-Pling: Zwei aufeinanderfolgende Töne
    private func generateDoublePling() -> AVAudioPCMBuffer {
        let duration = 0.35
        let frameCount = AVAudioFrameCount(sampleRate * duration)
        let buffer = AVAudioPCMBuffer(pcmFormat: format, frameCapacity: frameCount)!
        buffer.frameLength = frameCount
        let data = buffer.floatChannelData![0]

        let splitFrame = Int(Double(frameCount) * 0.45)

        for i in 0..<Int(frameCount) {
            let t = Double(i) / sampleRate
            if i < splitFrame {
                let env = exp(-t * 16.0)
                let sig = sin(2.0 * .pi * 880.0 * t) + sin(2.0 * .pi * 1320.0 * t) * 0.4
                data[i] = Float(sig * env * 0.3)
            } else {
                let t2 = Double(i - splitFrame) / sampleRate
                let env = exp(-t2 * 14.0)
                let sig = sin(2.0 * .pi * 1047.0 * t2) + sin(2.0 * .pi * 1568.0 * t2) * 0.4
                data[i] = Float(sig * env * 0.3)
            }
        }
        return buffer
    }

    /// Boom: Tiefer Sinus + Rausch-Burst
    private func generateBoom() -> AVAudioPCMBuffer {
        let duration = 0.4
        let frameCount = AVAudioFrameCount(sampleRate * duration)
        let buffer = AVAudioPCMBuffer(pcmFormat: format, frameCapacity: frameCount)!
        buffer.frameLength = frameCount
        let data = buffer.floatChannelData![0]

        for i in 0..<Int(frameCount) {
            let t = Double(i) / sampleRate
            // Tiefer Sinus mit Pitch-Drop
            let freq = 80.0 * exp(-t * 3.0) + 30.0
            let bass = sin(2.0 * .pi * freq * t) * exp(-t * 5.0)
            // Rausch-Burst
            let noise = Double(Float.random(in: -1...1)) * exp(-t * 12.0)
            // Zusammen mit Soft-Clipping
            let raw = (bass * 0.7 + noise * 0.3) * 0.6
            data[i] = Float(tanh(raw * 2.0))
        }
        return buffer
    }

    /// Freeze: Absteigender Ton-Sweep
    private func generateFreeze() -> AVAudioPCMBuffer {
        let duration = 0.3
        let frameCount = AVAudioFrameCount(sampleRate * duration)
        let buffer = AVAudioPCMBuffer(pcmFormat: format, frameCapacity: frameCount)!
        buffer.frameLength = frameCount
        let data = buffer.floatChannelData![0]

        var phase: Double = 0
        for i in 0..<Int(frameCount) {
            let t = Double(i) / sampleRate
            let env = exp(-t * 6.0)
            // Frequency sweep: 2000Hz → 400Hz
            let freq = 2000.0 * exp(-t * 5.5) + 400.0
            phase += 2.0 * .pi * freq / sampleRate
            let sig = sin(phase) * 0.6 + sin(phase * 1.5) * 0.2
            data[i] = Float(sig * env * 0.35)
        }
        return buffer
    }

    /// Fanfare: Aufsteigender Dreiklang (Boss besiegt)
    private func generateFanfare() -> AVAudioPCMBuffer {
        let duration = 0.5
        let frameCount = AVAudioFrameCount(sampleRate * duration)
        let buffer = AVAudioPCMBuffer(pcmFormat: format, frameCapacity: frameCount)!
        buffer.frameLength = frameCount
        let data = buffer.floatChannelData![0]

        let notes: [(freq: Double, start: Double, dur: Double)] = [
            (523.25, 0.0, 0.2),   // C5
            (659.25, 0.12, 0.2),  // E5
            (783.99, 0.24, 0.26)  // G5
        ]

        for i in 0..<Int(frameCount) {
            let t = Double(i) / sampleRate
            var sample = 0.0
            for note in notes {
                guard t >= note.start else { continue }
                let noteT = t - note.start
                guard noteT < note.dur else { continue }
                let env = sin(noteT / note.dur * .pi)
                sample += sin(2.0 * .pi * note.freq * noteT) * env * 0.25
            }
            data[i] = Float(sample)
        }
        return buffer
    }

    // MARK: - Cleanup

    func stop() {
        stopWipe()
        players.forEach { $0.stop() }
        engine.stop()
        isReady = false
    }
}
