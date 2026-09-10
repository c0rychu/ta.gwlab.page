/* Classroom tools: countdown timer, random picker, blackout screen, link filter.
   Plain ES modules-free JS so the page needs no bundler — `make site` only copies
   this file across. */
(() => {
  "use strict";

  const $ = (sel) => document.querySelector(sel);
  // Order matters only for readability; the first entry is the default landing tab.
  const TABS = ["home", "timer", "picker", "black"];
  const TITLE = "TA Tools";

  // localStorage is a convenience, not state we depend on: it throws in some
  // privacy modes and comes back empty in others.
  const store = {
    get(key, fallback) {
      try {
        const raw = localStorage.getItem(key);
        return raw === null ? fallback : JSON.parse(raw);
      } catch {
        return fallback;
      }
    },
    set(key, value) {
      try {
        localStorage.setItem(key, JSON.stringify(value));
      } catch {
        /* not worth telling the user about */
      }
    },
  };

  const randomInt = (n) => {
    // Rejection sampling keeps every value equally likely; a plain % would bias
    // the low end, which for picking students is a real (if small) unfairness.
    const limit = Math.floor(0x100000000 / n) * n;
    const buf = new Uint32Array(1);
    let v;
    do {
      crypto.getRandomValues(buf);
      v = buf[0];
    } while (v >= limit);
    return (v % n) + 1;
  };

  /* ---------------------------------------------------------------- tabs -- */

  let lastTool = "home"; // where Esc returns you after the blackout

  function showTab(name) {
    const tab = TABS.includes(name) ? name : TABS[0];
    if (tab !== "black") lastTool = tab;

    for (const t of TABS) {
      const panel = document.getElementById(`panel-${t}`);
      if (panel) panel.classList.toggle("is-active", t === tab);
      document.querySelector(`[data-tab="${t}"]`).classList.toggle("is-active", t === tab);
    }
    setBlackout(tab === "black");
    if (tab === "picker") $("#p-max").focus();
  }

  const routeFromHash = () => showTab(location.hash.replace("#", ""));
  window.addEventListener("hashchange", routeFromHash);

  /* --------------------------------------------------------------- timer -- */

  const clock = $("#clock");
  const toggleBtn = $("#t-toggle");

  const timer = {
    duration: store.get("ta.timer.duration", 600), // seconds; the Reset target
    remaining: 0, // ms, authoritative while paused
    deadline: 0, // epoch ms, authoritative while running
    running: false,
    ticker: null,
  };
  timer.remaining = timer.duration * 1000;

  function formatClock(ms) {
    const total = Math.ceil(ms / 1000);
    const h = Math.floor(total / 3600);
    const m = Math.floor((total % 3600) / 60);
    const s = total % 60;
    const pad = (n) => String(n).padStart(2, "0");
    return h > 0 ? `${h}:${pad(m)}:${pad(s)}` : `${pad(m)}:${pad(s)}`;
  }

  function renderTimer() {
    // Always derive from the deadline rather than decrementing a counter:
    // background tabs get their timers throttled, and a counter would drift.
    const ms = timer.running ? Math.max(0, timer.deadline - Date.now()) : timer.remaining;
    const text = formatClock(ms);
    clock.textContent = text;
    toggleBtn.textContent = timer.running ? "Pause" : "Start";

    if (timer.running && ms <= 0) finishTimer();
    else if (timer.running) document.title = `${text} · ${TITLE}`;
  }

  function startTimer() {
    if (timer.remaining <= 0) timer.remaining = timer.duration * 1000;
    timer.deadline = Date.now() + timer.remaining;
    timer.running = true;
    clock.classList.remove("is-alarm");
    clearInterval(timer.ticker);
    timer.ticker = setInterval(renderTimer, 100);
    renderTimer();
  }

  function pauseTimer() {
    if (!timer.running) return;
    timer.remaining = Math.max(0, timer.deadline - Date.now());
    timer.running = false;
    clearInterval(timer.ticker);
    document.title = TITLE;
    renderTimer();
  }

  function finishTimer() {
    timer.running = false;
    timer.remaining = 0;
    clearInterval(timer.ticker);
    clock.textContent = "00:00";
    clock.classList.add("is-alarm");
    toggleBtn.textContent = "Start";
    document.title = `Time's up · ${TITLE}`;
  }

  function setDuration(seconds) {
    timer.duration = Math.max(1, Math.min(seconds, 24 * 3600));
    timer.remaining = timer.duration * 1000;
    if (timer.running) timer.deadline = Date.now() + timer.remaining;
    clock.classList.remove("is-alarm");
    if (!timer.running) document.title = TITLE;
    store.set("ta.timer.duration", timer.duration);
    renderTimer();
  }

  // Accepts "10" (minutes), "7:30", "1:02:30" and "90s".
  function parseDuration(text) {
    const raw = text.trim().toLowerCase();
    if (!raw) return null;
    if (/^\d+(\.\d+)?s$/.test(raw)) return Math.round(parseFloat(raw));
    if (/^\d+(\.\d+)?m?$/.test(raw)) return Math.round(parseFloat(raw) * 60);
    const parts = raw.split(":");
    if (parts.length > 3 || !parts.every((p) => /^\d+$/.test(p))) return null;
    return parts.reduce((acc, p) => acc * 60 + Number(p), 0);
  }

  toggleBtn.addEventListener("click", () => (timer.running ? pauseTimer() : startTimer()));

  $("#t-reset").addEventListener("click", () => {
    pauseTimer();
    timer.remaining = timer.duration * 1000;
    clock.classList.remove("is-alarm");
    document.title = TITLE;
    renderTimer();
  });

  for (const btn of document.querySelectorAll(".t-delta")) {
    btn.addEventListener("click", () => {
      // Nudge the running clock and the reset target together, so a "+5 min"
      // mid-exercise is not undone by the next Reset.
      const delta = Number(btn.dataset.delta);
      const base = timer.running ? Math.max(0, timer.deadline - Date.now()) / 1000 : timer.remaining / 1000;
      setDuration(Math.round(base) + delta);
    });
  }

  for (const btn of document.querySelectorAll(".t-preset")) {
    btn.addEventListener("click", () => setDuration(Number(btn.dataset.preset)));
  }

  $("#t-form").addEventListener("submit", (e) => {
    e.preventDefault();
    const seconds = parseDuration($("#t-input").value);
    if (seconds === null || seconds <= 0) {
      $("#t-input").classList.add("is-alarm");
      setTimeout(() => $("#t-input").classList.remove("is-alarm"), 600);
      return;
    }
    setDuration(seconds);
    $("#t-input").value = "";
    $("#t-input").blur();
  });

  /* -------------------------------------------------------------- picker -- */

  const die = $("#die");
  const maxInput = $("#p-max");
  const noRepeat = $("#p-norepeat");
  const note = $("#p-note");

  let picked = new Set(store.get("ta.picker.picked", []));
  let rolling = false;

  maxInput.value = store.get("ta.picker.max", 30);
  noRepeat.checked = store.get("ta.picker.norepeat", false);

  // The digit keeps its size/weight classes; only the colour is swapped.
  const DIE_COLORS = ["text-slate-600", "text-slate-400", "text-sky-400"];
  const setDieColor = (cls) => {
    die.classList.remove(...DIE_COLORS);
    die.classList.add(cls);
  };

  const currentMax = () => Math.max(1, Math.min(Math.floor(Number(maxInput.value) || 1), 9999));

  function renderPicked() {
    const max = currentMax();
    const chips = [...picked];
    $("#p-picked").innerHTML = chips
      .map((n) => `<span class="kbd">${n}</span>`)
      .join("");
    const exhausted = noRepeat.checked && chips.length >= max;
    $("#p-pick").disabled = rolling || exhausted;
    note.textContent = !noRepeat.checked
      ? ""
      : exhausted
        ? `All ${max} picked — Clear to start over.`
        : `${chips.length} of ${max} picked.`;
    store.set("ta.picker.picked", chips);
  }

  function pick() {
    const max = currentMax();
    if (!noRepeat.checked) return randomInt(max);
    const pool = [];
    for (let i = 1; i <= max; i++) if (!picked.has(i)) pool.push(i);
    return pool.length ? pool[randomInt(pool.length) - 1] : null;
  }

  function runPick() {
    if (rolling) return;
    const result = pick();
    if (result === null) return renderPicked();

    rolling = true;
    $("#p-pick").disabled = true;
    die.classList.remove("is-pop");
    setDieColor("text-slate-400");

    const max = currentMax();
    const until = performance.now() + 1500;
    let delay = 40;

    // Decelerating shuffle: fast blur, then visibly slowing, so the room feels
    // the result land instead of it simply appearing.
    const step = () => {
      die.textContent = randomInt(max);
      if (performance.now() < until) {
        delay *= 1.16;
        setTimeout(step, delay);
        return;
      }
      die.textContent = result;
      setDieColor("text-sky-400");
      die.classList.add("is-pop");
      if (noRepeat.checked) picked.add(result);
      rolling = false;
      renderPicked();
    };
    step();
  }

  $("#p-pick").addEventListener("click", runPick);

  $("#p-reset").addEventListener("click", () => {
    picked.clear();
    die.textContent = "–";
    die.classList.remove("is-pop");
    setDieColor("text-slate-600");
    renderPicked();
  });

  maxInput.addEventListener("change", () => {
    maxInput.value = currentMax();
    store.set("ta.picker.max", currentMax());
    // The pool changed, so previously picked numbers no longer describe it.
    picked.clear();
    renderPicked();
  });

  noRepeat.addEventListener("change", () => {
    store.set("ta.picker.norepeat", noRepeat.checked);
    renderPicked();
  });

  /* ------------------------------------------------------------ blackout -- */

  const blackout = $("#blackout");
  const hint = $("#black-hint");
  let hintTimer = null;

  function idleHint() {
    hint.classList.remove("opacity-0");
    document.body.classList.remove("cursor-none");
    clearTimeout(hintTimer);
    hintTimer = setTimeout(() => {
      hint.classList.add("opacity-0");
      document.body.classList.add("cursor-none");
    }, 800);
  }

  function setBlackout(on) {
    blackout.classList.toggle("is-active", on);
    $("#chrome").hidden = on;
    $("#foot").hidden = on;
    if (on) {
      idleHint();
    } else {
      clearTimeout(hintTimer);
      document.body.classList.remove("cursor-none");
      if (document.fullscreenElement) document.exitFullscreen().catch(() => {});
    }
  }

  const leaveBlackout = () => {
    location.hash = `#${lastTool}`;
  };

  blackout.addEventListener("click", leaveBlackout);
  blackout.addEventListener("mousemove", idleHint);

  $("#black-full").addEventListener("click", (e) => {
    e.stopPropagation(); // do not also exit the blackout
    if (document.fullscreenElement) document.exitFullscreen().catch(() => {});
    else document.documentElement.requestFullscreen().catch(() => {});
    idleHint();
  });

  /* ---------------------------------------------------------------- home -- */

  const filter = $("#home-filter");

  filter.addEventListener("input", () => {
    const q = filter.value.trim().toLowerCase();
    let visible = 0;
    for (const item of document.querySelectorAll("#home-content li")) {
      const hit = !q || item.textContent.toLowerCase().includes(q);
      item.hidden = !hit;
      if (hit) visible++;
    }
    // Hide a section heading whose items all filtered out.
    for (const heading of document.querySelectorAll("#home-content h2")) {
      const list = heading.nextElementSibling;
      heading.hidden = !!q && !!list && [...list.children].every((li) => li.hidden);
    }
    $("#home-empty").classList.toggle("hidden", visible > 0);
  });

  /* ------------------------------------------------------------ keyboard -- */

  document.addEventListener("keydown", (e) => {
    if (e.key === "Escape" && blackout.classList.contains("is-active")) {
      leaveBlackout();
      return;
    }
    const typing = /^(INPUT|TEXTAREA|SELECT|BUTTON|A)$/.test(e.target.tagName);
    if (e.code === "Space" && !typing && $("#panel-timer").classList.contains("is-active")) {
      e.preventDefault();
      timer.running ? pauseTimer() : startTimer();
    }
  });

  /* ----------------------------------------------------------------- go -- */

  routeFromHash();
  renderTimer();
  renderPicked();
})();
