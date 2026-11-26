# PR body

Used by the captain when opening a PR. The body follows the repo's own template **exactly** (sections, headings, casing, emoji) and stays as short as possible while answering: what changed, why it's safe to deploy, and what to run after deploy.

## 1. Find the repo's template

Look in this order, relative to the git root (and the changed app's folder in a monorepo; an app's template beats the root one):

1. `pull_request_template.md` / `PULL_REQUEST_TEMPLATE.md`, in `.github/`, the repo root or `docs/`, in the app folder first, then the root.
2. A `PULL_REQUEST_TEMPLATE/` folder next to those: pick the one that fits the change; if several fit, ask.
3. None found: use the fallback below.

Re-read the template at write time (they drift). Copy its headings verbatim. Never invent, rename, reorder or drop a section.

## 2. Fill it

- Delete template helper text and example bullets. Never ship them.
- **Context**: one sentence with the ticket link. Don't restate the title.
- **What changed / Done in this PR**: 3-5 bullets max, each one shippable concern, not one file. Lead with the user-visible change. Backtick class, method and task names.
- **Deploy section**: keep the template's checkbox lines as-is, check the ones that apply, leave the rest unchecked. Under them list post-deploy tasks (maintenance tasks, rake tasks, manual steps), one per line, and a final follow-up bullet when relevant.
- **QA / Testing steps / Screenshots**: only if the template has them; fill only what a reviewer can't infer from the diff.
- Never add: Summary, Background, Implementation notes, "Review feedback addressed", tables, diagrams, marketing copy, anything about stacking ("stacked on #N", "part 2 of 3"), or any mention of tests added or changed.
- No false claims: compare every bullet with `git diff origin/<baseBranch>..HEAD --stat` and the code. Delete (don't soften) anything the diff doesn't support.
- Aim for 15 lines of content or fewer, excluding template scaffolding.
- No attribution lines unless the user's own instructions ask for them.

## 3. Fallback (no template in the repo)

```markdown
## Context

<one sentence with the ticket link>

## Done in this PR

- <user-visible change>

## Deploy Concerns

- [ ] No migrations
- [ ] No rake tasks / manual steps to run post-deploy
- [ ] No environment variables to add

After deploy:

- <task, if any>
```

## 4. Write it

Save the body to `<git root>/.tmp/pr_body.md` (create `.tmp/` if missing) and pass `--body-file`; multi-line `--body` strings break shell allowlists. Create with `gh pr create --draft --body-file ...`, update with `gh pr edit <n> --body-file ...`.

## Example

```markdown
## Context

This PR addresses [this task](https://tracker.example/ADHD-new-product-types).

## Done in this PR

- Added 3 new ADHD product types: `AdhdHealthAssessmentVideoCall`, `AdhdDiagnosisVideoCall`, `AdhdFollowUpVideoCall`.
- Gated the new products by journey: legacy patients see only follow-ups; new-journey patients walk through visits sequentially.
- Added maintenance tasks: `CreateAdhdFollowUpProductsTask`, `CopyAdhdProvidersToNewFollowUpProductsTask`.

## Deploy Concerns

- [x] No migrations
- [ ] No rake tasks to run post-deploy
- [x] No environment variables to add

After deploy:

- `Maintenance::CreateAdhdFollowUpProductsTask`
- `Maintenance::CopyAdhdProvidersToNewFollowUpProductsTask`
- Create cleanup ticket for legacy stuff
```
