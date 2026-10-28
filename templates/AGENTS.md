# templates: example caller workflows

Example workflows for consuming repositories to copy (see "Using the workflows" in [`README.md`](../README.md)).
They are not under `.github/workflows/`, so GitHub never runs them here, and consumers keep their own copies. Adds to
the root `AGENTS.md`; the workflow interface rules are in
[`.github/workflows/AGENTS.md`](../.github/workflows/AGENTS.md).

## Rules

- These files are documentation. Editing them changes no consumer, and nothing validates them here.
- Keep each template in step with the workflow or composite it calls. When you add or change an input, secret, or
  required permission in `.github/workflows/` or `composites/`, update the matching template in the same PR. Check
  that every `required: true` input and secret in the target's `on.workflow_call` (or composite `inputs`) is passed.
- Use `@main` refs, as real consumers do. Map consumer secret names explicitly (for example
  `GITHUB_READ_ONLY_SSH_KEY: ${{ secrets.PMC_GITHUB_ACTION_SSH_KEY }}`), and never use `secrets: inherit`.
- Keep placeholders obvious (`[REPO SLUG]`, `replace-me`). Never put real repository slugs, hostnames, or secret
  values in a template: this is a public repository.
- Templates for workflows with side effects keep the dry-run or opt-in gating. `pmc-stale-prs.yml` stays a dry run
  until the consumer sets the `STALE_PRS_LIVE` variable to `true` (see "Stale PRs" in [`README.md`](../README.md)).
- Run `actionlint templates/<file>.yml` for syntax and expression errors. It does **not** check inputs or secrets
  against the called workflow (the `owner/repo/...@main` refs are remote to it), so verify those by hand.

## Coverage

- `pmc.yml`: build, coding-standards, linting, AI PR summarizer, unit-tests.
- `pmc-stale-prs.yml`: stale-prs.
- `vip-go-sync-prod.yml`: the `composites/sync-vip-prod` action.
- No example yet for `build-larva`, `qat`, `vercel`, `jira-sync`, or `pmc-qa-vip-go`. When you add a reusable
  workflow, add an example here or extend `pmc.yml`.

## Adding a template

1. Copy the closest existing template and reference `penske-media-corp/github-workflows-wordpress/...@main`.
2. Pass every required input and secret explicitly. Add a comment for any repo variable that gates behaviour.
3. Mention the template in `README.md` if the workflow needs setup beyond copying.

Counter-examples: adding a required input to `unit-tests.yml` and leaving `pmc.yml` unchanged; replacing
`replace-me` with a real brand's directory.
