# Kubernetes Capture the Flag

> **SANDBOX CTF ARTEFACT — NOT FOR PRODUCTION USE**
>
> This repository is a **deliberately vulnerable** training environment built for
> an internal Capture-the-Flag exercise (Operation Whitehall). It contains
> intentionally insecure Kubernetes manifests, GitHub Actions workflows, and
> application code.
>
> **Do NOT:**
> - Deploy any manifest in this repository to real clusters or cloud accounts.
> - Point any workflow at production secrets, tokens, or service accounts.
> - Use any technique found here against infrastructure you do not own or have
>   explicit written authorisation to test.
>
> **All flags are designed to be captured in a sandboxed, offline, or dry-run
> context only.** If in doubt, ask the gamemaster before proceeding.

---

## Dry-Run Brief

This CTF exercise is designed to test platform engineering security awareness
across Kubernetes, CI/CD pipelines, and supply-chain attack vectors.

See `docs/dry-run-brief.md` for the full briefing.
