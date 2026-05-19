import 'dart:convert';
import 'dart:ffi';

import 'package:cc_natives/src/native_library.dart';
import 'package:cc_natives/src/native_unavailable.dart';
import 'package:cc_natives/src/saml/saml_ffi_bindings.dart';
import 'package:ffi/ffi.dart';

/// Stable error codes the native reports (mirrors `error_code` in
/// `cc_saml.h` — the codes are ABI; extend, never renumber).
enum SamlErrorCode {
  /// Signature missing, untrusted, tampered, or a disallowed
  /// algorithm/transform — includes the signature-wrapping family.
  signature,

  /// `NotBefore`/`NotOnOrAfter` window violated (beyond the clock skew).
  expired,

  /// Audience restriction does not name this service provider.
  audience,

  /// Response `Destination` is not our ACS URL.
  destination,

  /// `InResponseTo` does not match a pending AuthnRequest, or an unsolicited
  /// response arrived while unsolicited is disallowed.
  requestMatch,

  /// Response `Issuer` is not the configured IdP entity id.
  issuer,

  /// SubjectConfirmationData `Recipient` is not our ACS URL.
  recipient,

  /// XML/Schema-level parse failure.
  malformed,

  /// IdP-reported status was not `Success`.
  status,

  /// Anything else the validator refused.
  invalid,

  /// The seam itself failed (bad arguments, internal error).
  internal;

  /// Parses the native wire code; unknown codes map to [invalid] so a newer
  /// native never crashes an older binding.
  static SamlErrorCode fromWire(String code) => switch (code) {
    'signature' => signature,
    'expired' => expired,
    'audience' => audience,
    'destination' => destination,
    'request_match' => requestMatch,
    'issuer' => issuer,
    'recipient' => recipient,
    'malformed' => malformed,
    'status' => status,
    'internal' => internal,
    _ => invalid,
  };
}

/// A SAML domain failure: unsigned/tampered response, expiry, wrong
/// audience/destination, unsolicited response, malformed XML, IdP status not
/// Success. Typed by [code]; [message] is safe to log (it never contains
/// assertion content, only the validator's reason).
class SamlFailure implements Exception {
  /// Creates a [SamlFailure].
  const SamlFailure(this.code, this.message);

  /// The stable category — branch on this, not on [message].
  final SamlErrorCode code;

  /// The validator's reason (log-safe).
  final String message;

  @override
  String toString() => 'SamlFailure($code): $message';
}

/// Thrown when the `libcc_saml` dylib itself cannot be used: absent, wrong
/// arch, or ABI-mismatched. Strictly a BROKEN INSTALL — there is no degraded
/// mode (a hand-rolled Dart XML-DSig is where signature-wrapping
/// vulnerabilities live). `cc_server`'s boot preflight refuses to start
/// without this library.
class SamlUnavailable implements NativeLibraryUnavailable {
  /// Creates a [SamlUnavailable].
  const SamlUnavailable(this.message);

  /// What failed.
  @override
  final String message;

  @override
  String toString() =>
      'SamlUnavailable: $message (build it with '
      'scripts/natives/build_saml.sh, or set \$$samlLibraryEnvVar)';
}

/// The fields of an IdP EntityDescriptor the SSO config UI and login flow
/// need (from `cc_saml_parse_idp_metadata`).
class SamlIdpMetadata {
  /// Creates a [SamlIdpMetadata].
  const SamlIdpMetadata({
    required this.entityId,
    this.ssoRedirect,
    this.ssoPost,
    this.signingCerts = const [],
  });

  /// The IdP's entityID (issuer) — the value assertions must carry.
  final String entityId;

  /// The Redirect-binding SSO endpoint, when the metadata declares one.
  final String? ssoRedirect;

  /// The POST-binding SSO endpoint, when the metadata declares one.
  final String? ssoPost;

  /// Signing certificates as bare base64 X509 bodies (the metadata form).
  final List<String> signingCerts;
}

/// An AuthnRequest dispatch (from `CcSaml.buildAuthnRequest`).
class SamlAuthnRequest {
  /// Creates a [SamlAuthnRequest].
  const SamlAuthnRequest({
    required this.redirectUrl,
    required this.requestId,
    required this.trackerJson,
  });

  /// The full HTTP-Redirect URL the browser should be sent to.
  final String redirectUrl;

  /// The AuthnRequest ID — the caller's pending-request cache key.
  final String requestId;

  /// Opaque state to hand back to `CcSaml.verifyResponse`; the caller stores
  /// it under [requestId] with a short TTL. Treat as a black box.
  final String trackerJson;
}

/// A verified identity (from `CcSaml.verifyResponse`). Replay defense is
/// caller-side: dedupe [assertionId] until [notOnOrAfter].
class SamlIdentity {
  /// Creates a [SamlIdentity].
  const SamlIdentity({
    required this.nameId,
    required this.attributes,
    required this.assertionId,
    required this.notOnOrAfter,
    required this.isOneTimeUse,
    this.nameIdFormat,
    this.sessionIndex,
  });

  /// The assertion's NameID value (with `emailAddress` format: the email).
  final String nameId;

  /// The NameID format (e.g. `EmailAddress`, `Persistent`).
  final String? nameIdFormat;

  /// Attributes keyed by friendlyName (falling back to Name).
  final Map<String, List<String>> attributes;

  /// Dedupe key for the caller's replay cache.
  final String assertionId;

  /// When the assertion stops being valid (replay-cache eviction horizon).
  final DateTime notOnOrAfter;

  /// The IdP session index, when the assertion carried one.
  final String? sessionIndex;

  /// Whether `<OneTimeUse>` was present (stricter than expiry-bounded
  /// replay defense: single use even within the validity window).
  final bool isOneTimeUse;
}

/// Resolves the `cc_saml` dynamic library; null when unavailable.
typedef SamlLibraryResolver = DynamicLibrary? Function();

/// Default `libcc_saml` resolution: env override → bundle candidates. The
/// host installs a richer resolver (with its app-support root) via
/// [CcSaml.libraryResolver] — same shape as `Pty`/`NativeDirectoryWatcher`.
DynamicLibrary? defaultSamlLibraryResolver() => tryOpenFirst(
  nativeLibraryCandidates(samlLibraryBaseName, envVar: samlLibraryEnvVar),
);

/// The typed surface over the native `cc_saml` library.
///
/// STATELESS by design: `buildAuthnRequest` returns the tracker JSON that
/// `verifyResponse` wants back; the pending-request cache (keyed by
/// AuthnRequest ID, short TTL) and the assertion-ID replay cache live in the
/// CALLER (the server's SAML service), exactly like the OIDC pending-state
/// map.
class CcSaml {
  CcSaml._(this._b);

  final CcSamlBindings _b;

  static CcSaml? _instance;
  static CcSamlBindings? _cachedBindings;

  /// Host-injectable library resolver (see [defaultSamlLibraryResolver]).
  static SamlLibraryResolver libraryResolver = defaultSamlLibraryResolver;

  /// Whether the native library resolves and speaks our ABI — the boot
  /// preflight's probe. Never throws: false means SAML SSO (and, per the
  /// no-degraded-mode rule, the boot) is refused.
  static bool get isAvailable => instance != null;

  /// The bound instance, or null when the native cannot load (broken
  /// install; see [SamlUnavailable] for the thrown variant).
  static CcSaml? get instance {
    if (_instance != null) {
      return _instance;
    }
    final cached = _cachedBindings;
    if (cached != null) {
      return _instance ??= CcSaml._(cached);
    }
    final lib = libraryResolver();
    if (lib == null) {
      return null;
    }
    final bindings = CcSamlBindings.tryFrom(lib);
    if (bindings == null) {
      return null;
    }
    _cachedBindings = bindings;
    return _instance = CcSaml._(bindings);
  }

  /// Like [instance], but throws [SamlUnavailable] instead of returning null
  /// — for call sites that want the failure loudly.
  static CcSaml get require {
    final saml = instance;
    if (saml == null) {
      throw const SamlUnavailable(
        'the cc_saml dynamic library could not be opened or speaks a '
        'different ABI',
      );
    }
    return saml;
  }

  /// Parses an IdP EntityDescriptor XML (the metadata the admin pastes or
  /// downloads from the IdP). Throws [SamlFailure] when unusable.
  SamlIdpMetadata parseIdpMetadata(String xml) {
    final json = _call(
      (b, arena) => b.parseIdpMetadata(xml.toNativeUtf8(allocator: arena)),
    );
    return SamlIdpMetadata(
      entityId: json['entity_id'] as String? ?? '',
      ssoRedirect: json['sso_redirect'] as String?,
      ssoPost: json['sso_post'] as String?,
      signingCerts: (json['signing_certs'] as List? ?? [])
          .whereType<String>()
          .toList(),
    );
  }

  /// Builds an HTTP-Redirect AuthnRequest for [spEntityId]/[acsUrl] against
  /// the IdP described by [idpMetadataXml]. Throws [SamlFailure] when the
  /// metadata is unusable.
  SamlAuthnRequest buildAuthnRequest({
    required String idpMetadataXml,
    required String spEntityId,
    required String acsUrl,
    String? relayState,
  }) {
    final json = _call((b, arena) {
      return b.buildAuthnRequest(
        idpMetadataXml.toNativeUtf8(allocator: arena),
        spEntityId.toNativeUtf8(allocator: arena),
        acsUrl.toNativeUtf8(allocator: arena),
        relayState?.toNativeUtf8(allocator: arena) ?? nullptr,
      );
    });
    return SamlAuthnRequest(
      redirectUrl: json['redirect_url'] as String,
      requestId: json['request_id'] as String,
      trackerJson: jsonEncode(json['tracker']),
    );
  }

  /// Verifies a POST-binding SAMLResponse (raw XML — base64-decode the form
  /// field first) and returns the verified identity. Throws [SamlFailure]
  /// with the typed code on any validation failure.
  ///
  /// [trackerJson] is the opaque state from [buildAuthnRequest] for the
  /// request this response answers; null for unsolicited (IdP-initiated)
  /// responses, which [allowUnsolicited] must then permit. [now] and
  /// [clockSkew] are the caller-owned validation clock.
  SamlIdentity verifyResponse({
    required String idpMetadataXml,
    required String spEntityId,
    required String acsUrl,
    required String responseXml,
    required DateTime now,
    Duration clockSkew = const Duration(seconds: 90),
    String? trackerJson,
    bool wantAssertionsSigned = true,
    bool wantResponseSigned = false,
    bool allowUnsolicited = false,
  }) {
    var flags = 0;
    if (wantAssertionsSigned) {
      flags |= ccSamlFlagWantAssertionsSigned;
    }
    if (wantResponseSigned) {
      flags |= ccSamlFlagWantResponseSigned;
    }
    if (allowUnsolicited) {
      flags |= ccSamlFlagAllowUnsolicited;
    }
    final json = _call((b, arena) {
      return b.verifyResponse(
        idpMetadataXml.toNativeUtf8(allocator: arena),
        spEntityId.toNativeUtf8(allocator: arena),
        acsUrl.toNativeUtf8(allocator: arena),
        flags,
        trackerJson?.toNativeUtf8(allocator: arena) ?? nullptr,
        responseXml.toNativeUtf8(allocator: arena),
        now.millisecondsSinceEpoch ~/ 1000,
        clockSkew.inSeconds,
      );
    });
    final attributes = <String, List<String>>{};
    final rawAttributes = json['attributes'];
    if (rawAttributes is Map) {
      for (final entry in rawAttributes.entries) {
        attributes['${entry.key}'] = (entry.value as List? ?? [])
            .whereType<String>()
            .toList();
      }
    }
    return SamlIdentity(
      nameId: json['name_id'] as String,
      nameIdFormat: json['name_id_format'] as String?,
      attributes: attributes,
      assertionId: json['assertion_id'] as String,
      notOnOrAfter: DateTime.fromMillisecondsSinceEpoch(
        (json['not_on_or_after'] as num).toInt() * 1000,
        isUtc: true,
      ),
      sessionIndex: json['session_index'] as String?,
      isOneTimeUse: json['is_one_time_use'] as bool? ?? false,
    );
  }

  /// Emits this SP's EntityDescriptor XML for the admin to register with the
  /// IdP. Raw XML on success; throws [SamlFailure] on config errors.
  String spMetadata({required String spEntityId, required String acsUrl}) {
    final out = using<String?>((
      arena,
    ) {
      final ptr = _b.spMetadata(
        spEntityId.toNativeUtf8(allocator: arena),
        acsUrl.toNativeUtf8(allocator: arena),
      );
      return ptr == nullptr ? null : _take(ptr);
    });
    if (out == null) {
      throw StateError('cc_saml_sp_metadata returned NULL');
    }
    // Raw XML on success; a JSON error object on failure.
    if (out.trimLeft().startsWith('{')) {
      _throwFromJson(jsonDecode(out) as Map<String, dynamic>);
    }
    return out;
  }

  /// Runs [call] with an arena, takes the native JSON out and decodes it —
  /// `{"ok": false}` results throw [SamlFailure]; NULL throws [StateError].
  Map<String, dynamic> _call(
    Pointer<Utf8> Function(CcSamlBindings, Arena) call,
  ) {
    final out = using<String?>((arena) {
      final ptr = call(_b, arena);
      return ptr == nullptr ? null : _take(ptr);
    });
    if (out == null) {
      final err = _lastError();
      throw StateError('cc_saml returned NULL: ${err ?? 'no native error'}');
    }
    final decoded = jsonDecode(out);
    if (decoded is! Map<String, dynamic>) {
      throw const SamlFailure(SamlErrorCode.internal, 'non-object JSON out');
    }
    if (decoded['ok'] == false) {
      _throwFromJson(decoded);
    }
    return decoded;
  }

  static Never _throwFromJson(Map<String, dynamic> json) {
    throw SamlFailure(
      SamlErrorCode.fromWire(json['error_code'] as String? ?? ''),
      json['error'] as String? ?? 'unknown native failure',
    );
  }

  /// Copies the native out-string into a Dart-owned string and frees the
  /// native copy.
  String _take(Pointer<Utf8> ptr) {
    final text = ptr.toDartString();
    _b.freeString(ptr);
    return text;
  }

  String? _lastError() {
    final ptr = _b.lastError();
    if (ptr == nullptr) {
      return null;
    }
    return ptr.toDartString();
  }
}
