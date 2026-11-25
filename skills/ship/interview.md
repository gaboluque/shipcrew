# Interview guide

Used by the captain in phase 1. The goal is a ticket nobody has to guess at. You ask, the user decides.

## Method

1. **Read first.** Start from `ticket-source.md`. Send read-only subagents to answer what the code can answer (where is X, what does Y return, does a helper exist). Never ask the user something you can look up.
2. **One question at a time.** At most two lines of context, then the question. Offer options when they exist, mark your recommendation, and say why in one clause. Number the question.
3. **Walk the decision tree.** Resolve a branch before moving to the next one. Stop at 15 questions and list what's left under **Open questions** in `ticket.md`.
4. **Don't restate** the ticket or recap what you checked.

## What to settle

- **Problem and outcome:** who is affected, what changes for them, how we'll know it worked.
- **Acceptance criteria:** each one observable and testable.
- **Out of scope:** what the user explicitly doesn't want.
- **States next to the happy path:** empty, expired, repeated, already-done, retry, partial failure, and every case a new rule implies.
- **Interfaces:** when two apps or services are touched, the request and response shapes, status codes and error cases, agreed before anyone builds.
- **Data:** migrations, backfills (reversible? in batches? who approves?), anything that touches sensitive data.
- **Rollback and flags:** can the change be reverted alone? Does it need a flag, and off by default?
- **Monitoring:** where would this fail in production, and what event would show it?
- **Ownership:** which implementer owns which part. If the work touches a part of the codebase no implementer owns, stop and ask.

## Design interview (any change a user sees)

Ask for a design first: image, mockup, annotated screenshot, or a detailed description. Then settle, using the code to answer what it can:

1. Every new or changed screen and component, and which existing components to reuse.
2. States the design doesn't show: loading, empty, error, success, disabled, partial data.
3. Exact copy, including errors and empty states. Placeholder text isn't final until the user says so.
4. Responsive behavior and accessibility basics (focus, labels, contrast, keyboard).
5. Analytics events, if the team tracks them.

The design interview has no question cap and must finish before G1.
