#!/usr/bin/env bash
# Flag 3.2 — Teardown
# Requires: AWS_PROFILE with IAM + S3 + Lambda + Events write access (e.g. govuk-test-fulladmin)

set -euo pipefail

REGION="eu-west-1"

echo "Removing EventBridge targets and rule..."
aws events remove-targets --rule daily-cost-rollup --ids cost-aggregator --region "${REGION}" || true
aws events delete-rule --name daily-cost-rollup --region "${REGION}" || true

echo "Deleting Lambda..."
aws lambda delete-function --function-name cost-aggregator --region "${REGION}" || true

echo "Deleting Lambda execution role..."
aws iam delete-role-policy --role-name ctf-cost-aggregator-role --policy-name lambda-exec || true
aws iam delete-role --role-name ctf-cost-aggregator-role || true

echo "Deleting LegacyMaintenanceRole..."
aws iam delete-role-policy --role-name LegacyMaintenanceRole --policy-name maintenance-s3 || true
aws iam delete-role --role-name LegacyMaintenanceRole || true

echo "Emptying and deleting buckets..."
aws s3 rm s3://govuk-eph-ctf-cost-audit --recursive --region "${REGION}" || true
aws s3api delete-bucket --bucket govuk-eph-ctf-cost-audit --region "${REGION}" || true
aws s3 rm s3://govuk-eph-ctf-maintenance-data --recursive --region "${REGION}" || true
aws s3api delete-bucket --bucket govuk-eph-ctf-maintenance-data --region "${REGION}" || true

echo "Done."
