#!/usr/bin/env bash
# Prints the user's messages from recent Claude Code conversations of this project, for /shipcrew:retro.
# Usage: transcripts.sh [--days N] [--match <text>] [--dir <projects dir>]... [--max-chars N] [--cues]
# --cues keeps only messages that read like a correction, rule or confirmation (a smaller, cheaper pass).
# Default projects dirs: $CLAUDE_CONFIG_DIR/projects (or ~/.claude/projects), $SHIPCREW_TRANSCRIPT_DIRS
# (colon-separated), and Orca profiles (~/Library/Application Support/orca/claude-profiles/*/home/projects).
# Default match: this repo's main checkout and its worktree root. Output goes to stdout only; nothing is stored.
set -u
command -v jq >/dev/null || { echo "transcripts: jq is required" >&2; exit 2; }
days=14; max=500; cues=0; matches=(); dirs=()
while [ $# -gt 0 ]; do
  case "$1" in
    --days) days=$2; shift 2;;
    --match) matches+=("$2"); shift 2;;
    --dir) dirs+=("$2"); shift 2;;
    --max-chars) max=$2; shift 2;;
    --cues) cues=1; shift;;
    *) echo "transcripts: unknown option $1" >&2; exit 2;;
  esac
done
slug() { printf '%s' "$1" | sed 's#[/.]#-#g'; }
if [ ${#matches[@]} -eq 0 ]; then
  common=$(git rev-parse --path-format=absolute --git-common-dir 2>/dev/null) && matches+=("$(slug "$(dirname "$common")")")
  cfg=""; top=$(git rev-parse --show-toplevel 2>/dev/null) && [ -f "$(dirname "$common")/.shipcrew/config.json" ] && cfg="$(dirname "$common")/.shipcrew/config.json"
  if [ -n "$cfg" ]; then
    root=$(jq -r '.worktree.root // empty' "$cfg"); root=${root/#\~/$HOME}
    [ -n "$root" ] && { case "$root" in /*) ;; *) root="$(dirname "$common")/$root";; esac; matches+=("$(slug "$(cd "$root" 2>/dev/null && pwd -P || echo "$root")")"); }
  fi
fi
[ ${#matches[@]} -eq 0 ] && { echo "transcripts: not in a git repo; pass --match <text>" >&2; exit 2; }
if [ ${#dirs[@]} -eq 0 ]; then
  dirs+=("${CLAUDE_CONFIG_DIR:-$HOME/.claude}/projects")
  if [ -n "${SHIPCREW_TRANSCRIPT_DIRS:-}" ]; then IFS=: read -ra extra <<<"$SHIPCREW_TRANSCRIPT_DIRS"; dirs+=("${extra[@]}"); fi
  for d in "$HOME"/Library/Application\ Support/orca/claude-profiles/*/home/projects; do dirs+=("$d"); done
fi
found=0
for d in "${dirs[@]}"; do
  [ -d "$d" ] || continue
  for p in "$d"/*/; do
    name=$(basename "$p"); ok=0
    for m in "${matches[@]}"; do case "$name" in "$m"*|*"$m"*) ok=1;; esac; done
    [ $ok = 1 ] || continue
    while IFS= read -r f; do
      found=$((found+1))
      jq -r --argjson max "$max" --argjson cues "$cues" '
        def cue: test("(?i)\\b(no|nope|don.?t|do not|stop|never|always|instead|wrong|incorrect|not what|i said|i meant|why (did|are|is|do)|again|too (long|much|verbose|wordy)|shorter|fluff|shouldn.?t|should have|should be|must|actually|rather|prefer|that.?s not|undo|revert|remember|from now on|exactly|perfect|keep|update|fix)\\b");
        def txt: if type=="string" then . else ([.[]? | select(.type=="text") | .text] | join(" ")) end;
        select((.type=="user" or .type=="assistant") and (.isSidechain|not) and (.isMeta|not))
        | (.message.content | txt | gsub("[\\n\\t\\r]+";" ") | .[0:$max]) as $t
        | select($t != "")
        | if .type=="assistant" then "A\t\($t[0:160])"
          elif ($t|test("^\\s*<(command-|local-command|system-reminder|task-notification|pasted)")) or ($t|test("^\\[Request interrupted")) then empty
          elif ($cues==1 and ($t|cue|not)) then empty
          else "U\t\(.timestamp // "")\t\($t)" end' "$f" 2>/dev/null |
      awk -F'\t' -v sid="$(basename "$f" .jsonl)" -v proj="$name" 'BEGIN{n=0}
        $1=="A"{last=$2; next}
        $1=="U"{ if(!n){printf "\n## session %s (%s)\n", substr(sid,1,8), proj}; n++;
                 printf "- [%s] %s\n", substr($2,1,16), $3; if(last!="") printf "  after: %s\n", last; last="" }'
    done < <(find "$p" -maxdepth 1 -name '*.jsonl' -mtime "-$days" 2>/dev/null | sort)
  done
done
[ $found -eq 0 ] && echo "transcripts: no conversations in the last $days days matched ${matches[*]}" >&2
exit 0
