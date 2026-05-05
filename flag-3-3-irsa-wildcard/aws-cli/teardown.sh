#!/usr/bin/env bash
# Flag 3.3 — Teardown
# Removes all AWS resources created by setup.sh.
# Requires: AWS_PROFILE with IAM write access (e.g. govuk-test-fulladmin)

set -euo pipefail

REGION="eu-west-1"
ROLE_NAME="eks-pod-data-access"
SECRET_NAME="platform/onboarding-token"

echo "Deleting inline policy..."
aws iam delete-role-policy \
  --role-name "${ROLE_NAME}" \
  --policy-name onboarding-secret-read || true

echo "Deleting IAM role..."
aws iam delete-role --role-name "${ROLE_NAME}" || true

echo "Deleting Secrets Manager secret..."
aws secretsmanager delete-secret \
  --secret-id "${SECRET_NAME}" \
  --force-delete-without-recovery \
  --region "${REGION}" || true

echo "Done."
