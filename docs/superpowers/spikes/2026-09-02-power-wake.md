# 스파이크: 절전 깨우기 권한

날짜: 2026-09-02
질문: `IOPMSchedulePowerEvent`가 관리자 권한 없이 동작하는가?

## 결과
- 반환값: `0xE00002C1` (`kIOReturnNotPrivileged`)
- `pmset -g sched`에 등록됨: 아니오

## 결론
`IOPMSchedulePowerEvent`는 일반 사용자 권한 프로세스에서 호출 시 `kIOReturnNotPrivileged`를 반환하며 등록되지 않습니다.

이에 따라 설계 문서 §9의 대안 중 다음과 같이 대응을 권장합니다:
1. **1단계 및 2단계:** 앱 실행 중(화면 잠금 포함) 타이머 기반 알람 동작에 집중.
2. **3단계 (신뢰성):**
   - **권장 방식:** 1회 권한 획득을 통한 `SMAppService` / Privileged Helper Tool 설치 또는 `IOPMAssertionCreateWithName` 기반의 절전 방지(Sleep Assertion) 결합 방식 적용.
   - 사용자 온보딩 시 1회 관리자 권한 승인을 받아 Helper를 설치하거나, 잘 때(나이트스탠드 모드) Mac이 딥 슬립으로 빠지지 않도록 Sleep Assertion을 활성화하는 방안을 채택합니다.
