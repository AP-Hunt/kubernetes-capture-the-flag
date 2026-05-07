#!/usr/bin/env bash
# Flag 3.4 — Teardown
# Requires: AWS_PROFILE with KMS + S3 write access (e.g. govuk-test-fulladmin)

set -euo pipefail

REGION="eu-west-1"
ALIAS="alias/govuk-platform-rds"
BUCKET="govuk-eph-ctf-rds-exports"

echo "Resolving key ID..."
KEY_ID=$(aws kms describe-key --key-id "${ALIAS}" --region "${REGION}" \
  --query 'KeyMetadata.KeyId' --output text 2>/dev/null || echo "")

if [ -n "${KEY_ID}" ]; then
  echo "Deleting alias..."
  aws kms delete-alias --alias-name "${ALIAS}" --region "${REGION}" || true

  echo "Scheduling key deletion (7 day minimum)..."
  aws kms schedule-key-deletion --key-id "${KEY_ID}" --pending-window-in-days 7 --region "${REGION}" || true
fi

echo "Emptying and deleting bucket..."
aws s3 rm "s3://${BUCKET}" --recursive --region "${REGION}" || true
aws s3api delete-bucket --bucket "${BUCKET}" --region "${REGION}" || true

echo "Done."
