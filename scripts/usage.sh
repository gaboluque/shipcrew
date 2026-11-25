#!/usr/bin/env bash
# Prints where tokens went in recent Claude Code sessions of this project: per session, the captain
# (main conversation) and each subagent (by type and description), for tuning the crew.
# Usage: usage.sh [--days N] [--match <text>] [--dir <projects dir>]...
# Columns: new = fresh input + cache writes, cached = cache reads, out = output tokens, turns = API calls.
# "new + out" is the real cost driver; cached tokens are billed at a fraction. Stdout only; nothing is stored.
set -u
command -v jq >/dev/null || { echo "usage: jq is required" >&2; exit 2; }
days=7; matches=(); dirs=()
while [ $# -gt 0 ]; do
  case "$1" in
    --days) days=$2; shift 2;;
    --match) matches+=("$2"); shift 2;;
    --dir) dirs+=("$2"); shift 2;;
    *) echo "usage: unknown option $1" >&2; exit 2;;
  esac
done
slug() { printf '%s' "$1" | sed 's#[/.]#-#g'; }
if [ ${#matches[@]} -eq 0 ]; then
  common=$(git rev-parse --path-format=absolute --git-common-dir 2>/dev/null) && matches+=("$(slug "$(dirname "$common")")")
  cfg="$(dirname "${common:-/nonexistent}")/.shipcrew/config.json"
  if [ -f "$cfg" ]; then
    root=$(jq -r '.worktree.root // empty' "$cfg"); root=${root/#\~/$HOME}
    [ -n "$root" ] && { case "$root" in /*) ;; *) root="$(dirname "$common")/$root";; esac; matches+=("$(slug "$(cd "$root" 2>/dev/null && pwd -P || echo "$root")")"); }
  fi
fi
[ ${#matches[@]} -eq 0 ] && { echo "usage: not in a git repo; pass --match <text>" >&2; exit 2; }
if [ ${#dirs[@]} -eq 0 ]; then
  dirs+=("${CLAUDE_CONFIG_DIR:-$HOME/.claude}/projects")
  if [ -n "${SHIPCREW_TRANSCRIPT_DIRS:-}" ]; then IFS=: read -ra extra <<<"$SHIPCREW_TRANSCRIPT_DIRS"; dirs+=("${extra[@]}"); fi
  for d in "$HOME"/Library/Application\ Support/orca/claude-profiles/*/home/projects; do dirs+=("$d"); done
fi
# Sums one transcript: one usage per message id (a message is logged once per content block).
sum() {
  jq -s -r '[.[] | select(.type=="assistant" and .message.usage != null)] | unique_by(.message.id) |
    [ (map(.message.usage | (.input_tokens//0) + (.cache_creation_input_tokens//0)) | add // 0),
      (map(.message.usage.cache_read_input_tokens//0) | add // 0),
      (map(.message.usage.output_tokens//0) | add // 0), length ] | @tsv' "$1" 2>/dev/null
}
printf '%-9s %-28s %9s %10s %8s %6s\n' session who new cached out turns
found=0; seen=""
for d in "${dirs[@]}"; do
  [ -d "$d" ] || continue
  for p in "$d"/*/; do
    name=$(basename "$p"); ok=0
    for m in "${matches[@]}"; do case "$name" in "$m"*|*"$m"*) ok=1;; esac; done
    [ $ok = 1 ] || continue
    while IFS= read -r f; do
      sid=$(basename "$f" .jsonl)
      case " $seen " in *" $sid "*) continue;; esac; seen="$seen $sid"; found=$((found+1))
      read -r n c o t < <(sum "$f"); printf '%-9s %-28s %9s %10s %8s %6s\n' "${sid:0:8}" "captain (main)" "${n:-0}" "${c:-0}" "${o:-0}" "${t:-0}"
      for s in "$p$sid"/subagents/agent-*.jsonl; do
        [ -f "$s" ] || continue
        meta="${s%.jsonl}.meta.json"
        who=$(jq -r '"\(.agentType // "?"): \(.description // "")"' "$meta" 2>/dev/null || echo "?")
        read -r n c o t < <(sum "$s"); printf '%-9s %-28s %9s %10s %8s %6s\n' "" "  ${who:0:26}" "${n:-0}" "${c:-0}" "${o:-0}" "${t:-0}"
      done
    done < <(find "$p" -maxdepth 1 -name '*.jsonl' -mtime "-$days" 2>/dev/null | sort)
  done
done
[ $found -eq 0 ] && echo "usage: no conversations in the last $days days matched ${matches[*]}" >&2
exit 0
