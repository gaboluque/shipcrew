# Customizing the crew

## Add or change a rule

- **A preference that came from a correction:** `/shipcrew:lesson <what went wrong>`. It lands in `.shipcrew/lessons/` and is read before every task.
- **A rule that is mechanical and checkable:** add it to a hook (`hooks/guard.sh`, `hooks/pre-push`) or to a check in `.shipcrew/config.json`, then mark its lesson `enforced` so agents stop spending context on it.
- **A rule about how an agent works:** edit that agent's file in `agents/`. Keep agent files short; long instruction files get ignored.

## Add a check to the gate

Add an entry to the app's `checks` in the config. Use the same command your CI runs. If it needs a prerequisite, set the app's `requires`.

## Add or rename roles

An agent is one markdown file in `agents/` with `name`, `description`, `model` and optionally `tools` in its frontmatter. To add a security reviewer, for example: copy `agents/reviewer.md`, narrow its lens, and have the captain dispatch it in phase 4 for risky diffs (add the step to `skills/ship/SKILL.md`). Names are yours: nothing in the plugin depends on them beyond the file names the skills reference.

## Use different models

The suggested models are in `skills/ship/SKILL.md` (table at the end) and each agent's frontmatter. Put the strongest model on the captain and the `full` reviews; the smallest on lookups and CI polling.

## Make the interview yours

`skills/ship/interview.md` is the checklist. Add questions that your domain always needs (data retention, localization, feature-flag policy, accessibility level).

## Change the ticket template

Edit `templates/ticket.md`. The captain fills whatever sections exist; sections you delete are simply not asked about. Keep **Acceptance criteria**, **Test strategy** and **Rollback**, because the reviewer and monitor read them.

## Turn a policy off

Set it in `policy`: for example `forbidAttribution: false` if your team wants co-author trailers, or `forbidNumericSuffix: false` if your branch names legitimately end in digits.

## Contribute a variant

Fork, change the skills, and run `scripts/selftest.sh` to confirm the hooks still pass. See [CONTRIBUTING.md](../CONTRIBUTING.md).
