#! /usr/bin/env bash

# Use `git` to fingerprint all files in this repo
# that "directly" influence how the image is built.
# This means the Dockerfile itself, and all files
# that end up in the Docker build context.
# Note that this method will account for file
# permissions (since these are tracked by git).
# A plain `shasum` would only check the
# contents, not producing a new hash in case of
# a change in permissions!
# Must be maintained manually!
SELF_FILES="Dockerfile sonar-scanner-run.sh"
SELF=$(\
git ls-tree -r master $SELF_FILES \
  | sha256sum \
  | cut -d' ' -f 1 \
)

jq -S -n -f schedule.jq \
  --arg self "$SELF" \
  --argfile dockle dockle.json \
  --argfile hadolint hadolint.json \
  --argfile java java.json \
  --argfile node node.json \
  --argfile ubuntu ubuntu.json \
  --argfile lts lts.json \
  --argfile latest latest.json \
