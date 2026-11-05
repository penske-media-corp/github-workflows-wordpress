# composites/sync-vip-prod

Composite action that syncs the caller repository into a `wpcomvip/*` repository and pushes the result. It is the
production deploy path for pmc-plugins and the brand themes. Adds to the root `AGENTS.md` and rule
`composite-actions`.

## Non-negotiables

- Any change ships on the consumers' next push to `main` and pushes to live VIP branches (`master` for most brands,
  `production` for some; see each caller's matrix).
- Never run or test it against any real `wpcomvip/*` repository, whatever the branch.
- Don't add force-push, history rewrites, or deletion outside the destination directory. Keep the
  "No changes to commit" early exit.
- `SSH_KEY` needs read/write access to `destination_repo` (the action pushes there) and read access to
  `penske-media-corp/pmc-jenkins-scripts`. The caller (source) repository is checked out with the default job token,
  not this key. The input's own description ("access to source and destination repositories") does not match the
  code; don't repeat it.
- Never echo the key or other inputs, including in the debug listing.

## How it works

See [`action.yml`](action.yml).

1. Three checkouts under `$GITHUB_WORKSPACE`: the caller repository into `source/` (shallow, job token), the
   destination repository and branch into `dest/` (`SSH_KEY`), and `penske-media-corp/pmc-jenkins-scripts` at its
   default branch into `jenkins-scripts/` (`SSH_KEY`). The helpers receive these fixed sibling paths as arguments.
2. A debug step lists those directories only when the run has debug logging on (`runner.debug == '1'`).
3. The sync step sources `jenkins-scripts/bin/functions.sh`, sets the commit identity (`pmcvipgo-sync` and
   `GIT_EMAIL`), creates `destination_directory` if needed, and calls `exclude_plugins`, `rsync_repo_files`,
   `restore_plugins`, and `setup_git_committer`.
4. It stages everything in `dest/`, exits 0 if nothing changed, then commits and pushes to `destination_branch`.
5. On failure, when `SLACK_WEBHOOK_URL` is set, it looks up the job URL through the GitHub API and posts
   [`slack-payload.json`](slack-payload.json) with `slackapi/slack-github-action`.

## Contract with pmc-jenkins-scripts

- The sync semantics come from the external helpers in `pmc-jenkins-scripts/bin/functions.sh`. Their code is not in
  this repository; check that repository before assuming what they do.
- The variables look like an implicit contract with those helpers (inferred, not verified here):
  `EXCLUDE_DIRECTORIES` is set from `protected_directories` but never read in this file, and `REVISION` and `AUTHOR`
  are used in the commit message but never set here. Don't rename or remove them without checking that repository.
- Counter-example: passing `${{ inputs.protected_directories }}` to a new helper call instead of the existing
  `EXCLUDE_DIRECTORIES` variable, or renaming that variable. The helpers may silently stop protecting brand plugins.

## Changing inputs

- Keep new inputs optional with defaults.
- `SLACK_WEBHOOK_URL` is still optional (there is a TODO to make it required). Making it required breaks callers that
  don't pass it before anything syncs.
- Slack: keep the `PAYLOAD_VAR_*` env values and `payload-file-path`. This is the workaround for
  [slack-github-action issue #203](https://github.com/slackapi/slack-github-action/issues/203). The `${{ env.* }}`
  text in `slack-payload.json` is filled in by the Slack action, not by GitHub expressions. If you upgrade the action
  past v1, recheck how it handles payload files.
- Update [`templates/vip-go-sync-prod.yml`](../../templates/vip-go-sync-prod.yml) when inputs change.

## Testing

1. Keep the step order: checkouts, then the sync, then the failure-only notification steps.
2. Review by hand against rule `composite-actions`; `actionlint` cannot lint `action.yml`.
3. Exercise it from a consumer branch with `uses: penske-media-corp/github-workflows-wordpress/composites/sync-vip-prod@<branch>`,
   a disposable non-production destination repository, and a dedicated test branch in it. Any `wpcomvip/<brand>`
   destination is live: callers deploy to `master` or `production` depending on the brand.
