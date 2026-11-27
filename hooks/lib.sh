#!/usr/bin/env bash
# Shared helpers. Source this file; it never exits on its own.
# Every shipcrew hook is a no-op unless the repo has .shipcrew/config.json.

shipcrew_config() {
  local top common main
  top=$(git rev-parse --show-toplevel 2>/dev/null) || return 1
  if [ -f "$top/.shipcrew/config.json" ]; then echo "$top/.shipcrew/config.json"; return 0; fi
  common=$(git rev-parse --git-common-dir 2>/dev/null) || return 1
  main=$(cd "$common/.." 2>/dev/null && pwd -P) || return 1
  [ -f "$main/.shipcrew/config.json" ] && { echo "$main/.shipcrew/config.json"; return 0; }
  return 1
}

# cfg '<jq filter>' '<default>'
cfg() {
  local v
  v=$(jq -r "$1" "$SHIPCREW_CONFIG" 2>/dev/null)
  if [ -z "$v" ] || [ "$v" = null ]; then printf '%s' "$2"; else printf '%s' "$v"; fi
}

shipcrew_types() {
  jq -r '(.policy.branchTypes // ["feat","fix","chore","refactor","docs","test"]) | join("|")' "$SHIPCREW_CONFIG"
}

# Branch-name regex built from policy.branchTypes.
shipcrew_branch_re() {
  printf '^(%s)/[A-Za-z0-9][A-Za-z0-9._-]*$' "$(shipcrew_types)"
}

shipcrew_is_exempt_branch() {
  local re; re=$(jq -r '.policy.exemptBranchPattern // empty' "$SHIPCREW_CONFIG" 2>/dev/null)
  [ -n "$re" ] && [[ "$1" =~ $re ]]
}
shipcrew_is_protected_branch() {
  jq -e --arg b "$1" '(.policy.protectedBranches // ["main","master","develop","development"]) | index($b)' "$SHIPCREW_CONFIG" >/dev/null 2>&1
}
