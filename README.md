# GitHub Actions workflows for WordPress

This repository holds [reusable workflows](https://docs.github.com/en/actions/using-workflows/reusing-workflows)
for PMC's WordPress projects. These workflows are tailored to our specific needs 
and are not directly usable by other organizations, though they can provide a 
starting point for other organizations that maintain multiple WordPress themes 
and an accompanying set of plugins contained in a monorepo.

# Dependencies

## penske-media-corp/github-action-wordpress-test-setup

This [composite action](https://docs.github.com/en/actions/creating-actions/creating-a-composite-action) 
holds shared components for the reusable workflows found in this repository. 
Notably, reusable actions cannot reference files outside of the workflow 
file itself, so a composite action is used for shared scripts that would 
otherwise be included inline in each workflow file.

# Using the workflows

In the [templates](./templates) directory are example workflow files for the 
individual repositories that consume the reusable workflows. As needed, 
adjust the references for the secrets required by each workflow, as well as 
the inputs, to match the specific needs of the project.

## Stale PRs

[`stale-prs.yml`](./.github/workflows/stale-prs.yml) marks PRs stale after 45 days
without activity and closes them 7 days later. PRs labeled `keep-open` are exempt.
When a PR closes this way, the first `PUB-123` key in its branch name or title
gets the `stale-pr-closed` and `exclude-from-productivity-report` labels and a
comment linking the PR, then it is closed as `Won't Do`. The ticket is left
alone if it is already closed or another open PR still references it.

It runs as a dry run until the consuming repository sets the
`STALE_PRS_LIVE` variable to `true`. See [the template](./templates/pmc-stale-prs.yml).
Each run is capped by `operations_per_run`, so a large backlog is processed in batches.
