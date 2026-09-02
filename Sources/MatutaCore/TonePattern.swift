import Foundation

/// 알람음의 파형을 코드로 합성한다.
///
/// 오디오 파일 의존성 없이 순수 수학적 파형 합성을 통해 100% 신뢰성을 보장하면서도,
/// 배음(Harmonics)과 아르페지오 엔벨로프를 결합하여 스튜디오급 어쿠스틱 사운드를 생성한다.
public struct TonePattern: Sendable {
    public struct Note: Sendable {
        public let frequency: Double
        public let offset: Double
        public let duration: Double
        public let harmonicDecay: Double

        public init(frequency: Double, offset: Double, duration: Double, harmonicDecay: Double = 0.5) {
            self.frequency = frequency
            self.offset = offset
            self.duration = duration
            self.harmonicDecay = harmonicDecay
        }
    }

    public let name: String
    public let totalDuration: Double
    public let notes: [Note]

    public init(name: String, totalDuration: Double, notes: [Note]) {
        self.name = name
        self.totalDuration = totalDuration
        self.notes = notes
    }

    /// 단일 주파수 패턴 생성자 (레거시 및 단순 비프 호환)
    public init(
        frequency: Double,
        beepDuration: Double,
        gapDuration: Double,
        beepCount: Int
    ) {
        self.name = "Custom"
        let unit = beepDuration + gapDuration
        self.totalDuration = unit * Double(beepCount) + 0.3
        var noteList: [Note] = []
        for i in 0..<beepCount {
            noteList.append(Note(frequency: frequency, offset: Double(i) * unit, duration: beepDuration))
        }
        self.notes = noteList
    }

    // MARK: - 스튜디오급 포근한 어쿠스틱 사운드스케이프

    /// 포근한 아침 하프 (F# Major 9 Arpeggio)
    public static let morningHarp = TonePattern(
        name: "Morning Harp",
        totalDuration: 3.6,
        notes: [
            Note(frequency: 369.99, offset: 0.0, duration: 1.8, harmonicDecay: 0.4),  // F#4
            Note(frequency: 466.16, offset: 0.25, duration: 1.8, harmonicDecay: 0.45), // A#4
            Note(frequency: 554.37, offset: 0.50, duration: 2.0, harmonicDecay: 0.5),  // C#5
            Note(frequency: 739.99, offset: 0.75, duration: 2.5, harmonicDecay: 0.6),  // F#5
            Note(frequency: 830.61, offset: 1.05, duration: 2.5, harmonicDecay: 0.65)  // G#5
        ]
    )

    /// 아늑한 웜 로즈 피아노 (Warm Rhodes Cmaj7 Chord)
    public static let warmRhodes = TonePattern(
        name: "Warm Rhodes",
        totalDuration: 3.2,
        notes: [
            Note(frequency: 261.63, offset: 0.0, duration: 2.2, harmonicDecay: 0.35),  // C4
            Note(frequency: 329.63, offset: 0.05, duration: 2.2, harmonicDecay: 0.4),  // E4
            Note(frequency: 392.00, offset: 0.10, duration: 2.2, harmonicDecay: 0.45), // G4
            Note(frequency: 493.88, offset: 0.15, duration: 2.5, harmonicDecay: 0.5),  // B4
            Note(frequency: 587.33, offset: 0.80, duration: 2.0, harmonicDecay: 0.55)  // D5
        ]
    )

    /// 숲속 맑은 차임 (528Hz Solfeggio Pentatonic)
    public static let forestChime = TonePattern(
        name: "Forest Chime",
        totalDuration: 3.0,
        notes: [
            Note(frequency: 528.00, offset: 0.0, duration: 1.6, harmonicDecay: 0.5),
            Note(frequency: 660.00, offset: 0.3, duration: 1.6, harmonicDecay: 0.55),
            Note(frequency: 792.00, offset: 0.6, duration: 2.0, harmonicDecay: 0.6)
        ]
    )

    /// 어쿠스틱 일출 마림바 (Acoustic Sunrise)
    public static let acousticSunrise = TonePattern(
        name: "Acoustic Sunrise",
        totalDuration: 2.8,
        notes: [
            Note(frequency: 432.00, offset: 0.0, duration: 1.2, harmonicDecay: 0.3),
            Note(frequency: 540.00, offset: 0.2, duration: 1.2, harmonicDecay: 0.35),
            Note(frequency: 648.00, offset: 0.4, duration: 1.6, harmonicDecay: 0.4),
            Note(frequency: 864.00, offset: 0.6, duration: 2.0, harmonicDecay: 0.45)
        ]
    )

    // MARK: - 클래식 합성 비프음

    public static let radar = TonePattern(
        name: "Radar",
        totalDuration: 1.5,
        notes: [
            Note(frequency: 880, offset: 0.0, duration: 0.15),
            Note(frequency: 880, offset: 0.4, duration: 0.15),
            Note(frequency: 880, offset: 0.8, duration: 0.15)
        ]
    )

    public static let beacon = TonePattern(
        name: "Beacon",
        totalDuration: 1.6,
        notes: [
            Note(frequency: 520, offset: 0.0, duration: 0.25),
            Note(frequency: 520, offset: 0.6, duration: 0.25)
        ]
    )

    public static let chime = TonePattern(
        name: "Chime",
        totalDuration: 1.8,
        notes: [
            Note(frequency: 660, offset: 0.0, duration: 0.12),
            Note(frequency: 660, offset: 0.27, duration: 0.12),
            Note(frequency: 660, offset: 0.54, duration: 0.12),
            Note(frequency: 660, offset: 0.81, duration: 0.12)
        ]
    )

    public static let signal = TonePattern(
        name: "Signal",
        totalDuration: 1.0,
        notes: [
            Note(frequency: 1050, offset: 0.0, duration: 0.10),
            Note(frequency: 1050, offset: 0.30, duration: 0.10)
        ]
    )

    public static let ripple = TonePattern(
        name: "Ripple",
        totalDuration: 1.8,
        notes: [
            Note(frequency: 440, offset: 0.0, duration: 0.30),
            Note(frequency: 440, offset: 0.5, duration: 0.30),
            Note(frequency: 440, offset: 1.0, duration: 0.30)
        ]
    )

    public static let allBuiltInNames = [
        "Morning Harp",
        "Warm Rhodes",
        "Forest Chime",
        "Acoustic Sunrise",
        "Radar",
        "Beacon",
        "Chime",
        "Signal",
        "Ripple"
    ]

    public static func pattern(named name: String) -> TonePattern {
        switch name.lowercased() {
        case "morning harp": return .morningHarp
        case "warm rhodes": return .warmRhodes
        case "forest chime": return .forestChime
        case "acoustic sunrise": return .acousticSunrise
        case "beacon": return .beacon
        case "chime": return .chime
        case "signal": return .signal
        case "ripple": return .ripple
        default: return .morningHarp
        }
    }

    public var cycleDuration: Double {
        totalDuration
    }

    /// 한 주기 분량의 모노 PCM 샘플 (배음 및 자연스러운 지수 감쇄 적용)
    public func samples(sampleRate: Double) -> [Float] {
        let totalSamples = max(100, Int((totalDuration * sampleRate).rounded()))
        var result = [Float](repeating: 0, count: totalSamples)

        for note in notes {
            let startSample = Int((note.offset * sampleRate).rounded())
            let noteSamples = Int((note.duration * sampleRate).rounded())
            let endSample = min(totalSamples, startSample + noteSamples)

            guard startSample < totalSamples else { continue }

            for i in startSample..<endSample {
                let noteTime = Double(i - startSample) / sampleRate
                let progress = noteTime / note.duration

                // 자연스러운 어쿠스틱 지수 감쇄 엔벨로프
                let envelope = exp(-3.2 * progress) * (1.0 - exp(-20.0 * progress))

                // 기음 + 2차/3차 배음 합성
                let phase1 = 2.0 * Double.pi * note.frequency * noteTime
                let phase2 = 2.0 * Double.pi * (note.frequency * 2.0) * noteTime
                let phase3 = 2.0 * Double.pi * (note.frequency * 3.0) * noteTime

                let wave = sin(phase1) + (sin(phase2) * note.harmonicDecay * 0.4) + (sin(phase3) * note.harmonicDecay * 0.2)
                let sampleValue = Float(wave * envelope * 0.45)

                result[i] += sampleValue
            }
        }

        // 클리핑 방지 정규화
        var maxAmp: Float = 0.001
        for s in result {
            let absVal = abs(s)
            if absVal > maxAmp { maxAmp = absVal }
        }
        if maxAmp > 0.95 {
            let scale = 0.95 / maxAmp
            for i in 0..<result.count {
                result[i] *= scale
            }
        }

        return result
    }
}
