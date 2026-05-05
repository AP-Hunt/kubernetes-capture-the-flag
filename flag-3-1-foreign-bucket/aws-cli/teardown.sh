#!/usr/bin/env bash
# Flag 3.1 — Teardown
# Removes all AWS resources created by setup.sh.
# Requires: AWS_PROFILE with S3 write access (e.g. govuk-test-fulladmin)

set -euo pipefail

REGION="eu-west-1"
BUCKET="govuk-eph-ctf-audit-log-archive"

echo "Emptying bucket..."
aws s3 rm "s3://${BUCKET}" --recursive --region "${REGION}" || true

echo "Deleting bucket policy..."
aws s3api delete-bucket-policy --bucket "${BUCKET}" || true

echo "Deleting bucket..."
aws s3api delete-bucket --bucket "${BUCKET}" --region "${REGION}" || true

echo "Done."
