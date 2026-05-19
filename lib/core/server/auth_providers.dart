import 'dart:convert';

/// One interactive auth method a server offers (from `/auth/providers`) —
/// an SSO connection the admin enabled. Ids are stable (`saml`, `oidc`
/// today; a future multi-connection server mints its own ids) and clients
/// must treat unknown kinds as invisible, never as errors.
class AuthProviderInfo {
  /// Creates an [AuthProviderInfo].
  const AuthProviderInfo({
    required this.id,
    required this.kind,
    required this.label,
  });

  /// Decodes one `/auth/providers` entry; null for malformed rows.
  factory AuthProviderInfo.fromJson(Map<String, dynamic> json) =>
      AuthProviderInfo(
        id: json['id'] as String? ?? '',
        kind: json['kind'] as String? ?? '',
        label: json['label'] as String? ?? '',
      );

  /// The connection id (`saml`, `oidc`, …).
  final String id;

  /// The protocol kind (`saml`, `oidc`, …).
  final String kind;

  /// A display label.
  final String label;

  /// The login URL that starts this provider's round-trip on [origin],
  /// with the new-tab relay for browser flows. [clientOrigin] declares the
  /// connect tab's own browser origin (web only): the server holds it with
  /// the pending login and postMessages the minted credential back to
  /// exactly this origin — required when the web app is served from a
  /// different origin than the server.
  String loginUrl(
    String origin, {
    String relay = 'web-popup',
    String? clientOrigin,
  }) {
    final base = kind == 'saml'
        ? '$origin/saml/login?relay=$relay'
        : '$origin/oidc/login?relay=$relay';
    return clientOrigin == null
        ? base
        : '$base&client_origin=${Uri.encodeComponent(clientOrigin)}';
  }
}

/// The parsed `/auth/providers` document: which SSO providers a server
/// offers and whether manual pairing (invite codes / pairing keys) is
/// allowed. This is the ONE probe connect screens make before any
/// credential exists; it carries no configuration detail.
class AuthProvidersSnapshot {
  /// Creates an [AuthProvidersSnapshot].
  const AuthProvidersSnapshot({
    required this.providers,
    required this.pairingEnabled,
  });

  /// Decodes the endpoint body; null when malformed.
  static AuthProvidersSnapshot? tryParse(String body) {
    try {
      final decoded = jsonDecode(body);
      if (decoded is! Map) {
        return null;
      }
      return AuthProvidersSnapshot(
        providers: [
          for (final raw in (decoded['providers'] as List? ?? const []))
            if (raw is Map)
              AuthProviderInfo.fromJson(raw.cast<String, dynamic>()),
        ],
        pairingEnabled: decoded['pairingEnabled'] as bool? ?? true,
      );
    } on Object {
      return null;
    }
  }

  /// The enabled SSO connections (possibly several in the future).
  final List<AuthProviderInfo> providers;

  /// Whether manual pairing is allowed. False = SSO-only onboarding: the
  /// connect screens hide the invite/pairing-key form entirely.
  final bool pairingEnabled;

  /// The providers speaking [kind].
  List<AuthProviderInfo> ofKind(String kind) =>
      providers.where((p) => p.kind == kind).toList();
}
