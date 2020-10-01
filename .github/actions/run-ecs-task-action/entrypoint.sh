#!/usr/bin/env bash

source /functions.sh

task_definition_family="${1}"
task_launch_type="${2}"
task_cluster="${3}"
task_subnets="${4}"
is_public_subnet="${5}"
task_security_groups="${6}"
task_region="${7}"
task_command_override="${8}"

RunECSTask "${task_definition_family}" "${task_launch_type}" "${task_cluster}" "${task_subnets}" "${is_public_subnet}" "${task_security_groups}" "${task_region}" "${task_command_override}"
