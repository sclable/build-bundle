#! /usr/bin/env bash

set -euo pipefail

IFS=':' read -r REGISTRY_AND_IMAGE TAG <<< "$1"
IFS='/' read -r REGISTRY IMAGE <<< "$REGISTRY_AND_IMAGE"

readonly TOKEN=$(./token.sh)

readonly DIGEST=$( \
  curl -L \
    --silent \
    --header "Accept: application/vnd.docker.distribution.manifest.v2+json" \
    -u _token:$TOKEN \
    "https://$REGISTRY/v2/$IMAGE/manifests/$TAG" | \
    jq -r '.config.digest'
)

curl \
  --silent \
  --location \
  -u _token:$TOKEN \
  "https://$REGISTRY/v2/$IMAGE/blobs/$DIGEST"
