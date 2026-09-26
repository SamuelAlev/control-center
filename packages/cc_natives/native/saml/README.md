# cc_saml

Stateless SAML 2.0 service-provider C ABI (`cc_saml.h`) over the pinned pure-Rust [`saml` crate](https://crates.io/crates/saml). No libxml2, xmlsec1, OpenSSL C toolchain, bindgen or libclang is needed. Build it from the repo root with `scripts/natives/build_saml.sh` (also called by `build_natives.sh`). The server requires this native at boot; there is no Dart signature-verification fallback.

The ABI parses IdP metadata (`cc_saml_parse_idp_metadata`), builds HTTP-Redirect AuthnRequests (`cc_saml_build_authn_request`), verifies POST-binding SAMLResponses (`cc_saml_verify_response`) and emits SP metadata (`cc_saml_sp_metadata`). Verification checks XML-DSig, audience, destination, `InResponseTo`, lifetime and recipient against caller-provided expectations. The native returns a verified identity or a typed error, plus the login tracker and `assertion_id`/`not_on_or_after`. **It does not hold state:** `SamlService` in `cc_server_core` stores pending requests and assertion-ID replay protection, so validation and replay use the caller's clock.

The upstream crypto/parser binds verified payloads to signed elements (XSW resistance), rejects multiple References, DTD/entities (XXE) and disallowed transforms such as XSLT/XPath/base64; weak algorithms are off by default. `src/tests.rs` exercises the exported ABI with normal and adversarial responses, including duplicate-assertion XSW and metadata cases.

The pre-1.0 crate is pinned `=0.0.1-alpha.2`. On an upgrade, review `Cargo.lock` and the upstream changelog, then run `cargo test` for the conformance corpus. The C ABI lets the implementation change without changing Dart callers. See [SECURITY.md](../../../../SECURITY.md) for shared SSO trust requirements.
