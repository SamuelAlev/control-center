/* cc_saml — Control Center's SAML 2.0 service-provider crypto native.
 *
 * The C ABI contract mirrored 1:1 by
 * packages/cc_natives/lib/src/saml/saml_ffi_bindings.dart. Bump
 * CC_SAML_ABI_VERSION on ANY change to these signatures; the Dart side
 * refuses to bind on a mismatch and cc_server's boot preflight names the
 * offender.
 *
 * Protocol: every entry point takes NUL-terminated UTF-8 strings and returns
 * a heap JSON string (UTF-8, NUL-terminated) that the caller MUST release
 * with cc_saml_free_string. NULL is catastrophic (panic/OOM — see
 * cc_saml_last_error); domain failures are `{"ok": false, "error_code": …}`
 * so callers branch on typed codes instead of parsing messages.
 *
 * The library is STATELESS: the cross-request SAML state (matching an ACS'd
 * Response back to its AuthnRequest) travels as the opaque `tracker` JSON
 * that cc_saml_build_authn_request returns and cc_saml_verify_response
 * accepts back. Replay defense is caller-side, keyed on the assertion_id +
 * not_on_or_after the verify result carries.
 */
#ifndef CC_SAML_H
#define CC_SAML_H

#include <stdint.h>

#ifdef __cplusplus
extern "C" {
#endif

#define CC_SAML_ABI_VERSION 1u

/* cc_saml_verify_response policy flags. */
/* Refuse Responses whose Assertion is not signed (recommended default). */
#define CC_SAML_FLAG_WANT_ASSERTIONS_SIGNED 1u
/* Accept unsolicited (IdP-initiated) Responses with no InResponseTo. */
#define CC_SAML_FLAG_ALLOW_UNSOLICITED 2u
/* Refuse Responses whose root element is not signed. */
#define CC_SAML_FLAG_WANT_RESPONSE_SIGNED 4u

/* The ABI version this library speaks. */
uint32_t cc_saml_abi_version(void);

/* Thread-local message describing the most recent failure on this thread;
 * NULL when none. Owned by the library; valid until the next failing call on
 * the same thread. */
const char* cc_saml_last_error(void);

/* Releases a string returned by this library. NULL-safe; not double-free
 * safe. */
void cc_saml_free_string(char* ptr);

/* Parses an IdP EntityDescriptor XML into
 * {"ok", "entity_id", "sso_redirect"?, "sso_post"?, "signing_certs": [b64]}.
 * Domain errors: {"ok": false, "error_code": "malformed" | …}. */
char* cc_saml_parse_idp_metadata(const char* idp_metadata_xml);

/* Builds an HTTP-Redirect AuthnRequest against the IdP and returns
 * {"ok", "redirect_url", "request_id", "tracker"}. The caller stores
 * `tracker` opaquely (short TTL) and hands it back at verify time; the
 * pending-request cache and its expiry are CALLER state. `relay_state_utf8`
 * may be NULL. */
char* cc_saml_build_authn_request(const char* idp_metadata_xml,
                                  const char* sp_entity_id,
                                  const char* acs_url,
                                  const char* relay_state_utf8);

/* Verifies + consumes a POST-binding SAMLResponse (raw XML — the caller
 * base64-decodes the form field first). `tracker_json_utf8` may be NULL
 * (then CC_SAML_FLAG_ALLOW_UNSOLICITED governs). `now_epoch_secs` and
 * `clock_skew_secs` are the caller-owned validation clock (Dart injects
 * DateTime.now() in production, fixed times in tests).
 *
 * Success: {"ok", "name_id", "name_id_format", "attributes": {name: [vals]},
 *           "assertion_id", "not_on_or_after", "session_index"?,
 *           "is_one_time_use"}.
 * Failure:  {"ok": false, "error_code": <code>, "error": <message>} with
 * codes: signature | expired | audience | destination | request_match |
 * issuer | recipient | malformed | status | invalid | internal. */
char* cc_saml_verify_response(const char* idp_metadata_xml,
                              const char* sp_entity_id,
                              const char* acs_url,
                              uint32_t flags,
                              const char* tracker_json_utf8,
                              const char* response_xml_utf8,
                              int64_t now_epoch_secs,
                              int64_t clock_skew_secs);

/* Emits this SP's EntityDescriptor metadata XML (entityID, POST ACS, NameID
 * formats; no signing cert — AuthnRequests are unsigned). Raw XML on
 * success, JSON error object on failure. */
char* cc_saml_sp_metadata(const char* sp_entity_id, const char* acs_url);

#ifdef __cplusplus
}
#endif

#endif /* CC_SAML_H */
