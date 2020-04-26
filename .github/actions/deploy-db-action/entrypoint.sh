#!/usr/bin/env bash

echo "Test client_payload values passed"
echo $ENV
echo $REGION


echo "Testing setting env vars in workflow persists to action"
echo "AWS env vars should be set so this should output something here"

aws s3 ls
