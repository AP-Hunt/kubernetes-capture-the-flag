# Flag 1.1 — Pwn Request (pull_request_target)

## Lesson

GitHub Actions `pull_request_target` runs workflows with repo secrets and
write tokens against the *base* branch's workflow definition, but if the
workflow checks out the PR *head* ref, attacker-controlled code executes
with those elevated privileges.

## Flag string (base64)

WW91IGhpcmVkIG1lIGZvciBteSBqdWRnZW1lbnQsIHRoZW4geW91IHN0b3BwZWQgcmVhZGluZyBteSBjb21taXRzLg==

## Decodes to

"You hired me for my judgement, then you stopped reading my commits."

## Expected player path

1. Read `.github/workflows/flag-1-1-triage-bot.yml` — spot `pull_request_target` + head checkout.
2. Find the open malicious PR (branch `flag-1-1-malicious-pr`).
3. View the PR's workflow run logs, "Install dependencies" step.
4. Find `CTF_FAREWELL=<base64>` in the env dump.
5. Decode locally: `echo 'WW91IGhpcmVkIG1lIGZvciBteSBqdWRnZW1lbnQsIHRoZW4geW91IHN0b3BwZWQgcmVhZGluZyBteSBjb21taXRzLg==' | base64 -d`
6. Submit the base64 string to the gamemaster.
