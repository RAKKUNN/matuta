import Foundation

/// 알람음의 파형을 코드로 만든다.
///
/// 오디오 파일을 번들하지 않는 이유는 신뢰성 때문이다. 파일은 없어지거나
/// 깨질 수 있지만 계산된 파형은 그럴 수 없다. 설계 문서 §7.4의 백업음이 이것이다.
public struct TonePattern: Sendable {
    /// 헤르츠.
    public let frequency: Double
    /// 삑 소리 하나의 길이 (초).
    public let beepDuration: Double
    /// 삑 소리 사이 침묵의 길이 (초).
    public let gapDuration: Double
    /// 한 주기에 들어가는 삑 소리 개수.
    public let beepCount: Int

    public init(
        frequency: Double,
        beepDuration: Double,
        gapDuration: Double,
        beepCount: Int
    ) {
        self.frequency = frequency
        self.beepDuration = beepDuration
        self.gapDuration = gapDuration
        self.beepCount = beepCount
    }

    /// 기본 백업음. 짧게 세 번 울리고 쉬는 것을 반복한다.
    public static let radar = TonePattern(
        frequency: 880,
        beepDuration: 0.15,
        gapDuration: 0.25,
        beepCount: 3
    )

    public static let beacon = TonePattern(
        frequency: 520,
        beepDuration: 0.25,
        gapDuration: 0.35,
        beepCount: 2
    )

    public static let chime = TonePattern(
        frequency: 660,
        beepDuration: 0.12,
        gapDuration: 0.15,
        beepCount: 4
    )

    public static let signal = TonePattern(
        frequency: 1050,
        beepDuration: 0.10,
        gapDuration: 0.20,
        beepCount: 2
    )

    public static let ripple = TonePattern(
        frequency: 440,
        beepDuration: 0.30,
        gapDuration: 0.20,
        beepCount: 3
    )

    public static let allBuiltInNames = ["Radar", "Beacon", "Chime", "Signal", "Ripple"]

    public static func pattern(named name: String) -> TonePattern {
        switch name.lowercased() {
        case "beacon": return .beacon
        case "chime": return .chime
        case "signal": return .signal
        case "ripple": return .ripple
        default: return .radar
        }
    }

    public var cycleDuration: Double {
        (beepDuration + gapDuration) * Double(beepCount)
    }

    /// 한 주기 분량의 모노 PCM 샘플. 재생 쪽에서 무한 반복한다.
    public func samples(sampleRate: Double) -> [Float] {
        let total = Int((cycleDuration * sampleRate).rounded())
        let beepSamples = Int((beepDuration * sampleRate).rounded())
        let unitSamples = Int(((beepDuration + gapDuration) * sampleRate).rounded())

        var result = [Float](repeating: 0, count: total)

        for index in 0..<total {
            let positionInUnit = index % unitSamples
            guard positionInUnit < beepSamples else { continue }  // 침묵 구간

            let phase = 2.0 * Double.pi * frequency * Double(index) / sampleRate
            // 삑 소리의 시작과 끝을 부드럽게 깎아 딱딱거리는 잡음을 없앤다.
            let envelope = Self.envelope(
                position: positionInUnit, length: beepSamples, sampleRate: sampleRate
            )
            result[index] = Float(sin(phase) * envelope * 0.8)
        }

        return result
    }

    /// 앞뒤 5밀리초를 선형으로 올리고 내린다.
    private static func envelope(
        position: Int, length: Int, sampleRate: Double
    ) -> Double {
        let rampSamples = max(1, Int(0.005 * sampleRate))
        guard length > rampSamples * 2 else { return 1.0 }

        if position < rampSamples {
            return Double(position) / Double(rampSamples)
        }
        if position > length - rampSamples {
            return Double(length - position) / Double(rampSamples)
        }
        return 1.0
    }
}
