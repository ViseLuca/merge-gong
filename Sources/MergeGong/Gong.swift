import AVFoundation

/// A gong strike synthesized at launch: no audio files, just inharmonic partials and a noisy attack.
final class Gong {
    private let engine = AVAudioEngine()
    private let player = AVAudioPlayerNode()
    private let buffer: AVAudioPCMBuffer

    init() {
        let sampleRate = 44_100.0
        let format = AVAudioFormat(standardFormatWithSampleRate: sampleRate, channels: 2)!
        let frames = AVAudioFrameCount(sampleRate * 7)
        buffer = AVAudioPCMBuffer(pcmFormat: format, frameCapacity: frames)!
        buffer.frameLength = frames

        // (frequency ratio, amplitude, seconds to fade out): inharmonic, like a real gong
        let partials: [(Double, Double, Double)] = [
            (1.00, 1.00, 6.5), (1.52, 0.60, 5.0), (2.03, 0.50, 4.5), (2.61, 0.35, 4.0),
            (3.17, 0.30, 3.2), (3.90, 0.20, 2.6), (4.70, 0.15, 2.0), (5.60, 0.10, 1.5),
        ]
        let base = 92.0
        var phases = [Double](repeating: 0, count: partials.count)
        var samples = [Float](repeating: 0, count: Int(frames))
        var noiseState = 0.0
        var peak: Float = 0

        for i in 0..<Int(frames) {
            let t = Double(i) / sampleRate
            let glide = 1 + 0.03 * exp(-t * 5)
            var value = 0.0
            for (k, (ratio, amp, fade)) in partials.enumerated() {
                phases[k] += 2 * .pi * base * ratio * glide / sampleRate
                let envelope = amp * (1 - exp(-t * 30)) * exp(-t * 4.6 / fade)
                let shimmer = 0.7 + 0.3 * cos(2 * .pi * (0.6 + Double(k) * 0.35) * t)
                value += envelope * shimmer * sin(phases[k])
            }
            if t < 0.25 {
                noiseState += (Double.random(in: -1...1) - noiseState) * 0.25
                value += noiseState * 1.5 * pow(1 - t / 0.25, 3)
            }
            samples[i] = Float(value)
            peak = max(peak, abs(Float(value)))
        }

        let left = buffer.floatChannelData![0], right = buffer.floatChannelData![1]
        for i in 0..<Int(frames) {
            left[i] = samples[i] / peak * 0.9
            right[i] = left[i]
        }

        engine.attach(player)
        engine.connect(player, to: engine.mainMixerNode, format: format)
    }

    func play() {
        if !engine.isRunning { try? engine.start() }
        player.scheduleBuffer(buffer, at: nil, options: .interrupts)
        player.play()
    }
}
