#!/usr/bin/env bash
# Flag 1.4 — GitHub Actions OIDC Wildcard Trust
# Creates: 2 S3 buckets, Lambda + execution role, GHA OIDC IAM role
# Requires: AWS_PROFILE with IAM + S3 + Lambda write access (e.g. govuk-test-fulladmin)

set -euo pipefail

ACCOUNT_ID="430354129336"
REGION="eu-west-1"
TROPHIES_BUCKET="govuk-eph-ctf-trophies"
OUTPUT_BUCKET="govuk-eph-ctf-trophies-output"
GHA_ROLE="gha-deploy-prod"
LAMBDA_ROLE="ctf-trophy-validator-role"
LAMBDA_NAME="ctf-trophy-validator"

echo "Creating S3 buckets..."
aws s3api create-bucket --bucket "${TROPHIES_BUCKET}" --region "${REGION}" \
  --create-bucket-configuration LocationConstraint="${REGION}"
aws s3api create-bucket --bucket "${OUTPUT_BUCKET}" --region "${REGION}" \
  --create-bucket-configuration LocationConstraint="${REGION}"

echo "Creating Lambda execution role..."
aws iam create-role --role-name "${LAMBDA_ROLE}" \
  --description "Execution role for CTF trophy validator Lambda" \
  --assume-role-policy-document '{"Version":"2012-10-17","Statement":[{"Effect":"Allow","Principal":{"Service":"lambda.amazonaws.com"},"Action":"sts:AssumeRole"}]}'

aws iam put-role-policy --role-name "${LAMBDA_ROLE}" --policy-name lambda-exec \
  --policy-document "$(cat <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {"Effect":"Allow","Action":["logs:CreateLogGroup","logs:CreateLogStream","logs:PutLogEvents"],"Resource":"arn:aws:logs:${REGION}:${ACCOUNT_ID}:*"},
    {"Effect":"Allow","Action":"s3:GetObjectTagging","Resource":"arn:aws:s3:::${TROPHIES_BUCKET}/*"},
    {"Effect":"Allow","Action":"s3:PutObject","Resource":"arn:aws:s3:::${OUTPUT_BUCKET}/*"}
  ]
}
EOF
)"

echo "Waiting for role propagation..."
sleep 10

echo "Creating Lambda function..."
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
TMPDIR=$(mktemp -d)
cp "${SCRIPT_DIR}/lambda_function.py" "${TMPDIR}/"
(cd "${TMPDIR}" && zip -j lambda.zip lambda_function.py)

aws lambda create-function --function-name "${LAMBDA_NAME}" \
  --runtime python3.12 --architectures arm64 \
  --handler lambda_function.handler \
  --role "arn:aws:iam::${ACCOUNT_ID}:role/${LAMBDA_ROLE}" \
  --zip-file "fileb://${TMPDIR}/lambda.zip" \
  --environment "Variables={OUTPUT_BUCKET=${OUTPUT_BUCKET}}" \
  --timeout 30 --region "${REGION}"

rm -rf "${TMPDIR}"

echo "Configuring S3 event notification..."
aws lambda add-permission --function-name "${LAMBDA_NAME}" \
  --statement-id s3-invoke --action lambda:InvokeFunction \
  --principal s3.amazonaws.com \
  --source-arn "arn:aws:s3:::${TROPHIES_BUCKET}" \
  --source-account "${ACCOUNT_ID}" --region "${REGION}"

aws s3api put-bucket-notification-configuration --bucket "${TROPHIES_BUCKET}" \
  --notification-configuration "{
    \"LambdaFunctionConfigurations\": [{
      \"LambdaFunctionArn\": \"arn:aws:lambda:${REGION}:${ACCOUNT_ID}:function:${LAMBDA_NAME}\",
      \"Events\": [\"s3:ObjectCreated:*\"]
    }]
  }" --region "${REGION}"

echo "Creating GHA OIDC role..."
aws iam create-role --role-name "${GHA_ROLE}" \
  --description "GitHub Actions OIDC role for production deployments" \
  --assume-role-policy-document "$(cat <<EOF
{
  "Version": "2012-10-17",
  "Statement": [{
    "Effect": "Allow",
    "Principal": {"Federated": "arn:aws:iam::${ACCOUNT_ID}:oidc-provider/token.actions.githubusercontent.com"},
    "Action": "sts:AssumeRoleWithWebIdentity",
    "Condition": {
      "StringLike": {"token.actions.githubusercontent.com:sub": "repo:jasonBirchall/*"},
      "StringEquals": {"token.actions.githubusercontent.com:aud": "sts.amazonaws.com"}
    }
  }]
}
EOF
)"

aws iam put-role-policy --role-name "${GHA_ROLE}" --policy-name gha-deploy-prod-policy \
  --policy-document "$(cat <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {"Sid":"WriteTrophies","Effect":"Allow","Action":["s3:PutObject","s3:PutObjectTagging"],"Resource":"arn:aws:s3:::${TROPHIES_BUCKET}/*"},
    {"Sid":"ReadOutput","Effect":"Allow","Action":"s3:GetObject","Resource":"arn:aws:s3:::${OUTPUT_BUCKET}/*"}
  ]
}
EOF
)"

echo "Done."
echo "GHA role ARN: arn:aws:iam::${ACCOUNT_ID}:role/${GHA_ROLE}"
echo "Trophies bucket: s3://${TROPHIES_BUCKET}"
echo "Output bucket: s3://${OUTPUT_BUCKET}"
