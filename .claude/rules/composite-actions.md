---
paths:
  - composites/**/action.yml
---

# Composite actions (composites/<name>/action.yml)

Examples: [`enforce-pmc-scripts/action.yml`](../../composites/enforce-pmc-scripts/action.yml),
[`sync-vip-prod/action.yml`](../../composites/sync-vip-prod/action.yml).

## Shape

- One composite per directory: `composites/<name>/action.yml`, plus any scripts or data files it needs next to it.
- Consumers call `penske-media-corp/github-workflows-wordpress/composites/<name>@main`, so the directory name is public
  API. Never rename or remove it.
- `runs.using: composite`, and every `run` step declares `shell: bash`. GitHub won't load the action without it.
- Pin third-party actions used inside a composite to a version tag, as the existing steps do.

## Inputs and secrets

- Composite actions have no `secrets` context. Take secrets as inputs (UPPER_CASE names, as with `SSH_KEY`), and
  never print them. Callers pass `${{ secrets.* }}` into those inputs.
- Mark a secret input `required` only if every caller already passes it.
- Inputs are strings: compare booleans as strings (`'true'`).
- New inputs are optional with a default, because consumers are pinned to `@main`.

## Files and paths

- Reference sibling files as `${{ github.action_path }}/<file>`. This is how the repo ships scripts to callers.
- The working directory is the caller's workspace (`$GITHUB_WORKSPACE`), not the action directory.
- A composite with its own script, an external checkout, or side effects gets a nested `AGENTS.md` (see
  `composites/sync-vip-prod/AGENTS.md` and `composites/enforce-pmc-scripts/AGENTS.md`).

## Checking your change

- `actionlint` cannot check `action.yml` (it reports a missing `jobs` section). Review by hand against this rule and
  rule `actions-run-steps`.
- Run `shellcheck` on any sibling script.
- Exercise it from a consumer branch with `.../composites/<name>@<branch>`.

## Adding a composite

1. Create `composites/<name>/action.yml` with `name`, `description`, `inputs`, and `runs.using: composite`.
2. Put scripts next to it and call them through `${{ github.action_path }}`.
3. Add a caller example to `templates/` and a `README.md` note; add a nested `AGENTS.md` if it has runtime footguns.
4. Exercise it from a consumer branch with `.../composites/<name>@<branch>`.

## Counter-examples

- `run: ./enforce.sh`: resolves against the caller's working directory, not the action directory.
- `env: TOKEN: ${{ secrets.TOKEN }}` inside a composite step: there is no `secrets` context; pass it as an input.
- A `run` step without `shell:`: the action fails to load.

Reference: [Creating a composite action](https://docs.github.com/en/actions/sharing-automations/creating-actions/creating-a-composite-action).

<!-- OAT-managed: do not edit directly. Source: .agents/rules/composite-actions.md -->
