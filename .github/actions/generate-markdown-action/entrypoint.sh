#!/usr/bin/env bash

FLYWAY_OPTIONS=(
  -url=jdbc:postgresql://postgres:5432/$POSTGRES_DB
  -user=$POSTGRES_USER
  -password=$POSTGRES_PASSWORD
  -locations=filesystem:./sql
  -placeholders.DATABASE_NAME=$POSTGRES_DB
  -placeholders.READ_ONLY_PASSWORD=password
  -placeholders.SAMPLE_APPLICATION_PASSWORD=password
)

/flyway/flyway "${FLYWAY_OPTIONS[@]}" info
/flyway/flyway "${FLYWAY_OPTIONS[@]}" migrate
/flyway/flyway "${FLYWAY_OPTIONS[@]}" info

postgres-markdown -H postgres --user $POSTGRES_USER --password $POSTGRES_PASSWORD --database $POSTGRES_DB -l en --output postgres.md

sed -i '/# Database Documentation/,$d' README.md
cat postgres.md >> README.md

git config user.email $GITBOT_EMAIL
git config user.name $GITBOT_NAME
git add README.md
git commit -m 'Updating Postgres Markdown on README from GitHub Actions'
git push https://$GITHUB_ACTOR:$GITHUB_TOKEN@github.com/$GITHUB_REPOSITORY.git
