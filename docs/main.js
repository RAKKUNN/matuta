/* Matuta — landing page motion
 *
 * anime.js v4 (vendored, MIT © Julian Garnier).
 * The brief was "dynamic but calm", so everything here is slow, low-amplitude
 * and opacity-led. Nothing bounces.
 *
 * Where there is delight, it comes from the product rather than from effects:
 * the hero tells the real time and counts down to a real 7am, the glow warms
 * and dims with the visitor's own hour, and the spacebar actually dismisses
 * something. */

import { animate, createAnimatable, createTimeline, onScroll, stagger, utils }
  from './vendor/anime.esm.min.js';

const reduced = matchMedia('(prefers-reduced-motion: reduce)').matches;
const $ = (sel) => document.querySelector(sel);

/* ── Copy that JS owns ─────────────────────────────────────
   Everything else lives in data-en / data-ko on the element. */
const COPY = {
  nextAlarm: {
    en: (h, m) => `Next alarm 7:00 AM · rings in ${h}h ${m}m`,
    ko: (h, m) => `다음 알람 오전 7:00 · ${h}시간 ${m}분 후`,
  },
  dismissed: { en: 'Alarm dismissed.', ko: '알람을 껐습니다.' },
  badge: {
    warn:  { en: 'System is muted', ko: '시스템 음소거' },
    fixed: { en: 'Volume 70%',      ko: '볼륨 70%' },
    act:   { en: 'Unmute to 70%',   ko: '70%로 해제' },
    done:  { en: 'Fixed',           ko: '해결됨' },
  },
};

/* ── Language ──────────────────────────────────────────────
   Echoes the app's headline feature: switching is instant. */
const langToggle = $('#lang-toggle');
let lang = (navigator.language || 'en').toLowerCase().startsWith('ko') ? 'ko' : 'en';

function applyLanguage() {
  document.documentElement.lang = lang;
  for (const el of document.querySelectorAll('[data-en]')) {
    const next = el.dataset[lang];
    if (next != null) el.textContent = next;
  }
  langToggle.textContent = lang === 'ko' ? 'English' : '한국어';
  paintCountdown();
}

langToggle.addEventListener('click', () => {
  lang = lang === 'ko' ? 'en' : 'ko';
  applyLanguage();
  if (reduced) return;
  // A brief dip on the translated text only, so the swap reads as deliberate.
  animate('[data-en], #next-alarm-text', {
    opacity: [.35, 1], duration: 420, ease: 'outQuad',
  });
});

/* ── Live clock ────────────────────────────────────────────
   A landing page for an alarm clock should be telling the time. */
const hh = $('#hh');
const mm = $('#mm');

function paintClock(initial = false) {
  const now = new Date();
  const h = String(now.getHours()).padStart(2, '0');
  const m = String(now.getMinutes()).padStart(2, '0');

  for (const [el, value] of [[hh, h], [mm, m]]) {
    if (el.textContent === value) continue;
    el.textContent = value;
    if (initial || reduced) continue;
    animate(el, { opacity: [.35, 1], y: [-5, 0], duration: 620, ease: 'outQuad' });
  }
}

/* Counts down to the next real 7am in the visitor's own timezone —
   the same line the app shows on the nightstand. */
function paintCountdown() {
  const el = $('#next-alarm-text');
  if (!el) return;
  const now = new Date();
  const next = new Date(now);
  next.setHours(7, 0, 0, 0);
  if (next <= now) next.setDate(next.getDate() + 1);

  const mins = Math.round((next - now) / 60000);
  el.textContent = COPY.nextAlarm[lang](Math.floor(mins / 60), mins % 60);
}

/* The glow warms and dims with the hour. Deep night is dimmest; the hour
   the app is named after — dawn — is the brightest it ever gets. */
function paintGlow() {
  const h = new Date().getHours();
  const alpha = h >= 5 && h < 8  ? .22    // dawn — Matuta's hour
              : h >= 8 && h < 17 ? .09    // daytime
              : h >= 17 && h < 22 ? .15   // evening
              : .10;                      // night
  document.documentElement.style.setProperty('--glow-a', String(alpha));
}

paintClock(true);
paintGlow();
applyLanguage();
setInterval(paintClock, 1000);
setInterval(paintCountdown, 30000);
setInterval(paintGlow, 5 * 60000);

/* ── Hero entrance ─────────────────────────────────────────*/
if (!reduced) {
  utils.set('.glow', { opacity: 0, scale: 1.18 });
  utils.set(['.clock', '.next-alarm', '.title', '.tagline', '.cta', '.meta'],
            { opacity: 0, y: 18 });
  utils.set('.scroll-cue', { opacity: 0 });

  createTimeline({ defaults: { ease: 'outQuad' } })
    .add('.glow',       { opacity: [0, 1], scale: [1.18, 1], duration: 2200 }, 0)
    .add('.clock',      { opacity: [0, 1], y: [18, 0], duration: 1000 }, 220)
    .add('.next-alarm', { opacity: [0, 1], y: [18, 0], duration: 800 }, 620)
    .add('.title',      { opacity: [0, 1], y: [18, 0], duration: 800 }, 760)
    .add('.tagline',    { opacity: [0, 1], y: [18, 0], duration: 800 }, 880)
    .add('.cta',        { opacity: [0, 1], y: [18, 0], duration: 800 }, 1000)
    .add('.meta',       { opacity: [0, 1], y: [18, 0], duration: 800 }, 1120)
    .add('.scroll-cue', { opacity: [0, 1], duration: 900 }, 1500);

  // Breathing glow — slow enough to read as light rather than movement.
  animate('.glow', {
    opacity: [1, .72], scale: [1, 1.05],
    duration: 7000, ease: 'inOutQuad', alternate: true, loop: true, delay: 2200,
  });

  // The colon blinks the way a bedside clock does.
  animate('.clock .colon', {
    opacity: [.5, .12],
    duration: 1100, ease: 'inOutQuad', alternate: true, loop: true, delay: 1400,
  });

  animate('.scroll-cue span', {
    y: [0, 12], opacity: [1, 0],
    duration: 1600, ease: 'inOutQuad', loop: true, delay: 1800,
  });

  /* The campfire drifts toward the pointer — far enough to feel alive,
     slow enough that you never catch it moving. */
  if (matchMedia('(pointer: fine)').matches) {
    const drift = createAnimatable('.glow', {
      x: { duration: 1400 }, y: { duration: 1400 }, ease: 'out(3)',
    });
    $('.hero').addEventListener('pointermove', (e) => {
      drift.x((e.clientX / innerWidth  - .5) * 70);
      drift.y((e.clientY / innerHeight - .5) * 50);
    });
  }
}

/* ── Scroll reveals ────────────────────────────────────────
   `repeat: false` so a section stays put once it has arrived. */
if (reduced) {
  utils.set('.reveal', { opacity: 1 });
} else {
  document.querySelectorAll('.reveal').forEach((el) => {
    animate(el, {
      opacity: [0, 1], y: [22, 0],
      duration: 900, ease: 'outQuad',
      autoplay: onScroll({ repeat: false }),
    });
  });

  animate('.hole', {
    opacity: [0, 1], x: [-14, 0],
    duration: 760, ease: 'outQuad', delay: stagger(110),
    autoplay: onScroll({ target: '.holes', repeat: false }),
  });
}

/* ── Reliability badge ─────────────────────────────────────
   Shows what the app does instead of describing it. */
const warnBadge = $('#badge-warn');

if (warnBadge && !reduced) {
  const label = warnBadge.querySelector('b');
  const action = warnBadge.querySelector('em');
  let fixed = false;

  const flip = () => {
    fixed = !fixed;
    animate(warnBadge, {
      opacity: [1, .3], duration: 260, ease: 'outQuad',
      alternate: true, loop: 2,
      onLoop: () => {
        warnBadge.classList.toggle('fixed', fixed);
        label.textContent  = COPY.badge[fixed ? 'fixed' : 'warn'][lang];
        action.textContent = COPY.badge[fixed ? 'done'  : 'act' ][lang];
      },
    });
  };

  animate(warnBadge, {
    scale: [1, 1], duration: 10,
    autoplay: onScroll({ repeat: false }),
    onComplete: () => setInterval(flip, 3200),
  });
}

/* ── Press space ───────────────────────────────────────────
   The app's signature gesture, made available on the page. Pressing space
   while the section is on screen dismisses a nonexistent alarm, which is
   more convincing than a sentence about it. */
const keycap = $('#keycap');
const dismissed = $('#dismissed');

if (keycap && dismissed) {
  let busy = false;

  const inView = () => {
    const r = keycap.getBoundingClientRect();
    return r.top < innerHeight * .9 && r.bottom > 0;
  };

  const press = () => {
    if (busy) return;
    busy = true;
    dismissed.textContent = COPY.dismissed[lang];

    if (reduced) {
      dismissed.style.opacity = '1';
      setTimeout(() => { dismissed.style.opacity = '0'; busy = false; }, 1800);
      return;
    }

    animate(keycap, {
      y: [0, 3], borderBottomWidth: ['3px', '1px'],
      duration: 90, ease: 'outQuad', alternate: true, loop: 2,
    });
    animate(dismissed, {
      opacity: [0, 1], y: [6, 0], duration: 320, ease: 'outQuad',
    });
    setTimeout(() => {
      animate(dismissed, {
        opacity: [1, 0], duration: 500, ease: 'outQuad',
        onComplete: () => { busy = false; },
      });
    }, 1900);
  };

  keycap.addEventListener('click', press);
  addEventListener('keydown', (e) => {
    if (e.code !== 'Space' || e.target === keycap) return;
    if (!inView()) return;          // otherwise let space scroll the page
    e.preventDefault();
    press();
  });
}

/* ── Nav hairline on scroll ────────────────────────────────*/
const nav = $('.nav');
const paintNav = () => nav.classList.toggle('scrolled', scrollY > 12);
addEventListener('scroll', paintNav, { passive: true });
paintNav();
