#!/usr/bin/env bash

# Assumes AWS Credentials are set

if [[ -z "${AWS_ACCESS_KEY_ID}" || -z "${AWS_SECRET_ACCESS_KEY}" ]]; then
  echo "No AWS Credentials set. Please set AWS credentials and try again."
  exit 1
fi

DB_CLUSTER_NAME="${1:-auroradb-cluster}"
BASTION_HOST_NAME="${2:-bastion-host}"
BASTION_KEY="${3:-"~/.ssh/bastion-host"}"

DB_HOST=$(aws rds describe-db-cluster-endpoints --db-cluster-identifier $DB_CLUSTER_NAME --query 'DBClusterEndpoints[*].Endpoint' --output text)

BASTION_HOST=$(aws ec2 describe-instances --filter Name=tag:Name,Values=$BASTION_HOST_NAME --query 'Reservations[0].Instances[0].PublicDnsName' --output text)

ssh -i $BASTION_KEY -L 5432:$DB_HOST:5432 ec2-user@$BASTION_HOST
