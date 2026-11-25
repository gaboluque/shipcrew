# Lessons

Every time the user corrects the crew, the correction becomes a written rule that every crew member reads before its next task. `/shipcrew:init` copies this folder to `.shipcrew/lessons/` in your repo; add your own rules there (commit them if the team should share them).

| File | Holds | Read by |
|---|---|---|
| `shared.md` | Rules for everyone (tone, git, tickets, reporting) | Every agent |
| `captain.md` | The main session's rules | The captain |
| `implementer.md` | Build rules | Implementers, and the reviewer (who flags repeats) |
| `reviewer.md` | Review rules | The reviewer |
| `triager.md` | Triage rules | The triager |
| `tester.md`, `monitor.md` | Their rules | Those agents |

Format, statuses, promotion and the monthly prune are described in `skills/lesson/SKILL.md`. Keep `shared.md` short: it is read before every task.
