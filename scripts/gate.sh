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
slug=$(basename "$TOP" | tr 'A-Z' 'a-z' | sed 's/[^a-z0-9]/_/g' | cut -c1-40)

# One gate at a time per repo (all worktrees share the common dir), so parallel agents don't
# oversubscribe the CPU or the shared services. gate.lock=false turns it off.
if [ "$(cfg '.gate.lock' true)" != false ]; then
  lock="$common/shipcrew-gate/.lock"; waited=0; max=$(cfg '.gate.lockTimeout' 1800)
  until mkdir "$lock" 2>/dev/null; do
    holder=$(cat "$lock/pid" 2>/dev/null)
    if [ -n "$holder" ] && ! kill -0 "$holder" 2>/dev/null; then rm -rf "$lock"; continue; fi
    [ $waited = 0 ] && echo "gate: another gate is running ($(cat "$lock/who" 2>/dev/null)); waiting for it." >&2
    [ "$waited" -ge "$max" ] && { echo "gate: waited ${max}s for the lock; giving up." >&2; exit 4; }
    sleep 5; waited=$((waited+5))
  done
  echo $$ > "$lock/pid"; echo "$slug" > "$lock/who"
  trap 'rm -rf "$lock"' EXIT
fi
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
  # Per-worktree isolation: app.env values may use {slug} (this worktree's folder name); exported to
  # requires, setup and checks, so a check can pick a per-worktree database, port or cache key.
  while IFS=$'\t' read -r k v; do [ -n "$k" ] && export "$k=${v//\{slug\}/$slug}"; done \
    < <(jq -r '.env // {} | to_entries[] | [.key, .value] | @tsv' <<<"$app")
  req=$(jq -r '.requires // empty' <<<"$app")
  if [ -n "$req" ] && ! bash -c "$req" >/dev/null 2>&1; then
    echo "gate: prerequisite failed for '$name': $req" >&2
    echo "      Ask the user once: use CI (push with SHIPCREW_GATE=ci) or fix the prerequisite?" >&2
    exit 3
  fi
  ok=1
  setup=$(jq -r '.setup // empty' <<<"$app")
  if [ -n "$setup" ]; then
    slog="$common/shipcrew-gate/$sha.$name.setup.log"
    if ! (cd "$path" && bash -c "$setup") >"$slog" 2>&1; then
      echo "gate: setup failed for '$name' (full log: $slog)" >&2; tail -n "${GATE_TAIL:-40}" "$slog" >&2
      echo "gate: $name FAIL" >&2; rc=1; continue
    fi
  fi
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
  teardown=$(jq -r '.teardown // empty' <<<"$app")
  if [ -n "$teardown" ]; then
    tlog="$common/shipcrew-gate/$sha.$name.teardown.log"
    (cd "$path" && bash -c "$teardown") >"$tlog" 2>&1 || echo "gate: teardown failed for '$name' (ignored; log: $tlog)" >&2
  fi
  if [ $ok = 1 ]; then touch "$common/shipcrew-gate/$sha.$name"; echo "gate: $name PASS"; else echo "gate: $name FAIL" >&2; rc=1; fi
done < <(jq -c '.apps // [] | .[]' "$SHIPCREW_CONFIG")
[ $ran = 0 ] && echo "gate: no configured app has changes. Nothing to check."
exit $rc
