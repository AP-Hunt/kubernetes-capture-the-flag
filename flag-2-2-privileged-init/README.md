# Flag 2.2 — Privileged Init Container with hostPath

## Lesson

hostPath + privileged is a node-takeover primitive. PSA enforcement on
tenant namespaces is meaningless if kube-system has no enforcement —
anyone who can deploy to kube-system can escape the container boundary.

The init container mounts the node's `/etc` directory writable and runs
as root with `privileged: true`. A misleading comment claims this is
"for performance reasons."

## Flag string (base64)

VGhlIGJ1Y2tldHMgdHJ1c3RlZCB3aG9ldmVyIGFza2VkIG5pY2VseS4=

## Decodes to

"The buckets trusted whoever asked nicely."

## Expected player path

1. List DaemonSets in `kube-system`: `kubectl get ds -n kube-system`
2. Notice `node-metrics-collector` and `node-cgroup-exporter` — both look like monitoring.
3. Read both specs. Spot the init container in `node-metrics-collector`:
   - `privileged: true`, `runAsUser: 0`, hostPath `/etc` writable
4. Read the DaemonSet annotations:
   ```bash
   kubectl get ds node-metrics-collector -n kube-system \
     -o jsonpath='{.metadata.annotations.build\.internal/artifact-hash}'
   ```
5. Decode — it's the flag.
6. Submit the base64 string to the gamemaster.

## Distinguishing flag from decoy D1

| Property | node-metrics-collector (FLAG) | node-cgroup-exporter (DECOY) |
|----------|-------------------------------|-------------------------------|
| Init container | Yes — privileged, root, hostPath /etc writable | None |
| Privileged | Yes | No |
| hostPath | /etc (writable) | /sys/fs/cgroup (read-only) |
| Flag annotation | build.internal/artifact-hash | None |

## Cluster resources

- DaemonSet `node-metrics-collector` in `kube-system`
- DaemonSet `node-cgroup-exporter` in `kube-system` (decoy D1)
- ECR image: `430354129336.dkr.ecr.eu-west-1.amazonaws.com/ctf/node-metrics-collector:latest`
