#!/usr/bin/env bash
# Flag 4.2 — Teardown
# Requires: AWS_PROFILE with IAM + S3 write access (e.g. govuk-test-fulladmin)

set -euo pipefail

REGION="eu-west-1"
ROLE_NAME="eks-hooky-data-reader"
BUCKET="govuk-eph-ctf-hooky-data"

echo "Deleting inline policy..."
aws iam delete-role-policy --role-name "${ROLE_NAME}" --policy-name hooky-s3-read || true

echo "Deleting IAM role..."
aws iam delete-role --role-name "${ROLE_NAME}" || true

echo "Emptying bucket..."
aws s3 rm "s3://${BUCKET}" --recursive --region "${REGION}" || true

echo "Deleting bucket..."
aws s3api delete-bucket --bucket "${BUCKET}" --region "${REGION}" || true

echo "Done."
