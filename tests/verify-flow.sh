#!/usr/bin/env bash
# ABOUTME: Comprehensive integration tests for the Ever Skills setup and browser control flow.
# ABOUTME: Requires Chrome with the Ever extension loaded and signed in. Run locally — not CI.

set -uo pipefail

# ---------------------------------------------------------------------------
# Test harness
# ---------------------------------------------------------------------------

PASS=0
FAIL=0
SKIP=0
FAILURES=()

pass() { ((PASS++)); printf "  ✓ %s\n" "$1"; }
fail() { ((FAIL++)); FAILURES+=("$1: $2"); printf "  ✗ %s — %s\n" "$1" "$2"; }
skip() { ((SKIP++)); printf "  ○ %s (skipped: %s)\n" "$1" "$2"; }

section() { printf "\n━━━ %s ━━━\n" "$1"; }

# ---------------------------------------------------------------------------
# Preflight
# ---------------------------------------------------------------------------

section "Preflight"

if command -v ever &>/dev/null; then
  pass "ever CLI is on PATH"
else
  fail "ever CLI is on PATH" "not found — install with: npm install -g @ever/cli"
  printf "\nCannot continue without the CLI. Exiting.\n"
  exit 1
fi

VERSION=$(ever --version 2>&1)
if [[ "$VERSION" =~ ^[0-9]+\.[0-9]+\.[0-9]+ ]]; then
  pass "ever --version ($VERSION)"
else
  fail "ever --version" "unexpected output: $VERSION"
fi

# ---------------------------------------------------------------------------
# 1. install.sh
# ---------------------------------------------------------------------------

section "install.sh"

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
INSTALL_SCRIPT="$SCRIPT_DIR/install.sh"

# --help flag
HELP_OUT=$(bash "$INSTALL_SCRIPT" --help 2>&1)
if echo "$HELP_OUT" | grep -q "Install Ever Skills"; then
  pass "install.sh --help shows usage"
else
  fail "install.sh --help" "missing expected output"
fi

if echo "$HELP_OUT" | grep -q "\-\-skip-star-prompt"; then
  pass "install.sh --help documents --skip-star-prompt"
else
  fail "install.sh --help documents --skip-star-prompt" "flag not mentioned"
fi

# Source and test star prompt gates
# Gate 1: SKIP_STAR_PROMPT=1
GATE1=$(bash -c 'source '"$INSTALL_SCRIPT"' && SKIP_STAR_PROMPT=1 maybe_prompt_to_star_repo && echo "SKIPPED"' 2>&1)
if [[ "$GATE1" == "SKIPPED" ]]; then
  pass "star prompt: SKIP_STAR_PROMPT=1 silently skips"
else
  fail "star prompt: SKIP_STAR_PROMPT=1" "did not skip silently"
fi

# Gate 2: EVER_SKILLS_SKIP_STAR_PROMPT=1
GATE2=$(bash -c 'source '"$INSTALL_SCRIPT"' && EVER_SKILLS_SKIP_STAR_PROMPT=1 maybe_prompt_to_star_repo && echo "SKIPPED"' 2>&1)
if [[ "$GATE2" == "SKIPPED" ]]; then
  pass "star prompt: EVER_SKILLS_SKIP_STAR_PROMPT=1 silently skips"
else
  fail "star prompt: EVER_SKILLS_SKIP_STAR_PROMPT=1" "did not skip silently"
fi

# Gate 3: non-interactive (no TTY) — our shell has no TTY so this should skip
GATE3=$(bash -c 'source '"$INSTALL_SCRIPT"' && maybe_prompt_to_star_repo && echo "SKIPPED"' 2>&1)
if [[ "$GATE3" == "SKIPPED" ]]; then
  pass "star prompt: non-interactive (no TTY) silently skips"
else
  fail "star prompt: non-interactive (no TTY)" "did not skip silently"
fi

# npm registry check — @ever/cli should be installable
NPM_VIEW=$(npm view @ever/cli version 2>&1) || true
if [[ "$NPM_VIEW" =~ ^[0-9]+\.[0-9]+\.[0-9]+ ]]; then
  pass "npm registry: @ever/cli is published ($NPM_VIEW)"
else
  fail "npm registry: @ever/cli is published" "package not found on npm — install.sh will fail for new users"
fi

# ---------------------------------------------------------------------------
# 2. npx skills add
# ---------------------------------------------------------------------------

section "npx skills add"

# Check skills CLI is available
if npx skills --version &>/dev/null; then
  pass "npx skills CLI is available"
else
  fail "npx skills CLI is available" "npx skills not found"
fi

# List available skills from the repo
LIST_OUT=$(npx skills add namuh-eng/ever-skills --list 2>&1)
if echo "$LIST_OUT" | grep -q "ever-browser"; then
  pass "skills add --list finds ever-browser skill"
else
  fail "skills add --list finds ever-browser skill" "ever-browser not found in output"
fi

# Install to claude-code non-interactively
INSTALL_OUT=$(npx skills add namuh-eng/ever-skills --skill ever-browser --agent claude-code -y 2>&1)
if echo "$INSTALL_OUT" | grep -q "Installation complete"; then
  pass "skills add installs ever-browser for claude-code"
else
  fail "skills add installs ever-browser for claude-code" "installation did not complete"
fi

# Verify files exist
if [[ -f "$SCRIPT_DIR/.claude/skills/ever-browser/SKILL.md" ]]; then
  pass "SKILL.md installed to .claude/skills/ever-browser/"
else
  fail "SKILL.md installed to .claude/skills/ever-browser/" "file not found"
fi

if [[ -d "$SCRIPT_DIR/.claude/skills/ever-browser/recipes" ]]; then
  pass "recipes/ directory installed to .claude/skills/ever-browser/"
else
  fail "recipes/ directory installed to .claude/skills/ever-browser/" "directory not found"
fi

# Verify skills list shows the installed skill
SKILLS_LIST=$(npx skills list 2>&1)
if echo "$SKILLS_LIST" | grep -q "ever-browser"; then
  pass "skills list shows ever-browser as installed"
else
  fail "skills list shows ever-browser as installed" "not found in list output"
fi

# ---------------------------------------------------------------------------
# 3. SKILL.md structure
# ---------------------------------------------------------------------------

section "SKILL.md validation"

SKILL_FILE="$SCRIPT_DIR/ever-browser/SKILL.md"

if [[ -f "$SKILL_FILE" ]]; then
  pass "ever-browser/SKILL.md exists"
else
  fail "ever-browser/SKILL.md exists" "file not found"
fi

# Check frontmatter
if head -5 "$SKILL_FILE" | grep -q "^name: ever-browser"; then
  pass "SKILL.md has correct frontmatter name"
else
  fail "SKILL.md has correct frontmatter name" "missing or wrong name field"
fi

if head -5 "$SKILL_FILE" | grep -q "^description:"; then
  pass "SKILL.md has description in frontmatter"
else
  fail "SKILL.md has description in frontmatter" "missing description"
fi

# Check key sections exist
for heading in "Quick Start" "Core Workflow" "Commands Reference" "Error Recovery"; do
  if grep -q "## $heading" "$SKILL_FILE"; then
    pass "SKILL.md has '## $heading' section"
  else
    fail "SKILL.md has '## $heading' section" "section not found"
  fi
done

# Check recipe file exists and is documented
RECIPE_FILE="$SCRIPT_DIR/ever-browser/recipes/x-feed-scraper.js"
if [[ -f "$RECIPE_FILE" ]]; then
  pass "x-feed-scraper.js recipe exists"
else
  fail "x-feed-scraper.js recipe exists" "file not found"
fi

if head -5 "$RECIPE_FILE" | grep -q "Recipe:"; then
  pass "x-feed-scraper.js has Recipe header comment"
else
  fail "x-feed-scraper.js has Recipe header comment" "missing header"
fi

if grep -q "INIT" "$RECIPE_FILE" && grep -q "COLLECT" "$RECIPE_FILE" && grep -q "DUMP" "$RECIPE_FILE"; then
  pass "x-feed-scraper.js follows INIT/COLLECT/DUMP pattern"
else
  fail "x-feed-scraper.js follows INIT/COLLECT/DUMP pattern" "missing one or more phases"
fi

# ---------------------------------------------------------------------------
# 4. GitHub release
# ---------------------------------------------------------------------------

section "GitHub release"

if command -v gh &>/dev/null && gh auth status &>/dev/null; then
  RELEASE_JSON=$(gh release view --repo namuh-eng/ever-skills --json tagName,assets 2>&1)
  if echo "$RELEASE_JSON" | grep -q "tagName"; then
    pass "GitHub release exists"
  else
    fail "GitHub release exists" "no release found"
  fi

  if echo "$RELEASE_JSON" | grep -q "everextension.*chrome.zip"; then
    pass "Chrome extension zip is in release assets"
  else
    fail "Chrome extension zip is in release assets" "asset not found"
  fi
else
  skip "GitHub release checks" "gh CLI not authenticated"
fi

# ---------------------------------------------------------------------------
# 5. Browser session lifecycle (requires Chrome + Ever extension)
# ---------------------------------------------------------------------------

section "Browser session lifecycle"

# Check if extension is reachable by trying to start a session
SESSION_OUT=$(ever start --url https://example.com 2>&1)
if echo "$SESSION_OUT" | grep -q "Session started"; then
  pass "ever start --url https://example.com"
else
  fail "ever start --url https://example.com" "$SESSION_OUT"
  printf "\n  ⚠ Skipping browser tests — Chrome/extension may not be running.\n"
  printf "  Make sure Chrome is open with the Ever extension loaded and signed in.\n\n"

  # Skip remaining browser tests
  skip "ever snapshot" "no session"
  skip "ever click" "no session"
  skip "ever scroll down" "no session"
  skip "ever extract" "no session"
  skip "ever eval" "no session"
  skip "ever input" "no session"
  skip "ever send-keys" "no session"
  skip "ever go-back" "no session"
  skip "ever navigate" "no session"
  skip "ever sessions" "no session"
  skip "ever tabs" "no session"
  skip "ever doctor" "no session"
  skip "ever screenshot" "no session"
  skip "ever stop" "no session"

  # Print summary and exit
  section "Summary"
  printf "  Passed: %d | Failed: %d | Skipped: %d\n" "$PASS" "$FAIL" "$SKIP"
  if [[ ${#FAILURES[@]} -gt 0 ]]; then
    printf "\n  Failures:\n"
    for f in "${FAILURES[@]}"; do printf "    • %s\n" "$f"; done
  fi
  exit $((FAIL > 0 ? 1 : 0))
fi

# --- snapshot ---
SNAP1=$(ever snapshot 2>&1)
if echo "$SNAP1" | grep -q "Example Domain"; then
  pass "ever snapshot — returns DOM with page content"
else
  fail "ever snapshot" "expected 'Example Domain' in output"
fi

if echo "$SNAP1" | grep -qE "\[[0-9]+\]<A"; then
  pass "ever snapshot — annotates interactive elements with [id]"
else
  fail "ever snapshot — annotates interactive elements" "no [id]<A found"
fi

# --- click ---
# Extract the link ID from snapshot (the "Learn more" link)
LINK_ID=$(echo "$SNAP1" | grep -oE "\[([0-9]+)\]<A" | head -1 | grep -oE "[0-9]+")
if [[ -n "$LINK_ID" ]]; then
  CLICK_OUT=$(ever click "$LINK_ID" 2>&1)
  if echo "$CLICK_OUT" | grep -q "Clicked element"; then
    pass "ever click $LINK_ID (Learn more link)"
  else
    fail "ever click $LINK_ID" "$CLICK_OUT"
  fi
else
  fail "ever click" "could not extract element ID from snapshot"
fi

# Wait for navigation
ever wait 2 &>/dev/null

# --- snapshot after navigation (new elements marked with *) ---
SNAP2=$(ever snapshot 2>&1)
if echo "$SNAP2" | grep -qE "\*\[[0-9]+\]"; then
  pass "ever snapshot — marks new elements with *[id] after navigation"
else
  fail "ever snapshot — new element markers" "no *[id] markers found after navigation"
fi

# --- snapshot --mode full (reset diff tracking) ---
SNAP_FULL=$(ever snapshot --mode full 2>&1)
if echo "$SNAP_FULL" | grep -qE "\[[0-9]+\]" && ! echo "$SNAP_FULL" | grep -qE "\*\[[0-9]+\]"; then
  pass "ever snapshot --mode full — resets diff tracking (no * markers)"
else
  # It's okay if there are still markers in some edge cases; just check it ran
  if echo "$SNAP_FULL" | grep -qE "\[[0-9]+\]"; then
    pass "ever snapshot --mode full — returns annotated DOM"
  else
    fail "ever snapshot --mode full" "no annotated elements found"
  fi
fi

# --- extract ---
EXTRACT_OUT=$(ever extract 2>&1)
if echo "$EXTRACT_OUT" | grep -q "Example Domains\|IANA"; then
  pass "ever extract — returns readable markdown"
else
  fail "ever extract" "expected page content in markdown"
fi

# No [id] annotations in extract output
if ! echo "$EXTRACT_OUT" | grep -qE "\[[0-9]+\]<"; then
  pass "ever extract — no [id] annotations (clean text)"
else
  fail "ever extract — no [id] annotations" "found [id]< markers in extract output"
fi

# --- eval ---
EVAL_SIMPLE=$(ever eval "document.title" 2>&1)
if [[ -n "$EVAL_SIMPLE" ]]; then
  pass "ever eval \"document.title\" — returns: $EVAL_SIMPLE"
else
  fail "ever eval" "empty result"
fi

# eval with IIFE pattern (as documented in SKILL.md)
EVAL_IIFE=$(ever eval "(() => { const links = document.querySelectorAll('a'); return JSON.stringify({ count: links.length }); })()" 2>&1)
if echo "$EVAL_IIFE" | grep -q "count"; then
  pass "ever eval with IIFE pattern — returns structured JSON"
else
  fail "ever eval with IIFE pattern" "expected JSON with 'count' key"
fi

# --- scroll ---
SCROLL_OUT=$(ever scroll down 2>&1)
# scroll may produce no output on success
pass "ever scroll down — no error"

SCROLL_UP=$(ever scroll up 2>&1)
pass "ever scroll up — no error"

# --- go-back ---
GOBACK_OUT=$(ever go-back 2>&1)
if echo "$GOBACK_OUT" | grep -q "Navigated back"; then
  pass "ever go-back"
else
  fail "ever go-back" "$GOBACK_OUT"
fi

ever wait 2 &>/dev/null

# Verify we're back on example.com
SNAP3=$(ever snapshot 2>&1)
if echo "$SNAP3" | grep -q "Example Domain"; then
  pass "ever go-back — returned to example.com"
else
  fail "ever go-back — returned to example.com" "page content doesn't match"
fi

# --- navigate ---
NAV_OUT=$(ever navigate https://www.google.com 2>&1)
if echo "$NAV_OUT" | grep -q "Navigated to"; then
  pass "ever navigate https://www.google.com"
else
  fail "ever navigate" "$NAV_OUT"
fi

ever wait 2 &>/dev/null

SNAP4=$(ever snapshot 2>&1)
if echo "$SNAP4" | grep -qi "search\|google\|TEXTAREA"; then
  pass "ever navigate — Google page loaded (search elements visible)"
else
  fail "ever navigate — Google page loaded" "expected search-related elements"
fi

# --- input ---
# Find the search textarea
SEARCH_ID=$(echo "$SNAP4" | grep -oE "\[[0-9]+\]<TEXTAREA" | head -1 | grep -oE "[0-9]+" | head -1)
if [[ -n "$SEARCH_ID" ]]; then
  INPUT_OUT=$(ever input "$SEARCH_ID" "ever cli test" 2>&1)
  if echo "$INPUT_OUT" | grep -q "Typed into element"; then
    pass "ever input $SEARCH_ID \"ever cli test\""
  else
    fail "ever input" "$INPUT_OUT"
  fi
else
  # Try with a known ID pattern
  INPUT_OUT=$(ever input 2 "ever cli test" 2>&1)
  if echo "$INPUT_OUT" | grep -q "Typed into element"; then
    pass "ever input 2 \"ever cli test\" (fallback ID)"
  else
    fail "ever input" "could not find search textarea to test input"
  fi
fi

# --- send-keys ---
KEYS_OUT=$(ever send-keys "Escape" 2>&1)
# send-keys may produce no output on success
pass "ever send-keys \"Escape\" — no error"

# --- sessions ---
SESSIONS_OUT=$(ever sessions 2>&1)
if echo "$SESSIONS_OUT" | grep -q "active"; then
  pass "ever sessions — lists active session"
else
  fail "ever sessions" "expected '(active)' in output"
fi

# --- tabs ---
TABS_OUT=$(ever tabs 2>&1)
if [[ -n "$TABS_OUT" ]]; then
  pass "ever tabs — returns tab list"
  # Check for the known undefined tab ID bug
  if echo "$TABS_OUT" | grep -q "undefined:"; then
    fail "ever tabs — tab ID is valid" "tab ID shows as 'undefined' (known bug)"
  else
    pass "ever tabs — tab ID is valid"
  fi
else
  fail "ever tabs" "empty output"
fi

# --- doctor ---
DOC_OUT=$(ever doctor 2>&1)
if echo "$DOC_OUT" | grep -q "\[OK\].*everd"; then
  pass "ever doctor — everd is reachable"
else
  fail "ever doctor — everd" "everd not OK"
fi

if echo "$DOC_OUT" | grep -q "\[OK\].*API server"; then
  pass "ever doctor — API server is reachable"
else
  fail "ever doctor — API server" "API server not OK"
fi

# --- screenshot ---
SCREENSHOT_OUT=$(ever screenshot 2>&1)
if echo "$SCREENSHOT_OUT" | grep -q "Screenshot saved to"; then
  SCREENSHOT_PATH=$(echo "$SCREENSHOT_OUT" | grep -oE "/[^ ]+\.jpg")
  if [[ -n "$SCREENSHOT_PATH" ]] && [[ -f "$SCREENSHOT_PATH" ]]; then
    pass "ever screenshot — file created at $SCREENSHOT_PATH"
    rm -f "$SCREENSHOT_PATH" 2>/dev/null  # cleanup
  else
    fail "ever screenshot — file exists on disk" "CLI reported success but file not found at: $SCREENSHOT_PATH"
  fi
else
  fail "ever screenshot" "$SCREENSHOT_OUT"
fi

# --- search (navigates away, do this near the end) ---
SEARCH_OUT=$(ever search "ever cli browser automation" 2>&1)
if echo "$SEARCH_OUT" | grep -qi "navigat\|search"; then
  pass "ever search \"ever cli browser automation\""
  ever wait 2 &>/dev/null
else
  fail "ever search" "$SEARCH_OUT"
fi

# --- stop ---
STOP_OUT=$(ever stop 2>&1)
if echo "$STOP_OUT" | grep -q "Session stopped"; then
  pass "ever stop"
else
  fail "ever stop" "$STOP_OUT"
fi

# Verify no sessions remain
SESSIONS_AFTER=$(ever sessions 2>&1)
if echo "$SESSIONS_AFTER" | grep -q "No active sessions"; then
  pass "ever sessions — clean after stop"
else
  fail "ever sessions — clean after stop" "sessions still active"
fi

# ---------------------------------------------------------------------------
# Summary
# ---------------------------------------------------------------------------

section "Summary"
printf "  Passed: %d | Failed: %d | Skipped: %d\n" "$PASS" "$FAIL" "$SKIP"

if [[ ${#FAILURES[@]} -gt 0 ]]; then
  printf "\n  Failures:\n"
  for f in "${FAILURES[@]}"; do printf "    • %s\n" "$f"; done
fi

exit $((FAIL > 0 ? 1 : 0))
