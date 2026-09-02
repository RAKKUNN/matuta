import Testing
import Foundation
@testable import MatutaCore

@Test("한 주기 길이는 삑 소리와 침묵의 합이다")
func cycleDurationIsSumOfParts() {
    let pattern = TonePattern(
        frequency: 880, beepDuration: 0.2, gapDuration: 0.3, beepCount: 2
    )

    // (0.2 + 0.3) * 2 = 1.0
    #expect(abs(pattern.cycleDuration - 1.0) < 0.0001)
}

@Test("샘플 개수는 주기 길이와 샘플레이트를 곱한 값이다")
func sampleCountMatchesDuration() {
    let pattern = TonePattern(
        frequency: 880, beepDuration: 0.2, gapDuration: 0.3, beepCount: 2
    )

    let samples = pattern.samples(sampleRate: 44_100)

    #expect(samples.count == 44_100)
}

@Test("삑 구간에는 소리가 있고 침묵 구간에는 없다")
func beepsAreLoudAndGapsAreSilent() {
    let pattern = TonePattern(
        frequency: 880, beepDuration: 0.2, gapDuration: 0.3, beepCount: 1
    )
    let sampleRate = 44_100.0
    let samples = pattern.samples(sampleRate: sampleRate)

    // 사인파는 주기적으로 0을 지난다. 한 샘플만 보면 소리가 나는 중에도
    // 0이 나올 수 있으므로, 구간 전체의 최대 진폭으로 판단한다.
    func peak(from start: Double, to end: Double) -> Float {
        let range = Int(start * sampleRate)..<Int(end * sampleRate)
        return samples[range].map(abs).max() ?? 0
    }

    #expect(peak(from: 0.05, to: 0.15) > 0.5)   // 삑 구간 한복판
    #expect(peak(from: 0.25, to: 0.45) == 0)    // 침묵 구간
}

@Test("모든 샘플이 -1...1 범위 안에 있다")
func samplesStayInRange() {
    let samples = TonePattern.radar.samples(sampleRate: 44_100)

    #expect(!samples.isEmpty)
    #expect(samples.allSatisfy { $0 >= -1.0 && $0 <= 1.0 })
}

@Test("백업음은 잠을 깨울 만큼 반복적이다")
func radarPatternIsRepetitive() {
    // 한 주기가 너무 길면 알람으로 안 들린다.
    #expect(TonePattern.radar.cycleDuration <= 2.0)
    #expect(TonePattern.radar.beepCount >= 2)
}
