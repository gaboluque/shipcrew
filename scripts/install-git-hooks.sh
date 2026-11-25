#!/usr/bin/env bash
# Installs the git hooks (commit-msg, pre-push) into the current repo's shared hooks dir.
# Git hooks cannot be declared by a plugin, so run this once per clone (/shipcrew:init does it).
set -eu
ROOT=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd -P)
chmod +x "$ROOT"/hooks/*.sh "$ROOT"/hooks/commit-msg "$ROOT"/hooks/pre-push "$ROOT"/scripts/*.sh
common=$(git rev-parse --git-common-dir); d="$common/hooks"; mkdir -p "$d"
for h in commit-msg pre-push; do
  f="$d/$h"
  if [ -e "$f" ] && ! grep -q 'shipcrew-hook' "$f"; then
    echo "skip $h: a non-shipcrew hook already exists at $f" >&2; continue
  fi
  printf '#!/usr/bin/env bash\n# shipcrew-hook\nexport SHIPCREW_ROOT="%s/hooks"\nexec "%s/hooks/%s" "$@"\n' "$ROOT" "$ROOT" "$h" > "$f"
  chmod +x "$f"; echo "installed $h in $d"
done
