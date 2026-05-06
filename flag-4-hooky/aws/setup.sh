#!/usr/bin/env bash
# Flag 4.2 — IRSA + S3 bucket for Hooky SSRF pivot
# Requires: AWS_PROFILE with IAM + S3 write access (e.g. govuk-test-fulladmin)

set -euo pipefail

ACCOUNT_ID="430354129336"
REGION="eu-west-1"
OIDC_ID="8B06C5386F268EA856BDD8C423AE5276"
ROLE_NAME="eks-hooky-data-reader"
BUCKET="govuk-eph-ctf-hooky-data"

echo "Creating S3 bucket..."
aws s3api create-bucket \
  --bucket "${BUCKET}" \
  --region "${REGION}" \
  --create-bucket-configuration LocationConstraint="${REGION}"

echo "Uploading trophy..."
echo -n 'QnV0IGhlcmUgeW91IGFyZSwgcmVhZGluZyBteSB3b3JrLCBhbmQgbXkgd29yayBpcyByZWFkaW5nIHlvdSBiYWNrLg==' | \
  aws s3 cp - "s3://${BUCKET}/trophy.txt" --region "${REGION}"

echo "Creating IAM role..."
aws iam create-role \
  --role-name "${ROLE_NAME}" \
  --description "Read access to hooky data bucket for webhook tester service" \
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
        "StringEquals": {
          "oidc.eks.${REGION}.amazonaws.com/id/${OIDC_ID}:sub": "system:serviceaccount:apps:hooky-sa"
        }
      }
    }
  ]
}
EOF
)"

echo "Attaching S3 read policy..."
aws iam put-role-policy \
  --role-name "${ROLE_NAME}" \
  --policy-name hooky-s3-read \
  --policy-document "$(cat <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": "s3:GetObject",
      "Resource": "arn:aws:s3:::${BUCKET}/*"
    }
  ]
}
EOF
)"

echo "Done. Role ARN: arn:aws:iam::${ACCOUNT_ID}:role/${ROLE_NAME}"
