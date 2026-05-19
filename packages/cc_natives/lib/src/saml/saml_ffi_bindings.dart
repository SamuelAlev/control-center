import 'dart:ffi';

import 'package:ffi/ffi.dart';

/// Base name of the native SAML library (`libcc_saml.dylib` /
/// `libcc_saml.so` / `cc_saml.dll`), built by
/// `scripts/natives/build_saml.sh` from the in-repo Rust crate
/// `packages/cc_natives/native/saml/`.
const String samlLibraryBaseName = 'cc_saml';

/// Env var overriding the SAML dylib path (highest-priority candidate).
const String samlLibraryEnvVar = 'CC_SAML_DYLIB';

/// The C ABI version this Dart binding speaks. Must equal the native's
/// `cc_saml_abi_version()`; a mismatch refuses to bind — a broken install,
/// not a degraded mode.
const int ccSamlAbiVersion = 1;

/// `CC_SAML_FLAG_WANT_ASSERTIONS_SIGNED` (see `cc_saml.h`).
const int ccSamlFlagWantAssertionsSigned = 1;

/// `CC_SAML_FLAG_ALLOW_UNSOLICITED` (see `cc_saml.h`).
const int ccSamlFlagAllowUnsolicited = 2;

/// `CC_SAML_FLAG_WANT_RESPONSE_SIGNED` (see `cc_saml.h`).
const int ccSamlFlagWantResponseSigned = 4;

/// Dart signature of `cc_saml_abi_version`.
typedef CcSamlAbiVersionFn = int Function();

/// Dart signature of `cc_saml_last_error`.
typedef CcSamlLastErrorFn = Pointer<Utf8> Function();

/// Dart signature of `cc_saml_free_string`.
typedef CcSamlFreeStringFn = void Function(Pointer<Utf8> ptr);

/// Dart signature of `cc_saml_parse_idp_metadata`.
typedef CcSamlParseIdpMetadataFn = Pointer<Utf8> Function(Pointer<Utf8> xml);

/// Dart signature of `cc_saml_build_authn_request`.
typedef CcSamlBuildAuthnRequestFn = Pointer<Utf8> Function(
  Pointer<Utf8> idpMetadataXml,
  Pointer<Utf8> spEntityId,
  Pointer<Utf8> acsUrl,
  Pointer<Utf8> relayState,
);

/// Dart signature of `cc_saml_verify_response`.
typedef CcSamlVerifyResponseFn = Pointer<Utf8> Function(
  Pointer<Utf8> idpMetadataXml,
  Pointer<Utf8> spEntityId,
  Pointer<Utf8> acsUrl,
  int flags,
  Pointer<Utf8> trackerJson,
  Pointer<Utf8> responseXml,
  int nowEpochSecs,
  int clockSkewSecs,
);

/// Dart signature of `cc_saml_sp_metadata`.
typedef CcSamlSpMetadataFn = Pointer<Utf8> Function(
  Pointer<Utf8> spEntityId,
  Pointer<Utf8> acsUrl,
);

/// Typed bindings over the `cc_saml` dylib.
///
/// Raw JSON-in/JSON-out only — the typed surface (parsed metadata, identity
/// results, error codes) lives in `saml_library.dart`, which is the file
/// consumers should use.
class CcSamlBindings {
  CcSamlBindings._({
    required this.abiVersion,
    required this.lastError,
    required this.freeString,
    required this.parseIdpMetadata,
    required this.buildAuthnRequest,
    required this.verifyResponse,
    required this.spMetadata,
  });

  /// `cc_saml_abi_version`.
  final CcSamlAbiVersionFn abiVersion;

  /// `cc_saml_last_error` — thread-local message; nullptr when none.
  final CcSamlLastErrorFn lastError;

  /// `cc_saml_free_string` — releases an owned out-string; nullptr-safe.
  final CcSamlFreeStringFn freeString;

  /// `cc_saml_parse_idp_metadata`.
  final CcSamlParseIdpMetadataFn parseIdpMetadata;

  /// `cc_saml_build_authn_request`.
  final CcSamlBuildAuthnRequestFn buildAuthnRequest;

  /// `cc_saml_verify_response`.
  final CcSamlVerifyResponseFn verifyResponse;

  /// `cc_saml_sp_metadata`.
  final CcSamlSpMetadataFn spMetadata;

  /// Binds against [lib], or returns null when a symbol is missing or the
  /// native speaks a different ABI version. Null surfaces to the caller as
  /// `SamlUnavailable` — a broken install, not a degraded mode.
  static CcSamlBindings? tryFrom(DynamicLibrary lib) {
    try {
      final abi = lib.lookupFunction<Uint32 Function(), CcSamlAbiVersionFn>(
        'cc_saml_abi_version',
      );
      if (abi() != ccSamlAbiVersion) {
        return null;
      }
      return CcSamlBindings._(
        abiVersion: abi,
        lastError: lib.lookupFunction<
          Pointer<Utf8> Function(),
          CcSamlLastErrorFn
        >('cc_saml_last_error'),
        freeString: lib.lookupFunction<
          Void Function(Pointer<Utf8>),
          CcSamlFreeStringFn
        >('cc_saml_free_string'),
        parseIdpMetadata: lib.lookupFunction<
          Pointer<Utf8> Function(Pointer<Utf8>),
          CcSamlParseIdpMetadataFn
        >('cc_saml_parse_idp_metadata'),
        buildAuthnRequest: lib.lookupFunction<
          Pointer<Utf8> Function(
            Pointer<Utf8>,
            Pointer<Utf8>,
            Pointer<Utf8>,
            Pointer<Utf8>,
          ),
          CcSamlBuildAuthnRequestFn
        >('cc_saml_build_authn_request'),
        verifyResponse: lib.lookupFunction<
          Pointer<Utf8> Function(
            Pointer<Utf8>,
            Pointer<Utf8>,
            Pointer<Utf8>,
            Uint32,
            Pointer<Utf8>,
            Pointer<Utf8>,
            Int64,
            Int64,
          ),
          CcSamlVerifyResponseFn
        >('cc_saml_verify_response'),
        spMetadata: lib.lookupFunction<
          Pointer<Utf8> Function(Pointer<Utf8>, Pointer<Utf8>),
          CcSamlSpMetadataFn
        >('cc_saml_sp_metadata'),
      );
    } on ArgumentError {
      // Missing symbol — an unrelated or truncated dylib.
      return null;
    }
  }
}
