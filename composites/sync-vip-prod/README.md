# Sync to VIP Production Composite Action

This GitHub Actions composite action synchronizes code from a source repository to a WordPress VIP production repository.

## Overview

The `sync-vip-prod` composite action is designed to automate the deployment process for WordPress VIP sites by:

1. Checking out the source repository
2. Checking out the destination VIP repository
3. Syncing files while preserving protected directories
4. Committing and pushing changes to the destination repository
5. Sending Slack notifications on failure

## Usage

```yaml
- name: Sync to VIP Production
  uses: ./composites/sync-vip-prod
  with:
    destination_repo: 'wpcomvip/your-site'
    destination_branch: 'production'
    destination_directory: 'wp-content/themes/your-theme'
    protected_directories: 'wp-content/plugins/brand-specific-plugin'
    GIT_EMAIL: 'your-bot@example.com'
    SLACK_WEBHOOK_URL: ${{ secrets.SLACK_WEBHOOK_URL }}
    SSH_KEY: ${{ secrets.SSH_PRIVATE_KEY }}
```

## Inputs

| Input | Description | Required | Default |
|-------|-------------|----------|---------|
| `destination_repo` | Destination repository slug, including organization (e.g., `wpcomvip/pmc`) | Yes | - |
| `destination_branch` | Branch name in the destination repository | Yes | - |
| `destination_directory` | Directory path relative to repository root where files will be synced | Yes | - |
| `protected_directories` | Directories to preserve during sync (typically brand-specific plugins) | No | `''` |
| `GIT_EMAIL` | Email address for the Git user making commits | Yes | - |
| `SLACK_WEBHOOK_URL` | Webhook URL for failure notifications | No | `''` |
| `SSH_KEY` | SSH private key with access to both source and destination repositories | Yes | - |

## Workflow Steps

### 1. Repository Checkout
- **Source Repository**: Checks out the current repository with minimal history (`fetch-depth: 1`)
- **Destination Repository**: Checks out the specified VIP repository and branch using the provided SSH key
- **Utility Scripts**: Checks out `penske-media-corp/pmc-jenkins-scripts` for helper functions

### 2. File Synchronization Process

The action uses several utility functions from the Jenkins scripts:

- **`exclude_plugins`**: Temporarily moves protected directories out of the way
- **`rsync_repo_files`**: Synchronizes files from source to destination using rsync
- **`restore_plugins`**: Restores the protected directories after sync
- **`setup_git_committer`**: Configures Git committer information based on the source repository

### 3. Git Operations

The action performs the following Git operations:
- Configures Git user as `pmcvipgo-sync` with the provided email
- Stages all changes (`git add --all`)
- Checks if there are changes to commit
- Creates a commit with metadata about the source repository and revision
- Pushes changes to the destination branch

### 4. Error Handling and Notifications

If the sync fails and a Slack webhook URL is provided:
- Retrieves job details from the GitHub API
- Sends a formatted Slack notification with source, destination, and failure details

## Commit Message Format

Commits created by this action follow this format:
```
Sync from {source-repo}:{branch-name} for revision {commit-hash} by {author}
```

## Slack Notification

When a sync fails, the action sends a Slack notification with:
- Alert header indicating production sync failure
- Source repository and branch information
- Destination repository and branch information
- Link to the failed GitHub Actions job

## Protected Directories

The `protected_directories` input allows you to specify directories that should be preserved in the destination repository during the sync. This is useful for:

- Brand-specific plugins that aren't in the shared source repository
- Configuration files specific to the VIP environment
- Any custom modifications that shouldn't be overwritten

Multiple directories can be specified (the exact format depends on the utility functions implementation).

## Requirements

- The SSH key must have read access to the source repository
- The SSH key must have write access to the destination VIP repository
- The destination repository must exist and have the specified branch
- The `penske-media-corp/pmc-jenkins-scripts` repository must be accessible

## Security Considerations

- SSH keys should be stored as GitHub repository secrets
- Slack webhook URLs should be stored as secrets
- The action runs with the permissions of the provided SSH key
- All file operations are performed in isolated workspace directories

## Debugging

Enable debug mode by setting `ACTIONS_STEP_DEBUG=true` in your workflow. This will:
- List contents of all workspace directories
- Show detailed information about the checkout process
- Display Git operations and status information

## Example Workflow

```yaml
name: Deploy to VIP Production

on:
  push:
    branches: [main]

jobs:
  deploy:
    runs-on: ubuntu-latest
    steps:
      - name: Deploy to Production
        uses: ./composites/sync-vip-prod
        with:
          destination_repo: 'wpcomvip/your-brand'
          destination_branch: 'production'
          destination_directory: 'wp-content/themes/brand-theme'
          protected_directories: 'wp-content/plugins/brand-analytics wp-content/mu-plugins/brand-config'
          GIT_EMAIL: 'deploy-bot@yourbrand.com'
          SLACK_WEBHOOK_URL: ${{ secrets.PROD_DEPLOY_SLACK_WEBHOOK }}
          SSH_KEY: ${{ secrets.VIP_DEPLOY_SSH_KEY }}
```

## Related Files

- [`action.yml`](./action.yml) - The composite action definition
- [`slack-payload.json`](./slack-payload.json) - Slack notification template