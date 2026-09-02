import AVFAudio
import Foundation
import MatutaCore

/// `TonePattern`이 만든 파형을 실제 소리로 낸다. 끌 때까지 무한 반복한다.
@MainActor
final class TonePlayer {
    private let engine = AVAudioEngine()
    private let player = AVAudioPlayerNode()
    private var fadeTask: Task<Void, Never>?

    init() {
        engine.attach(player)
    }

    func start(pattern: TonePattern, volume: Double, fadeIn: Bool) {
        stop()

        let targetVol = Float(volume)
        let sampleRate = 44_100.0
        guard let format = AVAudioFormat(
            standardFormatWithSampleRate: sampleRate, channels: 1
        ) else { return }

        let samples = pattern.samples(sampleRate: sampleRate)
        guard let buffer = AVAudioPCMBuffer(
            pcmFormat: format, frameCapacity: AVAudioFrameCount(samples.count)
        ) else { return }

        buffer.frameLength = AVAudioFrameCount(samples.count)
        if let channel = buffer.floatChannelData?[0] {
            for (index, sample) in samples.enumerated() {
                channel[index] = sample
            }
        }

        engine.connect(player, to: engine.mainMixerNode, format: format)
        // 페이드인이 켜져 있어도 최초 0초에 완전 무음(0.0) 대신 작게 들릴 수 있는 최소 볼륨으로 시작
        let initialVol = fadeIn ? min(targetVol, max(targetVol * 0.15, 0.08)) : targetVol
        engine.mainMixerNode.outputVolume = initialVol

        do {
            try engine.start()
        } catch {
            // 엔진이 안 뜨면 알람이 소리를 못 낸다. 3단계 AudioGuard가 다룰 영역이다.
            return
        }

        player.scheduleBuffer(buffer, at: nil, options: .loops)
        player.play()

        if fadeIn && initialVol < targetVol {
            startFade(from: initialVol, to: targetVol)
        }
    }

    func stop() {
        fadeTask?.cancel()
        fadeTask = nil
        player.stop()
        engine.stop()
    }

    /// 20초에 걸쳐 목표 볼륨까지 부드럽게 올린다.
    private func startFade(from initial: Float, to target: Float) {
        let duration = 20.0
        let tick: Double = 0.5
        let step = (target - initial) / Float(duration / tick)

        fadeTask?.cancel()
        fadeTask = Task { @MainActor [weak self] in
            while !Task.isCancelled {
                try? await Task.sleep(nanoseconds: UInt64(tick * 1_000_000_000))
                guard let self, !Task.isCancelled else { break }
                let current = self.engine.mainMixerNode.outputVolume
                let next = min(target, current + step)
                self.engine.mainMixerNode.outputVolume = next
                if next >= target { break }
            }
        }
    }
}
