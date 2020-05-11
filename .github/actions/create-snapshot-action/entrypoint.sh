#!/usr/bin/env bash

# Inputs are required by action.yml for GitHub actions
db_cluster=$1
db_snapshot=$2
region=$3

RDS.createClusterSnapshot $db_cluster $db_snapshot $region

# Update snapshot name in metadata
echo "Updating snapshot version tag"
eval "cat metadata.json | \
  jq '.snapshot = \"$db_snapshot\"' \
  > metadata_tmp.json \
  && mv metadata_tmp.json metadata.json"
cat metadata.json

# Commit metadata changes
git config user.email $GITBOT_EMAIL
git config user.name $GITBOT_NAME
git add metadata.json
git commit -m "Updating metadata.json from GitHub Actions"
git push https://$GITHUB_ACTOR:$GITHUB_TOKEN@github.com/$GITHUB_REPOSITORY.git
