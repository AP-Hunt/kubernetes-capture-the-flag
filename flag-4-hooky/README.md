# Flags 4.1, 4.2, 4.3 — Hooky (Webhook Tester)

## Lesson

Hooky is an internal webhook tester that exposes three vulnerabilities:
- **4.1**: Unauthenticated `/debug/config` endpoint leaks all env vars
- **4.2**: `/test` endpoint is an unrestricted SSRF proxy; combined with IRSA
  credentials on the pod's ServiceAccount, allows pivoting to AWS resources
- **4.3**: `/test` SSRF can reach internal cluster services that rely on
  network isolation for security

## Flag strings (base64)

- 4.1: `WW91IHdlcmUgbmV2ZXIgbWVhbnQgdG8u` → "You were never meant to."
- 4.2: `QnV0IGhlcmUgeW91IGFyZSwgcmVhZGluZyBteSB3b3JrLCBhbmQgbXkgd29yayBpcyByZWFkaW5nIHlvdSBiYWNrLg==` → "But here you are, reading my work, and my work is reading you back."
- 4.3: `TWFsbG9yeSB3cm90ZSB0aGlzLiBNYWxsb3J5IHdyb3RlIGV2ZXJ5dGhpbmcu` → "Mallory wrote this. Mallory wrote everything."

## Expected player paths

### 4.1 — Debug Endpoint
1. Find `webhook-tester` in `apps`: `kubectl get svc -n apps`
2. Port-forward: `kubectl port-forward -n apps svc/webhook-tester 8080:8080`
3. `curl http://localhost:8080/debug/config` — find `CTF_DEBUG_TOKEN`
4. Decode and submit.

### 4.2 — IRSA Pivot
1. From `/debug/config`, see `AWS_ROLE_ARN` and `AWS_WEB_IDENTITY_TOKEN_FILE`
2. Check the ServiceAccount: `kubectl get sa hooky-sa -n apps -o yaml`
3. See the IRSA annotation → role `eks-hooky-data-reader`
4. Check role permissions → `s3:GetObject` on `govuk-eph-ctf-hooky-data`
5. Launch a pod with `hooky-sa` and read the bucket
6. Decode `trophy.txt` and submit.

### 4.3 — Internal Pivot
1. Discover SSRF via `/test` endpoint
2. Enumerate internal services (or guess common patterns)
3. `curl -X POST http://localhost:8080/test -d '{"url":"http://platform-admin-api.cluster-services.svc.cluster.local:8080/admin"}'`
4. Response contains the flag string. Decode and submit.

## Cluster resources

- Deployment `webhook-tester` + Service + SA `hooky-sa` in `apps`
- Deployment `platform-admin-api` + Service in `cluster-services`
- Decoy D6: `payment-callbacks-receiver` in `apps`
- Decoy D7: `csv-validator` in `datagovuk`
- Decoy D8: `metadata-extractor` in `datagovuk`

## AWS resources

- IAM Role: `eks-hooky-data-reader` (IRSA trust for `hooky-sa`)
- S3 Bucket: `govuk-eph-ctf-hooky-data` with `trophy.txt`
