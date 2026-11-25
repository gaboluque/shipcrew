#!/usr/bin/env bash
# shipcrew PreToolUse guard (Claude Code hook). Reads the hook JSON on stdin.
# Acts only in repos with .shipcrew/config.json. Denies attribution trailers, malformed PR titles and
# branch renames that would close a PR. Asks before editing protected paths.
# Skip for one command: SHIPCREW_SKIP_GUARD=1 (only on the user's explicit word).
[ "${SHIPCREW_SKIP_GUARD:-}" = 1 ] && exit 0
command -v jq >/dev/null 2>&1 || exit 0
DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd -P); . "$DIR/lib.sh"

in=$(cat)
tool=$(jq -r '.tool_name // empty' <<<"$in")
cwd=$(jq -r '.cwd // empty' <<<"$in")
[ -n "$cwd" ] && cd "$cwd" 2>/dev/null || exit 0
SHIPCREW_CONFIG=$(shipcrew_config) || exit 0

decide() { # deny|ask, reason
  jq -n --arg d "$1" --arg r "$2" '{hookSpecificOutput:{hookEventName:"PreToolUse",permissionDecision:$d,permissionDecisionReason:$r}}'
  exit 0
}
BRANCH_RE=$(shipcrew_branch_re)
TYPES=$(shipcrew_types)
NOSUFFIX=$(cfg '.policy.forbidNumericSuffix' true)

case "$tool" in
Edit|Write|MultiEdit|NotebookEdit)
  f=$(jq -r '.tool_input.file_path // .tool_input.notebook_path // empty' <<<"$in")
  top=$(git rev-parse --show-toplevel)
  # Resolve symlinks (for example /var vs /private/var) so the prefix match is reliable.
  fdir=$(cd "$(dirname "$f")" 2>/dev/null && pwd -P) && f="$fdir/$(basename "$f")"
  rel="${f#"$top"/}"
  while IFS= read -r p; do
    [ -z "$p" ] && continue
    [[ "$rel" == "$p"/* || "$rel" == "$p" ]] && decide ask "'$p' is a protected path (policy.askBeforeEditing in .shipcrew/config.json). Confirm this edit."
  done < <(jq -r '.policy.askBeforeEditing // [] | .[]' "$SHIPCREW_CONFIG")
  ;;
Bash)
  cmd=$(jq -r '.tool_input.command // empty' <<<"$in")
  # Only look at the command line itself, not at heredoc bodies written into files.
  head_cmd=$(sed -E '/<<-?[[:space:]]*['\''"]?[A-Za-z_]+['\''"]?/,$d' <<<"$cmd")
  [ -z "$head_cmd" ] && head_cmd="$cmd"
  is_commit=0; is_pr=0
  [[ "$head_cmd" =~ (^|[;&|[:space:]])git([[:space:]]+-C[[:space:]]+[^[:space:]]+)?[[:space:]]+commit([[:space:]]|$) ]] && is_commit=1
  [[ "$head_cmd" =~ (^|[;&|[:space:]])gh[[:space:]]+pr[[:space:]]+(create|edit)([[:space:]]|$) ]] && is_pr=1

  if { [ $is_commit = 1 ] || [ $is_pr = 1 ]; } && [ "$(cfg '.policy.forbidAttribution' true)" = true ]; then
    text="$cmd"
    bf=$(grep -oE '(--body-file|-F)[ =]+[^ ]+' <<<"$head_cmd" | head -1 | sed -E 's/^(--body-file|-F)[ =]+//; s/["'\'']//g')
    [ -n "$bf" ] && [ -r "$bf" ] && text="$text"$'\n'"$(cat "$bf")"
    grep -qiE 'co-authored-by:' <<<"$text" && decide deny "policy.forbidAttribution: no co-author trailers in commits or PR bodies. Remove it and retry."
    grep -qiE 'generated with \[?claude' <<<"$text" && decide deny "policy.forbidAttribution: no 'Generated with Claude' line in commits or PR bodies. Remove it and retry."
  fi

  if [ $is_pr = 1 ]; then
    title=$(sed -nE "s/.*--title[ =]+\"([^\"]+)\".*/\1/p; s/.*--title[ =]+'([^']+)'.*/\1/p" <<<"$head_cmd" | head -1)
    if [ -n "$title" ]; then
      [[ "$title" =~ ^($TYPES)(\([A-Za-z0-9._/-]+\))?!?:\  ]] || decide deny "PR title must start with '<type>: ' where type is one of: ${TYPES//|/, }. Got: $title"
      pos=$(cfg '.policy.ticketPosition' suffix); pat=$(cfg '.policy.ticketPattern' '')
      if [ -n "$pat" ] && [ "$pos" = suffix ]; then
        [[ "$title" =~ ^\[$pat\] ]] && decide deny "Put the ticket id at the END of the title, e.g. 'feat: summary [ABC-123]' (policy.ticketPosition). Got: $title"
        if [ "$(cfg '.policy.requireTicketInTitle' false)" = true ] && ! [[ "$title" =~ \[$pat\]$ ]]; then
          decide deny "PR title must end with the ticket id in brackets (policy.requireTicketInTitle). Got: $title"
        fi
      fi
    fi
  fi

  if [[ "$head_cmd" =~ /branches/[^[:space:]]+/rename ]]; then
    decide deny "Renaming a branch through the GitHub API closes its open PR. Open a new PR from a new branch instead."
  fi

  if [[ "$head_cmd" =~ (^|[;&|[:space:]])git([[:space:]]+-C[[:space:]]+[^[:space:]]+)?[[:space:]]+branch[[:space:]]+(-m|-M|--move)[[:space:]]+([^[:space:]]+)([[:space:]]+([^[:space:]]+))? ]]; then
    a="${BASH_REMATCH[4]}"; b="${BASH_REMATCH[6]}"
    if [ -n "$b" ]; then old="$a"; new="$b"; else old=$(git branch --show-current); new="$a"; fi
    ok=1; [[ "$new" =~ $BRANCH_RE ]] || ok=0; [ "$NOSUFFIX" = true ] && [[ "$new" =~ -[0-9]+$ ]] && ok=0
    [ $ok = 1 ] || decide deny "New branch name '$new' must be <type>/<kebab-name> with type one of: ${TYPES//|/, }$([ "$NOSUFFIX" = true ] && echo ", and no '-<digit>' suffix")."
    if command -v gh >/dev/null 2>&1; then
      n=$(gh pr list --head "$old" --state open --json number -q length 2>/dev/null || echo 0)
      [ "${n:-0}" -gt 0 ] && decide deny "Branch '$old' has an open PR. Renaming it closes the PR. Open a new PR instead, or ask the user."
    fi
    [ -n "$(git ls-remote --heads origin "$old" 2>/dev/null)" ] && decide deny "Branch '$old' already exists on the remote. Renaming it locally would orphan it. Ask the user."
  fi
  ;;
esac
exit 0
