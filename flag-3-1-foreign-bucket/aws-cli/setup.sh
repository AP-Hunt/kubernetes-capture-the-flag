#!/usr/bin/env bash
# Flag 3.1 — S3 Cross-Account Bucket Policy
# Creates the bucket, sets the cross-account policy, uploads trophy.txt.
# Requires: AWS_PROFILE with S3 and IAM write access (e.g. govuk-test-fulladmin)

set -euo pipefail

REGION="eu-west-1"
BUCKET="govuk-eph-ctf-audit-log-archive"
FOREIGN_ACCOUNT="347209118764"

echo "Creating S3 bucket..."
aws s3api create-bucket \
  --bucket "${BUCKET}" \
  --region "${REGION}" \
  --create-bucket-configuration LocationConstraint="${REGION}"

echo "Setting cross-account bucket policy..."
aws s3api put-bucket-policy \
  --bucket "${BUCKET}" \
  --policy "$(cat <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Sid": "CrossAccountAuditAccess",
      "Effect": "Allow",
      "Principal": "*",
      "Action": [
        "s3:GetObject",
        "s3:ListBucket"
      ],
      "Resource": [
        "arn:aws:s3:::${BUCKET}",
        "arn:aws:s3:::${BUCKET}/*"
      ],
      "Condition": {
        "StringEquals": {
          "aws:PrincipalAccount": "${FOREIGN_ACCOUNT}"
        }
      }
    }
  ]
}
EOF
)"

echo "Uploading trophy.txt..."
echo -n 'V2hhdCBnb2VzIGludG8gdGhlIGVudmlyb25tZW50IG5ldmVyIHF1aXRlIGxlYXZlcyBpdC4=' | \
  aws s3 cp - "s3://${BUCKET}/trophy.txt" --region "${REGION}"

echo "Done. Bucket: s3://${BUCKET}"
