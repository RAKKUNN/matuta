# 스파이크: 메인 액터 실행자 크래시 재현

날짜: 2026-09-06
질문: 알람 토글 반복으로 `isMainExecutor()` 크래시를 재현할 수 있는가?

## 시도
- 최신 빌드 번들 설치 및 실행 (/Applications/Matuta.app)
- 기존 DiagnosticReports 분석: 2026-09-03 (0.1.0, 96초), 2026-09-06 (1.1.1, 7시간 18분) 동일 스택 확인 (`MatutaApp.body` -> `closure #1 in MatutaApp.body.getter` -> `SerialExecutorRef::isMainExecutor()` -> EXC_BAD_ACCESS)
- 알람 토글 및 메뉴바 팝오버 개폐 반복 시도: 30회
- 설정 창(⌘,)을 연 상태에서 동일 반복: 했음

## 결과
- 새 크래시 리포트: 안 생김
- 스택이 isMainExecutor 인가: 해당 없음 (과거 2건의 리포트는 모두 isMainExecutor 동일 스택 확인됨)

## 결론
재현 안 됨 — 크래시가 타이밍 및 메모리 배치에 의존하여 즉시 재현이 극히 드물다.
Task 1 (App 구조체에서 `@State` 제거 및 `@MainActor` 상태 격리)을 적용하여 원인 경로(`MatutaApp.body` 씬 클로저 내 동적 액터 검사)를 구조적으로 원천 제거하고, 향후 `~/Library/Logs/DiagnosticReports`를 지속 관찰한다.
