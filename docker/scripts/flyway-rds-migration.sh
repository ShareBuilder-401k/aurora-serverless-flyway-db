#!/usr/bin/env bash

GITHUB_BRANCH="${1:-master}"

echo "Starting Fargate taks to run flyway migration from $GITHUB_BRANCH branch for RDS database on $REGION"

# Get Repository Token to pull SQL code from GitHub
mkdir ~/.ssh
aws secretsmanager get-secret-value --secret-id $REPOSITORY_DEPLOY_KEY_SECRET --region $REGION --query SecretString --output text > ~/.ssh/id_rsa
chmod 0600 ~/.ssh/id_rsa
ssh-keyscan github.com >> ~/.ssh/known_hosts

# Clone GitHub branch to get access to SQL migrations
git clone --single-branch -b $GITHUB_BRANCH git@github.com:sharebuilder-401k/aurora-serverless-flyway-db.git
cd aurora-serverless-flyway-db

# Get DB user Passwords
SQLADMIN_PASSWORD=$(aws secretsmanager get-secret-value --secret-id postgresql@auroradb@master@sqladmin --region $REGION --query SecretString --output text | jq -r '.password')
READ_ONLY_PASSWORD=$(aws secretsmanager get-secret-value --secret-id postgresql@auroradb@master@read_only --region $REGION --query SecretString --output text | jq -r '.password')
SAMPLE_APPLICATION_PASSWORD=$(aws secretsmanager get-secret-value --secret-id postgresql@auroradb@sample@sample_application --region $REGION --query SecretString --output text | jq -r '.password')

# Set flyway config options
FLYWAY_OPTIONS=(
  -url=jdbc:postgresql://${DB_HOST}:5432/${DB_NAME}
  -user=sqladmin
  -password=${SQLADMIN_PASSWORD}
  -locations=filesystem:./sql
  -placeholders.DATABASE_NAME=${DB_NAME}
  -placeholders.READ_ONLY_PASSWORD=${READ_ONLY_PASSWORD}
  -placeholders.SAMPLE_APPLICATION_PASSWORD=${SAMPLE_APPLICATION_PASSWORD}
)

# Run flyway migration. Display flyway version details before and after migration.
/flyway/flyway "${FLYWAY_OPTIONS[@]}" info
/flyway/flyway "${FLYWAY_OPTIONS[@]}" migrate
/flyway/flyway "${FLYWAY_OPTIONS[@]}" info
