#!/usr/bin/env bash

db_cluster=$1
snapshot_name=$2
db_subnet_group=$3
vpc_security_groups=$4
region=$5

scaling_configuration="MinCapacity=2,MaxCapacity=16,AutoPause=true,SecondsUntilAutoPause=300,TimeoutAction=ForceApplyCapacityChange"

RestoreClusterSnapshot $DB_CLUSTER $SNAPSHOT_NAME $DB_SUBNET_GROUP $VPC_SECURITY_GROUPS $SCALING_CONFIGURATION $REGION
