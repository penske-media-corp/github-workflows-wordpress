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
