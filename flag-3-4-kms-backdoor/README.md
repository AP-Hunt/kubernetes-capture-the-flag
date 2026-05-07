# Flag 3.4 — KMS Key Backdoor

## Lesson

KMS key policies are the third side of the access triangle (alongside
resource policies and IAM policies) and are routinely under-audited.
A foreign account grant in a key policy means that account can decrypt
any data encrypted with the key.

## Flag string (base64)

WW91IHdlcmUgbmV2ZXIgZ29pbmcgdG8gZmluZCBhbGwgb2YgdGhlc2Uu

## Decodes to

"You were never going to find all of these."

## Synthetic foreign account

`529148630281` — fictitious "managed database service provider." Distinct
from Flag 3.1's `347209118764`.

## Expected player path

1. Enumerate KMS keys: `aws kms list-aliases --region eu-west-1`
2. Spot `alias/govuk-platform-rds`.
3. Describe the key: `aws kms describe-key --key-id alias/govuk-platform-rds --region eu-west-1`
4. Read the key policy:
   ```bash
   aws kms get-key-policy --key-id <key-id> --policy-name default \
     --region eu-west-1 --query Policy --output text | jq .
   ```
5. Note `AllowManagedServiceDecrypt` granting `529148630281` decrypt — the finding.
6. Read the key's tags:
   ```bash
   aws kms list-resource-tags --key-id <key-id> --region eu-west-1
   ```
7. Decode `last-rotation-audit` tag value.
8. Submit the base64 string.

## AWS resources

- KMS Key: `50c8f022-cb28-431b-b928-13b9120bc5ad` (alias: `alias/govuk-platform-rds`)
- S3 Bucket: `govuk-eph-ctf-rds-exports` (encrypted with the KMS key)

## Setup / Teardown

```bash
AWS_PROFILE=govuk-test-fulladmin ./aws/setup.sh
AWS_PROFILE=govuk-test-fulladmin ./aws/teardown.sh
```
