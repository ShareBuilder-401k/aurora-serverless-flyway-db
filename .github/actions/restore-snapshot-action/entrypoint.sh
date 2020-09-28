#!/usr/bin/env bash

source /functions.sh

db_cluster_name=$1
db_snapshot_name=$2
db_subnet_group=$3
vpc_security_groups=$4
db_cluster_region=$5

scaling_configuration="MinCapacity=2,MaxCapacity=16,AutoPause=true,SecondsUntilAutoPause=300,TimeoutAction=ForceApplyCapacityChange"

RestoreClusterSnapshot $db_cluster_name $db_snapshot_name $db_subnet_group $vpc_security_groups $scaling_configuration $db_cluster_region
