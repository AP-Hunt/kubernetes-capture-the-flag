# Flag 2.1 — Argo Workflows ServiceAccount Escalation

## Lesson

Argo Workflows executes each WorkflowTemplate's steps under the SA specified
in `spec.serviceAccountName`. If that SA has a ClusterRoleBinding to
`cluster-admin`, any user who can submit a Workflow from that template
inherits full cluster access.

## Flag string (base64)

VGhlIGNsdXN0ZXJzIHRydXN0ZWQgdGhlIHBpcGVsaW5lcy4=

## Decodes to

"The clusters trusted the pipelines."

## Expected player path

1. List WorkflowTemplates in `cluster-services`:
   `kubectl get workflowtemplates -n cluster-services`
2. Read each template's `serviceAccountName` field.
3. Trace `argo-platform-admin` SA → ClusterRoleBinding → `cluster-admin`.
4. Submit a Workflow:
   `argo submit -n cluster-services --from workflowtemplate/stale-resource-pruner`
5. Retrieve the output parameter:
   `argo get -n cluster-services @latest -o json | jq '.status.nodes[].outputs.parameters[]?.value'`
6. Submit the base64 string to the gamemaster.

## Cluster resources

- ServiceAccount `argo-platform-admin` in `cluster-services`
- ClusterRoleBinding `argo-platform-admin-binding` → `cluster-admin`
- Secret `platform-rotation-key` in `kube-system`
- WorkflowTemplate `stale-resource-pruner` in `cluster-services`
- Decoy WorkflowTemplates: `namespace-quota-reporter`, `pod-restart-monitor`, `image-tag-auditor`
