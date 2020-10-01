#!/usr/bin/env bash

function loadRegionConfig() {
  regions=($(jq -r '.infrastructure | keys[] // "us-west-2"' config.json))

  PS3="Enter a number: "
  select region in "${regions[@]}"; do
    for item in "${regions[@]}"; do
      if [[ $item == $region ]]; then
        echo "${region}"
        break 2
      fi
    done
    echo "Invalid Entry. Please select a number between 1 and ${#regions[@]}" >&2
  done
}

function selectInfrastructureFolder() {
  folders=('aurora-db' 'bastion' 'ecs-cluster' 'fargate-iam' 'flyway-fargate-task')

  PS3="Enter a number: "
  select folder in "${folders[@]}"; do
    for item in "${folders[@]}"; do
      if [[ ${item} == ${folder} ]]; then
        echo "${folder}"
        break 2
      fi
    done
    echo "Invalid Entry. Please select a number between 1 and ${#folders[@]}" >&2
  done
}

echo "Select Workflow to trigger:"

PS3="Enter a number: "
actions=('generate_markdown' 'deploy_infrastructure' 'destroy_infrastructure' 'create_snapshot' 'restore_snapshot' 'run_migration' 'build_flyway')
select action in "${actions[@]}"; do
  event_type="${action}"
  case $action in
    'generate_markdown'|'build_flyway')
      echo "Action: ${action}"
      echo ""
      break
      ;;
    'deploy_infrastructure'|'destroy_infrastructure')
      echo "Action: ${action}"
      echo ""

      echo "Select an AWS Region:"
      region=$(loadRegionConfig)
      echo "Region: ${region}"
      echo ""

      echo "Select Infrastructure to deploy"
      infrastructure_folder=$(selectInfrastructureFolder)
      echo ""
      echo "Infrastructure: ${infrastructure_folder}"

      terraform_bucket="$(jq --arg region "${region}" -r '.infrastructure[$region].terraformBucket // "aurora-terraform-us-west-2"' config.json)"

      client_payload="{\"region\": \"${region}\", \"bucket\": \"${terraform_bucket}\", \"infrastructure_folder\": \"${infrastructure_folder}\"}"

      break
      ;;
    'create_snapshot')
      echo "Action: ${action}"
      echo ""

      echo "Select an AWS Region:"
      region=$(loadRegionConfig)
      echo "Region: ${region}"
      echo ""

      timestamp=$(date -u +"%Y%m%d-%H%M%SZ")
      aurora_config=$(jq --arg region "${region}" -r '.infrastructure[$region].auroraDB' config.json)
      db_cluster_name=$(jq -r '.dbClusterName // "auroradb-cluster"' <<< "${aurora_config}")
      db_snapshot_name="${db_cluster_name}-snapshot-${timestamp}"

      client_payload="{\"db_cluster_name\": \"${db_cluster_name}\", \"db_snapshot_name\": \"${db_snapshot_name}\", \"db_cluster_region\": \"${region}\"}"

      break
      ;;
    'restore_snapshot')
      echo "Action: ${action}"
      echo ""

      echo "Select an AWS Region:"
      region=$(loadRegionConfig)
      echo "Region: ${region}"
      echo ""

      db_snapshot_name="$(jq --arg region "${region}" -r '.[$region].snapshot' metadata.json)"
      if [[ "${db_snapshot_name}" == "null" ]]; then
        echo "No snapshot to restore. Exiting"
        exit
      fi

      aurora_config="$(jq --arg region "${region}" -r '.infrastructure[$region].auroraDB' config.json)"
      db_cluster_name="$(jq -r '.dbClusterName // "auroradb-cluster"' <<< "${aurora_config}")"
      db_subnet_group="$(jq -r '.dbSubnetGroup // "auroradb-subnet-group"' <<< "${aurora_config}")"
      vpc_security_groups="$(jq -r '.vpcSecurityGroups // "auroradb-sg"' <<< "${aurora_config}")"

      client_payload="{\"db_cluster_name\": \"${db_cluster_name}\", \"db_snapshot_name\": \"${db_snapshot_name}\", \"db_subnet_group\": \"${db_subnet_group}\", \"vpc_security_groups\": \"${vpc_security_groups}\", \"db_cluster_region\": \"${region}\"}"

      break
      ;;
    'run_migration')
      echo "Action: ${action}"
      echo ""

      echo "Select an AWS Region:"
      region=$(loadRegionConfig)
      echo "Region: ${region}"
      echo ""

      flyway_config="$(jq --arg region "${region}" -r '.infrastructure[$region].flywayTask' config.json)"
      task_definition_family="$(jq -r '.taskDefinitonFamily // "flyway-migration-family"' <<< "${flyway_config}")"
      task_launch_type="$(jq -r '.taskLaunchType // "FARGATE"' <<< "${flyway_config}")"
      task_cluster="$(jq -r '.taskCluster // "ecs-cluster"' <<< "${flyway_config}")"
      task_subnets="$(jq -r '.taskSubnets // "default-us-west-2a,default-us-west-2b,default-us-west-2c"' <<< "${flyway_config}")"
      is_public_subnet="$(jq -r 'if has("isPublicSubnet") then .isPublicSubnet else true end' <<< "${flyway_config}")"
      task_security_groups="$(jq -r '.taskSecurityGroups // "flyway-fargate-sg,auroradb-sg"' <<< "${flyway_config}")"

      client_payload="{\"branch\": \"master\", \"region\": \"${region}\", \"task_definition_family\": \"${task_definition_family}\", \"task_launch_type\": \"${task_launch_type}\", \"task_cluster\": \"${task_cluster}\", \"task_subnets\": \"${task_subnets}\", \"is_public_subnet\": ${is_public_subnet}, \"task_security_groups\": \"${task_security_groups}\"}"

      break
      ;;
    *)
      echo "Invalid Entry: $REPLY. Please enter a number between 1 and ${#actions[@]}"
      ;;
  esac
done

if [[ -n $client_payload ]]; then
  curl_data="{\"event_type\": \"${event_type}\", \"client_payload\": ${client_payload}}"
else
  curl_data="{\"event_type\": \"${event_type}\"}"
fi

echo "${curl_data}"

token_name="$(jq -r '.githubTokenName // "GITHUB_AURORA_ACTIONS_TOKEN"' config.json)"
eval "token_value=\$${token_name}"

github_owner="$(jq -r '.githubOwner // "sharebuilder-401k"' config.json)"
github_repo="$(jq -r '.githubRepo // "aurora-serverless-flyway-db"' config.json)"

status_code="$(curl -H "Accept: application/vnd.github.v3+json" \
  -H "Authorization: token ${token_value}" \
  --request POST \
  --data "${curl_data}" \
  -w "%{http_code}\n" \
  "https://api.github.com/repos/${github_owner}/${github_repo}/dispatches"
)"

if [[ "${status_code}" == "204" ]]; then
  echo "Successfully invoked github action"
  echo "Follow to view action execution:"
  echo "https://github.com/${github_owner}/${github_repo}/actions"
else
  echo "Failed to invoke github action"
  echo "Status: ${status_code}"
fi
