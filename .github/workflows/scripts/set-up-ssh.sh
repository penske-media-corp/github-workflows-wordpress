#!/bin/bash

mkdir -p ~/.ssh
ssh-keyscan bitbucket.org >> ~/.ssh/known_hosts
echo "${{ secrets.BITBUCKET_READ_ONLY_SSH_KEY }}" | base64 --decode --ignore-garbage > ~/.ssh/id_rsa
chmod 400 ~/.ssh/id_rsa
ssh-keygen -lf ~/.ssh/id_rsa
