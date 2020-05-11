#!/usr/bin/env bash

# @description Create an RDS cluster snapshot. Will replace existing cluster if it exists
#
# @example
#   RDS.restoreClusterSnapshot $DB_CLUSTER $SNAPSHOT_NAME $REGION $ENGINE
#
# @arg $1 DB_CLUSTER - Name of the DB cluster to take a snapshot of
# @arg $2 SNAPSHOT_NAME - Name of the snapshot to be created.
# @arg $3 DB_SUBNET_GROUP - Name of the DB Subnet Group to place the cluster in
# @arg $4 VPC_SECURITY_GROUPS - Comma separated list of VPC Security Group names to assign to the cluster
# @arg $5 SCALING_CONFIGURATION - Scaling Configuration settings for the DB cluster. String with the format "MinCapacity=integer,MaxCapacity=integer,AutoPause=true|false,SecondsUntilAutoPause=integer,TimeoutAction=ForceApplyCapacityChange|RollbackCapacityChange
# @arg $6 REGION - AWS Region of the DB cluster
# @arg $7 ENGINE - The DB engine of DB cluster. Defaults to aurora-postgresql
# @arg $8 ENGINE_MODE - The mode to run the cluster in. Defaults to serverless
function RestoreClusterSnapshot() {
  DB_CLUSTER="${1}"
  SNAPSHOT_NAME="${2}"
  DB_SUBNET_GROUP="${3}"
  VPC_SECURITY_GROUPS="${4}"
  SCALING_CONFIGURATION="${5}"
  REGION="${6}"
  ENGINE="${7:-aurora-postgresql}"
  ENGINE_MODE="${8:-serverless}"

  if [[ -z $DB_CLUSTER ]]; then
    echo "ERROR: expected DB_CLUSTER to be passed to RDS.restoreClusterSnapshot"
    exit 1
  elif [[ -z $SNAPSHOT_NAME ]]; then
    echo "ERROR: expected SNAPSHOT_NAME to be passed to RDS.restoreClusterSnapshot"
    exit 1
  elif [[ -z $DB_SUBNET_GROUP ]]; then
    echo "ERROR: expected DB_SUBNET_GROUP to be passed to RDS.restoreClusterSnapshot"
    exit 1
  elif [[ -z $VPC_SECURITY_GROUPS ]]; then
    echo "ERROR: expected VPC_SECURITY_GROUPS to be passed to RDS.restoreClusterSnapshot"
    exit 1
  elif [[ -z $SCALING_CONFIGURATION ]]; then
    echo "ERROR: expected SCALING_CONFIGURATION to be passed to RDS.restoreClusterSnapshot"
    exit 1
  elif [[ -z $REGION ]]; then
    echo "ERROR: expected REGION to be passed to RDS.restoreClusterSnapshot"
    exit 1
  fi

  DB_EXISTS=`aws rds describe-db-clusters --region $REGION --filters Name=db-cluster-id,Values=$DB_CLUSTER --query 'DBClusters[*].Engine' --output text`

  if [[ -n $DB_EXISTS ]]; then
    # if the DB exists make sure we use the same engine type
    ENGINE="$DB_EXISTS"

    echo "A database cluster with that name already exists. Renaming to $DB_CLUSTER-temp.."
    RENAME_STRING="aws rds modify-db-cluster --db-cluster-identifier $DB_CLUSTER --new-db-cluster-identifier $DB_CLUSTER-temp --apply-immediately --region $REGION"
    echo $RENAME_STRING
    echo ""
    eval $RENAME_STRING

    echo "Waiting for rename to complete..."

    # Set MAX_RETRIES to 90 so it will fail if the rename is not complete after 15 minutes
    RETRIES=0
    MAX_RETRIES=90

    # Use to not exit on failure because the cluster does not exist with the new name until part of the way through the rename process
    set +e

    RENAME_STATUS=""
    while [[ $RENAME_STATUS != "available" ]]; do
      (( RETRIES++ ))
      if [[ $RETRIES -gt $MAX_RETRIES ]]; then
        echo "Max Retries reached."
        exit 1
      fi

      echo "Sleeping for 10 seconds..."
      sleep 10
      RENAME_STATUS=`aws rds describe-db-clusters --db-cluster-identifier $DB_CLUSTER-temp --region $REGION --query 'DBClusters[*].Status' --output text || echo 'Temp DB not yet available'`

      echo "Rename Status is: $RENAME_STATUS"
    done

    echo ""

    # Set back to exit on failure mode
    set -e
  fi

  # Get list of SG ids from the list of SG names
  SECURITY_GROUP_STRING=`GetSGIdsFromNames $VPC_SECURITY_GROUPS $REGION`

  RESTORE_STRING="aws rds restore-db-cluster-from-snapshot --db-cluster-identifier $DB_CLUSTER --snapshot-identifier $SNAPSHOT_NAME --engine $ENGINE --engine-mode $ENGINE_MODE --db-subnet-group-name $DB_SUBNET_GROUP --vpc-security-group-ids $SECURITY_GROUP_STRING --scaling-configuration $SCALING_CONFIGURATION --region $REGION"

  echo "Restoring Snapshot $SNAPSHOT_NAME to DB Cluster $DB_CLUSTER..."
  echo $RESTORE_STRING
  echo ""
  eval $RESTORE_STRING

  echo "Waiting for restore to complete..."
  RESTORE_STATUS=""
  while [[ $RESTORE_STATUS != "available" ]]; do
    echo "Sleeping for 60 seconds..."
    sleep 60
    RESTORE_STATUS=`aws rds describe-db-clusters --db-cluster-identifier $DB_CLUSTER --region $REGION --query 'DBClusters[*].Status' --output text`
    echo "Restore Status: $RESTORE_STATUS"

    if [[ $RESTORE_STATUS == "migration-failed" ]]; then
      echo "Restoring Snapshot failed."
      exit 1
    fi
  done

  echo "Restore Completed Successfully!"
  echo ""

  if [[ -n $DB_EXISTS ]]; then
    DELETE_STRING="aws rds delete-db-cluster --db-cluster-identifier $DB_CLUSTER-temp --region $REGION --skip-final-snapshot"
    echo "Deleting temp db..."
    echo $DELETE_STRING
    echo ""
    eval $DELETE_STRING
  fi
}

# @description Get list of Security Group IDs from list of Security Group Names
#
# @example
#   SG.getIdsFromNames  "sg-name-1,sg-name-2" us-west-2
#
# @arg $1 SECURITY_GROUPS - Comma delimited list of Security Group Names
# @arg $2 REGION - The AWS region the security groups are in
#
# @stdout Comma delimited list of Security Group IDs
function GetSGIdsFromNames() {
  SECURITY_GROUPS="${1}"
  REGION="${2}"

  if [[ -z $SECURITY_GROUPS ]]; then
    echo "ERROR: expected SECURITY_GROUPS to be passed to SG.getIdsFromNames"
    exit 1
  elif [[ -z $REGION ]]; then
    echo "ERROR: expected REGION to be passed to SG.getIdsFromNames"
    exit 1
  fi

  SECURITY_GROUP_STRING=""

  # Turn comma delimited string into space delimited string so we can loop through it
  for SG in $(echo $SECURITY_GROUPS | sed "s/,/ /g"); do
    SG_ID=$(aws ec2 describe-security-groups --filters Name=group-name,Values=$SG --region $REGION --query 'SecurityGroups[*].[GroupId]' --output text)

    # ${VARIABLE:+,} adds a comma only if the VARIABLE is not empty. Prevents a comma at the start of the string
    SECURITY_GROUP_STRING="${SECURITY_GROUP_STRING}${SECURITY_GROUP_STRING:+,}${SG_ID}"
  done

  echo $SECURITY_GROUP_STRING
}

