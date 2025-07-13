# Security Policy

This repository (`infra-utils`) is maintained by the ITByteOrg organization. Branch protections are enforced on the `main` branch to preserve repository integrity and ensure safe deployment workflows.

## Branch Protection Details

- **Branch:** `main`
- **Ruleset:** `protect-main`
- **Protections Enabled:**
  - Restrict branch updates, deletions, and creation
  - Require pull requests before merging
  - Block force pushes
  - Optional: linear commit history and commit signing (if applicable)
- **Bypass Roles:**
  - GitHub **Organization Admins** only (`@ITByteOrg`)
  - No individual or team-specific bypasses

These policies ensure that only approved administrators can directly modify the protected branch. All other contributors must follow the PR process and pass required checks.

## Reporting Security Issues

This is a personal project maintained by a solo developer. While security is a priority, this repository is not monitored for formal vulnerability reporting. If you notice a serious issue, feel free to open a GitHub issue with **[security]** in the title or email:

- Contact (optional): `itbyteenthusiast@gmail.com`

Please note that I may not respond immediately, but I appreciate responsible reports and will address valid concerns as time allows.

---

_Thanks for contributing to a secure and reliable open source ecosystem._
