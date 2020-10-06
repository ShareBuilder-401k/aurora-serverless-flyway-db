#!/usr/bin/env bash

# Use config.json infrastructure object to select from available regions
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

# Assumes AWS Credentials are set

if [[ -z "${AWS_ACCESS_KEY_ID}" || -z "${AWS_SECRET_ACCESS_KEY}" ]]; then
  echo "No AWS Credentials set. Please set AWS credentials and try again."
  exit 1
fi

echo "Select a Region:"
region="$(loadRegionConfig)"
echo "Region: ${region}"
echo ""

region_config="$(jq --arg region "${region}" -r '.infrastructure[$region]' config.json)"

# Get connection details from config.json
bastion_host_name="$(jq -r '.bastion.bastionHostName // "bastion-host"' <<< "${region_config}")"
bastion_key_bucket="$(jq -r '.bastion.privateKeyBucket // "sharebuilder401k-ssh-keys-us-west-2"' <<< "${region_config}")"
bastion_key_path="$(jq -r '.bastion.privateKeyPath // "private/bastion-host-key"' <<< "${region_config}")"
aurora_db_cluster_name="$(jq -r '.auroraDB.dbClusterName // "aurora-cluster"' <<< "${region_config}")"

# Get Aurora DB host endpoint from cluster nmae
aurora_db_host="$(aws rds describe-db-cluster-endpoints --db-cluster-identifier "${aurora_db_cluster_name}" --query 'DBClusterEndpoints[*].Endpoint' --output text)"

# Get bastion host endpoint from bastion host name
bastion_host="$(aws ec2 describe-instances --filter Name=tag:Name,Values="${bastion_host_name}" --query 'Reservations[0].Instances[0].PublicDnsName' --output text)"

# Download private key to SSH into bastion host from S3
aws s3 cp "s3://${bastion_key_bucket}/${bastion_key_path}" ./bastion-host-key-temp

# Set permissions to use SSH key
chmod 0600 ./bastion-host-key-temp

# Establish SSH tunnel connection. Will remain open until exit command is issued
ssh -i ./bastion-host-key-temp -L "5432:${aurora_db_host}:5432" "ec2-user@${bastion_host}"

# Remove temp private key file
rm -rf ./bastion-host-key-temp
