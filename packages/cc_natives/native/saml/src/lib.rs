//! cc_saml — Control Center's SAML 2.0 service-provider native.
//!
//! FIRST-PARTY seam (not vendored crypto): the C ABI in `cc_saml.h` is
//! consumed by `packages/cc_natives/lib/src/saml/` over `dart:ffi`. All
//! XML-DSig verification, canonicalization and SAML profile validation live
//! in the pinned pure-Rust `saml` crate (quick-xml + RustCrypto; no
//! libxml2/xmlsec1/openssl C toolchain). Built by
//! `scripts/natives/build_saml.sh`.
//!
//! Statelessness is the design: every entry point takes its whole world as
//! arguments and returns a JSON string. The one piece of cross-request state
//! SAML needs — matching an ACS'd Response back to the AuthnRequest that
//! started it — travels as the serialized `LoginTracker` JSON that
//! `cc_saml_build_authn_request` returns and `cc_saml_verify_response`
//! accepts back; the CALLER (Dart) stores it with a TTL, exactly like the
//! OIDC pending-state map. Replay defense is likewise caller-side: the verify
//! result carries `assertion_id` + `not_on_or_after` for the caller's dedupe
//! cache (the crate's in-memory cache sweeps by wall clock, which would mix
//! clock sources with the caller-supplied validation clock).
//!
//! Every extern "C" body is wrapped in `catch_unwind`: a panic becomes a
//! NULL return plus `cc_saml_last_error`, never an unwind across FFI.
//! Domain failures are NOT null — they are `{"ok": false, "error_code": …}`
//! JSON so Dart can branch on typed codes.

use std::ffi::{c_char, CStr, CString};
use std::panic::{catch_unwind, AssertUnwindSafe};
use std::time::{Duration, SystemTime, UNIX_EPOCH};

use saml::binding::{Binding, Dispatch, SsoResponseBinding, SsoResponseEndpoint};
use saml::descriptor::IdpDescriptor;
use saml::dsig::algorithms::{DigestAlgorithm, PeerCryptoPolicy, SignatureAlgorithm};
use saml::error::Error;
use saml::nameid::NameIdFormat;
use saml::response::Identity;
use saml::sp::{LoginTracker, ServiceProvider, ServiceProviderConfig, SpWantSigned, StartLogin};

pub const ABI_VERSION: u32 = 1;

/// `cc_saml_verify_response` flags — the SP-side signing/unsolicited policy.
pub const FLAG_WANT_ASSERTIONS_SIGNED: u32 = 1;
pub const FLAG_ALLOW_UNSOLICITED: u32 = 2;
pub const FLAG_WANT_RESPONSE_SIGNED: u32 = 4;

thread_local! {
    static LAST_ERROR: std::cell::RefCell<Option<CString>> =
        const { std::cell::RefCell::new(None) };
}

fn set_last_error(message: String) {
    LAST_ERROR.with(|slot| {
        *slot.borrow_mut() = Some(CString::new(message).unwrap_or_else(|_| {
            CString::new("error message contained NUL").unwrap()
        }));
    });
}

#[no_mangle]
pub extern "C" fn cc_saml_abi_version() -> u32 {
    ABI_VERSION
}

#[no_mangle]
pub extern "C" fn cc_saml_last_error() -> *const c_char {
    LAST_ERROR.with(|slot| {
        slot.borrow()
            .as_ref()
            .map(|s| s.as_ptr())
            .unwrap_or(std::ptr::null())
    })
}

/// Frees a string returned by this library (leaked `CString` outs).
///
/// # Safety
/// `ptr` must originate from a non-null return of one of the `cc_saml_*`
/// functions and must not be freed twice.
#[no_mangle]
pub unsafe extern "C" fn cc_saml_free_string(ptr: *mut c_char) {
    if !ptr.is_null() {
        drop(CString::from_raw(ptr));
    }
}

fn leak_json(value: serde_json::Value) -> *mut c_char {
    match CString::new(value.to_string()) {
        Ok(s) => s.into_raw(),
        Err(_) => {
            set_last_error("JSON output contained NUL".into());
            std::ptr::null_mut()
        }
    }
}

unsafe fn arg_str<'a>(ptr: *const c_char, name: &str) -> Result<&'a str, String> {
    if ptr.is_null() {
        return Err(format!("{name} is null"));
    }
    CStr::from_ptr(ptr).to_str().map_err(|_| format!("{name} is not valid UTF-8"))
}

fn epoch_of(t: SystemTime) -> i64 {
    t.duration_since(UNIX_EPOCH)
        .map(|d| d.as_secs() as i64)
        .unwrap_or(0)
}

fn build_sp(
    entity_id: &str,
    acs_url: &str,
    want: SpWantSigned,
    allow_unsolicited: bool,
) -> Result<ServiceProvider, Error> {
    ServiceProvider::new(ServiceProviderConfig {
        entity_id: entity_id.to_owned(),
        acs: vec![SsoResponseEndpoint::post(acs_url, 0, true)],
        slo: vec![],
        name_id_formats: vec![NameIdFormat::Persistent, NameIdFormat::EmailAddress],
        signing_key: None, // Unsigned AuthnRequests; Okta/Entra default accepts this.
        decryption_key: None,
        sign_authn_requests: false,
        want_signed: want,
        allow_unsolicited,
        logout_signing: saml::SpLogoutSigning::default(),
        logout_want_signed: saml::SpLogoutWantSigned::default(),
        default_peer_crypto_policy: PeerCryptoPolicy::strong_defaults(),
        outbound_signature_algorithm: SignatureAlgorithm::RsaSha256,
        outbound_digest_algorithm: DigestAlgorithm::Sha256,
    })
}

fn want_from_flags(flags: u32) -> SpWantSigned {
    SpWantSigned {
        response: flags & FLAG_WANT_RESPONSE_SIGNED != 0,
        assertions: flags & FLAG_WANT_ASSERTIONS_SIGNED != 0,
    }
}

fn identity_to_json(identity: &Identity) -> serde_json::Value {
    let mut attributes = serde_json::Map::new();
    for attr in &identity.attributes {
        let key = match attr.friendly_name.as_deref() {
            Some(f) if !f.is_empty() => f.to_owned(),
            _ if !attr.name.is_empty() => attr.name.clone(),
            _ => continue,
        };
        attributes.insert(key, serde_json::json!(attr.values));
    }
    serde_json::json!({
        "ok": true,
        "name_id": identity.name_id.value,
        "name_id_format": serde_json::to_value(&identity.name_id.format)
            .unwrap_or(serde_json::Value::Null),
        "attributes": attributes,
        "assertion_id": identity.assertion_id,
        "not_on_or_after": epoch_of(identity.not_on_or_after),
        "session_index": identity.session_index,
        "is_one_time_use": identity.is_one_time_use,
    })
}

/// Maps a crate error onto the stable wire codes Dart branches on. The codes
/// are ABI: keep in sync with `SamlErrorCode` in the Dart bindings.
fn error_code(e: &Error) -> &'static str {
    match e {
        Error::SignatureVerification { .. }
        | Error::SignatureMissing
        | Error::ReferenceResolution
        | Error::NoPeerSigningCert
        | Error::DisallowedAlgorithm { .. }
        | Error::DisallowedTransform { .. } => "signature",
        Error::Expired | Error::NotYetValid => "expired",
        Error::AudienceMismatch => "audience",
        Error::DestinationMismatch => "destination",
        Error::InResponseToMismatch | Error::UnsolicitedNotAllowed => "request_match",
        Error::IssuerMismatch { .. } => "issuer",
        Error::RecipientMismatch => "recipient",
        Error::XmlParse(_)
        | Error::Inflate
        | Error::SchemaViolation { .. }
        | Error::IllegalResponseBinding { .. } => "malformed",
        Error::StatusNotSuccess { .. } => "status",
        _ => "invalid",
    }
}

fn error_json(e: &Error) -> serde_json::Value {
    serde_json::json!({
        "ok": false,
        "error_code": error_code(e),
        "error": e.to_string(),
    })
}

/// Parses an IdP EntityDescriptor (the XML the admin pastes/downloads) into
/// the fields the config UI and the login flow need.
///
/// # Safety
/// `xml_utf8` must be a valid NUL-terminated UTF-8 string for the call.
#[no_mangle]
pub unsafe extern "C" fn cc_saml_parse_idp_metadata(xml_utf8: *const c_char) -> *mut c_char {
    catch_unwind(AssertUnwindSafe(|| {
        let xml = match arg_str(xml_utf8, "idp metadata xml") {
            Ok(x) => x,
            Err(e) => return set_null_err(e),
        };
        match IdpDescriptor::from_metadata_xml(xml.as_bytes()) {
            Ok(desc) => leak_json(serde_json::json!({
                "ok": true,
                "entity_id": desc.entity_id,
                "sso_redirect": desc.sso_endpoint(Binding::HttpRedirect).map(|e| e.url.clone()),
                "sso_post": desc.sso_endpoint(Binding::HttpPost).map(|e| e.url.clone()),
                "signing_certs": desc.signing_certs.iter()
                    .map(|c| c.to_base64_x509())
                    .collect::<Vec<_>>(),
            })),
            Err(e) => leak_json(error_json(&e)),
        }
    }))
    .unwrap_or_else(|_| {
        set_null_err("panic in cc_saml_parse_idp_metadata".into());
        std::ptr::null_mut()
    })
}

fn set_null_err(msg: String) -> *mut c_char {
    set_last_error(msg);
    std::ptr::null_mut()
}

/// Builds an HTTP-Redirect-binding AuthnRequest against the IdP and returns
/// `{"redirect_url", "request_id", "tracker"}`. `tracker` is opaque JSON the
/// caller must store (short TTL) and hand back to `cc_saml_verify_response`.
///
/// # Safety
/// All string args must be valid NUL-terminated UTF-8; `relay_state_utf8`
/// may be null.
#[no_mangle]
pub unsafe extern "C" fn cc_saml_build_authn_request(
    idp_metadata_xml: *const c_char,
    sp_entity_id: *const c_char,
    acs_url: *const c_char,
    relay_state_utf8: *const c_char,
) -> *mut c_char {
    catch_unwind(AssertUnwindSafe(|| {
        let run = || -> Result<serde_json::Value, String> {
            let xml = arg_str(idp_metadata_xml, "idp metadata xml")?;
            let sp_entity = arg_str(sp_entity_id, "sp entity id")?;
            let acs = arg_str(acs_url, "acs url")?;
            let relay = if relay_state_utf8.is_null() {
                None
            } else {
                Some(arg_str(relay_state_utf8, "relay state")?)
            };
            let idp = IdpDescriptor::from_metadata_xml(xml.as_bytes())
                .map_err(|e| e.to_string())?;
            let sp = build_sp(sp_entity, acs, SpWantSigned { response: false, assertions: true }, false)
                .map_err(|e| e.to_string())?;
            let start = sp
                .start_login(
                    &idp,
                    StartLogin {
                        relay_state: relay,
                        binding: Binding::HttpRedirect,
                        force_authn: false,
                        is_passive: false,
                        requested_name_id_format: None,
                        requested_authn_context: None,
                        acs_index: None,
                        acs_url: None,
                        response_binding: Some(SsoResponseBinding::HttpPost),
                    },
                )
                .map_err(|e| e.to_string())?;
            match start.dispatch {
                Dispatch::Redirect(url) => Ok(serde_json::json!({
                    "ok": true,
                    "redirect_url": url.as_str(),
                    "request_id": start.tracker.request_id,
                    "tracker": serde_json::to_value(&start.tracker)
                        .map_err(|e| e.to_string())?,
                })),
                Dispatch::Post(_) => Err("redirect binding produced a POST dispatch".into()),
            }
        };
        match run() {
            Ok(v) => leak_json(v),
            Err(msg) => leak_json(serde_json::json!({
                "ok": false, "error_code": "internal", "error": msg,
            })),
        }
    }))
    .unwrap_or_else(|_| {
        set_null_err("panic in cc_saml_build_authn_request".into());
        std::ptr::null_mut()
    })
}

/// Verifies + consumes a POST-binding SAMLResponse (raw XML; the caller
/// base64-decodes the form field) against the IdP metadata and SP policy.
///
/// Returns the identity JSON (see `identity_to_json`) or
/// `{"ok": false, "error_code", "error"}`. NULL only on panic/OOM.
///
/// # Safety
/// All string args must be valid NUL-terminated UTF-8; `tracker_json_utf8`
/// may be null (unsolicited responses require FLAG_ALLOW_UNSOLICITED).
#[no_mangle]
pub unsafe extern "C" fn cc_saml_verify_response(
    idp_metadata_xml: *const c_char,
    sp_entity_id: *const c_char,
    acs_url: *const c_char,
    flags: u32,
    tracker_json_utf8: *const c_char,
    response_xml_utf8: *const c_char,
    now_epoch_secs: i64,
    clock_skew_secs: i64,
) -> *mut c_char {
    catch_unwind(AssertUnwindSafe(|| {
        let run = || -> Result<serde_json::Value, String> {
            let xml = arg_str(idp_metadata_xml, "idp metadata xml")?;
            let sp_entity = arg_str(sp_entity_id, "sp entity id")?;
            let acs = arg_str(acs_url, "acs url")?;
            let response = arg_str(response_xml_utf8, "response xml")?;
            let tracker: Option<LoginTracker> = if tracker_json_utf8.is_null() {
                None
            } else {
                Some(
                    serde_json::from_str(arg_str(tracker_json_utf8, "tracker json")?)
                        .map_err(|e| format!("tracker json invalid: {e}"))?,
                )
            };
            let now = if now_epoch_secs >= 0 {
                UNIX_EPOCH + Duration::from_secs(now_epoch_secs as u64)
            } else {
                UNIX_EPOCH
            };
            let idp = IdpDescriptor::from_metadata_xml(xml.as_bytes())
                .map_err(|e| e.to_string())?;
            let sp = build_sp(
                sp_entity,
                acs,
                want_from_flags(flags),
                flags & FLAG_ALLOW_UNSOLICITED != 0,
            )
            .map_err(|e| e.to_string())?;
            match sp.consume_response(saml::sp::ConsumeResponse {
                idp: &idp,
                peer_crypto_policy: None, // SP default: strong_defaults.
                saml_response: response.as_bytes(),
                binding: SsoResponseBinding::HttpPost,
                relay_state: None,
                tracker: tracker.as_ref(),
                expected_destination: acs,
                now,
                clock_skew: Duration::from_secs(clock_skew_secs.max(0) as u64),
                replay_cache: None, // Caller-side dedupe on assertion_id.
                replay_mode: saml::replay::ReplayMode::Off,
                holder_of_key_cert: None,
            }) {
                Ok(identity) => Ok(identity_to_json(&identity)),
                // Domain failures are data, not NULL: Dart branches on the code.
                Err(e) => Ok(error_json(&e)),
            }
        };
        match run() {
            Ok(v) => leak_json(v),
            Err(msg) => leak_json(serde_json::json!({
                "ok": false, "error_code": "internal", "error": msg,
            })),
        }
    }))
    .unwrap_or_else(|_| {
        set_null_err("panic in cc_saml_verify_response".into());
        std::ptr::null_mut()
    })
}

/// Emits this SP's EntityDescriptor metadata (entityID, POST ACS, NameID
/// formats) for the admin to register with the IdP. No signing cert is
/// declared — we send unsigned AuthnRequests.
///
/// # Safety
/// String args must be valid NUL-terminated UTF-8.
#[no_mangle]
pub unsafe extern "C" fn cc_saml_sp_metadata(
    sp_entity_id: *const c_char,
    acs_url: *const c_char,
) -> *mut c_char {
    catch_unwind(AssertUnwindSafe(|| {
        let run = || -> Result<String, String> {
            let sp_entity = arg_str(sp_entity_id, "sp entity id")?;
            let acs = arg_str(acs_url, "acs url")?;
            let sp = build_sp(
                sp_entity,
                acs,
                SpWantSigned { response: false, assertions: true },
                false,
            )
            .map_err(|e| e.to_string())?;
            sp.metadata_xml(false).map_err(|e| e.to_string())
        };
        match run() {
            Ok(xml) => match CString::new(xml) {
                Ok(s) => s.into_raw(),
                Err(_) => set_null_err("metadata XML contained NUL".into()),
            },
            Err(msg) => leak_json(serde_json::json!({
                "ok": false, "error_code": "internal", "error": msg,
            })),
        }
    }))
    .unwrap_or_else(|_| {
        set_null_err("panic in cc_saml_sp_metadata".into());
        std::ptr::null_mut()
    })
}

// =============================================================================
// Tests (unit — they compile the crate itself, so the `saml` dependency is
// visible; the conformance corpus drives the extern entry points directly so
// the FFI seam is what's under test).
// =============================================================================
#[cfg(test)]
mod tests;
