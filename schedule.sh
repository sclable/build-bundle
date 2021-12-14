#! /usr/bin/env bash
set -euo pipefail

function token() {
  if [ ! -v GOOGLE_TOKEN ]
  then 
    URL=http://metadata.google.internal./computeMetadata/v1/instance/service-accounts/default/token 
    set +eo pipefail # Allow authentication to fail.
    GOOGLE_TOKEN=$(curl -s -L -H 'Metadata-Flavor: Google' $URL | jq -r '.access_token' || gcloud auth print-access-token)
    set -eo pipefail
  fi
  echo $GOOGLE_TOKEN
}

function curlne() {
  if [ -e $2 ]
  then
    echo "$2 exists. Not downloading." >&2
  else
    curl -s -L $1 \
      -o $2
  fi
}

function metadata() {
  local IMAGE
  IFS=':' read -r REGISTRY_AND_IMAGE TAG <<< "$1"
  IFS='/' read -r REGISTRY IMAGE <<< "$REGISTRY_AND_IMAGE"
  local TARGET="${TAG}.json"
  if [ -e $TARGET ]
  then
    echo "$TARGET exists. Not fetching metadata." >&2
    return
  fi
  TOKEN=$(token)
  if [ "$TOKEN" = "" ]
  then
    echo "{}" > $TARGET
    return
  fi
  DIGEST=$( \
    curl -L \
      --silent \
      --header "Accept: application/vnd.docker.distribution.manifest.v2+json" \
      -u _token:$(token) \
      "https://$REGISTRY/v2/$IMAGE/manifests/$TAG" | \
      jq -r '.config.digest'
  )
  curl \
    --silent \
    --location \
    -u _token:$(token) \
    -o "$TARGET" \
    "https://$REGISTRY/v2/$IMAGE/blobs/$DIGEST"
}

curlne "https://api.github.com/repos/goodwithtech/dockle/releases" \
  dockle.json

curlne "https://api.github.com/repos/hadolint/hadolint/releases" \
  hadolint.json

curlne "https://api.adoptopenjdk.net/v3/info/available_releases" \
  java.json

curlne "https://raw.githubusercontent.com/nodejs/Release/master/schedule.json" \
  node.json

curlne "https://cloud-images.ubuntu.com/releases/streams/v1/com.ubuntu.cloud:released:download.json" \
  ubuntu.json

metadata $IMAGE:latest

metadata $IMAGE:lts

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
git ls-tree HEAD $SELF_FILES \
  | sha256sum \
  | cut -d' ' -f 1 \
)

set +u
if [ "$GITLAB_CI" = "true" ]
then
	FILTER="gitlab"
elif [ "$GITHUB_ACTIONS" = "true" ]
then
	FILTER="github"
fi
set -u

jq -S -n -r -f ${FILTER}.jq \
  --arg self "$SELF" \
  --argfile dockle dockle.json \
  --argfile hadolint hadolint.json \
  --argfile java java.json \
  --argfile node node.json \
  --argfile ubuntu ubuntu.json \
  --argfile lts lts.json \
  --argfile latest latest.json
