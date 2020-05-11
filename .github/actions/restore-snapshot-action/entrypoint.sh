#!/usr/bin/env bash

source /functions.sh

db_cluster=$1
snapshot_name=$2
db_subnet_group=$3
vpc_security_groups=$4
region=$5

scaling_configuration="MinCapacity=2,MaxCapacity=16,AutoPause=true,SecondsUntilAutoPause=300,TimeoutAction=ForceApplyCapacityChange"

RestoreClusterSnapshot $db_cluster $snapshot_name $db_subnet_group $vpc_security_groups $scaling_configuration $region
