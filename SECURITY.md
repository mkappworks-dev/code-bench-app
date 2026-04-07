# Security Policy

## Project Status

Code Bench is currently in **alpha**. Security reports can be filed as public GitHub issues.

---

## Supported Versions

Only the latest release receives security fixes. Patch releases are issued for confirmed, in-scope vulnerabilities.

| Version        | Supported |
| -------------- | --------- |
| Latest release | Yes       |
| Older releases | No        |

---

## How to Report a Vulnerability

Open a [GitHub issue](https://github.com/mkappworks-dev/code-bench-app/issues/new) with the label `security`.

Include in your report:

- **Description** — what the vulnerability is and its potential impact
- **Reproduction steps** — the minimum steps needed to trigger it
- **Affected versions** — which version(s) you tested against
- **Impact assessment** — what an attacker could achieve (e.g. credential exposure, arbitrary file read)
- **Suggested fix** (optional) — if you have one

Do not include sensitive personal data or live credentials in your report.

---

## Response Timeline

| Stage              | Target                                                   |
| ------------------ | -------------------------------------------------------- |
| Acknowledgment     | Within 72 hours of receipt                               |
| Initial assessment | Within 7 days                                            |
| Fix or mitigation  | Within 30 days for high/critical; 90 days for low/medium |
| Public disclosure  | After fix is released, coordinated with the reporter     |

If a timeline cannot be met we will notify you and agree on a revised date.

---

## Coordinated Disclosure

We follow a coordinated disclosure model:

1. Reporter submits the vulnerability.
2. Maintainers reproduce and assess severity.
3. A fix is developed and released.
4. A public advisory is published (GitHub Security Advisory) after the fix is available.
5. Credit is given to the reporter in the advisory unless they prefer to remain anonymous.

We ask that reporters avoid publishing details of unpatched vulnerabilities. We commit to working toward a fix before any public disclosure.

---

## Scope

### In Scope

The following vulnerability classes are in scope for the Code Bench desktop application:

| Class                                   | Example                                                                                          |
| --------------------------------------- | ------------------------------------------------------------------------------------------------ |
| API key / credential exposure           | Keys stored via `flutter_secure_storage` written to disk in plaintext, logged, or leaked via IPC |
| Keychain bypass                         | Circumventing platform-native secure storage (Keychain / DPAPI / libsecret)                      |
| GitHub OAuth token leakage              | Access tokens exposed in logs, temp files, or transmitted insecurely                             |
| Insecure local file access              | Path traversal when reading or writing files via the file explorer or editor                     |
| Sensitive data in crash reports or logs | API keys, OAuth tokens, or chat content written to unprotected log files                         |
| Local privilege escalation              | App executing code or accessing files beyond its sandbox entitlements                            |
| Insecure outbound TLS                   | Failure to validate certificates when communicating with AI providers or the GitHub API          |

### Out of Scope

The following are **not** in scope:

- Denial-of-service attacks (the app is a single-user local tool)
- Social engineering of maintainers or users
- Vulnerabilities in third-party dependencies (Flutter SDK, Drift, Dio, etc.) — report those to the respective upstream projects
- Vulnerabilities in third-party AI provider APIs (OpenAI, Anthropic, Gemini) or the GitHub API — report those upstream
- Issues that require physical access to an already-compromised machine

---

## Security Model

Code Bench is designed to run fully locally. Key security properties:

- **No telemetry.** The app does not phone home or transmit usage data.
- **Local-only storage.** All chat history and session data are stored in a local SQLite database on disk.
- **Encrypted credentials.** AI API keys and OAuth tokens are stored in the platform's native credential store (macOS Keychain, Windows DPAPI, Linux libsecret) — never in the SQLite file.
- **User-supplied AI keys.** The app makes no AI API calls on its own behalf; all requests use keys the user explicitly configures.

## Known Limitations

- Session metadata (conversation titles, timestamps) is stored in plaintext in the local SQLite database.
- The app does not yet support certificate pinning for connections to AI provider APIs.
