/* 
  🏓 Ping Pong Scoreboard - Web Core Logic
  Manages single-page view switching and the interactive scoreboard simulator.
*/

document.addEventListener('DOMContentLoaded', () => {
  initNavigation();
  initScoreboardSimulator();
});

/* -------------------------------------------------------------
 * 1. Single Page View Switching (Tabs & Hash Routing)
 * ------------------------------------------------------------- */
function initNavigation() {
  const navButtons = document.querySelectorAll('.nav-btn, .footer-nav-btn');
  const sections = document.querySelectorAll('.view-section');

  const switchView = (targetId) => {
    // Scroll to top
    window.scrollTo({ top: 0, behavior: 'smooth' });

    // Update active nav buttons
    navButtons.forEach(btn => {
      if (btn.getAttribute('data-target') === targetId) {
        btn.classList.add('active');
      } else {
        btn.classList.remove('active');
      }
    });

    // Update active sections
    sections.forEach(section => {
      if (section.id === targetId) {
        section.classList.add('active');
      } else {
        section.classList.remove('active');
      }
    });
  };

  // Nav Button Clicks
  navButtons.forEach(btn => {
    btn.addEventListener('click', (e) => {
      e.preventDefault();
      const targetId = btn.getAttribute('data-target');
      switchView(targetId);
      // Update hash in URL
      history.pushState(null, null, `#${targetId}`);
    });
  });

  // Handle direct links with hashes (e.g. website.com/#support or website.com/#privacy)
  const handleHash = () => {
    const hash = window.location.hash.substring(1);
    const validSections = ['features', 'support', 'privacy'];
    if (hash && validSections.includes(hash)) {
      switchView(hash);
    } else {
      switchView('features'); // Default to home features
    }
  };

  window.addEventListener('hashchange', handleHash);
  handleHash(); // Run once at load
}

/* -------------------------------------------------------------
 * 2. Interactive Scoreboard Simulator (OLED Web Mockup)
 * ------------------------------------------------------------- */
function initScoreboardSimulator() {
  // Elements
  const sidePink = document.getElementById('sim-pink-side');
  const sideCyan = document.getElementById('sim-cyan-side');
  const scorePinkEl = document.getElementById('sim-pink-score');
  const scoreCyanEl = document.getElementById('sim-cyan-score');
  const setsPinkContainer = document.getElementById('sim-pink-sets');
  const setsCyanContainer = document.getElementById('sim-cyan-sets');
  const bannerEl = document.getElementById('sim-status-banner');
  const btnUndo = document.getElementById('sim-btn-undo');
  const btnReset = document.getElementById('sim-btn-reset');

  // State Variables
  let state = {
    scorePink: 0,
    scoreCyan: 0,
    setsPink: 0,
    setsCyan: 0,
    server: 'pink', // 'pink' or 'cyan'
    initialServer: 'pink',
    history: []
  };

  // Keep history for Undo
  function saveState() {
    state.history.push({
      scorePink: state.scorePink,
      scoreCyan: state.scoreCyan,
      setsPink: state.setsPink,
      setsCyan: state.setsCyan,
      server: state.server,
      initialServer: state.initialServer
    });
    if (state.history.length > 20) {
      state.history.shift(); // Limit history buffer
    }
    btnUndo.disabled = false;
    btnUndo.style.opacity = '1';
  }

  // Determine current active server based on scores (ITTF rules)
  function calculateServer() {
    const totalPoints = state.scorePink + state.scoreCyan;
    
    // Deuce scenario (10-10 or above): rotate serve every single point
    if (state.scorePink >= 10 && state.scoreCyan >= 10) {
      const pointDifference = totalPoints - 20;
      if (pointDifference % 2 === 0) {
        state.server = state.initialServer;
      } else {
        state.server = state.initialServer === 'pink' ? 'cyan' : 'pink';
      }
    } else {
      // Normal rotation: switch server every 2 points
      const rotationStep = Math.floor(totalPoints / 2);
      if (rotationStep % 2 === 0) {
        state.server = state.initialServer;
      } else {
        state.server = state.initialServer === 'pink' ? 'cyan' : 'pink';
      }
    }
  }

  // Update UI Elements based on state
  function updateUI() {
    scorePinkEl.textContent = state.scorePink;
    scoreCyanEl.textContent = state.scoreCyan;

    // Active serve glows
    if (state.server === 'pink') {
      sidePink.classList.add('active-serve');
      sideCyan.classList.remove('active-serve');
    } else {
      sideCyan.classList.add('active-serve');
      sidePink.classList.remove('active-serve');
    }

    // Render set indicator dots
    renderSetDots(setsPinkContainer, state.setsPink);
    renderSetDots(setsCyanContainer, state.setsCyan);

    // Banner message updates
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

    // Toggle Undo button disabled status
    if (state.history.length === 0) {
      btnUndo.disabled = true;
      btnUndo.style.opacity = '0.4';
    }
  }

  function renderSetDots(container, count) {
    container.innerHTML = '';
    // Max 3 sets for a visual mockup
    for (let i = 0; i < 3; i++) {
      const dot = document.createElement('div');
      dot.className = 'sim-dot' + (i < count ? ' filled' : '');
      container.appendChild(dot);
    }
  }

  // Trigger floating point indicator animation
  function animateScore(element, rect) {
    const floatText = document.createElement('div');
    floatText.className = 'sim-float';
    floatText.textContent = '+1';
    
    // Random offset slightly inside the clicked container
    const x = Math.min(Math.max(rect.left + rect.width / 2, 40), window.innerWidth - 60);
    const y = rect.top + rect.height / 2;

    floatText.style.left = `${x}px`;
    floatText.style.top = `${y}px`;

    document.body.appendChild(floatText);

    setTimeout(() => {
      floatText.remove();
    }, 600);
  }

  // Check if a set has been won
  function checkSetWinner(player) {
    const pScore = player === 'pink' ? state.scorePink : state.scoreCyan;
    const oppScore = player === 'pink' ? state.scoreCyan : state.scorePink;

    if (pScore >= 11 && pScore - oppScore >= 2) {
      // Current set is won!
      if (player === 'pink') {
        state.setsPink++;
      } else {
        state.setsCyan++;
      }

      // Reset scores for next set
      state.scorePink = 0;
      state.scoreCyan = 0;
      
      // Winner of the set serves first in the next set
      state.initialServer = player;
      state.server = player;
      
      // Match Won scenario (First to 2 sets for this mockup)
      if (state.setsPink === 2 || state.setsCyan === 2) {
        const matchWinner = state.setsPink === 2 ? 'PLAYER 1' : 'PLAYER 2';
        bannerEl.textContent = `🏆 ${matchWinner} WINS THE MATCH!`;
        
        // Temporarily flash celebratory banner
        bannerEl.style.color = '#fff';
        setTimeout(() => {
          bannerEl.style.color = '';
          resetMatch(true); // Full Reset
        }, 3000);
      }
    }
  }

  // Handle Score Input
  function handleScoreAdd(player, e) {
    saveState();
    
    const rect = e.currentTarget.getBoundingClientRect();
    animateScore(e.currentTarget, rect);

    if (player === 'pink') {
      state.scorePink++;
    } else {
      state.scoreCyan++;
    }

    calculateServer();
    checkSetWinner(player);
    updateUI();
  }

  // Event Listeners for tap interactions
  sidePink.addEventListener('click', (e) => handleScoreAdd('pink', e));
  sideCyan.addEventListener('click', (e) => handleScoreAdd('cyan', e));

  // Undo Action
  btnUndo.addEventListener('click', () => {
    if (state.history.length > 0) {
      const prevState = state.history.pop();
      state.scorePink = prevState.scorePink;
      state.scoreCyan = prevState.scoreCyan;
      state.setsPink = prevState.setsPink;
      state.setsCyan = prevState.setsCyan;
      state.server = prevState.server;
      state.initialServer = prevState.initialServer;
      updateUI();
    }
  });

  // Reset Match
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

  // Initial Load UI Call
  updateUI();
}
