# Project Instructions

## Secrets & SOPS

- Never commit plaintext secrets to the repository.
- All files matching `*secret*.yaml` are encrypted with SOPS (age key).
- Before committing secret files, run `make encrypt` to encrypt them in-place.
- To decrypt for local use or cluster apply, run `make decrypt`.
- Single file operations: `make encrypt-file FILE=<path>` / `make decrypt-file FILE=<path>`.
- The SOPS age key lives at `~/.config/sops/age/keys.txt`. Set `SOPS_AGE_KEY_FILE` if using a different path.
- The `.sops.yaml` config uses `encrypted_regex: "^(data|stringData)$"` so metadata stays in cleartext.
