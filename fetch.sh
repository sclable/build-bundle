#! /usr/bin/env bash

curl "https://api.adoptopenjdk.net/v3/info/available_releases" \
  -o java.json

curl "https://raw.githubusercontent.com/nodejs/Release/master/schedule.json" \
  -o node.json
