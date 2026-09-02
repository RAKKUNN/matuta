import Testing
import Foundation
@testable import MatutaCore

@Test("한 주기 길이는 양수이다")
func cycleDurationIsPositive() {
    let pattern = TonePattern.morningHarp
    #expect(pattern.cycleDuration > 0)
    #expect(pattern.notes.count >= 3)
}

@Test("샘플 개수는 주기 길이와 샘플레이트를 곱한 값이다")
func sampleCountMatchesDuration() {
    let pattern = TonePattern.radar
    let samples = pattern.samples(sampleRate: 44_100)
    #expect(samples.count == Int((pattern.cycleDuration * 44_100).rounded()))
}

@Test("모든 샘플이 -1...1 범위 안에 있다")
func samplesStayInRange() {
    for pattern in [TonePattern.morningHarp, TonePattern.warmRhodes, TonePattern.radar] {
        let samples = pattern.samples(sampleRate: 44_100)
        #expect(!samples.isEmpty)
        #expect(samples.allSatisfy { $0 >= -1.0 && $0 <= 1.0 })
    }
}

@Test("백업음은 잠을 깨울 만큼 반복적이다")
func radarPatternIsRepetitive() {
    #expect(TonePattern.radar.cycleDuration <= 2.0)
    #expect(TonePattern.radar.notes.count >= 2)
}
