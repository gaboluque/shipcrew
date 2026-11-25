#!/usr/bin/env bash
# Fails if the repo contains strings that identify a private source: absolute home paths, tokens, UUIDs.
# Add your own patterns (company name, internal hostnames, ticket prefixes) to .scanignore-patterns,
# one regex per line. That file is git-ignored on purpose: it names what you are scrubbing.
set -u
cd "$(dirname "${BASH_SOURCE[0]}")/.."
pat='/Users/[a-z]|/home/[a-z]+/|AKIA[0-9A-Z]{16}|ghp_[A-Za-z0-9]{20,}|xox[bp]-|sk-[A-Za-z0-9]{20,}|[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}'
[ -f .scanignore-patterns ] && pat="$pat|$(paste -sd'|' .scanignore-patterns)"
if grep -rInE "$pat" --exclude-dir=.git --exclude=scan-private.sh --exclude=.scanignore-patterns . ; then
  echo "scan-private: matches found above." >&2; exit 1
fi
echo "scan-private: clean"
