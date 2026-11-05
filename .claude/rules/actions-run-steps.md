---
paths:
  - .github/workflows/**/*.yml
  - composites/**/action.yml
---

# Run steps in workflows and composite actions

Applies to every `run:` step in `.github/workflows/*.yml` and `composites/*/action.yml`. These steps run in
consumer repositories, so the values they handle come from callers and events, not from this repo.

## Pass values through env

- Never put free-text or ref-name expressions directly in `run:`. That covers `github.event.*` text fields (PR or
  issue title and body, comment body, label names, commit messages) and branch/ref names (`github.ref_name`,
  `github.head_ref`, `github.ref`, `github.event.pull_request.head.ref`). Git ref names can contain shell
  metacharacters such as `$`, `(`, `)` and backticks. Map them into `env:` and use `"$VAR"`.
- New and edited steps also pass `inputs.*`, `matrix.*`, and `steps.*.outputs.*` through `env:`, as
  [`jira-sync.yml`](../../.github/workflows/jira-sync.yml) and [`stale-prs.yml`](../../.github/workflows/stale-prs.yml)
  do. Existing inline uses in steps you don't touch can stay; convert a step when you edit it.
- Whether the existing inline uses can be exploited has not been assessed. It depends on caller-supplied values,
  triggers (for example `workflow_dispatch` on arbitrary refs), and permissions. Don't describe them as either safe
  or exploitable.

Good:

```yaml
- name: Create ticket
  env:
    PR_TITLE: ${{ github.event.pull_request.title }}
    PROJECT_KEY: ${{ inputs.project_key }}
  run: |
    echo "Creating $PROJECT_KEY ticket for: $PR_TITLE"
```

Bad: `run: echo "${{ github.event.pull_request.title }}"`.

## Shell hygiene

- Quote shell expansions (`"$VAR"`). The existing shellcheck SC2086 findings are not a pattern to copy.
- Write step outputs to `"$GITHUB_OUTPUT"`, values for later steps to `"$GITHUB_ENV"`, summaries to
  `"$GITHUB_STEP_SUMMARY"`, and scratch files under `"$RUNNER_TEMP"`.
- HTTP calls: use `curl -sS --fail-with-body`, or check the status code and print the response body on failure, as
  `jira-sync.yml` does. Use `::error::` / `::warning::` for annotations.
- In composite actions every `run` step needs `shell: bash` (rule `composite-actions`).
- Check workflows with `actionlint`. It cannot parse composite `action.yml` files; review those by hand.

## Secrets

- Map secrets into `env:` (step or job level) and reference `$VAR`.
- Never echo a secret or put it in command text that is printed. Never use `set -x` in a step that holds secrets.

## Counter-example

- `run: git push origin ${{ inputs.destination_branch }}` in a new step: a caller-supplied value becomes shell syntax.
- `VERCEL_CMD="npx vercel --token ${{ secrets.VERCEL_TOKEN }}"`: the secret is part of the command text (today's
  `vercel.yml` build-log step; don't copy it).

Reference: [GitHub security hardening: script injections](https://docs.github.com/en/actions/security-for-github-actions/security-guides/security-hardening-for-github-actions#understanding-the-risk-of-script-injections).

<!-- OAT-managed: do not edit directly. Source: .agents/rules/actions-run-steps.md -->
