#!/usr/bin/env bash

task_definition_family="${1}"
task_launch_type="${2}"
task_cluster="${3}"
task_subnets="${4}"
task_security_groups="${5}"
task_region="${6}"
task_command_override="${7}"

echo "task_definition_family: ${task_definition_family}"
echo "task_launch_type: ${task_launch_type}"
echo "task_cluster: ${task_cluster}"
echo "task_subnets: ${task_subnets}"
echo "task_security_groups: ${task_security_groups}"
echo "task_region: ${task_region}"
echo "task_command_override: ${task_command_override}"

source /functions.sh

RunECSTask "${task_definition_family}" "${task_launch_type}" "${task_cluster}" "${task_subnets}" "${task_security_groups}" "${task_region}" "${task_command_override}"
