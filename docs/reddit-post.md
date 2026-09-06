# Reddit 홍보글 초안

**추천 서브레딧:** r/macapps (1순위) · r/SideProject · r/macOS
r/apple 은 자기 앱 홍보를 대부분 지웁니다. r/macapps 는 개발자 본인임을 밝히면 환영하는 분위기입니다.

---

## 제목

```
[Free] My Mac's alarm never went off when the lid was closed, so I built one that does
```

대안:
```
[Free] I made a macOS alarm clock that actually wakes the Mac up
```

---

## 본문

```
Hi all — I made a small macOS alarm clock called Matuta. Sharing it in case it's
useful to anyone else, and I'd genuinely like feedback. I'm the developer.

**The itch**

macOS has had an alarm in the Clock app since Ventura, but it doesn't ring once
the Mac goes to sleep. I found that out the way you'd expect. The workaround
people suggest is "turn off automatic sleep", which isn't a workaround.

So the first thing Matuta does is schedule a power event a couple of minutes
before each alarm. Close the lid and it still rings. I've tested that one on my
own machine — lid shut, woke up, it went off.

**The part I got stuck on**

Once I started I realised a Mac has far more ways to quietly not wake you than a
phone does. A phone has one speaker. A Mac might be routed to the Bluetooth
earbuds you fell asleep wearing, or muted, or sitting at zero volume — and
every alarm app I looked at assumes that ringing is the whole job.

So Matuta:

- checks before you go to sleep. Nightstand mode keeps a status row along the
  bottom; anything that would stop the alarm turns amber with a one-click fix
- at alarm time it forces output back to the built-in speakers, unmutes, and
  brings the volume up
- for any source it can't verify — Spotify, a browser tab — it plays a quiet
  backup tone underneath, so something always makes noise

The built-in tones are synthesized in code rather than shipped as audio files,
mostly so there's no file that can go missing.

**Other bits**

- One field for the sound. Paste a Spotify or YouTube link, drop an mp3, or
  type a name — it works out what you gave it
- Spacebar dismisses. Snooze is deliberately mouse-only
- Korean and English, switches instantly in Settings, no restart
- Free, MIT, no account, no analytics. The only network request the app makes
  on its own is checking a radio stream URL you typed in
- Signed with a Developer ID and notarized, so it opens without the scary dialog

**What isn't done yet**

Being upfront, since it's an alarm clock and you might rely on it:

I've verified wake-from-sleep for a normal alarm on real hardware. I have *not*
yet verified the case where you hit snooze and the Mac then goes to sleep. The
code path and unit tests are there, I just haven't measured it overnight. If
you're catching a flight, keep a second alarm.

The Apple Music source also just tells the Music app to play, so you get
whatever is queued there. The backup tone still fires either way.

**Links**

Site: https://rakkunn.github.io/matuta/
Source: https://github.com/RAKKUNN/matuta

macOS 14 or later. Happy to hear that it's broken, or that I've missed an
obvious app that already does all this.
```

---

## 댓글에서 나올 만한 질문과 답

**"Awaken/Alarm Clock Pro 있는데 왜?"**
> Awaken is genuinely good and does the wake-from-sleep part too (via a separate
> helper). The difference is what happens *before* the alarm — Matuta checks the
> output device, mute state and volume while you're still awake and offers to fix
> them, and always lays a backup tone under sources it can't verify. That's the
> part I couldn't find elsewhere.

**"샌드박스/App Store 아닌 이유?"**
> Scheduling a power event needs an API the App Store sandbox blocks. Awaken
> ships a separate helper to get around it. I went with direct distribution
> instead — Developer ID signed and notarized.

**"자동화 권한 왜 필요함?"**
> Only if you pick Spotify or Apple Music as the sound. macOS asks before the
> app can tell those apps to play. Decline it and the backup tone still rings.

**"소스 있음?"**
> Yes, MIT: https://github.com/RAKKUNN/matuta

---

## 한국어판 (클리앙·개발자 커뮤니티용)

```
맥 기본 알람이 절전 들어가면 안 울려서 직접 만들었습니다.

Ventura부터 시계 앱에 알람이 생겼는데, 맥이 잠들면 그냥 안 울립니다.
검색해보면 해결책이라고 나오는 게 "자동 절전 끄기"인데 그건 해결이 아니죠.

그래서 알람 2분 전에 전원 이벤트를 예약해서 맥을 깨우는 걸 먼저 만들었습니다.
덮개 닫고 자도 울립니다. 이건 직접 확인했습니다.

만들다 보니 맥은 폰보다 조용히 실패할 방법이 훨씬 많더군요. 폰은 스피커가
하나지만 맥은 이어폰 끼고 잠들었을 수도, 음소거일 수도, 볼륨이 0일 수도
있습니다. 그런데 알람 앱들은 대부분 "울리기만 하면 끝"으로 가정합니다.

그래서 이렇게 만들었습니다.

- 자기 전에 미리 점검합니다. 나이트스탠드 화면 하단에 상태 줄이 있고,
  문제가 있으면 주황으로 바뀌면서 누르면 그 자리에서 고쳐집니다
- 알람 시각에 출력을 내장 스피커로 되돌리고 음소거를 풀고 볼륨을 확보합니다
- Spotify나 웹처럼 재생을 검증할 수 없는 소스에는 백업음을 낮게 함께 깝니다.
  무슨 일이 있어도 소리는 납니다

그 외에

- 사운드는 칸 하나입니다. 링크 붙여넣거나 파일 끌어놓거나 이름 치면 알아서 판별
- 스페이스바로 끕니다. 스누즈는 일부러 마우스로만 누르게 했습니다
- 한국어·영어 즉시 전환
- 무료, MIT, 계정 없음, 추적 없음
- Developer ID 서명 + 애플 공증이라 경고 없이 열립니다

솔직히 아직 안 된 것도 적어둡니다. 알람 앱이라 중요할 것 같아서요.
일반 알람의 절전 깨우기는 실기기에서 확인했는데, **스누즈를 누른 뒤 맥이
절전에 들어간 경우는 아직 실측을 못 했습니다.** 코드와 테스트는 있지만
밤새 돌려본 적이 없습니다. 중요한 일정에는 다른 알람도 같이 걸어두세요.

사이트: https://rakkunn.github.io/matuta/
소스: https://github.com/RAKKUNN/matuta

macOS 14 이상입니다. 안 되는 거 있으면 알려주세요.
```

---

## 올리기 전 확인

- [ ] r/macapps 규칙 확인 (개발자 본인 밝히기, 플레어 지정)
- [ ] 댓글에 답할 수 있는 시간대에 올릴 것. 초반 1~2시간 반응이 중요합니다
- [ ] **스누즈 실측을 먼저 끝내면** "안 된 것" 문단을 지울 수 있습니다.
      알람 앱에서 이 한 줄이 신뢰에 꽤 영향을 줍니다
