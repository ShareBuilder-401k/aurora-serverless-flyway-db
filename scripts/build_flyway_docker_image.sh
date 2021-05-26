#!/usr/bin/env bash

# Set Flyway image tag using flywayVersion from config.json
# Add Github Workflow unique Run ID to tag version if build is not from master
image_tag="$(jq -r '.flywayVersion // "0.0.0"' config.json)"
if [[ "${GITHUB_REF}" != "refs/heads/master" ]]; then
  image_tag="${image_tag}.${GITHUB_RUN_ID}"
fi

# Get docker registry and repo details from config.json
docker_registry="$(jq -r '.dockerRegistry // "ghcr.io"' config.json)"
docker_owner="$(jq -r '.dockerOwner // "CHANGE ME"' config.json)"
docker_repo="$(jq -r '.dockerRepo // "CHANGE ME"' config.json)"

if [[ "${docker_owner}" == "CHANGE ME" || "${docker_repo}" == "CHANGE ME" ]]; then
  echo "dockerOwner and dockerRepo must be changed in config.json" >&2
  exit 1
fi

# Login to Docker Registry
echo "${DOCKER_AUTH_TOKEN}" | docker login "${docker_registry}" -u "${GITHUB_ACTOR}" --password-stdin

# Build Docker Image from /docker and tag as latest. Push both to Docker Registry
docker build -t "${docker_registry}/${docker_owner}/${docker_repo}/flyway:${image_tag}" ./docker
docker tag "${docker_registry}/${docker_owner}/${docker_repo}/flyway:${image_tag}" "${docker_registry}/${docker_owner}/${docker_repo}/flyway:latest"
docker push "${docker_registry}/${docker_owner}/${docker_repo}/flyway:${image_tag}"
docker push "${docker_registry}/${docker_owner}/${docker_repo}/flyway:latest"

# Configure git using gitbot name and email from config.json
gitbot_email="$(jq -r '.gitbotEmail // "aurora.gitbot@example.com"' config.json)"
gitbot_name="$(jq -r '.gitbotName // "aurora-gitbot"' config.json)"
git config user.email "${gitbot_email}"
git config user.name "${gitbot_name}"

# Get list of regions used for infrastructure from config.json
regions=($(jq -r '.infrastructure // {"us-west-2": {}} | keys[]' config.json))

# Update app_version terraform variable in each region to have newly built image_tag. Stage changes for commit
for region in "${regions[@]}"; do
  sed -i "s/app_version =.*/app_version = \"${image_tag}\"/" "infrastructure/flyway-fargate-task/var-files/${region}.tfvars"
  git add "infrastructure/flyway-fargate-task/var-files/${region}.tfvars"
done

# Commit changes to github as gitbot user
git commit -m "Updating flyway app_version from GitHub Actions"
git push "https://${GITHUB_ACTOR}:${GITHUB_TOKEN}@github.com/${GITHUB_REPOSITORY}.git"
