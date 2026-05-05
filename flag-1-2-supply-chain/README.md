# Flag 1.2 — Supply-Chain Action Pinning

## Lesson

Pinning a third-party GitHub Action by mutable tag (e.g., `@v3`) means
the Action's code can change without your workflow changing. A tag is a
pointer — the maintainer (or an attacker who compromises the maintainer)
can move it to arbitrary code at any time.

The secure practice is to pin by full 40-character commit SHA.

## Flag string (base64)

WW91IGdhdmUgbWUgY2x1c3Rlci1hZG1pbiBvbiBhIFR1ZXNkYXkgYW5kIGZvcmdvdCBieSBUaHVyc2RheS4=

## Decodes to

"You gave me cluster-admin on a Tuesday and forgot by Thursday."

## Expected player path

1. Read `.github/workflows/flag-1-2-cache-helper.yml`.
2. See `jasonBirchall/whitehall-cache-helper@v3` — pinned by mutable tag.
3. Visit the Action repo, read `action.yml` at `v3` tag — spot the `curl` POST.
4. Compare `v2` vs `v3`: `https://github.com/jasonBirchall/whitehall-cache-helper/compare/v2...v3`
5. Note `CTF_CANARY` env var in the workflow — decode it.
6. Submit the base64 string.

## Resources

- Action repo: https://github.com/jasonBirchall/whitehall-cache-helper
- Workflow: `.github/workflows/flag-1-2-cache-helper.yml`
