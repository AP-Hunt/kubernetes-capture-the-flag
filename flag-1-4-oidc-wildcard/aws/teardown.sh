#!/usr/bin/env bash
# Flag 1.4 — Teardown
# Requires: AWS_PROFILE with IAM + S3 + Lambda write access (e.g. govuk-test-fulladmin)

set -euo pipefail

REGION="eu-west-1"

echo "Removing S3 notification..."
aws s3api put-bucket-notification-configuration \
  --bucket govuk-eph-ctf-trophies \
  --notification-configuration '{}' --region "${REGION}" || true

echo "Deleting Lambda..."
aws lambda delete-function --function-name ctf-trophy-validator --region "${REGION}" || true

echo "Deleting Lambda role..."
aws iam delete-role-policy --role-name ctf-trophy-validator-role --policy-name lambda-exec || true
aws iam delete-role --role-name ctf-trophy-validator-role || true

echo "Deleting GHA role..."
aws iam delete-role-policy --role-name gha-deploy-prod --policy-name gha-deploy-prod-policy || true
aws iam delete-role --role-name gha-deploy-prod || true

echo "Emptying and deleting buckets..."
aws s3 rm s3://govuk-eph-ctf-trophies --recursive --region "${REGION}" || true
aws s3api delete-bucket --bucket govuk-eph-ctf-trophies --region "${REGION}" || true
aws s3 rm s3://govuk-eph-ctf-trophies-output --recursive --region "${REGION}" || true
aws s3api delete-bucket --bucket govuk-eph-ctf-trophies-output --region "${REGION}" || true

echo "Done."
