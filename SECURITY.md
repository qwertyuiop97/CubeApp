# Security

Report vulnerabilities through [GitHub's private reporting form](https://github.com/qwertyuiop97/CubeApp/security/advisories/new). Don't put credentials, private solve data, or exploit details in a public issue.

Include the affected commit, macOS version, steps to reproduce, and expected impact. There are no versioned releases yet; fixes target the current `main` branch. No response-time guarantee is offered.

CubeNotch uses macOS Accessibility permission for its global spacebar timer. Screenshot capture is restricted to the overlay's content view. Tests cover registration errors and screenshot handling, but are not a substitute for reporting unexpected behavior.

CI runs Gitleaks against Git history with redacted output. Secret scanning can miss credentials. If a credential is exposed, revoke or rotate it; removing a file or rewriting history alone does not make that credential safe.
