/* ═══════════════════════════════════════════════════════════════════════════
   The scoreboard on this page runs the same rules the app runs.
   serveTurns(), the deuce collapse and the set-change logic are ports of
   DoublesLineup.serveTurns and ScoreViewModel in the iOS source, so what you
   try here behaves exactly like what you install.
   ═══════════════════════════════════════════════════════════════════════════ */
/* Browsers do not reliably scroll to the fragment when a document is opened via
   location.replace(), which is how /docs/index.html forwards the #support and
   #privacy links that are live in the published App Store listing. Without this,
   someone tapping "Privacy Policy" on the App Store lands on the hero instead of
   the privacy policy. */
(function () {
  'use strict';
  var hash = window.location.hash;
  if (!hash || hash === '#') return;
  var target;
  try { target = document.querySelector(hash); } catch (e) { return; }
  if (!target) return;
  requestAnimationFrame(function () {
    if (window.scrollY < 4) target.scrollIntoView({ behavior: 'auto', block: 'start' });
  });
})();

(function () {
  'use strict';

  var board = document.querySelector('[data-board]');
  if (!board) return;

  var STORE = 'ppc.board.v1';
  var THEME_STORE = 'ppc.theme.v1';
  var UNDO_LIMIT = 30;

  var el = {
    sides: [null, board.querySelector('[data-side="1"]'), board.querySelector('[data-side="2"]')],
    score: [null, board.querySelector('[data-score="1"]'), board.querySelector('[data-score="2"]')],
    sets: [null, board.querySelector('[data-sets="1"]'), board.querySelector('[data-sets="2"]')],
    clock: board.querySelector('[data-clock]'),
    flag: board.querySelector('[data-flag]'),
    won: board.querySelector('[data-won]'),
    wonName: board.querySelector('[data-won-name]'),
    wonLine: board.querySelector('[data-won-line]'),
    undo: board.querySelector('[data-act="undo"]'),
    live: document.querySelector('[data-live]')
  };

  var NAME = { 1: 'Player 1', 2: 'Player 2' };

  var s = {
    target: 11, setsToWin: 3, interval: 2, winByTwo: true,
    p: { 1: 0, 2: 0 }, sets: { 1: 0, 2: 0 },
    startOfMatch: 1, startOfSet: 1, server: 1,
    winner: null, startedAt: null, frozen: 0,
    history: []
  };

  /* ── storage ──────────────────────────────────────────────────────────── */

  function read(key) {
    try { return JSON.parse(localStorage.getItem(key)); } catch (e) { return null; }
  }
  function write(key, value) {
    try { localStorage.setItem(key, JSON.stringify(value)); } catch (e) { /* private mode */ }
  }
  function save() {
    write(STORE, {
      target: s.target, setsToWin: s.setsToWin, interval: s.interval, winByTwo: s.winByTwo,
      p: s.p, sets: s.sets, startOfMatch: s.startOfMatch, startOfSet: s.startOfSet,
      server: s.server, winner: s.winner, startedAt: s.startedAt, frozen: s.frozen,
      history: s.history
    });
  }
  function restore() {
    var saved = read(STORE);
    if (!saved || typeof saved !== 'object') return;
    if ([11, 21].indexOf(saved.target) >= 0) s.target = saved.target;
    if ([1, 3, 5].indexOf(saved.setsToWin) >= 0) s.setsToWin = saved.setsToWin;
    if ([2, 5].indexOf(saved.interval) >= 0) s.interval = saved.interval;
    s.winByTwo = saved.winByTwo !== false;
    if (saved.p) { s.p[1] = clampInt(saved.p[1]); s.p[2] = clampInt(saved.p[2]); }
    if (saved.sets) { s.sets[1] = clampInt(saved.sets[1]); s.sets[2] = clampInt(saved.sets[2]); }
    s.startOfMatch = saved.startOfMatch === 2 ? 2 : 1;
    s.startOfSet = saved.startOfSet === 2 ? 2 : 1;
    s.winner = saved.winner === 1 || saved.winner === 2 ? saved.winner : null;
    s.startedAt = typeof saved.startedAt === 'number' ? saved.startedAt : null;
    s.frozen = typeof saved.frozen === 'number' ? saved.frozen : 0;
    s.history = Array.isArray(saved.history) ? saved.history.slice(-UNDO_LIMIT) : [];
    updateServer();
  }
  function clampInt(n) { return typeof n === 'number' && isFinite(n) && n >= 0 ? Math.floor(n) : 0; }

  /* ── rules engine ─────────────────────────────────────────────────────── */

  // Total points after which each serve turn shortens to a single point.
  function deucePointTotal() { return 2 * Math.max(0, s.target - 1); }

  // Port of DoublesLineup.serveTurns — a turn only part-played when deuce
  // arrives is ended by the deuce rule, hence the round-up.
  function serveTurns(totalPoints, interval, deuceAfter) {
    var points = Math.max(0, totalPoints);
    var iv = Math.max(1, interval);
    var da = Math.max(0, deuceAfter);
    if (points < da) return Math.floor(points / iv);
    return Math.ceil(da / iv) + (points - da);
  }

  function updateServer() {
    var turns = serveTurns(s.p[1] + s.p[2], s.interval, deucePointTotal());
    var even = turns % 2 === 0;
    s.server = s.startOfSet === 1 ? (even ? 1 : 2) : (even ? 2 : 1);
  }

  function isSetWon(mine, theirs) {
    if (mine < s.target) return false;
    return s.winByTwo ? mine - theirs >= 2 : true;
  }

  function isSetPoint(who) {
    if (s.winner) return false;
    var mine = s.p[who], theirs = s.p[who === 1 ? 2 : 1];
    if (mine < s.target - 1) return false;
    return s.winByTwo ? mine - theirs >= 1 : true;
  }

  function isMatchPoint(who) { return isSetPoint(who) && s.sets[who] === s.setsToWin - 1; }

  function isDeuce() {
    return s.winByTwo && s.p[1] >= s.target - 1 && s.p[2] >= s.target - 1;
  }

  function snapshot() {
    return {
      p1: s.p[1], p2: s.p[2], s1: s.sets[1], s2: s.sets[2],
      server: s.server, startOfSet: s.startOfSet, winner: s.winner, frozen: s.frozen
    };
  }

  function addPoint(who) {
    if (s.winner) return;
    s.history.push(snapshot());
    if (s.history.length > UNDO_LIMIT) s.history.shift();

    if (s.startedAt === null) s.startedAt = Date.now();
    s.p[who] += 1;

    if (isSetWon(s.p[1], s.p[2])) completeSet(1);
    else if (isSetWon(s.p[2], s.p[1])) completeSet(2);

    updateServer();
    render(who);
  }

  function removePoint(who) {
    if (s.winner || s.p[who] === 0) return;
    s.history.push(snapshot());
    if (s.history.length > UNDO_LIMIT) s.history.shift();
    s.p[who] -= 1;
    updateServer();
    render(who);
  }

  function completeSet(who) {
    s.sets[who] += 1;
    if (s.sets[who] >= s.setsToWin) {
      s.winner = who;
      s.frozen = elapsed();
      return;
    }
    s.p[1] = 0; s.p[2] = 0;
    // ITTF: the player who did not open the previous set serves first in the next.
    s.startOfSet = s.startOfSet === 1 ? 2 : 1;
    s.server = s.startOfSet;
  }

  function undo() {
    var prev = s.history.pop();
    if (!prev) return;
    s.p[1] = prev.p1; s.p[2] = prev.p2;
    s.sets[1] = prev.s1; s.sets[2] = prev.s2;
    s.startOfSet = prev.startOfSet;
    s.winner = prev.winner;
    s.frozen = prev.frozen;
    updateServer();
    render();
  }

  function reset() {
    s.p[1] = 0; s.p[2] = 0;
    s.sets[1] = 0; s.sets[2] = 0;
    s.startOfSet = s.startOfMatch;
    s.server = s.startOfMatch;
    s.winner = null;
    s.startedAt = null;
    s.frozen = 0;
    s.history = [];
    render();
  }

  /* ── clock ────────────────────────────────────────────────────────────── */

  function elapsed() {
    if (s.winner) return s.frozen;
    if (s.startedAt === null) return 0;
    return Math.floor((Date.now() - s.startedAt) / 1000);
  }
  function mmss(total) {
    var m = Math.floor(total / 60), sec = total % 60;
    return m + ':' + (sec < 10 ? '0' : '') + sec;
  }

  /* ── render ───────────────────────────────────────────────────────────── */

  var lastScore = { 1: null, 2: null };

  function render(popped) {
    for (var who = 1; who <= 2; who++) {
      var side = el.sides[who];
      var value = s.p[who];

      if (el.score[who].textContent !== String(value)) el.score[who].textContent = value;
      if (popped === who && lastScore[who] !== null && value !== lastScore[who]) {
        el.score[who].classList.remove('pop');
        void el.score[who].offsetWidth;
        el.score[who].classList.add('pop');
      }
      lastScore[who] = value;

      if (s.server === who && !s.winner) side.setAttribute('data-serving', '');
      else side.removeAttribute('data-serving');

      if (isSetPoint(who)) side.setAttribute('data-point', '');
      else side.removeAttribute('data-point');

      // set dots: one per set needed to win
      var dots = '';
      for (var i = 0; i < s.setsToWin; i++) dots += '<i class="' + (i < s.sets[who] ? 'on' : '') + '"></i>';
      if (el.sets[who].innerHTML !== dots) el.sets[who].innerHTML = dots;

      side.setAttribute('aria-label',
        NAME[who] + ', ' + value + ' point' + (value === 1 ? '' : 's') +
        ', ' + s.sets[who] + ' set' + (s.sets[who] === 1 ? '' : 's') + ' won' +
        (s.server === who && !s.winner ? ', serving' : '') +
        (isMatchPoint(who) ? ', match point' : isSetPoint(who) ? ', set point' : '') +
        '. Activate to add a point.');
    }

    var flag = isMatchPoint(1) || isMatchPoint(2) ? 'Match point'
             : isSetPoint(1) || isSetPoint(2) ? 'Set point'
             : isDeuce() ? 'Deuce' : '';
    if (flag && !s.winner) { el.flag.textContent = flag; el.flag.hidden = false; }
    else el.flag.hidden = true;

    el.undo.disabled = s.history.length === 0;

    if (s.winner) {
      el.wonName.textContent = NAME[s.winner];
      el.wonLine.textContent = s.sets[1] + '–' + s.sets[2];
      el.won.hidden = false;
    } else {
      el.won.hidden = true;
    }

    el.clock.textContent = mmss(elapsed());

    if (el.live) {
      el.live.textContent = s.winner
        ? NAME[s.winner] + ' wins the match, ' + s.sets[1] + ' sets to ' + s.sets[2] + '.'
        : NAME[1] + ' ' + s.p[1] + ', ' + NAME[2] + ' ' + s.p[2] + '. ' + NAME[s.server] + ' to serve.'
          + (flag ? ' ' + flag + '.' : '');
    }

    save();
  }

  /* ── input ────────────────────────────────────────────────────────────── */

  [1, 2].forEach(function (who) {
    var side = el.sides[who];
    var dragFrom = null, dragged = false;

    side.addEventListener('click', function () {
      if (dragged) { dragged = false; return; }
      addPoint(who);
    });

    // Mouse only: a downward drag takes a point back, mirroring the app's
    // swipe. Touch is left alone so the page always scrolls.
    side.addEventListener('pointerdown', function (e) {
      if (e.pointerType !== 'mouse') return;
      dragFrom = e.clientY; dragged = false;
    });
    side.addEventListener('pointerup', function (e) {
      if (e.pointerType !== 'mouse' || dragFrom === null) return;
      if (e.clientY - dragFrom > 40) { dragged = true; removePoint(who); }
      dragFrom = null;
    });
    side.addEventListener('pointercancel', function () { dragFrom = null; });

    side.addEventListener('keydown', function (e) {
      if (e.key === 'ArrowDown') { e.preventDefault(); removePoint(who); }
      if (e.key === 'ArrowUp') { e.preventDefault(); addPoint(who); }
    });
  });

  board.addEventListener('click', function (e) {
    var act = e.target.closest('[data-act]');
    if (!act) return;
    if (act.dataset.act === 'undo') undo();
    if (act.dataset.act === 'reset') reset();
  });

  /* ── rule controls ────────────────────────────────────────────────────── */

  function press(group, value) {
    Array.prototype.forEach.call(group.querySelectorAll('button'), function (b) {
      b.setAttribute('aria-pressed', String(b.dataset.val === String(value)));
    });
  }

  Array.prototype.forEach.call(document.querySelectorAll('[data-seg]'), function (group) {
    var kind = group.dataset.seg;
    group.addEventListener('click', function (e) {
      var btn = e.target.closest('button[data-val]');
      if (!btn) return;
      var raw = btn.dataset.val;

      if (kind === 'theme') {
        document.documentElement.setAttribute('data-theme', raw);
        write(THEME_STORE, raw);
        press(group, raw);
        return;
      }

      if (kind === 'target') { s.target = parseInt(raw, 10); press(group, s.target); reset(); }
      if (kind === 'sets') { s.setsToWin = parseInt(raw, 10); press(group, s.setsToWin); reset(); }
      if (kind === 'interval') { s.interval = parseInt(raw, 10); press(group, s.interval); updateServer(); render(); }
      if (kind === 'deuce') { s.winByTwo = raw === '1'; press(group, raw); updateServer(); render(); }
    });
  });

  function syncControls() {
    var map = { target: s.target, sets: s.setsToWin, interval: s.interval, deuce: s.winByTwo ? '1' : '0' };
    Object.keys(map).forEach(function (kind) {
      var group = document.querySelector('[data-seg="' + kind + '"]');
      if (group) press(group, map[kind]);
    });
    var theme = document.documentElement.getAttribute('data-theme');
    var themeGroup = document.querySelector('[data-seg="theme"]');
    if (themeGroup) press(themeGroup, theme);
  }

  /* ── go ───────────────────────────────────────────────────────────────── */

  restore();
  syncControls();
  render();
  setInterval(function () {
    if (!s.winner && s.startedAt !== null) el.clock.textContent = mmss(elapsed());
  }, 1000);
})();
