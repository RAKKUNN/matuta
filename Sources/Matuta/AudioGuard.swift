import Foundation
import CoreAudio
import AudioToolbox

/// 시스템 오디오 출력을 감시하고, 알람 발화 시 내장 스피커로 강제 전환 및 볼륨을 확보하는 가드.
///
/// 설계 문서 §7.3:
/// 1. 현재 출력 기기·볼륨·뮤트 상태를 저장
/// 2. 목표 출력 기기(내장 스피커)로 전환, 뮤트 해제, 볼륨을 알람 볼륨까지 확보
/// 3. 알람 해제 시 저장해둔 오디오 상태를 원상복구
@MainActor
public final class AudioGuard {
    public struct AudioSnapshot {
        public let defaultDeviceID: AudioDeviceID
        public let volume: Float
        public let isMuted: Bool
    }

    private var previousSnapshot: AudioSnapshot?

    public init() {}

    // MARK: - Protection & Restoration

    /// 알람 발화 시: 오디오 스냅샷 저장 후 내장 스피커로 전환, 뮤트 해제, 볼륨 확보
    public func protect(targetVolume: Float) {
        guard previousSnapshot == nil else { return } // 이미 보호 중이면 중복 저장 방지

        guard let currentDevice = getDefaultOutputDeviceID() else { return }
        let currentVol = getVolume(deviceID: currentDevice)
        let isMuted = getMute(deviceID: currentDevice)

        self.previousSnapshot = AudioSnapshot(
            defaultDeviceID: currentDevice,
            volume: currentVol,
            isMuted: isMuted
        )

        // 1. 내장 스피커 찾기
        if let speakerID = findBuiltInSpeakerDeviceID() {
            // 출력 기기를 내장 스피커로 강제 전환
            if speakerID != currentDevice {
                setDefaultOutputDevice(speakerID)
            }

            // 2. 뮤트 해제
            setMute(deviceID: speakerID, isMuted: false)

            // 3. 볼륨을 알람 볼륨으로 확보
            let effectiveVolume = max(targetVolume, 0.3)
            setVolume(deviceID: speakerID, volume: effectiveVolume)
        } else {
            // 내장 스피커를 못 찾더라도 현재 기기 뮤트 해제 및 볼륨 확보
            setMute(deviceID: currentDevice, isMuted: false)
            setVolume(deviceID: currentDevice, volume: max(targetVolume, 0.3))
        }
    }

    /// 알람 종료 시: 이전 오디오 상태(기기, 볼륨, 뮤트)로 복원
    public func restore() {
        guard let snapshot = previousSnapshot else { return }

        // 이전 기기로 복원
        setDefaultOutputDevice(snapshot.defaultDeviceID)
        setMute(deviceID: snapshot.defaultDeviceID, isMuted: snapshot.isMuted)
        setVolume(deviceID: snapshot.defaultDeviceID, volume: snapshot.volume)

        self.previousSnapshot = nil
    }

    // MARK: - CoreAudio Device Helpers

    public func getDefaultOutputDeviceID() -> AudioDeviceID? {
        var address = AudioObjectPropertyAddress(
            mSelector: kAudioHardwarePropertyDefaultOutputDevice,
            mScope: kAudioObjectPropertyScopeGlobal,
            mElement: kAudioObjectPropertyElementMain
        )
        var deviceID = AudioDeviceID()
        var size = UInt32(MemoryLayout<AudioDeviceID>.size)
        let status = AudioObjectGetPropertyData(
            AudioObjectID(kAudioObjectSystemObject),
            &address,
            0,
            nil,
            &size,
            &deviceID
        )
        return status == noErr ? deviceID : nil
    }

    public func setDefaultOutputDevice(_ deviceID: AudioDeviceID) {
        var address = AudioObjectPropertyAddress(
            mSelector: kAudioHardwarePropertyDefaultOutputDevice,
            mScope: kAudioObjectPropertyScopeGlobal,
            mElement: kAudioObjectPropertyElementMain
        )
        var targetID = deviceID
        let size = UInt32(MemoryLayout<AudioDeviceID>.size)
        _ = AudioObjectSetPropertyData(
            AudioObjectID(kAudioObjectSystemObject),
            &address,
            0,
            nil,
            size,
            &targetID
        )
    }

    public func findBuiltInSpeakerDeviceID() -> AudioDeviceID? {
        var address = AudioObjectPropertyAddress(
            mSelector: kAudioHardwarePropertyDevices,
            mScope: kAudioObjectPropertyScopeGlobal,
            mElement: kAudioObjectPropertyElementMain
        )
        var dataSize: UInt32 = 0
        guard AudioObjectGetPropertyDataSize(AudioObjectID(kAudioObjectSystemObject), &address, 0, nil, &dataSize) == noErr else {
            return nil
        }

        let deviceCount = Int(dataSize) / MemoryLayout<AudioDeviceID>.size
        var deviceIDs = [AudioDeviceID](repeating: 0, count: deviceCount)
        guard AudioObjectGetPropertyData(AudioObjectID(kAudioObjectSystemObject), &address, 0, nil, &dataSize, &deviceIDs) == noErr else {
            return nil
        }

        for id in deviceIDs {
            let transport = getDeviceTransportType(deviceID: id)
            let name = getDeviceName(deviceID: id).lowercased()

            // 내장 트랜스포트이거나 이름에 스피커/speaker가 들어간 경우
            if transport == kAudioDeviceTransportTypeBuiltIn && (name.contains("speaker") || name.contains("스피커") || !name.contains("마이크")) {
                return id
            }
        }

        // fallback: 이름에 speaker가 포함된 디바이스
        for id in deviceIDs {
            let name = getDeviceName(deviceID: id).lowercased()
            if name.contains("speaker") || name.contains("스피커") {
                return id
            }
        }

        return nil
    }

    public func getDeviceName(deviceID: AudioDeviceID) -> String {
        var address = AudioObjectPropertyAddress(
            mSelector: kAudioObjectPropertyName,
            mScope: kAudioObjectPropertyScopeGlobal,
            mElement: kAudioObjectPropertyElementMain
        )
        var nameString: Unmanaged<CFString>?
        var size = UInt32(MemoryLayout<Unmanaged<CFString>?>.size)
        let status = withUnsafeMutablePointer(to: &nameString) { ptr in
            AudioObjectGetPropertyData(deviceID, &address, 0, nil, &size, ptr)
        }
        if status == noErr, let unmanaged = nameString {
            return unmanaged.takeRetainedValue() as String
        }
        return "알 수 없는 기기"
    }

    public func getDeviceTransportType(deviceID: AudioDeviceID) -> UInt32 {
        var address = AudioObjectPropertyAddress(
            mSelector: kAudioDevicePropertyTransportType,
            mScope: kAudioObjectPropertyScopeGlobal,
            mElement: kAudioObjectPropertyElementMain
        )
        var transport: UInt32 = 0
        var size = UInt32(MemoryLayout<UInt32>.size)
        let status = AudioObjectGetPropertyData(deviceID, &address, 0, nil, &size, &transport)
        return status == noErr ? transport : 0
    }

    public func isHeadphones(deviceID: AudioDeviceID) -> Bool {
        let transport = getDeviceTransportType(deviceID: deviceID)
        let name = getDeviceName(deviceID: deviceID).lowercased()
        return transport == kAudioDeviceTransportTypeBluetooth ||
               transport == kAudioDeviceTransportTypeBluetoothLE ||
               name.contains("airpod") ||
               name.contains("headphone") ||
               name.contains("이어폰") ||
               name.contains("헤드폰") ||
               name.contains("버즈")
    }

    public func getVolume(deviceID: AudioDeviceID) -> Float {
        var address = AudioObjectPropertyAddress(
            mSelector: kAudioHardwareServiceDeviceProperty_VirtualMainVolume,
            mScope: kAudioDevicePropertyScopeOutput,
            mElement: kAudioObjectPropertyElementMain
        )
        var volume: Float = 0.5
        var size = UInt32(MemoryLayout<Float>.size)
        _ = AudioObjectGetPropertyData(deviceID, &address, 0, nil, &size, &volume)
        return volume
    }

    public func setVolume(deviceID: AudioDeviceID, volume: Float) {
        var address = AudioObjectPropertyAddress(
            mSelector: kAudioHardwareServiceDeviceProperty_VirtualMainVolume,
            mScope: kAudioDevicePropertyScopeOutput,
            mElement: kAudioObjectPropertyElementMain
        )
        var vol = max(0.0, min(1.0, volume))
        let size = UInt32(MemoryLayout<Float>.size)
        _ = AudioObjectSetPropertyData(deviceID, &address, 0, nil, size, &vol)
    }

    public func getMute(deviceID: AudioDeviceID) -> Bool {
        var address = AudioObjectPropertyAddress(
            mSelector: kAudioDevicePropertyMute,
            mScope: kAudioDevicePropertyScopeOutput,
            mElement: kAudioObjectPropertyElementMain
        )
        var isMuted: UInt32 = 0
        var size = UInt32(MemoryLayout<UInt32>.size)
        _ = AudioObjectGetPropertyData(deviceID, &address, 0, nil, &size, &isMuted)
        return isMuted != 0
    }

    public func setMute(deviceID: AudioDeviceID, isMuted: Bool) {
        var address = AudioObjectPropertyAddress(
            mSelector: kAudioDevicePropertyMute,
            mScope: kAudioDevicePropertyScopeOutput,
            mElement: kAudioObjectPropertyElementMain
        )
        var muteVal: UInt32 = isMuted ? 1 : 0
        let size = UInt32(MemoryLayout<UInt32>.size)
        _ = AudioObjectSetPropertyData(deviceID, &address, 0, nil, size, &muteVal)
    }
}
