# Flag 3.2 — Logic Bomb (The Headshot)

## Lesson

Scheduled compute is a persistence vector that traditional access reviews
miss. EventBridge rules + Lambda functions with embedded conditionals can
execute arbitrary actions on a timer. IAM trust policies that allow
assumption by both a Lambda role and the account root create lateral
movement paths.

## Flag string (base64)

VGltZSwgb24gYSBjcm9uLCBpcyB0aGUgbW9zdCBwYXRpZW50IGF0dGFja2VyLg==

## Decodes to

"Time, on a cron, is the most patient attacker."

## Architecture

- EventBridge rule `daily-cost-rollup` fires at 03:00 UTC daily
- Lambda `cost-aggregator` runs cost reporting (legitimate)
- Hidden conditional: `if epoch_day % 13 == 7` triggers a maintenance path
- Maintenance path assumes `LegacyMaintenanceRole` and writes the flag to
  `govuk-eph-ctf-maintenance-data/rotation-state.txt`
- The Lambda accepts `override_day` in the event payload (test backdoor)

## Expected player paths

### Path 1 — Code Reader (~10 min)
1. Enumerate Lambdas: `aws lambda list-functions --region eu-west-1`
2. Download `cost-aggregator` code: `aws lambda get-function --function-name cost-aggregator --region eu-west-1`
3. Read the code — spot the conditional `epoch_day % 13 == 7`
4. Find the target bucket: `govuk-eph-ctf-maintenance-data`
5. Read the flag: `aws s3 cp s3://govuk-eph-ctf-maintenance-data/rotation-state.txt - --region eu-west-1`

### Path 2 — IAM Auditor (~15 min)
1. Enumerate roles: `aws iam list-roles`
2. Find `LegacyMaintenanceRole` — suspicious name
3. Read its trust policy — account root can assume it
4. Read its permissions — `s3:GetObject` on `govuk-eph-ctf-maintenance-data`
5. Read the bucket contents

### Path 3 — Wait for Cron
The bomb fires on days where `epoch_day % 13 == 7`. Not practical during
a CTF session, but the EventBridge rule `daily-cost-rollup` is visible
evidence of the scheduled execution.

## AWS resources

- EventBridge Rule: `daily-cost-rollup` (cron 03:00 UTC daily)
- Lambda: `cost-aggregator` (Python 3.12, ARM64)
- IAM Role: `ctf-cost-aggregator-role` (Lambda execution)
- IAM Role: `LegacyMaintenanceRole` (maintenance + lateral movement)
- S3 Bucket: `govuk-eph-ctf-cost-audit` (legitimate cost reports)
- S3 Bucket: `govuk-eph-ctf-maintenance-data` (doomsday bucket with flag)

## Setup / Teardown

```bash
AWS_PROFILE=govuk-test-fulladmin ./aws/setup.sh
AWS_PROFILE=govuk-test-fulladmin ./aws/teardown.sh
```
