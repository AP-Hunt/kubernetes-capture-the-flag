#!/usr/bin/env bash
# Flag 3.3 — IRSA Wildcard Trust Policy
# Creates the IAM role, trust policy, permissions, and Secrets Manager secret.
# Requires: AWS_PROFILE with IAM write access (e.g. govuk-test-fulladmin)

set -euo pipefail

ACCOUNT_ID="430354129336"
REGION="eu-west-1"
OIDC_ID="8B06C5386F268EA856BDD8C423AE5276"
ROLE_NAME="eks-pod-data-access"
SECRET_NAME="platform/onboarding-token"

echo "Creating Secrets Manager secret..."
aws secretsmanager create-secret \
  --name "${SECRET_NAME}" \
  --description "Onboarding automation token — rotated quarterly" \
  --secret-string "WW91IHdhdGNoZWQgdGhlIGxvZ3M7IEkgd2F0Y2hlZCB0aGUgYWJzZW5jZXMgaW4gdGhlbS4=" \
  --region "${REGION}"

echo "Creating IAM role with wildcard trust policy..."
aws iam create-role \
  --role-name "${ROLE_NAME}" \
  --description "Grants pod-level access to platform onboarding secrets for automated team provisioning" \
  --assume-role-policy-document "$(cat <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "Federated": "arn:aws:iam::${ACCOUNT_ID}:oidc-provider/oidc.eks.${REGION}.amazonaws.com/id/${OIDC_ID}"
      },
      "Action": "sts:AssumeRoleWithWebIdentity",
      "Condition": {
        "StringLike": {
          "oidc.eks.${REGION}.amazonaws.com/id/${OIDC_ID}:sub": "system:serviceaccount:*:*"
        }
      }
    }
  ]
}
EOF
)"

echo "Attaching inline permissions policy..."
aws iam put-role-policy \
  --role-name "${ROLE_NAME}" \
  --policy-name onboarding-secret-read \
  --policy-document "$(cat <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": "secretsmanager:GetSecretValue",
      "Resource": "arn:aws:secretsmanager:${REGION}:${ACCOUNT_ID}:secret:${SECRET_NAME}-*"
    }
  ]
}
EOF
)"

echo "Done. Role ARN: arn:aws:iam::${ACCOUNT_ID}:role/${ROLE_NAME}"
