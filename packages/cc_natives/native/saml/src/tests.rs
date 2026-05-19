//! Conformance corpus for the cc_saml FFI seam.
//!
//! Every test drives the extern "C" entry points themselves (not internal
//! helpers) with real signed responses minted by the `saml` crate's IdP side,
//! so what's under test is exactly what Dart will call. The corpus is the
//! security ratchet for the pinned dependency: re-run on every bump of the
//! `saml` crate and extend it before relaxing anything.

use std::ffi::{c_char, CStr, CString};
use std::io::Read;
use std::time::{Duration, SystemTime};

use base64::engine::general_purpose::STANDARD as BASE64;
use base64::Engine as _;

use saml::attribute::Attribute;
use saml::authn_context::AuthnContextClassRef;
use saml::binding::{Binding, Endpoint, SsoResponseDispatch};
use saml::crypto::cert::X509Certificate;
use saml::crypto::keypair::KeyPair;
use saml::descriptor::SpDescriptor;
use saml::dsig::algorithms::{
    C14nAlgorithm, DigestAlgorithm, PeerCryptoPolicy, SignatureAlgorithm,
};
use saml::idp::{ConsumeAuthnRequest, IdentityProvider, IdentityProviderConfig, IssueResponse};
use saml::nameid::{NameId, NameIdFormat};
use saml::xmlenc::algorithms::{DataEncryptionAlgorithm, KeyTransportAlgorithm};

use crate::*;

const SP_ENTITY_ID: &str = "https://cc.example.com/saml";
const SP_ACS_URL: &str = "https://cc.example.com/saml/acs";
const SP_B_ENTITY_ID: &str = "https://other.example.com/saml";
const IDP_ENTITY_ID: &str = "https://idp.example.com";
const IDP_SSO_URL: &str = "https://idp.example.com/sso";
const USER_EMAIL: &str = "alice@example.com";
const USER_NAME: &str = "Alice Example";

const RSA_CERT_PEM: &[u8] = b"-----BEGIN CERTIFICATE-----
MIIDCzCCAfOgAwIBAgIUMOn0qquTgAJJwHbKm2N1V464CDIwDQYJKoZIhvcNAQEL
BQAwFDESMBAGA1UEAwwJc2FtbC10ZXN0MCAXDTI2MDUyNjIxMzcwMVoYDzIxMjYw
NTAyMjEzNzAxWjAUMRIwEAYDVQQDDAlzYW1sLXRlc3QwggEiMA0GCSqGSIb3DQEB
AQUAA4IBDwAwggEKAoIBAQDaqL2wBXPWOtBqKErO58ddEa8L9r7OlI1Gh+SseXo1
ZYYH/cISplLMqch8SWk0rH4Aeg1/dcGYATVHYisToko785FphNiAVN3Mz4sL99lU
G7kogP88Beoe0N0s5o8Q53OXD2mHiLwkds0SoH5p8ghlM+Spw1gSq70+MJGKnaBS
O1XocupxARVb1MYhGnDDbJYAip2P2/eg0M7TPi4Kwe6yRndRbcTzKltTOECKaUBU
RbdE6fkwegMNOZ7vivQYsNUkrrgDYjEIKh8bmSsI61vNNhYJpdgja0UHnfguKinX
vF0GlFdtAWn9N8i+d7BfHyaj4TWjqRL8xM5ThM7Cts7BAgMBAAGjUzBRMB0GA1Ud
DgQWBBSyw8b031HFXwOSpE0SzavfT1RHxjAfBgNVHSMEGDAWgBSyw8b031HFXwOS
pE0SzavfT1RHxjAPBgNVHRMBAf8EBTADAQH/MA0GCSqGSIb3DQEBCwUAA4IBAQDG
Tn/w5sMK7ceNJa1jAwJKdhumlwknBP3ifozKX3ikmdU+yAs4W1iiGXtaZaL9tv6/
Pg9YXJBJaEO5tyH/xwEjH7+QDqrCIZ77ljZk0Qf0Rl3jdUnnR6TGF4+ToKtN+uG0
gZwXRBtjo+B/hL5mxP72/AHqvowVGblTzuefruuEUs/2bOD11XjW7wKl7kzYLZ65
kj8IXjzTetBlAqqhmQrEmIwVAtcURS+lfLvl7QZVvRwuKadvIa63kJSybV51oahN
08amDJRd0NXHBYHpPlCCUwujcTw2aBGzRgR+Pkx/kJSTOcx4+QZiYBB3BCvYhzg5
UkTEs4+5J1kgDIklDumS
-----END CERTIFICATE-----";

const RSA_KEY_PKCS8_PEM: &[u8] = b"-----BEGIN PRIVATE KEY-----
MIIEvQIBADANBgkqhkiG9w0BAQEFAASCBKcwggSjAgEAAoIBAQDaqL2wBXPWOtBq
KErO58ddEa8L9r7OlI1Gh+SseXo1ZYYH/cISplLMqch8SWk0rH4Aeg1/dcGYATVH
YisToko785FphNiAVN3Mz4sL99lUG7kogP88Beoe0N0s5o8Q53OXD2mHiLwkds0S
oH5p8ghlM+Spw1gSq70+MJGKnaBSO1XocupxARVb1MYhGnDDbJYAip2P2/eg0M7T
Pi4Kwe6yRndRbcTzKltTOECKaUBURbdE6fkwegMNOZ7vivQYsNUkrrgDYjEIKh8b
mSsI61vNNhYJpdgja0UHnfguKinXvF0GlFdtAWn9N8i+d7BfHyaj4TWjqRL8xM5T
hM7Cts7BAgMBAAECggEABncvn7czjwm/bKorFx3lqF/73PbTesyL9mJRjdOMPGy3
d0BGxzIll+Fr2Rf7HUh989HoGQUgf7gGbSlPFIYrm4T232fDFp1bzyDyb7zJD3p/
4b2Zvnq+yuE6bwfUwmdTpMt6/3vYs1vTccnu3v9eBe8QQ4BQGAI9xutc/Fwvl8rV
FZ+/Ze07Mbbxk9f+PROFI/xCopwup1/rMBuN5CEgaL1uZmZPl9snVADjMkn2TluV
XeS01xq7ahpJxjr/tIl5XgFC/214DpLLUxgxGPvKnvPOaUsSwnWZ0S2Se8VJsa7p
i/jM4R/VXa5j52kIDOf8gojg+7BxoRxCqxTzSJl9CQKBgQD/cO2rbHA/bj81xebh
Th5DzJHFdDQJEjPqg8E2jBKrUKli0LsH0WmtNozVjv2RrB4VU5dJmGINJu26i5p/
rbkhtoCfZqoCyWnz1pbHPHoe2OSQhIUv2Srd/VhbvqNTjAMdebnFH+s/ewrxlh9S
kpY8leANhIRJfYzkHylkHocNSQKBgQDbIzYMFd7oywEj3IE+LCLQXHEbwxrPfR23
rC0gfR0RseupxNosMTnHNRjF7bXg+qKO6AQ8MZaYgfyUjELDgpLrKhBOc84HgAvD
HuUz3xVlWIdOQS3LcReHjN7tyFjR+SUYywuRiPNskyZOfWlt8LnvjPy2Xx/bcHht
Vooqe2WNuQKBgBUmEmdo+PondJBNLEpnH1ZZr4/7iPtfSHEYK30Kp9kLOpr10SZa
jjdLFunvhsryxyLY4uOy/Bs+p9wUBtyfU36ZD5ki9Nx6NI19rMoeFbZMGtBkSGqn
vkbW3OPrqrYWF4PvOhQ6Ck4dL9DErx81B79IYV59JD65aFrSwaiKZoARAoGBANmE
DfXZD7ZLKwqJqdAoxzXDTJKeC1LBgmn6gaCqD9ysmpudRmJvSkauMbTly49RuWHY
c7u8DRu8ixZ4Uxz10xeSXTVCRdO0CfjYBfKDER3TzhqjH+28h/qIng+wullR0LzX
btg69EVlmrR2T9xNAoMBkycDLQAIl8EQEX0xlxAhAoGAWNKS/mkM7OTHp1sOzcZ+
3qNoH4s30zdYQAmSwdgZDe+LcCnvZn8IsxsR5aaJYbYFeziAeB+PVMfTdcW89/Qn
72b0KDgBZ9FpLMzYg86nuAZ0moDgg2hY49e+XD6VYVwiPWO5VL4CE+HGyfOsqgDx
K0dYsJzrrDnL23ajO1yzAak=
-----END PRIVATE KEY-----";

fn now() -> SystemTime {
    SystemTime::now()
}

fn keypair() -> Result<KeyPair, Box<dyn std::error::Error + Send + Sync>> {
    Ok(KeyPair::from_pkcs8_pem(RSA_KEY_PKCS8_PEM)?
        .with_certificate(X509Certificate::from_pem(RSA_CERT_PEM)?))
}

fn make_idp() -> Result<IdentityProvider, Box<dyn std::error::Error + Send + Sync>> {
    Ok(IdentityProvider::new(IdentityProviderConfig {
        entity_id: IDP_ENTITY_ID.to_owned(),
        sso: vec![
            Endpoint::post(IDP_SSO_URL, 0, true),
            Endpoint::redirect(IDP_SSO_URL, 1, false),
        ],
        slo: vec![],
        artifact_resolution: vec![],
        supported_name_id_formats: vec![NameIdFormat::Persistent, NameIdFormat::EmailAddress],
        default_name_id_format: NameIdFormat::EmailAddress,
        signing_key: keypair()?,
        decryption_key: None,
        want_authn_requests_signed: false,
        assertion_signing: saml::IdpAssertionSigning {
            sign_responses: false,
            sign_assertions: true,
        },
        encrypt_assertions_when_possible: false,
        logout_signing: saml::IdpLogoutSigning::default(),
        logout_want_signed: saml::IdpLogoutWantSigned::default(),
        default_session_duration: Duration::from_hours(1),
        default_peer_crypto_policy: PeerCryptoPolicy::strong_defaults(),
        outbound_signature_algorithm: SignatureAlgorithm::RsaSha256,
        outbound_digest_algorithm: DigestAlgorithm::Sha256,
        outbound_c14n: C14nAlgorithm::ExclusiveCanonical,
        outbound_data_encryption_algorithm: DataEncryptionAlgorithm::Aes256Gcm,
        outbound_key_transport_algorithm: KeyTransportAlgorithm::RsaOaep,
    })?)
}

fn idp_metadata() -> Result<String, Box<dyn std::error::Error + Send + Sync>> {
    Ok(make_idp()?.metadata_xml(false)?)
}

// -- FFI plumbing ------------------------------------------------------------

fn c(s: &str) -> CString {
    CString::new(s).unwrap()
}

unsafe fn take_json(ptr: *mut c_char) -> serde_json::Value {
    assert!(!ptr.is_null(), "native returned NULL: {:?}", error_message());
    let raw = CString::from_raw(ptr); // takes ownership; do not free twice
    let s = raw.to_str().expect("UTF-8 JSON");
    // sp_metadata returns raw XML, not JSON — only call this on JSON outs.
    serde_json::from_str(s).unwrap_or_else(|_| panic!("not JSON: {s}"))
}

unsafe fn error_message() -> String {
    let p = cc_saml_last_error();
    if p.is_null() {
        "(no last_error)".into()
    } else {
        CStr::from_ptr(p).to_string_lossy().into_owned()
    }
}

unsafe fn build_authn_request(metadata: &str, relay: Option<&str>) -> serde_json::Value {
    let relay_ptr = relay.map(|r| c(r)).unwrap_or_default();
    take_json(cc_saml_build_authn_request(
        c(metadata).as_ptr(),
        c(SP_ENTITY_ID).as_ptr(),
        c(SP_ACS_URL).as_ptr(),
        if relay.is_some() { relay_ptr.as_ptr() } else { std::ptr::null() },
    ))
}

/// Mints a signed Response for OUR SP by driving the crate's IdP against a
/// real AuthnRequest. Returns the raw response XML plus the SP-side tracker
/// JSON our FFI produced (so the test consumes exactly like Dart will).
unsafe fn issue_response(
    now: SystemTime,
    sp_entity_id: &str,
) -> Result<(String, String), Box<dyn std::error::Error + Send + Sync>> {
    let idp = make_idp()?;
    let sp = saml::sp::ServiceProvider::new(saml::sp::ServiceProviderConfig {
        entity_id: sp_entity_id.to_owned(),
        acs: vec![saml::binding::SsoResponseEndpoint::post(SP_ACS_URL, 0, true)],
        slo: vec![],
        name_id_formats: vec![NameIdFormat::Persistent, NameIdFormat::EmailAddress],
        signing_key: None,
        decryption_key: None,
        sign_authn_requests: false,
        want_signed: saml::SpWantSigned { response: false, assertions: true },
        allow_unsolicited: false,
        logout_signing: saml::SpLogoutSigning::default(),
        logout_want_signed: saml::SpLogoutWantSigned::default(),
        default_peer_crypto_policy: PeerCryptoPolicy::strong_defaults(),
        outbound_signature_algorithm: SignatureAlgorithm::RsaSha256,
        outbound_digest_algorithm: DigestAlgorithm::Sha256,
    })?;
    let sp_desc = SpDescriptor::from_metadata_xml(sp.metadata_xml(false)?.as_bytes())?;

    // Ask OUR FFI for the AuthnRequest so the tracker JSON is the real thing.
    let metadata = idp.metadata_xml(false)?;
    let start_json = build_authn_request(&metadata, Some("relay-1"));
    assert_eq!(start_json["ok"], serde_json::json!(true), "build_authn_request failed");
    let tracker_json = start_json["tracker"].to_string();
    let redirect_url = start_json["redirect_url"].as_str().unwrap().to_owned();

    // IdP consumes the redirect (raw-DEFLATE + base64 in the query param).
    let url = url::Url::parse(&redirect_url)?;
    let b64 = url
        .query_pairs()
        .find(|(k, _)| k == "SAMLRequest")
        .map(|(_, v)| v.into_owned())
        .ok_or("no SAMLRequest in redirect URL")?;
    let compressed = BASE64.decode(b64.as_bytes())?;
    let mut authn_xml = String::new();
    flate2::read::DeflateDecoder::new(&compressed[..])
        .read_to_string(&mut authn_xml)?;

    let parsed = idp.consume_authn_request(ConsumeAuthnRequest {
        sp: &sp_desc,
        peer_crypto_policy: None,
        saml_request: authn_xml.as_bytes(),
        binding: Binding::HttpRedirect,
        relay_state: None,
        detached_signature: None,
        expected_destination: IDP_SSO_URL,
        now,
        clock_skew: Duration::from_mins(2),
    })?;

    let dispatch = idp.issue_response(IssueResponse {
        sp: &sp_desc,
        in_response_to: &parsed,
        name_id: NameId::email(USER_EMAIL),
        attributes: vec![
            Attribute::email(USER_EMAIL),
            Attribute::display_name(USER_NAME),
        ],
        authn_instant: now,
        session_index: "sess-1".to_owned(),
        session_not_on_or_after: Some(now + Duration::from_hours(1)),
        authn_context_class_ref: AuthnContextClassRef::PasswordProtectedTransport,
        force_encrypt_assertion: None,
        now,
        assertion_lifetime: Duration::from_mins(10),
        subject_confirmation_lifetime: Duration::from_mins(5),
        holder_of_key_cert: None,
    })?;

    let xml = match dispatch {
        SsoResponseDispatch::Post(form) => String::from_utf8(BASE64.decode(form.saml_response.as_bytes())?)?,
        SsoResponseDispatch::Artifact(_) => panic!("expected POST dispatch"),
    };
    Ok((xml, tracker_json))
}

unsafe fn verify(
    metadata: &str,
    tracker_json: Option<&str>,
    response_xml: &str,
    now: SystemTime,
    acs: &str,
    flags: u32,
) -> serde_json::Value {
    verify_as(metadata, SP_ENTITY_ID, tracker_json, response_xml, now, acs, flags)
}

unsafe fn verify_as(
    metadata: &str,
    sp_entity_id: &str,
    tracker_json: Option<&str>,
    response_xml: &str,
    now: SystemTime,
    acs: &str,
    flags: u32,
) -> serde_json::Value {
    let tracker = tracker_json.map(c).unwrap_or_default();
    take_json(cc_saml_verify_response(
        c(metadata).as_ptr(),
        c(sp_entity_id).as_ptr(),
        c(acs).as_ptr(),
        flags,
        if tracker_json.is_some() { tracker.as_ptr() } else { std::ptr::null() },
        c(response_xml).as_ptr(),
        now.duration_since(std::time::UNIX_EPOCH).unwrap().as_secs() as i64,
        120,
    ))
}

fn assertion_span(xml: &str) -> Option<(usize, usize)> {
    for open in ["<saml2:Assertion", "<saml:Assertion", "<Assertion"] {
        if let Some(start) = xml.find(open) {
            let close = format!("</{}>", &open[1..]);
            let end = xml[start..].find(&close)? + start + close.len();
            return Some((start, end));
        }
    }
    None
}

// -- The corpus --------------------------------------------------------------

#[test]
fn ffi_happy_path_round_trip() {
    unsafe {
        let metadata = idp_metadata().unwrap();
        let now = now();
        let (xml, tracker_json) = issue_response(now, SP_ENTITY_ID).unwrap();
        let out = verify(&metadata, Some(&tracker_json), &xml, now, SP_ACS_URL,
            FLAG_WANT_ASSERTIONS_SIGNED);
        assert_eq!(out["ok"], serde_json::json!(true), "verify failed: {out}");
        assert_eq!(out["name_id"], serde_json::json!(USER_EMAIL));
        assert_eq!(out["attributes"]["mail"], serde_json::json!([USER_EMAIL]));
        assert_eq!(out["attributes"]["displayName"], serde_json::json!([USER_NAME]));
        assert!(out["assertion_id"].as_str().is_some_and(|s| !s.is_empty()));
        assert!(out["not_on_or_after"].as_i64().is_some_and(|t| t > 0));
    }
}

#[test]
fn ffi_metadata_parse() {
    unsafe {
        let metadata = idp_metadata().unwrap();
        let out = take_json(cc_saml_parse_idp_metadata(c(&metadata).as_ptr()));
        assert_eq!(out["ok"], serde_json::json!(true));
        assert_eq!(out["entity_id"], serde_json::json!(IDP_ENTITY_ID));
        assert_eq!(out["sso_post"], serde_json::json!(IDP_SSO_URL));
        assert_eq!(out["sso_redirect"], serde_json::json!(IDP_SSO_URL));
        assert!(out["signing_certs"].as_array().is_some_and(|a| !a.is_empty()));
    }
}

#[test]
fn ffi_sp_metadata_emits_parseable_descriptor() {
    unsafe {
        let ptr = cc_saml_sp_metadata(c(SP_ENTITY_ID).as_ptr(), c(SP_ACS_URL).as_ptr());
        assert!(!ptr.is_null());
        let raw = CString::from_raw(ptr);
        let xml = raw.to_str().unwrap();
        let desc = SpDescriptor::from_metadata_xml(xml.as_bytes()).unwrap();
        assert_eq!(desc.entity_id, SP_ENTITY_ID);
    }
}

#[test]
fn ffi_rejects_tampered_assertion() {
    unsafe {
        let metadata = idp_metadata().unwrap();
        let now = now();
        let (xml, tracker) = issue_response(now, SP_ENTITY_ID).unwrap();
        let tampered = xml.replacen(USER_EMAIL, "blive@example.com", 1);
        let out = verify(&metadata, Some(&tracker), &tampered, now, SP_ACS_URL,
            FLAG_WANT_ASSERTIONS_SIGNED);
        assert_eq!(out["ok"], serde_json::json!(false), "tamper accepted: {out}");
        assert_eq!(out["error_code"], serde_json::json!("signature"));
    }
}

#[test]
fn ffi_rejects_expired_assertion() {
    unsafe {
        let metadata = idp_metadata().unwrap();
        let now = now();
        let (xml, tracker) = issue_response(now, SP_ENTITY_ID).unwrap();
        let out = verify(&metadata, Some(&tracker), &xml, now + Duration::from_mins(30),
            SP_ACS_URL, FLAG_WANT_ASSERTIONS_SIGNED);
        assert_eq!(out["ok"], serde_json::json!(false));
        assert_eq!(out["error_code"], serde_json::json!("expired"));
    }
}

#[test]
fn ffi_rejects_wrong_audience() {
    unsafe {
        let metadata = idp_metadata().unwrap();
        let now = now();
        // Issued for our SP, verified under a different SP identity: the
        // audience restriction names ours, not the verifier's.
        let (xml, tracker) = issue_response(now, SP_ENTITY_ID).unwrap();
        let out = verify_as(&metadata, SP_B_ENTITY_ID, Some(&tracker), &xml, now, SP_ACS_URL,
            FLAG_WANT_ASSERTIONS_SIGNED);
        assert_eq!(out["ok"], serde_json::json!(false), "foreign audience accepted: {out}");
        assert_eq!(out["error_code"], serde_json::json!("audience"));
    }
}

#[test]
fn ffi_rejects_unsolicited_response() {
    // No tracker: a Response carrying InResponseTo must be refused outright.
    //
    // NOTE: the ALLOW-unsolicited path (FLAG_ALLOW_UNSOLICITED, IdP-initiated
    // SSO) is NOT fixture-mintable through the crate's IdP API — its
    // issue_response always binds to a request and a true IdP-initiated
    // Response carries no InResponseTo at all. That path gets covered by the
    // Phase 6 manual Okta pass (IdP-initiated launch).
    unsafe {
        let metadata = idp_metadata().unwrap();
        let now = now();
        let (xml, _tracker) = issue_response(now, SP_ENTITY_ID).unwrap();
        let denied = verify(&metadata, None, &xml, now, SP_ACS_URL,
            FLAG_WANT_ASSERTIONS_SIGNED);
        assert_eq!(denied["ok"], serde_json::json!(false), "unsolicited accepted: {denied}");
        assert_eq!(denied["error_code"], serde_json::json!("request_match"));
    }
}

#[test]
fn ffi_rejects_wrong_destination() {
    unsafe {
        let metadata = idp_metadata().unwrap();
        let now = now();
        let (xml, tracker) = issue_response(now, SP_ENTITY_ID).unwrap();
        let out = verify(&metadata, Some(&tracker), &xml, now, "https://evil.example.com/acs",
            FLAG_WANT_ASSERTIONS_SIGNED);
        assert_eq!(out["ok"], serde_json::json!(false));
        assert_eq!(out["error_code"], serde_json::json!("destination"));
    }
}

#[test]
fn ffi_rejects_xsw_duplicate_assertion_injection() {
    unsafe {
        let metadata = idp_metadata().unwrap();
        let now = now();
        let (xml, tracker) = issue_response(now, SP_ENTITY_ID).unwrap();
        let (start, end) = assertion_span(&xml).expect("assertion element found");
        let evil = xml[start..end].replace(USER_EMAIL, "mallory@example.com");
        let injected = format!("{}{}{}", &xml[..start], evil, &xml[start..]);
        let out = verify(&metadata, Some(&tracker), &injected, now, SP_ACS_URL,
            FLAG_WANT_ASSERTIONS_SIGNED);
        assert_eq!(out["ok"], serde_json::json!(false), "XSW accepted: {out}");
    }
}

#[test]
fn ffi_rejects_response_answering_a_different_request() {
    // Two independent logins: a Response answering request #2 must NOT
    // verify against request #1's tracker. Pins that InResponseTo binds to
    // the SPECIFIC outstanding request, not merely to "a" request — the
    // confusion a forwarded or re-sequenced Response would otherwise ride.
    unsafe {
        let metadata = idp_metadata().unwrap();
        let now = now();
        let (_xml1, tracker1) = issue_response(now, SP_ENTITY_ID).unwrap();
        let (xml2, _tracker2) = issue_response(now, SP_ENTITY_ID).unwrap();
        let out = verify(&metadata, Some(&tracker1), &xml2, now, SP_ACS_URL,
            FLAG_WANT_ASSERTIONS_SIGNED);
        assert_eq!(out["ok"], serde_json::json!(false),
            "cross-request confusion accepted: {out}");
        assert_eq!(out["error_code"], serde_json::json!("request_match"));
    }
}

#[test]
fn ffi_rejects_idp_error_status() {
    // A genuine IdP-minted ERROR Response (Status != Success, no Assertion):
    // the ACS must never treat a failure notice as a login. Minted through
    // the crate's own `issue_error_response`, so the shape is exactly what
    // a real IdP emits on failure.
    unsafe {
        use saml::{IssueErrorResponse, SamlStatusCode};

        let idp = make_idp().unwrap();
        let sp = saml::sp::ServiceProvider::new(saml::sp::ServiceProviderConfig {
            entity_id: SP_ENTITY_ID.to_owned(),
            acs: vec![saml::binding::SsoResponseEndpoint::post(SP_ACS_URL, 0, true)],
            slo: vec![],
            name_id_formats: vec![NameIdFormat::Persistent, NameIdFormat::EmailAddress],
            signing_key: None,
            decryption_key: None,
            sign_authn_requests: false,
            want_signed: saml::SpWantSigned { response: false, assertions: true },
            allow_unsolicited: false,
            logout_signing: saml::SpLogoutSigning::default(),
            logout_want_signed: saml::SpLogoutWantSigned::default(),
            default_peer_crypto_policy: PeerCryptoPolicy::strong_defaults(),
            outbound_signature_algorithm: SignatureAlgorithm::RsaSha256,
            outbound_digest_algorithm: DigestAlgorithm::Sha256,
        })
        .unwrap();
        let sp_desc =
            SpDescriptor::from_metadata_xml(sp.metadata_xml(false).unwrap().as_bytes()).unwrap();
        let metadata = idp.metadata_xml(false).unwrap();

        // Our FFI's AuthnRequest (so the tracker is the real Dart-side shape).
        let start_json = build_authn_request(&metadata, None);
        assert_eq!(start_json["ok"], serde_json::json!(true));
        let tracker_json = start_json["tracker"].to_string();
        let redirect_url = start_json["redirect_url"].as_str().unwrap().to_owned();
        let url = url::Url::parse(&redirect_url).unwrap();
        let b64 = url
            .query_pairs()
            .find(|(k, _)| k == "SAMLRequest")
            .map(|(_, v)| v.into_owned())
            .unwrap();
        let compressed = BASE64.decode(b64.as_bytes()).unwrap();
        let mut authn_xml = String::new();
        flate2::read::DeflateDecoder::new(&compressed[..])
            .read_to_string(&mut authn_xml)
            .unwrap();
        let now = now();
        let parsed = idp
            .consume_authn_request(ConsumeAuthnRequest {
                sp: &sp_desc,
                peer_crypto_policy: None,
                saml_request: authn_xml.as_bytes(),
                binding: Binding::HttpRedirect,
                relay_state: None,
                detached_signature: None,
                expected_destination: IDP_SSO_URL,
                now,
                clock_skew: Duration::from_mins(2),
            })
            .unwrap();

        let dispatch = idp
            .issue_error_response(IssueErrorResponse {
                sp: &sp_desc,
                in_response_to: &parsed,
                status_code: SamlStatusCode::Responder,
                second_level_status_code: None,
                message: Some("no such user".to_owned()),
                now,
            })
            .unwrap();
        let xml = match dispatch {
            SsoResponseDispatch::Post(form) => {
                String::from_utf8(BASE64.decode(form.saml_response.as_bytes()).unwrap()).unwrap()
            }
            SsoResponseDispatch::Artifact(_) => panic!("expected POST dispatch"),
        };

        let out = verify(&metadata, Some(&tracker_json), &xml, now, SP_ACS_URL,
            FLAG_WANT_ASSERTIONS_SIGNED);
        assert_eq!(out["ok"], serde_json::json!(false),
            "error-status Response accepted as a login: {out}");
        assert_eq!(out["error_code"], serde_json::json!("status"));
    }
}

#[test]
fn ffi_assertion_id_enables_caller_side_replay_dedupe() {
    // The native is stateless by design: replay defense is the caller's job,
    // keyed on the assertion_id this seam returns. The contract: two verifies
    // of the same response BOTH succeed at the native level and return the
    // SAME assertion_id — Dart's cache does the rejection.
    unsafe {
        let metadata = idp_metadata().unwrap();
        let now = now();
        let (xml, tracker) = issue_response(now, SP_ENTITY_ID).unwrap();
        let first = verify(&metadata, Some(&tracker), &xml, now, SP_ACS_URL,
            FLAG_WANT_ASSERTIONS_SIGNED);
        let second = verify(&metadata, Some(&tracker), &xml, now, SP_ACS_URL,
            FLAG_WANT_ASSERTIONS_SIGNED);
        assert_eq!(first["ok"], serde_json::json!(true));
        assert_eq!(second["ok"], serde_json::json!(true));
        assert_eq!(first["assertion_id"], second["assertion_id"]);
    }
}

#[test]
fn ffi_parses_okta_style_metadata() {
    let cert_body: String = {
        let pem = std::str::from_utf8(RSA_CERT_PEM).unwrap();
        pem.lines().filter(|l| !l.starts_with("-----")).collect::<Vec<_>>().concat()
    };
    let okta = format!(
        r#"<?xml version="1.0" encoding="UTF-8"?>
<md:EntityDescriptor xmlns:md="urn:oasis:names:tc:SAML:2.0:metadata" entityID="http://www.okta.com/exk1a2b3c4d5">
  <md:IDPSSODescriptor WantAuthnRequestsSigned="false" protocolSupportEnumeration="urn:oasis:names:tc:SAML:2.0:protocol">
    <md:KeyDescriptor use="signing">
      <ds:KeyInfo xmlns:ds="http://www.w3.org/2000/09/xmldsig#">
        <ds:X509Data><ds:X509Certificate>{cert_body}</ds:X509Certificate></ds:X509Data>
      </ds:KeyInfo>
    </md:KeyDescriptor>
    <md:NameIDFormat>urn:oasis:names:tc:SAML:1.1:nameid-format:emailAddress</md:NameIDFormat>
    <md:SingleSignOnService Binding="urn:oasis:names:tc:SAML:2.0:bindings:HTTP-Redirect" Location="https://dev-12345678.okta.com/app/controlcenter/exk1a2b3c4d5/sso/saml"/>
    <md:SingleSignOnService Binding="urn:oasis:names:tc:SAML:2.0:bindings:HTTP-POST" Location="https://dev-12345678.okta.com/app/controlcenter/exk1a2b3c4d5/sso/saml"/>
  </md:IDPSSODescriptor>
</md:EntityDescriptor>"#
    );
    unsafe {
        let out = take_json(cc_saml_parse_idp_metadata(c(&okta).as_ptr()));
        assert_eq!(out["ok"], serde_json::json!(true), "Okta metadata rejected: {out}");
        assert_eq!(out["entity_id"], serde_json::json!("http://www.okta.com/exk1a2b3c4d5"));
    }
}

#[test]
fn ffi_abi_version_matches_binding() {
    assert_eq!(cc_saml_abi_version(), 1);
}
