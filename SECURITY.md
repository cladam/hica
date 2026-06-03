# Security Policy

## Supported Versions

Hica is pre-1.0 software. Security fixes are applied to the latest release only.

| Version | Supported |
|---------|-----------|
| latest  | ✅ |
| older   | ❌ |

## Reporting a Vulnerability

Please **do not** report security vulnerabilities through public GitHub issues.

Instead, open a [GitHub Security Advisory](https://github.com/cladam/hica/security/advisories/new) to report the issue privately. Include:

- A description of the vulnerability and its potential impact
- Steps to reproduce or a minimal example
- The hica version (`hica --version`) and your OS/platform

You can expect an acknowledgement within a few days. We will work with you to understand and address the issue before any public disclosure.

## Scope

Hica is a language compiler — the primary security concern is in the compiler's handling of untrusted `.hc` source files and its code generation output.

Areas of particular interest:

- **Code generation safety** — generated Koka/C/JS code should not introduce memory unsafety or privilege escalation
- **Path traversal** — file I/O operations (e.g. `import`, `read_file`) should not allow access outside intended directories
- **Resource exhaustion** — malformed source files should not cause unbounded memory or CPU usage in the compiler
- **Dependency security** — vulnerabilities in Koka itself or the bundled stdlib

Out of scope: issues in the user's own hica programs that result from their own code logic.
