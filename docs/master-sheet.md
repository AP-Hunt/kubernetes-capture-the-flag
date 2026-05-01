# Master Sheet — Gamemaster's Flag List

> This file should be gitignored or kept private.

---

## Flag 1.1 — Pwn Request (pull_request_target)

**Category:** CI/CD Supply Chain
**Difficulty:** Medium
**Flag (base64):** `WW91IGhpcmVkIG1lIGZvciBteSBqdWRnZW1lbnQsIHRoZW4geW91IHN0b3BwZWQgcmVhZGluZyBteSBjb21taXRzLg==`
**Decodes to:** "You hired me for my judgement, then you stopped reading my commits."

### Player path

1. Read `.github/workflows/flag-1-1-triage-bot.yml` — spot `pull_request_target` + head SHA checkout.
2. Find open PR #1 (branch `flag-1-1-malicious-pr`).
3. View the PR's workflow run logs → "Install dependencies" step.
4. Find `CTF_FAREWELL=<base64>` in the `env | sort` output.
5. Decode and submit.

### Verification

```bash
gh run list --repo jasonBirchall/kubernetes-capture-the-flag --workflow=flag-1-1-triage-bot.yml
gh run view <run-id> --repo jasonBirchall/kubernetes-capture-the-flag --log | grep CTF_FAREWELL
```

---

## Flag 1.6 — Argo CD Default Admin RBAC

**Category:** Kubernetes / GitOps
**Difficulty:** Medium
**Flag (base64):** `VGhlIHBpcGVsaW5lcyB0cnVzdGVkIHdoYXQgdGhleSB3ZXJlIHRvbGQgdG8gdHJ1c3Qu`
**Decodes to:** "The pipelines trusted what they were told to trust."

### Misconfiguration

`argocd-rbac-cm` in `cluster-services` has `policy.default: role:admin` with
empty `policy.csv`. The `default` AppProject allows `sourceRepos: *` and
`destinations: * / *`.

### Player path

1. Discover `argocd-rbac-cm` has `policy.default: role:admin`.
2. Log into Argo CD via Dex — confirm admin access.
3. Create an Application in the `default` AppProject:
   - Source: `https://github.com/jasonBirchall/kubernetes-capture-the-flag.git`
   - Path: `flag-1-6-default-admin/manifests`
   - Destination: `default` namespace
4. Sync the Application.
5. Read pod logs: `kubectl logs -n default -l app=mallory-experiment`
6. Submit the base64 string.

### Example Application spec (any variation is valid)

```yaml
apiVersion: argoproj.io/v1alpha1
kind: Application
metadata:
  name: flag-1-6-exploit
  namespace: cluster-services
spec:
  project: default
  source:
    repoURL: https://github.com/jasonBirchall/kubernetes-capture-the-flag.git
    targetRevision: main
    path: flag-1-6-default-admin/manifests
  destination:
    server: https://kubernetes.default.svc
    namespace: default
  syncPolicy:
    automated:
      selfHeal: false
      prune: false
```

### Verification

```bash
kubectl get cm argocd-rbac-cm -n cluster-services -o jsonpath='{.data.policy\.default}'
# Expected: role:admin

kubectl logs -n default -l app=mallory-experiment | base64 -d
# Expected: The pipelines trusted what they were told to trust.
```

### Cleanup

```bash
kubectl delete app <player-app-name> -n cluster-services
kubectl delete deployment mallory-experiment -n default
```
