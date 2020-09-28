#!/usr/bin/env bash

# @description Runs a single ECS task, waits for it to complete, and prints out the logs
#
# @example
#   RunECSTask $TASK_DEFINITION_FAMILY $LAUNCH_TYPE $CLUSTER $SUBNETS $SECURITY_GROUPS $REGION $COMMAND_OVERRIDE
#
# @arg $1 TASK_DEFINITION_FAMILY - Name of the task definition family to create the task from. If no revision is specified it will default to latest
# @arg $2 LAUNCH_TYPE - Launch Type for the task. EC2 or FARGATE
# @arg $3 CLUSTER - The ECS cluster to run the task in
# @arg $4 SUBNETS = Comma separated list of subnets the task can be run in
# @arg $5 SECURITY_GROUPS - Comma separated list of security groups to assign to the task
# @arg $6 REGION - the AWS region to run the task in
# @arg $7 COMMAND_OVERRIDE - Optional argument. The command to run on the container instead of the default command
function RunECSTask() {
  TASK_DEFINITION_FAMILY="${1}"
  LAUNCH_TYPE="${2}"
  CLUSTER="${3}"
  SUBNETS="${4}"
  SECURITY_GROUPS="${5}"
  REGION="${6}"
  COMMAND_OVERRIDE="${7}"

  if [[ -z $TASK_DEFINITION_FAMILY ]]; then
    echo "ERROR: expected TASK_DEFINITION_FAMILY to be passed to RunECSTask"
    exit 1
  elif [[ -z $LAUNCH_TYPE ]]; then
    echo "ERROR: expected LAUNCH_TYPE to be passed to RunECSTask"
    exit 1
  elif [[ -z $CLUSTER ]]; then
    echo "ERROR: expected CLUSTER to be passed to RunECSTask"
    exit 1
  elif [[ -z $SUBNETS ]]; then
    echo "ERROR: expected SUBNETS to be passed to RunECSTask"
    exit 1
  elif [[ -z $SECURITY_GROUPS ]]; then
    echo "ERROR: expected SECURITY_GROUPS to be passed to RunECSTask"
    exit 1
  elif [[ -z $REGION ]]; then
    echo "ERROR: expected REGION to be passed to RunECSTask"
    exit 1
  fi

  if [[ -z $COMMAND_OVERRIDE ]]; then
    echo "No COMMAND_OVERRIDE provided. Using default command for the ECS container."
  else
    # Remove -family from TASK_DEFINITION_FAMILY to set the name of the task. Replace spaces in Command Override string "," to put it in the Docker CMD format (["cmd","arg1"."arg2",...]).
    OVERRIDE_STRING="--overrides {\"containerOverrides\":[{\"name\":\"${TASK_DEFINITION_FAMILY//-family/}\",\"command\":[\"${COMMAND_OVERRIDE// /\",\"}\"]}]}"
  fi

  # # Dev uses a public subnet and needs a public IP to access the internet
  # if [[ $ENV == "dev" ]]; then
  #   ASSIGN_PUBLIC_IP_STRING="ENABLED"
  # else
  #   ASSIGN_PUBLIC_IP_STRING="DISABLED"
  # fi
  ASSIGN_PUBLIC_IP_STRING="ENABLED"

  SECURITY_GROUP_STRING=`GetSGIdsFromNames $SECURITY_GROUPS $REGION`
  SUBNET_STRING=`GetSubnetIdsFromNames $SUBNETS $REGION`

  NETWORK_CONFIGURATION_STRING="awsvpcConfiguration={subnets=[$SUBNET_STRING],securityGroups=[$SECURITY_GROUP_STRING],assignPublicIp=$ASSIGN_PUBLIC_IP_STRING}"

  RUN_TASK_STRING="aws ecs run-task --task-definition $TASK_DEFINITION_FAMILY --launch-type $LAUNCH_TYPE --cluster $CLUSTER --network-configuration $NETWORK_CONFIGURATION_STRING $OVERRIDE_STRING --region $REGION --query tasks[*].taskArn --output text"

  echo "Starting ECS task..."
  echo "$RUN_TASK_STRING"
  echo ""
  TASK_ARN=$($RUN_TASK_STRING)

  echo "$TASK_ARN"

  echo "Waiting for task to complete..."
  WAIT_STRING="aws ecs wait tasks-stopped --cluster $CLUSTER --tasks $TASK_ARN --region $REGION"
  echo "$WAIT_STRING"
  echo ""
  eval $WAIT_STRING

  # ecs-cli logs command expects just the task ID not the full arn. Reverse the arn string, take the section until the first / (the task ID), and then flip it back.
  TASK_ID=$(echo $TASK_ARN | rev | cut -d/ -f1 | rev)

  echo "Getting task logs..."
  LOG_STRING="ecs-cli logs --cluster $CLUSTER --task-id $TASK_ID --region $REGION"
  echo "$LOG_STRING"
  echo ""
  eval $LOG_STRING
}

# @description Get list of Security Group IDs from list of Security Group Names
#
# @example
#   GetSGIdsFromNames  "sg-name-1,sg-name-2" us-west-2
#
# @arg $1 SECURITY_GROUPS - Comma delimited list of Security Group Names
# @arg $2 REGION - The AWS region the security groups are in
#
# @stdout Comma delimited list of Security Group IDs
function GetSGIdsFromNames() {
  SECURITY_GROUPS="${1}"
  REGION="${2}"

  if [[ -z $SECURITY_GROUPS ]]; then
    echo "ERROR: expected SECURITY_GROUPS to be passed to GetSGIdsFromNames"
    exit 1
  elif [[ -z $REGION ]]; then
    echo "ERROR: expected REGION to be passed to GetSGIdsFromNames"
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

# @description Get list of Subnet IDs from list of Subnet Names
#
# @example
#   GetSubnetIdsFromNames  "sb401k-general-us-west-2a,sb401k-general-us-west-2b,sb401k-general-us-west-2c" us-west-2
#
# @arg $1 SUBNETS - Comma delimited list of Subnet Names
# @arg $2 REGION - The AWS region the subnets are in
#
# @stdout Comma delimited list of Subnet IDs
function GetSubnetIdsFromNames() {
  SUBNETS="${1}"
  REGION="${2}"

  if [[ -z $SUBNETS ]]; then
    echo "ERROR: expected SUBNETS to be passed to GetSubnetIdsFromNames"
    exit 1
  elif [[ -z $REGION ]]; then
    echo "ERROR: expected REGION to be passed to GetSubnetIdsFromNames"
    exit 1
  fi

  SUBNET_STRING=""

  # Turn comma delimited string into space delimited string so we can loop through it
  for SUBNET in $(echo $SUBNETS | sed "s/,/ /g"); do
    SUBNET_ID=$(aws ec2 describe-subnets --filters Name=tag:Name,Values=$SUBNET --region $REGION --query 'Subnets[*].[SubnetId]' --output text)

    # ${VARIABLE:+,} adds a comma only if the VARIABLE is not empty. Prevents a comma at the start of the string
    SUBNET_STRING="${SUBNET_STRING}${SUBNET_STRING:+,}${SUBNET_ID}"
  done

  echo $SUBNET_STRING
}
