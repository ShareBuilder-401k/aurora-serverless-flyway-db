#!/usr/bin/env bash

# @description Create an RDS cluster snapshot
#
# @example
#   RDS.createClusterSnapshot $DB_CLUSTER $SNAPSHOT_NAME $REGION
#
# @arg $1 DB_CLUSTER - Name of the DB cluster to take a snapshot of
# @arg $2 SNAPSHOT_NAME - Name of the snapshot to be created.
# @arg $3 REGION - AWS Region of the DB cluster
function RDS.createClusterSnapshot() {
  DB_CLUSTER="${1}"
  SNAPSHOT_NAME="${2}"
  REGION="${3}"

  if [[ -z $DB_CLUSTER ]]; then
    echo "ERROR: expected DB_CLUSTER to be passed to RDS.createClusterSnapshot"
    exit 1
  elif [[ -z $SNAPSHOT_NAME ]]; then
    echo "ERROR: expected SNAPSHOT_NAME to be passed to RDS.createClusterSnapshot"
    exit 1
  elif [[ -z $REGION ]]; then
    echo "ERROR: expected REGION to be passed to RDS.createClusterSnapshot"
    exit 1
  fi

  SNAPSHOT_STRING="aws rds create-db-cluster-snapshot --db-cluster-snapshot-identifier $SNAPSHOT_NAME --db-cluster-identifier $DB_CLUSTER --region $REGION"
  echo "Creating snapshot $SNAPSHOT_NAME for DB Cluster $DB_CLUSTER..."
  echo $SNAPSHOT_STRING
  echo ""
  eval $SNAPSHOT_STRING

  WAIT_STRING="aws rds wait db-cluster-snapshot-available --db-cluster-snapshot-identifier $SNAPSHOT_NAME --db-cluster-identifier $DB_CLUSTER --region $REGION"
  echo "Waiting for snapshot to finish..."
  echo $WAIT_STRING
  echo ""
  eval $WAIT_STRING
}

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
