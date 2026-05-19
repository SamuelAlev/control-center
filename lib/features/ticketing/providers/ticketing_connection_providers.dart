import 'package:cc_domain/features/ticketing/domain/entities/ticket_provider.dart';
import 'package:control_center/core/providers/rpc_client_provider.dart';
import 'package:control_center/features/auth/providers/oauth_providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// One ticketing vendor's connection state for the signed-in user.
class TicketingConnection {
  /// Creates a [TicketingConnection].
  const TicketingConnection({
    required this.provider,
    this.connected = false,
    this.username = '',
  });

  /// Which vendor.
  final TicketProvider provider;

  /// Whether this user has a credential for it.
  final bool connected;

  /// The account behind that credential, when known.
  final String username;
}

/// Every remote ticketing vendor's connection state, as reported by the
/// server for the CALLING user.
///
/// Never carries a token — the credential stays server-side, exactly like the
/// forge lane. Never completes with an error either: a failure resolves to
/// "nothing connected", so the card renders a connect affordance instead of an
/// error nobody can act on.
final ticketingConnectionsProvider =
    FutureProvider<Map<TicketProvider, TicketingConnection>>((ref) async {
      try {
        final data = await ref
            .watch(rpcClientProvider)
            .call('ticketing.listConnections', const {});
        final raw = data['connections'];
        if (raw is! List) {
          return const {};
        }
        final parsed = <TicketProvider, TicketingConnection>{};
        for (final entry in raw.whereType<Map<String, dynamic>>()) {
          final provider = TicketProvider.fromStorage(
            entry['provider'] as String?,
          );
          parsed[provider] = TicketingConnection(
            provider: provider,
            connected: entry['connected'] as bool? ?? false,
            username: entry['username'] as String? ?? '',
          );
        }
        return parsed;
      } on Object {
        return const {};
      }
    });

/// Stores [token] as the caller's own credential for [provider].
Future<void> setTicketingToken(
  WidgetRef ref,
  TicketProvider provider,
  String token,
) async {
  await ref.read(rpcClientProvider).call('credentials.setTicketingToken', {
    'provider': provider.toStorageString(),
    'token': token,
  });
  ref.invalidate(ticketingConnectionsProvider);
}

/// Clears the caller's credential for [provider].
Future<void> clearTicketingToken(WidgetRef ref, TicketProvider provider) async {
  await ref.read(rpcClientProvider).call('credentials.clearTicketingToken', {
    'provider': provider.toStorageString(),
  });
  ref.invalidate(ticketingConnectionsProvider);
}

/// Starts [provider]'s sign-in and returns what the human has to do next.
Future<SignInStarted> signInToTicketing(
  WidgetRef ref,
  TicketProvider provider,
) => startProviderSignIn(ref, provider.toStorageString());

/// Whether [provider] now reports a connection for the signed-in user.
Future<bool> isTicketingConnected(
  WidgetRef ref,
  TicketProvider provider,
) async {
  ref.invalidate(ticketingConnectionsProvider);
  final connections = await ref.read(ticketingConnectionsProvider.future);
  return connections[provider]?.connected ?? false;
}
