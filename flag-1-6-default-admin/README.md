# Flag 1.6 — Argo CD Default Admin RBAC

## Lesson

Argo CD's `argocd-rbac-cm` ConfigMap has `policy.default: role:admin` with
empty `policy.csv`. Every authenticated Dex user is an Argo CD admin. The
`default` AppProject allows all source repos and all destination namespaces.

Combined, any authenticated user can create an Application pointing at any
Git repo and sync arbitrary workloads into any namespace.

## Flag string (base64)

VGhlIHBpcGVsaW5lcyB0cnVzdGVkIHdoYXQgdGhleSB3ZXJlIHRvbGQgdG8gdHJ1c3Qu

## Decodes to

"The pipelines trusted what they were told to trust."

## Expected player path

1. Discover `argocd-rbac-cm` has `policy.default: role:admin`.
2. Log into Argo CD via Dex — confirm they have admin access.
3. Create a new Application in the `default` AppProject pointing at
   `github.com/jasonBirchall/kubernetes-capture-the-flag`,
   path `flag-1-6-default-admin/manifests`, targeting `default` namespace.
4. Sync the Application.
5. Read the pod logs: `kubectl logs -n default -l app=mallory-experiment`.
6. Submit the base64 string to the gamemaster.
