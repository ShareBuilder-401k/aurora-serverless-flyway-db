#!/usr/bin/env bash

# Set Flyway image tag using flywayVersion from config.json
# Add Github Workflow unique Run ID to tag version if build is not from master
image_tag="$(jq -r '.flywayVersion // "0.0.0"' config.json)"
if [[ "${GITHUB_REF}" != "refs/heads/master" ]]; then
  image_tag="${image_tag}.${GITHUB_RUN_ID}"
fi

# Get docker registry and repo details from config.json
docker_registry="$(jq -r '.dockerRegistry // "docker.pkg.github.com"' config.json)"
docker_owner="$(jq -r '.dockerOwner // "sharebuilder-401k"' config.json)"
docker_repo="$(jq -r '.dockerRepo // "aurora-serverless-flyway-db"' config.json)"

# Login to
echo "Do we even have the token?"
echo "${GITHUB_TOKEN}"
echo "${GITHUB_TOKEN}" | docker login "${docker_registry}" -u "${GITHUB_ACTOR}" --password-stdin
docker build -t "${docker_registry}/${docker_owner}/${docker_repo}/flyway:${image_tag}" ./docker
docker tag "${docker_registry}/${docker_owner}/${docker_repo}/flyway:${image_tag}" "${docker_registry}/${docker_owner}/${docker_repo}/flyway:latest"
docker push "${docker_registry}/${docker_owner}/${docker_repo}/flyway:${image_tag}"
docker push "${docker_registry}/${docker_owner}/${docker_repo}/flyway:latest"

gitbot_email="$(jq -r '.gitbotEmail // "aurora.gitbot@example.com"' config.json)"
gitbot_name="$(jq -r '.gitbotName // "aurora-gitbot"' config.json)"
git config user.email "${gitbot_email}"
git config user.name "${gitbot_name}"

regions=($(jq -r '.infrastructure // {"us-west-2": {}} | keys[]' config.json))

for region in "${regions[@]}"; do
  sed -i "s/app_version =.*/app_version = \"${image_tag}\"/" "infrastructure/flyway-fargate-task/var-files/${region}.tfvars"
  git add "infrastructure/flyway-fargate-task/var-files/${region}.tfvars"
done

git commit -m "Updating flyway app_version from GitHub Actions"
git push "https://${GITHUB_ACTOR}:${GITHUB_TOKEN}@github.com/${GITHUB_REPOSITORY}.git"
