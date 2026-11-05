# .github/workflows: reusable workflows

Every file here is a reusable workflow (`on: workflow_call` only) called by consumer repositories at `@main`. This
file adds to the root `AGENTS.md`; its non-negotiables still apply. Shell and expression rules for `run:` steps are
in [`.agents/rules/actions-run-steps.md`](../../.agents/rules/actions-run-steps.md).

## Interface contract

- `on.workflow_call` (inputs, secrets, outputs) plus workflow and job `name:` values are a public API. Make additive
  changes only.
- A new input must be `required: false` with a `default` that keeps today's behaviour. Don't combine
  `required: true` with `default:`: the default is never used, and actionlint flags it.
- Declare every secret explicitly. A new secret must be `required: false` unless every consumer is updated first.
  Callers pass secrets one by one; never rely on `secrets: inherit`.
- Check names are `<caller job name> / <job name>`, and consumers use them as required status checks in branch
  protection (for example `Linting / PHP: current` and `Unit Tests / PHP: current, WP: latest`). Never rename job
  `name:` values (`JS`, `PHP`, `Code Quality`, `Assets`, ...) or the matrix labels `current` / `latest`.
- Never delete a workflow file. That includes `build.yml`, a no-op placeholder (`if: false`, "Not implemented")
  that pmc-plugins and `templates/pmc.yml` still call.
- Don't "fix" the `VERCEL_ORG_SlUG` input spelling in `vercel.yml` (lower-case `l`): callers pass that exact name.

## Runs in the caller's repo

- Inside a reusable workflow, `github.repository`, `github.event`, and `actions/checkout` refer to the **caller**.
  Files in this repo are not in the caller's checkout. Scripts must come from a composite (through
  `${{ github.action_path }}`, see [`composites/enforce-pmc-scripts/`](../../composites/enforce-pmc-scripts/)) or
  from the setup action.
- Keep the pmc-plugins special cases intact: `coding-standards.yml` skips the text-domain step for pmc-plugins,
  `unit-tests.yml` gives it the `ubuntu-latest-4-cores` runner, and `PMC_IS_PMC_PLUGINS` switches the PHPUnit working
  directory. That variable is not defined in this repo; it is presumably exported by the setup action.
- Keep the existing `if: ${{ github.repository != 'penske-media-corp/github-workflows-wordpress' }}` guards. New jobs
  don't need one, because nothing in this repo calls these workflows.

## Shared CI plumbing

- CI jobs (coding standards, linting, unit tests) start with "Prepare environment"
  (`penske-media-corp/github-action-wordpress-test-setup@main`) and end with `git diff --exit-code`.
- The check step's command sequence depends on the job kind. The `pmc-*` commands are not defined in this repo; they
  presumably come from the setup action. Copy the sequence of the closest existing job of the same kind, and don't
  add steps that job never had:
  - PHP checks (phpcs, phplint, phpunit): `. pmc-manifest`, then `. pmc-test-phpcs` / `. pmc-test-phplint` /
    `. pmc-test-phpunit`.
  - eslint: `. "$NVM_DIR/nvm.sh" --no-use`, `. pmc-manifest`, `nvm use`, `. pmc-test-eslint`.
  - Jest (`npm test`): `. "$NVM_DIR/nvm.sh" --no-use`, then `. pmc-test-npm`, without `pmc-manifest`.
- New jobs get top-level least-privilege `permissions:`, a `concurrency` group of
  `${{ github.ref_name || github.run_id }}-<workflow>-<job>` (CI jobs use `cancel-in-progress: true`), and
  `timeout-minutes`.

## Version defaults

- The PHP default (`'8.4'`) is set in three files: `coding-standards.yml`, `linting.yml`, and `unit-tests.yml`.
  Change all three together.
- The WordPress default in `unit-tests.yml` must have a row in its Jetpack pinning table ("Keep this table
  current"). When you change the WordPress default, add or update the Jetpack row in the same PR; an unmatched
  version falls through to "No Jetpack pinning needed" and may break Jetpack-gated tests.

## Workflow catalog

| File | What it does | Side effects / risk | Template |
| --- | --- | --- | --- |
| `build.yml` | Placeholder `Assets` job, disabled with `if: false` | None; still called, never delete | `templates/pmc.yml` |
| `build-larva.yml` | Builds larva HTML and publishes it to S3 | Assumes an IAM role, `aws s3 rm --recursive`, then uploads | none |
| `coding-standards.yml` | PHPCS | None | `templates/pmc.yml` |
| `linting.yml` | PHP lint; JS job runs the `enforce-pmc-scripts` composite and eslint | None | `templates/pmc.yml` |
| `unit-tests.yml` | PHPUnit, Jest, then Sonar code quality | Sends coverage to SonarCloud | `templates/pmc.yml` |
| `pmc-ai-pr-summarizer.yml` | Checks out `pmc-ai-pr-summarizer` by SSH key and runs it | Runs external code with `pull-requests: write` | `templates/pmc.yml` |
| `jira-sync.yml` | Creates a Jira ticket on a trigger label; moves it when the PR closes | Creates and transitions Jira issues | none |
| `stale-prs.yml` | Marks and closes stale PRs and their linked Jira tickets | Closes PRs and tickets; `dry_run` defaults to `true` | `templates/pmc-stale-prs.yml` |
| `pmc-qa-vip-go.yml` | Validates `THEME_NAME`, then calls `pmc-github-actions`' workflow | Uses `JENKINS_BUILD_TOKEN` | none |
| `qat.yml` | Checkly Playwright checks against the QA site for the branch | Comments on PRs | none |
| `vercel.yml` | Vercel build and deploy | `--prod` on `main`/`master`; build-log fetch on failure | none |

- Workflows that write to external systems must keep or add a dry-run or explicit opt-in path. `stale-prs.yml`
  defaults to `dry_run: true`; consumers go live with the repo variable `STALE_PRS_LIVE` (see the "Stale PRs"
  section of [`README.md`](../../README.md)).
- `jira-sync.yml` targets the PUB project's custom fields and finds its own ticket through a
  `<!-- jira-key:KEY -->` comment marker; keep both when editing it.

## Adding or changing a workflow

1. Create `.github/workflows/<name>.yml` with only `on: workflow_call`. Declare every input (type, description,
   optional with a default where possible) and every secret explicitly.
2. Add top-level `permissions:`, and `concurrency` and `timeout-minutes` on jobs. Route values into `run:` through
   `env:` (rule `actions-run-steps`).
3. Run `actionlint .github/workflows/<name>.yml`; changed files must have no new findings.
4. Add a caller example to [`templates/`](../../templates/) (a new file or a job in `templates/pmc.yml`) and a
   `README.md` note if usage is non-obvious.
5. Exercise it from a consumer branch with
   `uses: penske-media-corp/github-workflows-wordpress/.github/workflows/<name>.yml@<branch>`.

Counter-examples: adding `secrets: inherit` or a new required secret (consumers break or over-share); renaming
`job_label: current` to `php-8.4` (required checks never report); `run: ./scripts/check.sh` (the script is not in
the caller's checkout).
