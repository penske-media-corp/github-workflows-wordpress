# github-workflows-wordpress

Public repository of reusable GitHub Actions workflows (`.github/workflows/`, all `on: workflow_call`), composite
actions (`composites/`), and example caller workflows (`templates/`) for PMC's WordPress repositories (pmc-plugins,
the brand themes, pmc-larva). There is no package manager, build, test suite, git hook, or CI of its own: nothing
here runs on this repository. See [`README.md`](README.md) for purpose and usage.

## Non-negotiables

- **Merging to `main` ships immediately to every consumer.** Consumers reference `@main`, with no tags or versions.
  Every change must stay backward compatible for existing callers: never remove or rename a workflow, composite,
  input, secret, output, or a job/workflow `name:` that consumers rely on. Add new inputs as optional with a
  default. Details in [`.github/workflows/AGENTS.md`](.github/workflows/AGENTS.md).
- **Public repository.** Never commit secrets, tokens, credentials, private hostnames, or internal-only data.
  Secrets reach workflows only through `secrets:` (reusable workflows) or inputs (composites).
- **Some paths deploy to production or write to external systems:** `composites/sync-vip-prod` (pushes to live VIP
  branches, `master` or `production`), `build-larva.yml` (empties and refills an S3 bucket), `vercel.yml` (`--prod`
  deploys on `main`/`master`), `stale-prs.yml` and `jira-sync.yml` (close PRs, change Jira issues). Never point them
  at real destinations to test, and call out changes to them in the PR.
- `@penske-media-corp/wp-admins` owns all paths ([`.github/CODEOWNERS`](.github/CODEOWNERS)) and is requested for
  review automatically. Get their review before merging.
- Don't interpolate `${{ }}` expressions holding caller, event, or ref-name data (inputs, PR fields,
  `github.ref_name`, `github.head_ref`) directly into `run:` scripts; pass them through `env:` (rule
  `actions-run-steps`).

## Verify a change

- Run `actionlint` on `.github/workflows/`. It also runs shellcheck on `run:` blocks when shellcheck is installed.
  These are the tools PR QA has used; nothing in the repo enforces them. Some workflows already have findings, so
  require **no new findings in the files you changed**, and don't fix unrelated findings as drive-bys.
- `actionlint` does not understand composite `action.yml` files; review them by hand against rule
  `composite-actions`.
- Run `shellcheck composites/enforce-pmc-scripts/enforce-pmc-scripts.sh` for the composite script (currently clean).
- Behavioural check: exercise the change from a consumer repo by pointing its `uses:` at your branch
  (`...@<branch>`) on a throwaway branch or PR. Never test deploy, Jira, or stale-PR paths against real targets;
  `stale-prs.yml` defaults to `dry_run: true`. For the composite script, a scratch git repo works locally (see
  `composites/enforce-pmc-scripts/AGENTS.md`).

## Definition of Done

- [ ] Backward compatible for existing `@main` callers, or every consumer is updated first and the PR says so.
- [ ] No new `actionlint` findings in changed workflow files; `shellcheck` clean for changed scripts.
- [ ] `templates/` and `README.md` updated when inputs, secrets, or usage change.
- [ ] PR follows the org template (Summary, Issue URL or additional context, QA evidence, Notes for Reviewers).
- [ ] Agent instructions are still true: if this change adds, renames, or removes a command, directory, convention,
  workflow, version pin, or known footgun, the instruction files covering it are created or updated in the same PR
  (see "Keeping instructions current").

## Layout and scoped instructions

Nested files add to this one and win for their scope. Read them before editing in their directory.

- `.github/workflows/`: reusable workflows. Read [`.github/workflows/AGENTS.md`](.github/workflows/AGENTS.md) before
  editing any workflow.
- `composites/<name>/`: composite actions, each with an `action.yml`. Read
  [`composites/sync-vip-prod/AGENTS.md`](composites/sync-vip-prod/AGENTS.md) or
  [`composites/enforce-pmc-scripts/AGENTS.md`](composites/enforce-pmc-scripts/AGENTS.md) before editing those.
- `templates/`: example caller workflows, never run here. Read [`templates/AGENTS.md`](templates/AGENTS.md).
- Path-scoped rules: canonical files in `.agents/rules/`. Claude Code and Cursor load the generated `.claude/rules/`
  and `.cursor/rules/` views by glob. Codex gets no rule view, so this list is how it finds them:
  - [`.agents/rules/actions-run-steps.md`](.agents/rules/actions-run-steps.md) (globs `.github/workflows/**/*.yml`,
    `composites/**/action.yml`): read it before editing matching files.
  - [`.agents/rules/composite-actions.md`](.agents/rules/composite-actions.md) (glob `composites/**/action.yml`):
    read it before editing matching files.

## Keeping instructions current

Instruction files are part of the code: a change that makes one wrong, or leaves new behavior undocumented, is not
done until it's fixed.

- Check what covers the paths you changed: this file, the `AGENTS.md` in each changed directory and its parents, and
  every `.agents/rules/*.md` whose `globs:` match a changed file.
- Fix or delete any line your change made false (commands, paths, versions, flags, workflow names, owners). Find
  leftovers of renamed or removed names with `git grep -n '<old-name>' -- '*AGENTS.md' '.agents/rules/'`.
- Create new instruction files when warranted; you don't need to be asked:
  - a directory with its own commands, runtime, or footguns gets a nested `AGENTS.md`;
  - a convention that spans directories gets a `.agents/rules/<topic>.md` with `globs:`;
  - only repo-wide facts go in this file, kept short.

  List every new file in "Layout and scoped instructions" (Codex finds rules only through that list), and keep its
  rule entries and globs current when a rule is renamed, removed, or re-globbed.
- After creating or changing a rule, run `npx @open-agent-toolkit/cli sync --scope project` and commit the rule, the
  generated views, and `.oat/sync/manifest.json` together (details in "Instruction rules (OAT sync)").
- Record durable facts an agent would otherwise get wrong; leave out task notes and guesses.
- In the PR description, list the instruction files you created or updated, or write "No instruction changes
  needed".

## Cross-repo dependencies

Code these workflows rely on but that lives elsewhere. The setup action and pmc-github-actions are referenced at
`@main`; pmc-jenkins-scripts and pmc-ai-pr-summarizer are checked out with no `ref` (their default branch). Check
those repos before assuming their behaviour.

- `penske-media-corp/github-action-wordpress-test-setup`: the "Prepare environment" step. The `pmc-manifest` and
  `pmc-test-*` commands the CI workflows source are not defined in this repo and are only used after that step, so
  they presumably come from it.
- `penske-media-corp/pmc-github-actions`: the Checkly QAT action and the nested `pmc-qa-vip-go` workflow.
- `penske-media-corp/pmc-jenkins-scripts`: the sync helpers used by `composites/sync-vip-prod`.
- `penske-media-corp/pmc-ai-pr-summarizer`: checked out and run by `pmc-ai-pr-summarizer.yml`.

## Commits and PRs

- Squash merge only. The subject is imperative and may start with a Jira key (`PUB-123: Add ...`).
- The PR body uses the org template sections; this repo has no template of its own.

## Instruction rules (OAT sync)

- Author path-scoped rules only in `.agents/rules/*.md` (frontmatter `activation: glob`, `globs`, `description`).
- `npx @open-agent-toolkit/cli sync --scope project` regenerates the provider views: `.claude/rules/*.md`,
  `.cursor/rules/*.mdc`, `.codex/config.toml`. Providers are set in
  [`.oat/sync/config.json`](.oat/sync/config.json).
- Never hand-edit generated files (the `.claude/rules/` and `.cursor/rules/` views end with an `OAT-managed`
  comment; `.codex/config.toml` has no marker). Edit the canonical rule and sync again.
- `npx @open-agent-toolkit/cli sync --scope project --dry-run` must end with "No changes to apply." before you
  push. `skip ... (already in sync)` lines are expected; any other planned write is drift.

## References

- [`README.md`](README.md): purpose, the setup-action dependency, using the templates, stale-PR behaviour.
- [`.github/workflows/AGENTS.md`](.github/workflows/AGENTS.md): interface contract and workflow catalog.
- [`templates/`](templates/): example callers.
