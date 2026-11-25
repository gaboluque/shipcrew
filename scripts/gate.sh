#!/usr/bin/env bash
# shipcrew local gate: runs the checks CI runs, for the apps this branch touches, and writes a marker
# per (commit, app) that the pre-push hook requires. Run from the worktree with everything committed.
# Usage: gate.sh [<app name>|auto]     (auto = apps changed against origin/<baseBranch>)
set -u
ROOT=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd -P)
. "$ROOT/hooks/lib.sh"
command -v jq >/dev/null 2>&1 || { echo "gate: jq is required." >&2; exit 2; }
TOP=$(git rev-parse --show-toplevel) || exit 2; cd "$TOP" || exit 2
SHIPCREW_CONFIG=$(shipcrew_config) || { echo "gate: no .shipcrew/config.json (run /shipcrew:init)." >&2; exit 2; }
BASE=$(cfg '.baseBranch' main); sha=$(git rev-parse HEAD); common=$(git rev-parse --git-common-dir)
mkdir -p "$common/shipcrew-gate"
if [ -n "$(git status --porcelain --untracked-files=no)" ]; then
  echo "gate: uncommitted changes. Commit first so the marker matches the pushed commit." >&2; exit 2
fi
base=$(git merge-base "origin/$BASE" HEAD) || { echo "gate: run 'git fetch origin $BASE' first." >&2; exit 2; }
changed=$(git diff --name-only "$base" HEAD)
want="${1:-auto}"; rc=0; ran=0
while IFS= read -r app; do
  name=$(jq -r '.name' <<<"$app"); path=$(jq -r '.path' <<<"$app")
  [ "$want" != auto ] && [ "$want" != "$name" ] && continue
  app_changed=$(grep "^$path/" <<<"$changed" | sed "s#^$path/##")
  [ "$want" = auto ] && [ -z "$app_changed" ] && continue
  ran=1; echo "== gate: $name @ ${sha:0:10} =="
  req=$(jq -r '.requires // empty' <<<"$app")
  if [ -n "$req" ] && ! bash -c "$req" >/dev/null 2>&1; then
    echo "gate: prerequisite failed for '$name': $req" >&2
    echo "      Ask the user once: use CI (push with SHIPCREW_GATE=ci) or fix the prerequisite?" >&2
    exit 3
  fi
  ok=1
  while IFS= read -r chk; do
    [ -z "$chk" ] && continue
    cname=$(jq -r '.name' <<<"$chk"); run=$(jq -r '.run' <<<"$chk"); re=$(jq -r '.files // empty' <<<"$chk")
    if [ -n "$re" ]; then
      files=$(grep -E "$re" <<<"$app_changed" | while read -r f; do [ -f "$path/$f" ] && printf '%q ' "$f"; done)
      [ -z "$files" ] && { echo "-- $cname: no matching files, skipped"; continue; }
      run="${run//\{files\}/$files}"
    fi
    log="$common/shipcrew-gate/$sha.$name.$cname.log"; log="${log// /_}"; t0=$SECONDS
    if (cd "$path" && bash -c "$run") >"$log" 2>&1; then
      echo "-- $cname: pass ($((SECONDS-t0))s)"
    else
      echo "-- $cname: FAIL, last ${GATE_TAIL:-40} lines (full log: $log)" >&2
      tail -n "${GATE_TAIL:-40}" "$log" >&2; ok=0
    fi
  done < <(jq -c '.checks // [] | .[]' <<<"$app")
  if [ $ok = 1 ]; then touch "$common/shipcrew-gate/$sha.$name"; echo "gate: $name PASS"; else echo "gate: $name FAIL" >&2; rc=1; fi
done < <(jq -c '.apps // [] | .[]' "$SHIPCREW_CONFIG")
[ $ran = 0 ] && echo "gate: no configured app has changes. Nothing to check."
exit $rc
