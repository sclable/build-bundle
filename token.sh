#! /usr/bin/env bash
set -o pipefail
URL=http://metadata.google.internal./computeMetadata/v1/instance/service-accounts/default/token 
curl -s -L -H 'Metadata-Flavor: Google' $URL | jq -r '.access_token' || gcloud auth print-access-token
