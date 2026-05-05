# Flag 2.3 — Default ServiceAccount Role

## Lesson

Granting RBAC permissions to the `default` ServiceAccount means every pod
in the namespace that doesn't set `serviceAccountName` silently inherits
those permissions. This is a common misconfiguration — teams bind roles to
`default` SA "temporarily" and forget to remove them.

## Flag string (base64)

VGhlIGJvdW5kYXJ5IGJldHdlZW4gdXMgd2FzIGFsd2F5cyBhIGNvbmZpZ3VyYXRpb24gZmlsZS4=

## Decodes to

"The boundary between us was always a configuration file."

## Expected player path

1. Notice `log-shipper` and `audit-trail-writer` Deployments in `apps` namespace.
2. Observe neither sets `serviceAccountName` — both run as `default` SA.
3. Run `kubectl auth can-i --as=system:serviceaccount:apps:default list secrets -n apps` — returns `yes`.
4. Exec into either pod and use the mounted SA token to call the K8s API.
5. List secrets in `apps`, find `pipeline-hmac-key`.
6. Read the secret value, decode once from base64 to get the flag string.
7. Submit the base64 string to the gamemaster.

## Cluster resources (applied, not synced via Argo)

- Role `secret-reader` in `apps`
- RoleBinding `default-sa-secret-reader` in `apps`
- Secret `pipeline-hmac-key` in `apps`
- Deployment `log-shipper` in `apps`
- Deployment `audit-trail-writer` in `apps` (decoy D2)
