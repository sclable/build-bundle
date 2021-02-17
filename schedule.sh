#! /usr/bin/env bash
jq -S -n -f schedule.jq \
  --argfile dockle dockle.json \
  --argfile hadolint hadolint.json \
  --argfile java java.json \
  --argfile node node.json \
  --argfile ubuntu ubuntu.json
