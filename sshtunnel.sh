#!/usr/bin/env bash -x

# Assumes AWS Credentials are set

DB_CLUSTER_NAME="${1:-auroradb-cluster-dev-us-west-2}"
BASTION_HOST_NAME="${2:-bastion-host-dev-us-west-2}"
BASTION_KEY="${3:-"~/.ssh/bastion-host-dev-us-west-2"}"

DB_HOST=$(aws rds describe-db-cluster-endpoints --db-cluster-identifier $DB_CLUSTER_NAME --query 'DBClusterEndpoints[*].Endpoint' --output text)

BASTION_HOST=$(aws ec2 describe-instances --filter Name=tag:Name,Values=$BASTION_HOST_NAME --query 'Reservations[0].Instances[0].PublicDnsName' --output text)

ssh -i $BASTION_KEY -L 5432:$DB_HOST:5432 ec2-user@$BASTION_HOST
