# cc_saml

Control Center's SAML 2.0 service-provider crypto native: a thin, stateless
C-ABI seam (`cc_saml.h`) over the pinned pure-Rust
[`saml` crate](https://crates.io/crates/saml) (quick-xml + RustCrypto — no
libxml2 / xmlsec1 / openssl C toolchain, no bindgen, no libclang; a plain
`cargo build` on every platform including Windows MSVC).

## What it owns

- `cc_saml_parse_idp_metadata` — IdP EntityDescriptor XML → entity id, SSO
  endpoints, signing certs (for the admin config UI and login flow).
- `cc_saml_build_authn_request` — HTTP-Redirect AuthnRequest → redirect URL
  - request id + serialized login tracker.
- `cc_saml_verify_response` — POST-binding SAMLResponse: XML-DSig
  verification (XSW-resistant by structure), audience / destination /
  InResponseTo / lifetime / recipient validation against caller-supplied
  expectations, → verified identity as JSON or a typed error code.
- `cc_saml_sp_metadata` — this SP's EntityDescriptor for IdP registration.

## What it deliberately does NOT own

State. The login tracker (matching an ACS'd Response back to its
AuthnRequest) and the assertion-ID replay cache live in the CALLER (the
server's `SamlService` in `cc_server_core`), mirroring the OIDC pending-state
map. The seam returns the tracker JSON and the `assertion_id` /
`not_on_or_after` pair; Dart stores and dedupes. This keeps the native dumb
(same rule as `cc_watcher`) and avoids the crate's in-memory replay cache,
which sweeps by wall clock while validation uses the caller-supplied clock.

## Security posture (delegated, verified)

The DSig/canonicalization core is the `saml` crate's — structurally
XSW-resistant (validated payload bound to the verified signature element),
multi-Reference signatures rejected, transform whitelist (XSLT/XPath/base64
rejected), DTD/entities rejected at parse (XXE), weak algorithms off by
default, `unsafe` forbidden, fuzz harnesses upstream. This crate adds the
conformance corpus in `src/tests.rs` (happy path, tampered, expired, wrong
audience, wrong destination, unsolicited, XSW duplicate-assertion injection,
Okta-style metadata) driven through the extern entry points themselves.

## Upgrade discipline

The dependency is pinned `=0.0.1-alpha.2` (pre-1.0). Bump only with: a
Cargo.lock review, a re-run of the corpus (`cargo test`) and a changelog
read. The FFI seam exists so this backend can be swapped (e.g. for an
xmlsec-backed one) without touching Dart.

## Build

`scripts/natives/build_saml.sh` (called by `build_natives.sh`; staged into
`build/natives/` and bundled by `apps/cc_server/hook/build.dart`).

REQUIRED native — no degraded mode. SAML SSO refuses to start and the
cc_server boot preflight names this library when it is missing: a hand-rolled
Dart XML-DSig is exactly where signature-wrapping vulnerabilities live.
