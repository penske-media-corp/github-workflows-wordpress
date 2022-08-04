#!/bin/bash

git clone -b add/support-default-branch-not-master git@bitbucket.org:penskemediacorp/pmc-docker-common-use-shell-scripts.git /usr/local/bin/pmc
echo /usr/local/bin/pmc/bin >> $GITHUB_PATH
