#! /usr/bin/env bash

curl "https://api.github.com/repos/goodwithtech/dockle/releases" \
  -o dockle.json

curl "https://api.github.com/repos/hadolint/hadolint/releases" \
  -o hadolint.json

curl "https://api.adoptopenjdk.net/v3/info/available_releases" \
  -o java.json

curl "https://raw.githubusercontent.com/nodejs/Release/master/schedule.json" \
  -o node.json

curl "http://cloud-images.ubuntu.com/releases/streams/v1/com.ubuntu.cloud:released:download.json" \
  -o ubuntu.json
