# Security policy

Control Center ships network-facing components — the headless `cc_server`
binary, the `cc_signaling_server` WebSocket broker and the desktop/web/phone
clients — so it has a real attack surface. This document describes how to
report a vulnerability and the trust boundaries a reviewer should know about.

## Reporting a vulnerability

**Please do not open a public issue for security problems.** Report privately
through GitHub's [private vulnerability reporting][gh-advisory] on this
repository (Security → Report a vulnerability). Include:

- a description of the issue and its impact,
- steps to reproduce (a proof-of-concept if you have one),
- affected component (`cc_server`, `cc_signaling_server`, desktop, web, or
  `cc_remote`) and version / commit.

You will get an acknowledgement and a fix or mitigation plan once the report
is triaged. Please allow reasonable time to remediate before any public
disclosure.

[gh-advisory]: https://docs.github.com/en/code-security/security-advisories/guidance-on-reporting-and-writing-information-about-vulnerabilities/privately-reporting-a-security-vulnerability

## Trust boundaries (for reviewers)

- **`cc_server` is the single source of truth.** All persistence, external API
  calls (GitHub/Linear/Google), process execution and agent runs happen here.
  Clients hold no business logic and reach data only over RPC.
- **A paired phone is authenticated but _untrusted_.** After pairing it is a
  lower-privilege principal: a default-deny allow-list (`RemoteToolPolicy`)
  restricts which MCP tools it may invoke and a per-session rate limiter
  (`RemoteRateLimiter`) caps call volume with a tighter sub-cap for mutations.
- **A non-loopback `cc_server` bind requires TLS.** Binding a public interface
  without `--tls-cert`/`--tls-key` (or `--insecure` behind a trusted
  TLS-terminating proxy) is refused rather than exposing plaintext.
- **The media proxy (`/proxy/media`) is SSRF-guarded.** Every target — and
  every redirect hop — is checked against a block-list (loopback, link-local,
  cloud-metadata, RFC-1918, IPv6 ULA) and requires a PSK-signed URL.
- **External MCP servers are untrusted.** Their tool descriptions and results
  are sanitised (ANSI/control-char stripping + length caps) before reaching an
  agent's context and every external tool defaults to the most cautious
  approval tier.
- **The signaling broker is a dumb relay.** It never sees the PSK; rooms are
  capped at two peers, rate-limited and reaped when idle. The PSK handshake is
  end-to-end between the two paired peers.
- **Secrets** live in the OS keychain (`flutter_secure_storage`); only
  non-sensitive preferences use `shared_preferences`. Logged command output is
  redacted before display.

## Dependencies

A scheduled workflow (`.github/workflows/dependency-audit.yml`) runs weekly and
fails on any dependency flagged by pub.dev's security-advisory database, or
that is retracted or discontinued upstream and reports outdated packages.
