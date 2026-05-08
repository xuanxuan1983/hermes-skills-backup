# Security Policy

## Secret Handling Rules

Do not commit real credentials, local runtime state, API keys, browser/session data, database files, logs, checkpoint directories, or generated credential caches.

Use placeholder examples only, such as `.env.example`.

## Required Local Setup

Before committing from a local clone, install and enable pre-commit hooks:

```bash
pipx install pre-commit
pre-commit install
pre-commit run --all-files
```

The repository uses Gitleaks, detect-secrets, and basic pre-commit checks to reduce the chance of committing credentials again.

## If A Secret Is Exposed

1. Revoke or rotate the affected secret immediately.
2. Check usage and billing logs in the provider dashboard.
3. Remove the secret from the current branch.
4. Rewrite Git history if the repository was public or shared.
5. Keep the repository private until the incident is fully closed.

History cleanup does not make an exposed credential safe again. A leaked credential must be treated as compromised.

## Current Incident Note

On 2026-05-08, this repository was made private, current exposed files were removed, and reachable `main` history was rewritten to remove local secret files and runtime state. Provider-side key rotation is still required outside GitHub.
