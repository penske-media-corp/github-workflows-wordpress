# composites/enforce-pmc-scripts

The "Enforce TypeScript" gate. [`linting.yml`](../../.github/workflows/linting.yml) runs it in the `JS` job of every
linting consumer, so a change here changes every consumer's `Linting / JS` check at once. Adds to the root
`AGENTS.md` and rule `composite-actions`.

## What it enforces

Both checks compare against `origin/<default branch>` and only look at **added** files (`--diff-filter=A`).

1. Newly added `.js`/`.jsx` files must be TypeScript, when the file's package is a qualifying wp-scripts package.
2. Two separate `package.json` checks. Both require the file to contain `@penskemediacorp/wordpress-scripts` and
   `pmc-scripts`:
   - newly added `*/package.json` files;
   - the qualifying `package.json` that owns each newly added JS file.

Package lookup walks up from the new JS file's directory and stops at the **first** directory that has any
`package.json`. That file qualifies only if its `dependencies` or `devDependencies` declare `@wordpress/scripts` or
`@penskemediacorp/wordpress-scripts`. If it doesn't, the JS file is skipped: the script does not keep walking to a
qualifying ancestor. With no `package.json` found, the walk stops at `.`, or, for pmc-plugins, at the top-level
plugin directory. Changing this lookup is a behaviour change for every consumer; call it out in the PR.

## Runtime gotchas

- [`action.yml`](action.yml) **sources** [`enforce-pmc-scripts.sh`](enforce-pmc-scripts.sh) into the step's bash
  through `${{ github.action_path }}`; it is not executed as a separate process. `set -e`, `exit`, and any variable it
  sets affect that shell. Keep it safe to source: no `cd` without returning, and no unguarded `exit 0` before the
  checks.
- It runs in the **caller's** checkout and working directory.
- Inputs come from the environment, not composite inputs: `DEFAULT_BRANCH` (from the PR base ref, with a
  `git ls-remote --symref` fallback) and the caller's optional `.pmc-scripts` file, whose `JS_IGNORE_PATTERNS` is an
  extended regex applied with `grep -v -E`. Changing the `.pmc-scripts` format or the variable name breaks
  pmc-plugins' ignore list.
- It needs a git `origin` and network access: the script runs `git fetch origin <default>` itself. The `JS` job in
  `linting.yml` does not pass `git_checkout_fetch_depth: 0` (the PHP job does). It also needs `jq`.
- Error messages (`TypeScript is required for the following JS file(s):`, `Build script needs to use
  @penskemediacorp/wordpress-scripts package:`) are what developers see in consumer CI. Keep them actionable.

## Editing the script

- The with-ignore and without-ignore command pairs are duplicated, both for new JS files and for new `package.json`
  files. Edit both branches together. They already differ: only the no-ignore branch's JS pathspec includes
  `*.jsx` and `*.tsx`, so new `.jsx` files are not flagged when ignore patterns are set.
- Keep the pmc-plugins top-level-directory stop and the `vendor/`, `.cache/`, `node_modules/`, and `build/`
  exclusions.
- Counter-example: converting the step to `run: bash .../enforce-pmc-scripts.sh` without moving `DEFAULT_BRANCH`
  into `env:`. The variable is then no longer visible to the script.

## Testing

1. Run `shellcheck composites/enforce-pmc-scripts/enforce-pmc-scripts.sh` (currently clean).
2. Reproduce the approach from [PR #71](https://github.com/penske-media-corp/github-workflows-wordpress/pull/71): a
   scratch git repo with an `origin`, a default branch, and a feature branch that adds `.js`, `.ts`, and
   `package.json` files. Run the script with and without a `.pmc-scripts` file, and compare old and new output.
3. Optionally run it from a consumer PR by pointing `linting.yml`'s composite ref at your branch (this needs a
   workflow branch too). Never test by pushing to `main`.
