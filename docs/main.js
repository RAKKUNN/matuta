/* Matuta — landing page motion
 *
 * anime.js v4 (vendored, MIT © Julian Garnier).
 * The brief was "dynamic but calm", so everything here is slow, low-amplitude
 * and opacity-led. Nothing bounces. */

import { animate, createTimeline, onScroll, stagger, utils }
  from './vendor/anime.esm.min.js';

const reduced = matchMedia('(prefers-reduced-motion: reduce)').matches;

/* ── Language ──────────────────────────────────────────────
   Echoes the app's own headline feature: switching is instant,
   nothing reloads. */
const langToggle = document.getElementById('lang-toggle');
let lang = (navigator.language || 'en').toLowerCase().startsWith('ko') ? 'ko' : 'en';

function applyLanguage() {
  document.documentElement.lang = lang;
  for (const el of document.querySelectorAll('[data-en]')) {
    const next = el.dataset[lang];
    if (next != null) el.textContent = next;
  }
  // Show the language you would switch *to*.
  langToggle.textContent = lang === 'ko' ? 'English' : '한국어';
}

langToggle.addEventListener('click', () => {
  lang = lang === 'ko' ? 'en' : 'ko';
  applyLanguage();
  if (reduced) return;
  animate('main, .hero-inner', {
    opacity: [.45, 1], duration: 420, ease: 'outQuad',
  });
});

applyLanguage();

/* ── Live clock ────────────────────────────────────────────
   The hero shows the actual time, in the nightstand's typeface.
   A landing page for an alarm clock should be telling the time. */
const hh = document.getElementById('hh');
const mm = document.getElementById('mm');

function paintClock(initial = false) {
  const now = new Date();
  const h = String(now.getHours()).padStart(2, '0');
  const m = String(now.getMinutes()).padStart(2, '0');

  for (const [el, value] of [[hh, h], [mm, m]]) {
    if (el.textContent === value) continue;
    el.textContent = value;
    if (initial || reduced) continue;
    // A soft lift as the digits change — the only motion in the hero
    // once it has settled.
    animate(el, { opacity: [.35, 1], y: [-5, 0], duration: 620, ease: 'outQuad' });
  }
}

paintClock(true);
setInterval(paintClock, 1000);

/* ── Hero entrance ─────────────────────────────────────────
   One timeline so the order is readable in one place. */
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

  // Breathing glow — very slow, so it reads as light rather than motion.
  animate('.glow', {
    opacity: [1, .72], scale: [1, 1.05],
    duration: 7000, ease: 'inOutQuad', alternate: true, loop: true, delay: 2200,
  });

  animate('.scroll-cue span', {
    y: [0, 12], opacity: [1, 0],
    duration: 1600, ease: 'inOutQuad', loop: true, delay: 1800,
  });
}

/* ── Scroll reveals ────────────────────────────────────────
   One observer per element so each arrives on its own. */
if (reduced) {
  utils.set('.reveal', { opacity: 1 });
} else {
  document.querySelectorAll('.reveal').forEach((el) => {
    animate(el, {
      opacity: [0, 1],
      y: [22, 0],
      duration: 900,
      ease: 'outQuad',
      autoplay: onScroll({ repeat: false }),
    });
  });

  // The problem list arrives as a group, one after another.
  animate('.hole', {
    opacity: [0, 1], x: [-14, 0],
    duration: 760, ease: 'outQuad', delay: stagger(110),
    autoplay: onScroll({ target: '.holes', repeat: false }),
  });
}

/* ── Reliability badge ─────────────────────────────────────
   Shows what the app does rather than describing it: the amber
   warning resolves itself, then quietly returns. */
const warnBadge = document.getElementById('badge-warn');

if (warnBadge && !reduced) {
  const label = warnBadge.querySelector('b');
  const action = warnBadge.querySelector('em');

  const copy = {
    warn:  { en: 'System is muted', ko: '시스템 음소거' },
    fixed: { en: 'Volume 70%',      ko: '볼륨 70%' },
    act:   { en: 'Unmute to 70%',   ko: '70%로 해제' },
    done:  { en: 'Fixed',           ko: '해결됨' },
  };

  let fixed = false;
  const flip = () => {
    fixed = !fixed;
    animate(warnBadge, {
      opacity: [1, .3], duration: 260, ease: 'outQuad',
      alternate: true, loop: 2,
      onLoop: () => {
        warnBadge.classList.toggle('fixed', fixed);
        label.textContent = copy[fixed ? 'fixed' : 'warn'][lang];
        action.textContent = copy[fixed ? 'done' : 'act'][lang];
      },
    });
  };

  // Only start once the row has actually been seen.
  animate(warnBadge, {
    scale: [1, 1], duration: 10,
    autoplay: onScroll({ repeat: false }),
    onComplete: () => setInterval(flip, 3200),
  });
}

/* ── Nav hairline on scroll ────────────────────────────────*/
const nav = document.querySelector('.nav');
const onScrollNav = () => nav.classList.toggle('scrolled', scrollY > 12);
addEventListener('scroll', onScrollNav, { passive: true });
onScrollNav();
