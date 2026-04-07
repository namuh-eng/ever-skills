#!/usr/bin/env bash
# ABOUTME: Install script for Ever Skills — installs CLI, skills, and optionally prompts to star the repo.
# ABOUTME: Designed to be sourced by tests (function-only) or executed directly (full install flow).

set -euo pipefail

REPO_OWNER="namuh-eng"
REPO_NAME="ever-skills"
PROJECT_NAME="ever-skills"

# ---------------------------------------------------------------------------
# Star prompt — safe to source and call independently for testing
# ---------------------------------------------------------------------------

maybe_prompt_to_star_repo() {
  # Wrap everything so errors never propagate
  {
    # Gate 1: skip flags / env vars
    if [[ "${SKIP_STAR_PROMPT:-0}" == "1" ]] || [[ "${EVER_SKILLS_SKIP_STAR_PROMPT:-0}" == "1" ]]; then
      return 0
    fi

    # Gate 2: interactive check (stdin + stdout are TTYs)
    # Allow EVER_SKILLS_FORCE_INTERACTIVE=1 for testing
    if [[ "${EVER_SKILLS_FORCE_INTERACTIVE:-0}" != "1" ]]; then
      if [[ ! -t 0 ]] || [[ ! -t 1 ]]; then
        return 0
      fi
    fi

    # Gate 3: gh installed and authenticated
    if ! command -v gh &>/dev/null; then
      return 0
    fi
    if ! gh auth status &>/dev/null; then
      return 0
    fi

    # Prompt (default No)
    printf "\n[%s] optional: star %s/%s on GitHub to support the project\n" \
      "$PROJECT_NAME" "$REPO_OWNER" "$REPO_NAME"
    printf "[%s] Would you like to star %s/%s on GitHub with gh? [y/N]: " \
      "$PROJECT_NAME" "$REPO_OWNER" "$REPO_NAME"

    read -r answer || answer=""

    case "$(printf '%s' "$answer" | tr '[:upper:]' '[:lower:]')" in
      y|yes)
        if gh api --method PUT "/user/starred/${REPO_OWNER}/${REPO_NAME}" --silent 2>/dev/null; then
          printf "[%s] Thanks for starring!\n" "$PROJECT_NAME"
        else
          printf "[%s] No worries — continuing without it.\n" "$PROJECT_NAME"
        fi
        ;;
      *)
        ;;
    esac
  } || true
}

# ---------------------------------------------------------------------------
# Main install flow — only runs when executed directly, not when sourced
# ---------------------------------------------------------------------------

main() {
  local skip_star=0

  for arg in "$@"; do
    case "$arg" in
      --skip-star-prompt) skip_star=1 ;;
      --help|-h)
        cat <<'HELP'
Usage: install.sh [OPTIONS]

Install Ever Skills — browser automation skills for AI coding assistants.

Steps:
  1. Installs the Ever CLI (npm install -g @ever/cli)
  2. Installs skills into your AI coding assistant (npx skills add)
  3. Optionally prompts to star the repo on GitHub

Options:
  --skip-star-prompt   Skip the optional GitHub star prompt at the end
  --help, -h           Show this help message

Environment variables:
  SKIP_STAR_PROMPT=1              Skip the star prompt
  EVER_SKILLS_SKIP_STAR_PROMPT=1  Skip the star prompt (project-specific)

HELP
        exit 0
        ;;
    esac
  done

  if command -v ever &>/dev/null; then
    printf "[%s] Ever CLI already installed ($(ever --version 2>/dev/null || echo 'unknown version')). Skipping.\n" "$PROJECT_NAME"
  else
    printf "[%s] Installing Ever CLI...\n" "$PROJECT_NAME"
    npm install -g @ever/cli
  fi

  printf "\n[%s] Installing skills...\n" "$PROJECT_NAME"
  npx skills add "$REPO_OWNER/$REPO_NAME"

  printf "\n[%s] Verifying installation...\n" "$PROJECT_NAME"
  ever --version

  if [[ "$skip_star" -eq 1 ]]; then
    SKIP_STAR_PROMPT=1
  fi

  maybe_prompt_to_star_repo

  printf "\n[%s] Done! Your AI assistant is ready to automate browsers.\n" "$PROJECT_NAME"
}

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
  main "$@"
fi
