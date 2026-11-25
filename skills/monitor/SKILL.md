---
name: monitor
description: >-
  After a change is merged and deployed, reads the error tracker and logs for the change's monitoring
  points and release health and returns a verdict: healthy, watch, bad or too early. Report-only. Use
  when the user runs /shipcrew:monitor or the captain reaches the monitor phase.
disable-model-invocation: true
argument-hint: "<change> [<window, e.g. 24h>]"
---

# Monitor

Dispatch the `monitor` agent (`${CLAUDE_PLUGIN_ROOT}/agents/monitor.md`) or do it yourself. Read-only: never fix, roll back or change alerts.

1. Read `.shipcrew/plans/<change>/ticket.md`: the **Monitoring** table (feature tag, reasons, levels) and the **Rollback** section.
2. Find the release or deploy that contains the PR's merge commit, and its time. If it isn't deployed yet, verdict `too early` with the time to retry.
3. Query the project's error tracker with whatever is available (`monitoring.tool` in the config: an MCP server, a CLI, or logs). For the window since the deploy:
   - events carrying the feature tag, grouped by reason, against the table;
   - new issues in the release, and regressions of existing ones in the touched files;
   - error-rate or latency change on the touched endpoints compared to the same window before the deploy.
4. **Verdict:**
   - `healthy`: no feature events beyond what the table expects, no new issues attributable to the release.
   - `watch`: low-volume feature events or a small regression; recheck later.
   - `bad`: sustained feature events, a new high-volume issue, or an error-rate jump.
   - `too early`: not enough traffic or time since deploy.
5. Report: verdict, evidence (counts, issue links, release), reasons that fired and any that fired but weren't in the table (a coverage gap, record as a lesson candidate), and for `watch` or `bad` the ticket's Rollback section quoted. Save to `PLAN/reports/monitor.md`.

**No sensitive data in output:** report ids, titles, counts, culprits, releases and URLs. If an event title looks like it holds personal data, say so without quoting it. A question that needs rows becomes a read-only snippet for the user that returns aggregates.
