/* 
  🏓 Ping Pong Scoreboard — Web Core Logic
  Navigation, scroll-driven reveals, interactive simulator, and gallery.
*/

document.addEventListener('DOMContentLoaded', () => {
  initNavigation();
  initScrollHeader();
  initScrollReveal();
  initScoreboardSimulator();
});

/* ═══════════════════════════════════════════
 * 1. NAVIGATION & VIEW SWITCHING
 * ═══════════════════════════════════════════ */
function initNavigation() {
  const navButtons = document.querySelectorAll('.nav-btn, .footer-nav-btn, .nav-action');
  const sections = document.querySelectorAll('.view-section');
  const mobileNav = document.getElementById('main-nav');
  const navToggle = document.getElementById('nav-toggle');

  const switchView = (targetId) => {
    window.scrollTo({ top: 0, behavior: 'smooth' });

    // Update active nav buttons
    document.querySelectorAll('.nav-btn').forEach(btn => {
      btn.classList.toggle('active', btn.getAttribute('data-target') === targetId);
    });

    // Update active sections
    sections.forEach(section => {
      if (section.id === targetId) {
        section.classList.add('active');
        // Re-trigger reveals for newly shown section
        setTimeout(() => triggerRevealsInView(), 100);
      } else {
        section.classList.remove('active');
      }
    });

    // Close mobile nav
    if (mobileNav) mobileNav.classList.remove('open');
  };

  // All nav buttons and action buttons
  navButtons.forEach(btn => {
    btn.addEventListener('click', (e) => {
      e.preventDefault();
      const targetId = btn.getAttribute('data-target');
      if (targetId) {
        switchView(targetId);
        history.pushState(null, null, `#${targetId}`);
      }
    });
  });

  // Mobile hamburger toggle
  if (navToggle) {
    navToggle.addEventListener('click', () => {
      mobileNav.classList.toggle('open');
    });
  }

  // Hash routing
  const handleHash = () => {
    const hash = window.location.hash.substring(1);
    const validSections = ['features', 'support', 'privacy'];
    switchView(validSections.includes(hash) ? hash : 'features');
  };

  window.addEventListener('hashchange', handleHash);
  handleHash();
}

/* ═══════════════════════════════════════════
 * 2. STICKY HEADER SCROLL EFFECT
 * ═══════════════════════════════════════════ */
function initScrollHeader() {
  const header = document.getElementById('site-header');
  if (!header) return;

  let ticking = false;
  const onScroll = () => {
    if (!ticking) {
      requestAnimationFrame(() => {
        header.classList.toggle('scrolled', window.scrollY > 30);
        ticking = false;
      });
      ticking = true;
    }
  };

  window.addEventListener('scroll', onScroll, { passive: true });
  onScroll(); // Check initial state
}

/* ═══════════════════════════════════════════
 * 3. SCROLL-DRIVEN REVEAL ANIMATIONS
 * ═══════════════════════════════════════════ */
function initScrollReveal() {
  const observer = new IntersectionObserver((entries) => {
    entries.forEach(entry => {
      if (entry.isIntersecting) {
        entry.target.classList.add('visible');
      }
    });
  }, {
    threshold: 0.1,
    rootMargin: '0px 0px -60px 0px'
  });

  document.querySelectorAll('.reveal').forEach(el => observer.observe(el));

  // Store observer reference for re-triggering
  window.__revealObserver = observer;
}

function triggerRevealsInView() {
  document.querySelectorAll('.reveal:not(.visible)').forEach(el => {
    const rect = el.getBoundingClientRect();
    if (rect.top < window.innerHeight && rect.bottom > 0) {
      el.classList.add('visible');
    }
  });
}

/* ═══════════════════════════════════════════
 * 4. INTERACTIVE SCOREBOARD SIMULATOR
 * ═══════════════════════════════════════════ */
function initScoreboardSimulator() {
  const sidePink = document.getElementById('sim-pink-side');
  const sideCyan = document.getElementById('sim-cyan-side');
  const scorePinkEl = document.getElementById('sim-pink-score');
  const scoreCyanEl = document.getElementById('sim-cyan-score');
  const setsPinkContainer = document.getElementById('sim-pink-sets');
  const setsCyanContainer = document.getElementById('sim-cyan-sets');
  const bannerEl = document.getElementById('sim-status-banner');
  const btnUndo = document.getElementById('sim-btn-undo');
  const btnReset = document.getElementById('sim-btn-reset');

  if (!sidePink || !sideCyan) return;

  let state = {
    scorePink: 0,
    scoreCyan: 0,
    setsPink: 0,
    setsCyan: 0,
    server: 'pink',
    initialServer: 'pink',
    history: []
  };

  function saveState() {
    state.history.push({
      scorePink: state.scorePink,
      scoreCyan: state.scoreCyan,
      setsPink: state.setsPink,
      setsCyan: state.setsCyan,
      server: state.server,
      initialServer: state.initialServer
    });
    if (state.history.length > 20) state.history.shift();
    btnUndo.disabled = false;
    btnUndo.style.opacity = '1';
  }

  function calculateServer() {
    const totalPoints = state.scorePink + state.scoreCyan;

    if (state.scorePink >= 10 && state.scoreCyan >= 10) {
      const pointDifference = totalPoints - 20;
      state.server = (pointDifference % 2 === 0) ? state.initialServer :
        (state.initialServer === 'pink' ? 'cyan' : 'pink');
    } else {
      const rotationStep = Math.floor(totalPoints / 2);
      state.server = (rotationStep % 2 === 0) ? state.initialServer :
        (state.initialServer === 'pink' ? 'cyan' : 'pink');
    }
  }

  function updateUI() {
    scorePinkEl.textContent = state.scorePink;
    scoreCyanEl.textContent = state.scoreCyan;

    if (state.server === 'pink') {
      sidePink.classList.add('active-serve');
      sideCyan.classList.remove('active-serve');
    } else {
      sideCyan.classList.add('active-serve');
      sidePink.classList.remove('active-serve');
    }

    renderSetDots(setsPinkContainer, state.setsPink);
    renderSetDots(setsCyanContainer, state.setsCyan);

    // Banner messages
    if (state.scorePink >= 10 && state.scoreCyan >= 10) {
      if (state.scorePink === state.scoreCyan) {
        bannerEl.textContent = 'DEUCE — WIN BY 2 POINTS';
      } else if (state.scorePink === state.scoreCyan + 1) {
        bannerEl.textContent = 'SET POINT — PLAYER 1';
      } else if (state.scoreCyan === state.scorePink + 1) {
        bannerEl.textContent = 'SET POINT — PLAYER 2';
      }
    } else if (state.scorePink === 10) {
      bannerEl.textContent = 'SET POINT — PLAYER 1';
    } else if (state.scoreCyan === 10) {
      bannerEl.textContent = 'SET POINT — PLAYER 2';
    } else {
      bannerEl.textContent = 'TAP SIDES TO RECORD POINTS';
    }

    if (state.history.length === 0) {
      btnUndo.disabled = true;
      btnUndo.style.opacity = '0.4';
    }
  }

  function renderSetDots(container, count) {
    container.innerHTML = '';
    for (let i = 0; i < 3; i++) {
      const dot = document.createElement('div');
      dot.className = 'sim-dot' + (i < count ? ' filled' : '');
      container.appendChild(dot);
    }
  }

  function animateScore(element, rect) {
    const floatText = document.createElement('div');
    floatText.className = 'sim-float';
    floatText.textContent = '+1';

    const x = Math.min(Math.max(rect.left + rect.width / 2, 40), window.innerWidth - 60);
    const y = rect.top + rect.height / 2;
    floatText.style.left = `${x}px`;
    floatText.style.top = `${y}px`;

    document.body.appendChild(floatText);
    setTimeout(() => floatText.remove(), 600);
  }

  function checkSetWinner(player) {
    const pScore = player === 'pink' ? state.scorePink : state.scoreCyan;
    const oppScore = player === 'pink' ? state.scoreCyan : state.scorePink;

    if (pScore >= 11 && pScore - oppScore >= 2) {
      if (player === 'pink') state.setsPink++;
      else state.setsCyan++;

      state.scorePink = 0;
      state.scoreCyan = 0;
      state.initialServer = player;
      state.server = player;

      if (state.setsPink === 2 || state.setsCyan === 2) {
        const matchWinner = state.setsPink === 2 ? 'PLAYER 1' : 'PLAYER 2';
        bannerEl.textContent = `🏆 ${matchWinner} WINS THE MATCH!`;
        bannerEl.style.color = '#fff';
        setTimeout(() => {
          bannerEl.style.color = '';
          resetMatch(true);
        }, 3000);
      }
    }
  }

  function handleScoreAdd(player, e) {
    saveState();
    const rect = e.currentTarget.getBoundingClientRect();
    animateScore(e.currentTarget, rect);

    if (player === 'pink') state.scorePink++;
    else state.scoreCyan++;

    calculateServer();
    checkSetWinner(player);
    updateUI();
  }

  sidePink.addEventListener('click', (e) => handleScoreAdd('pink', e));
  sideCyan.addEventListener('click', (e) => handleScoreAdd('cyan', e));

  btnUndo.addEventListener('click', () => {
    if (state.history.length > 0) {
      const prevState = state.history.pop();
      Object.assign(state, prevState);
      updateUI();
    }
  });

  function resetMatch(full = false) {
    state.scorePink = 0;
    state.scoreCyan = 0;
    if (full) {
      state.setsPink = 0;
      state.setsCyan = 0;
      state.initialServer = 'pink';
      state.server = 'pink';
    }
    state.history = [];
    updateUI();
  }

  btnReset.addEventListener('click', () => resetMatch(true));

  updateUI();
}
