// Recipe: X (Twitter) Feed Scraper
// Site: x.com
// Task: Collect posts from timeline with metadata
// Parameters: timeWindowHours (default: 5)
//
// Usage pattern:
//   1. Navigate to x.com and ensure desired tab (Following, For You, etc.) is selected
//   2. Run INIT to set up global accumulator
//   3. Run COLLECT in a bash loop with `ever scroll down && sleep 1` between iterations
//   4. Run DUMP to get all collected posts as JSON
//
// Selectors (last verified: 2026-03-22):
//   article[data-testid="tweet"]       — tweet container
//   [data-testid="User-Name"]          — name + handle wrapper
//   [data-testid="tweetText"]          — tweet text content
//   [data-testid="reply"]              — reply button (aria-label has count)
//   [data-testid="retweet"]            — retweet button (aria-label has count)
//   [data-testid="like"]               — like button (aria-label has count)
//   [data-testid="unlike"]             — liked button (aria-label has count)
//   [data-testid="socialContext"]      — "X reposted" banner
//   time[datetime]                     — timestamp element

// --- INIT ---
// Run once before starting collection.
// ever eval "window._xposts = {}; window._xposts_cfg = { timeWindowMs: 5 * 60 * 60 * 1000 }; 'init ok'"

// --- COLLECT ---
// Run after each scroll. Wrap in IIFE to avoid redeclaration errors.
// Use in a bash loop:
//   for i in $(seq 1 N); do
//     ever scroll down 2>/dev/null
//     sleep 1
//     ever eval "<COLLECT_SCRIPT>" 2>&1
//   done
//
// The collect script:
(() => {
  const fha = Date.now() - window._xposts_cfg.timeWindowMs;
  let oc = 0;
  for (const a of document.querySelectorAll('article[data-testid="tweet"]')) {
    const t = a.querySelector("time");
    if (!t) continue;
    const dt = t.getAttribute("datetime");
    if (!dt) continue;
    const link = t.closest("a")?.href || dt;
    if (window._xposts[link]) continue;
    if (new Date(dt).getTime() < fha) {
      oc++;
      continue;
    }
    const n = a.querySelector('[data-testid="User-Name"]');
    let nm = "",
      hd = "";
    for (const l of n?.querySelectorAll('a[role="link"]') || []) {
      if (l.textContent.startsWith("@")) hd = l.textContent;
      else if (!nm && l.textContent.trim()) nm = l.textContent.trim();
    }
    const txt = a.querySelector('[data-testid="tweetText"]')?.textContent || "";
    const r =
      a
        .querySelector('[data-testid="reply"]')
        ?.getAttribute("aria-label")
        ?.match(/(\d+)/)?.[1] || "0";
    const rt =
      a
        .querySelector('[data-testid="retweet"]')
        ?.getAttribute("aria-label")
        ?.match(/(\d+)/)?.[1] || "0";
    const lk =
      (
        a.querySelector('[data-testid="like"]') ||
        a.querySelector('[data-testid="unlike"]')
      )
        ?.getAttribute("aria-label")
        ?.match(/(\d+)/)?.[1] || "0";
    const sc =
      a.querySelector('[data-testid="socialContext"]')?.textContent || null;
    window._xposts[link] = {
      who: nm + " (" + hd + ")",
      link,
      content: txt.substring(0, 400),
      time: t.textContent,
      replies: +r,
      retweets: +rt,
      likes: +lk,
      repostBy: sc,
    };
  }
  return JSON.stringify({
    collected: Object.keys(window._xposts).length,
    oldOnScreen: oc,
  });
})();

// --- DUMP ---
// Run once after collection is complete.
// ever eval "JSON.stringify(Object.values(window._xposts), null, 2)"
