# factory-ci

Reusable GitHub Actions workflows that every factory repository calls, so security,
governance and promotion behave the same everywhere. Public because repositories in
other organisations can only call reusable workflows
from a public repository. It holds no secrets.

| Workflow | What it does | Call it from |
| --- | --- | --- |
| `security.yml` | gitleaks (full history), semgrep, osv-scanner, trivy; pinned versions, checksum-verified installs | every push |
| `governed-files.yml` | Fails when a commit changes a `CODEOWNERS` path and its author is not an owner: CODEOWNERS for the no-PR workflow | pushes to `dev` |
| `standard-drift.yml` | Golden set present, no `CLAUDE.md`/`docs/todo.md`, shared `AGENTS.md` section on the current `factory-standards` version | weekly schedule |
| `promote.yml` | Fast-forwards `dev → stage` or `stage → prod`, only when every check on the source commit passed, behind a GitHub environment | manual promote workflows |

Ready-to-copy callers are in `examples/`.

## Setting up a repository

1. Copy `examples/factory.yml`, `examples/standard.yml`, `examples/promote-to-stage.yml`
   and `examples/promote-to-prod.yml` into `.github/workflows/`. Replace the owner
   email in `factory.yml`. Remove any older promote workflows they replace.
2. Settings → Environments: create `stage` (no reviewers) and `prod` with
   **Required reviewers: the owner** and **Deployment branches: `stage` only**.
   GitHub checks the branch the workflow runs from, so Promote to prod is run from
   `stage`; a `prod` rule would block it. Your GitHub account signs in with a passkey, so approving a production
   promotion needs your phone or hardware key.
3. Branch rules (Settings → Rules → Rulesets):
   - `stage`, `prod`/`main`: block force pushes and deletion; restrict updates so only
     the promote workflow (GitHub Actions) can push.
   - `dev`: block force pushes and deletion. Agents push directly (no PRs); the
     `factory` workflow scans every push.
4. Coolify: stage deploys from the `stage` branch, prod from `prod`/`main`. Turn off
   auto-deploy for any other branch.
5. Agents commit with their own git identity (never the owner's email), so
   `governed-files` can tell them apart.

## Versioning

Callers pin `@v1`. Changes that keep inputs compatible move the `v1` tag; breaking
changes become `v2`. Pass the same ref as `factory_ref` if you pin something other than
`v1`.

## Updating scanner versions

Bump the versions at the top of `scripts/install-scanners.sh`. Every download is
verified against the publisher's checksum file. Action references are pinned to
commit SHAs.

## Development

```bash
bash tests/governed-files.test.sh
actionlint .github/workflows/*.yml examples/*.yml
```
