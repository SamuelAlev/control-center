import 'package:control_center/core/providers/rpc_client_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// One provider app's configuration as the server reports it.
///
/// Carries presence flags, never secrets: the private key and client secret
/// leave the server only in a request to the provider itself, so this class
/// deliberately has nowhere to put them.
class ProviderAppStatusView {
  /// Creates a [ProviderAppStatusView].
  const ProviderAppStatusView({
    required this.provider,
    this.appId = '',
    this.clientId = '',
    this.botLogin = '',
    this.hasPrivateKey = false,
    this.hasClientSecret = false,
    this.hasApiKey = false,
    this.canSignIn = false,
    this.canActAsServer = false,
    this.redirectUri = '',
    this.installations = const [],
    this.error = '',
  });

  /// Decodes one `providerApps.list` entry.
  factory ProviderAppStatusView.fromJson(Map<String, dynamic> json) =>
      ProviderAppStatusView(
        provider: json['provider'] as String? ?? '',
        appId: json['app_id'] as String? ?? '',
        clientId: json['client_id'] as String? ?? '',
        botLogin: json['bot_login'] as String? ?? '',
        hasPrivateKey: json['has_private_key'] as bool? ?? false,
        hasClientSecret: json['has_client_secret'] as bool? ?? false,
        hasApiKey: json['has_api_key'] as bool? ?? false,
        canSignIn: json['can_sign_in'] as bool? ?? false,
        canActAsServer: json['can_act_as_server'] as bool? ?? false,
        redirectUri: json['redirect_uri'] as String? ?? '',
        installations: [
          for (final entry
              in (json['installations'] as List? ?? const [])
                  .whereType<Map<String, dynamic>>())
            entry['account'] as String? ?? '',
        ]..removeWhere((a) => a.isEmpty),
        error: json['error'] as String? ?? '',
      );

  /// The provider's wire id (`github`, `linear`).
  final String provider;

  /// The GitHub App's numeric id; empty for providers that have none.
  final String appId;

  /// The OAuth client id (not a secret — it rides in every authorize URL).
  final String clientId;

  /// The GitHub App's bot login (`<slug>[bot]`), after a test. The identity a
  /// PR comment @mentions to talk to the server.
  final String botLogin;

  /// Whether a private key is stored.
  final bool hasPrivateKey;

  /// Whether an OAuth client secret is stored.
  final bool hasClientSecret;

  /// Whether a server-level API key is stored.
  final bool hasApiKey;

  /// Whether this provider can run a user sign-in.
  final bool canSignIn;

  /// Whether the server can act as itself on this provider.
  final bool canActAsServer;

  /// The callback URL to register with the provider, verbatim.
  final String redirectUri;

  /// Accounts the app is installed on, after a test.
  final List<String> installations;

  /// Why the last test failed, or empty.
  final String error;
}

/// The server's provider app configuration (operator only).
///
/// Resolves to an empty list when the caller is not the server owner or the
/// server is older than these ops — the card then simply does not render,
/// which is the right answer for a member who cannot change it anyway.
final providerAppsProvider = FutureProvider<List<ProviderAppStatusView>>((
  ref,
) async {
  try {
    final data = await ref
        .watch(rpcClientProvider)
        .call('providerApps.list', const {});
    final raw = data['apps'];
    if (raw is! List) {
      return const [];
    }
    return [
      for (final entry in raw.whereType<Map<String, dynamic>>())
        ProviderAppStatusView.fromJson(entry),
    ];
  } on Object {
    return const [];
  }
});

/// Saves one field of [provider]'s app configuration.
///
/// A field that is not passed is left alone; an EMPTY STRING clears it. That
/// is what lets the form save without re-typing a secret it was never shown.
Future<void> saveProviderApp(
  WidgetRef ref,
  String provider,
  Map<String, String> fields,
) async {
  await ref.read(rpcClientProvider).call('providerApps.save', {
    'provider': provider,
    ...fields,
  });
  ref.invalidate(providerAppsProvider);
}

/// Asks the provider whether the stored credentials actually work, and
/// refreshes the card with the verdict.
///
/// "Saved" and "works" are different claims, and only the second one means
/// background work will run.
Future<ProviderAppStatusView> testProviderApp(
  WidgetRef ref,
  String provider,
) async {
  final data = await ref.read(rpcClientProvider).call('providerApps.test', {
    'provider': provider,
  });
  ref.invalidate(providerAppsProvider);
  return ProviderAppStatusView.fromJson(data);
}
