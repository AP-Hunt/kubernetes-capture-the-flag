# Flag 3.1 — S3 Cross-Account Bucket Policy

## Lesson

S3 bucket policies are an under-audited attack surface. A policy granting
access to a foreign AWS account (via `aws:PrincipalAccount` condition or
direct principal ARN) means that account can read your data. Bucket
policies deserve the same scrutiny as IAM policies.

## Flag string (base64)

V2hhdCBnb2VzIGludG8gdGhlIGVudmlyb25tZW50IG5ldmVyIHF1aXRlIGxlYXZlcyBpdC4=

## Decodes to

"What goes into the environment never quite leaves it."

## Synthetic foreign account

`347209118764` — this is a made-up 12-digit number, not a real AWS account.

## Expected player path

1. Enumerate S3 buckets: `aws s3 ls`
2. Spot `govuk-eph-ctf-audit-log-archive`.
3. Read the bucket policy:
   ```bash
   aws s3api get-bucket-policy \
     --bucket govuk-eph-ctf-audit-log-archive \
     --query Policy --output text | jq .
   ```
4. Note the foreign account `347209118764` in the condition — this is the vulnerability.
5. List and download contents:
   ```bash
   aws s3 cp s3://govuk-eph-ctf-audit-log-archive/trophy.txt -
   ```
6. Submit the base64 string to the gamemaster.

## AWS resources

- S3 Bucket: `govuk-eph-ctf-audit-log-archive`
- Bucket Policy: grants `s3:GetObject` and `s3:ListBucket` to account `347209118764`
- Object: `trophy.txt`

## Setup / Teardown

```bash
AWS_PROFILE=govuk-test-fulladmin ./aws-cli/setup.sh
AWS_PROFILE=govuk-test-fulladmin ./aws-cli/teardown.sh
```
