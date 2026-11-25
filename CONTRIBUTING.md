# Contributing

Thanks for helping. shipcrew is small on purpose: markdown skills and agents plus a few bash scripts.

## Before you open a PR

1. Run `scripts/selftest.sh`. It exercises the hooks and the gate in a throwaway repo. All checks must pass.
2. Run `scripts/scan-private.sh`. It must be clean: no absolute home paths, tokens, UUIDs, or names from a private project.
3. Run `bash -n` on any script you touched.
4. If you changed a skill or agent, say what behavior changed and why, and give an example run if you can.

## What fits

- Fixes to hooks and the gate, with a self-test case that fails before the fix.
- New adapters or examples (`examples/`, `docs/ADAPTERS.md`).
- Interview, review or triage improvements backed by a concrete failure you saw.
- Docs, in plain words.

## What doesn't

- Rules that only make sense for one company. Put them in your own lessons.
- Long instruction files. Every line an agent reads costs attention; prefer a script over a paragraph.
- Anything that weakens the untrusted-input or sensitive-data rules without a replacement.

## Style

- Markdown: short sentences, tables only for real structure, no filler.
- Bash: `set -u`, quote everything, no dependencies beyond `git`, `jq` and coreutils (`gh` optional).
- Commit messages: conventional (`fix(hooks): ...`). Don't add co-author or "generated with" lines.

## Conduct

Be kind and assume good faith. See [CODE_OF_CONDUCT.md](CODE_OF_CONDUCT.md).
