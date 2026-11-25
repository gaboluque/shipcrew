#!/usr/bin/env bash
# Self-test for the hooks and the gate, in a throwaway repo. Usage: scripts/selftest.sh
set -u
ROOT=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd -P)
T=$(mktemp -d); trap 'rm -rf "$T"' EXIT
pass=0; failn=0
ok()   { echo "ok   - $1"; pass=$((pass+1)); }
bad()  { echo "FAIL - $1"; failn=$((failn+1)); }
expect() { # name, expected decision (deny|ask|allow), command JSON helper output
  local got; got=$(jq -r '.hookSpecificOutput.permissionDecision // "allow"' <<<"${3:-{\}}" 2>/dev/null || echo allow)
  [ "$got" = "$2" ] && ok "$1" || bad "$1 (wanted $2, got $got)"
}
bash_in() { jq -n --arg c "$1" --arg d "$T/work" '{tool_name:"Bash",cwd:$d,tool_input:{command:$c}}' | "$ROOT/hooks/guard.sh"; }
edit_in() { jq -n --arg f "$1" --arg d "$T/work" '{tool_name:"Edit",cwd:$d,tool_input:{file_path:$f}}' | "$ROOT/hooks/guard.sh"; }

git init -q --bare "$T/remote.git"
git init -q -b main "$T/work"; cd "$T/work" || exit 1
git config user.email t@example.com; git config user.name t
mkdir -p .shipcrew app legacy
cat > .shipcrew/config.json <<'JSON'
{
  "baseBranch": "main",
  "apps": [ { "name": "app", "path": "app",
    "checks": [ { "name": "echo-files", "run": "test -n '{files}'", "files": "\\.txt$" } ] } ],
  "policy": { "ticketPattern": "[A-Z]+-[0-9]+", "ticketPosition": "suffix", "askBeforeEditing": ["legacy"] }
}
JSON
echo a > app/a.txt; git add -A; git commit -qm init
git remote add origin "$T/remote.git"; git push -q origin main 2>/dev/null; git fetch -q origin
SHIPCREW_ROOT="$ROOT/hooks" bash "$ROOT/scripts/install-git-hooks.sh" >/dev/null

# guard
expect "attribution trailer in commit denied" deny "$(bash_in 'git commit -m "x

Co-Authored-By: A <a@example.com>"')"
expect "generated-with line in PR body denied" deny "$(bash_in 'gh pr create --title "feat: x [AB-1]" --body "Generated with [Claude Code](u)"')"
expect "ticket prefix in title denied" deny "$(bash_in 'gh pr create --title "[AB-1] feat: x" --body hi')"
expect "missing type in title denied" deny "$(bash_in 'gh pr create --title "add thing" --body hi')"
expect "good title allowed" allow "$(bash_in 'gh pr create --title "feat: add thing [AB-1]" --body hi')"
expect "bad rename target denied" deny "$(bash_in 'git branch -m Some-Name')"
expect "api rename denied" deny "$(bash_in 'gh api -X POST repos/o/r/branches/x/rename -f new_name=y')"
expect "heredoc body that only mentions the words is allowed" allow "$(bash_in "cat > notes.md <<'EOF'
Never add Co-Authored-By lines. git commit rules live here.
EOF")"
expect "protected path asks" ask "$(edit_in "$T/work/legacy/x.rb")"
expect "unprotected path allowed" allow "$(edit_in "$T/work/app/x.rb")"
cd /tmp && expect "outside a configured repo is a no-op" allow "$(jq -n '{tool_name:"Bash",cwd:"/tmp",tool_input:{command:"git commit -m \"Co-Authored-By: x\""}}' | "$ROOT/hooks/guard.sh")"
cd "$T/work"

# commit-msg hook
git checkout -qb feat/thing
echo b > app/b.txt; git add -A
git commit -qm "$(printf 'feat: b\n\nCo-Authored-By: A <a@example.com>')" 2>/dev/null && bad "commit-msg hook blocks trailer" || ok "commit-msg hook blocks trailer"
git commit -qm "feat: b" && ok "clean commit passes" || bad "clean commit passes"

# pre-push: gate required, then satisfied
git push -q origin feat/thing 2>/dev/null && bad "push without gate blocked" || ok "push without gate blocked"
"$ROOT/scripts/gate.sh" auto >/dev/null 2>&1 && ok "gate passes" || bad "gate passes"
git push -q origin feat/thing 2>/dev/null && ok "push after gate passes" || bad "push after gate passes"
git checkout -qb feat/thing-2; git push -q origin feat/thing-2 2>/dev/null && bad "numeric suffix blocked" || ok "numeric suffix blocked"
git checkout -qb BadName; git push -q origin BadName 2>/dev/null && bad "bad branch name blocked" || ok "bad branch name blocked"
git checkout -q feat/thing; echo c > app/c.txt; git add -A; git commit -qm "feat: c"
SHIPCREW_GATE=ci git push -q origin feat/thing 2>/dev/null && ok "SHIPCREW_GATE=ci override works" || bad "SHIPCREW_GATE=ci override works"

echo; echo "$pass passed, $failn failed"; [ $failn = 0 ]
