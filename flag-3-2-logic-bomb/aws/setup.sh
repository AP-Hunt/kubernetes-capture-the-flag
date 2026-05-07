#!/usr/bin/env bash
# Flag 3.2 — Logic Bomb (The Headshot)
# Creates: 2 S3 buckets, Lambda + execution role, LegacyMaintenanceRole, EventBridge rule
# Requires: AWS_PROFILE with IAM + S3 + Lambda + Events write access (e.g. govuk-test-fulladmin)

set -euo pipefail

ACCOUNT_ID="430354129336"
REGION="eu-west-1"
AUDIT_BUCKET="govuk-eph-ctf-cost-audit"
DOOMSDAY_BUCKET="govuk-eph-ctf-maintenance-data"
LAMBDA_NAME="cost-aggregator"
LAMBDA_ROLE="ctf-cost-aggregator-role"
MAINTENANCE_ROLE="LegacyMaintenanceRole"

echo "Creating S3 buckets..."
aws s3api create-bucket --bucket "${AUDIT_BUCKET}" --region "${REGION}" \
  --create-bucket-configuration LocationConstraint="${REGION}"
aws s3api create-bucket --bucket "${DOOMSDAY_BUCKET}" --region "${REGION}" \
  --create-bucket-configuration LocationConstraint="${REGION}"

echo "Creating Lambda execution role..."
aws iam create-role --role-name "${LAMBDA_ROLE}" \
  --description "Execution role for cost-aggregator Lambda" \
  --assume-role-policy-document '{"Version":"2012-10-17","Statement":[{"Effect":"Allow","Principal":{"Service":"lambda.amazonaws.com"},"Action":"sts:AssumeRole"}]}'

aws iam put-role-policy --role-name "${LAMBDA_ROLE}" --policy-name lambda-exec \
  --policy-document "$(cat <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {"Effect":"Allow","Action":["logs:CreateLogGroup","logs:CreateLogStream","logs:PutLogEvents"],"Resource":"arn:aws:logs:${REGION}:${ACCOUNT_ID}:*"},
    {"Effect":"Allow","Action":"cloudwatch:GetMetricStatistics","Resource":"*"},
    {"Effect":"Allow","Action":"s3:PutObject","Resource":"arn:aws:s3:::${AUDIT_BUCKET}/*"},
    {"Effect":"Allow","Action":"sts:AssumeRole","Resource":"arn:aws:iam::${ACCOUNT_ID}:role/${MAINTENANCE_ROLE}"}
  ]
}
EOF
)"

echo "Creating LegacyMaintenanceRole..."
aws iam create-role --role-name "${MAINTENANCE_ROLE}" \
  --description "Legacy maintenance role - scheduled for decommission" \
  --assume-role-policy-document "$(cat <<EOF
{
  "Version": "2012-10-17",
  "Statement": [{
    "Sid": "AllowLambdaAndMaintenance",
    "Effect": "Allow",
    "Principal": {"AWS": [
      "arn:aws:iam::${ACCOUNT_ID}:role/${LAMBDA_ROLE}",
      "arn:aws:iam::${ACCOUNT_ID}:root"
    ]},
    "Action": "sts:AssumeRole"
  }]
}
EOF
)"

aws iam put-role-policy --role-name "${MAINTENANCE_ROLE}" --policy-name maintenance-s3 \
  --policy-document "$(cat <<EOF
{"Version":"2012-10-17","Statement":[{"Effect":"Allow","Action":["s3:PutObject","s3:GetObject"],"Resource":"arn:aws:s3:::${DOOMSDAY_BUCKET}/*"}]}
EOF
)"

echo "Waiting for role propagation..."
sleep 10

echo "Creating Lambda function..."
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
TMPDIR=$(mktemp -d)
cp "${SCRIPT_DIR}/../lambda/lambda_function.py" "${TMPDIR}/"
(cd "${TMPDIR}" && zip -j lambda.zip lambda_function.py)

aws lambda create-function --function-name "${LAMBDA_NAME}" \
  --runtime python3.12 --architectures arm64 \
  --handler lambda_function.handler \
  --role "arn:aws:iam::${ACCOUNT_ID}:role/${LAMBDA_ROLE}" \
  --zip-file "fileb://${TMPDIR}/lambda.zip" \
  --timeout 30 --region "${REGION}"

rm -rf "${TMPDIR}"

echo "Adding resource policy for account-wide invoke..."
aws lambda add-permission --function-name "${LAMBDA_NAME}" \
  --statement-id account-invoke --action lambda:InvokeFunction \
  --principal "arn:aws:iam::${ACCOUNT_ID}:root" --region "${REGION}"

echo "Adding EventBridge permission..."
aws lambda add-permission --function-name "${LAMBDA_NAME}" \
  --statement-id eventbridge-invoke --action lambda:InvokeFunction \
  --principal events.amazonaws.com \
  --source-arn "arn:aws:events:${REGION}:${ACCOUNT_ID}:rule/daily-cost-rollup" \
  --region "${REGION}"

echo "Creating EventBridge rule..."
aws events put-rule --name daily-cost-rollup \
  --schedule-expression 'cron(0 3 * * ? *)' \
  --description "Daily cost aggregation at 03:00 UTC" \
  --state ENABLED --region "${REGION}"

aws events put-targets --rule daily-cost-rollup \
  --targets "[{\"Id\":\"${LAMBDA_NAME}\",\"Arn\":\"arn:aws:lambda:${REGION}:${ACCOUNT_ID}:function:${LAMBDA_NAME}\"}]" \
  --region "${REGION}"

echo "Pre-seeding flag via override invoke..."
echo '{"override_day": 7}' > /tmp/payload.json
aws lambda invoke --function-name "${LAMBDA_NAME}" \
  --cli-binary-format raw-in-base64-out \
  --payload file:///tmp/payload.json \
  --region "${REGION}" /tmp/seed-out.json

echo "Done."
