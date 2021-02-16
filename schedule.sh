#! /usr/bin/env bash
jq -n --argfile java java.json --argfile node node.json -f schedule.jq
