import 'dart:async';

import 'package:cc_domain/core/domain/value_objects/forge_host.dart';
import 'package:cc_domain/features/ticketing/domain/entities/ticket_provider.dart';
import 'package:control_center/core/constants/app_constants.dart';
import 'package:control_center/core/providers/rpc_client_provider.dart';
import 'package:control_center/core/providers/storage_providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Moves credentials this machine still holds in its keychain to the server,
/// once, then deletes the local copies.
///
/// Before provider credentials were server-side, a GitHub PAT and a ticketing
/// key were written into the OS keychain of whichever machine typed them. An
/// upgrade that simply stopped reading them would look like being signed out
/// for no reason — the token is right there, it is just somewhere the app no
/// longer looks. So it is handed to the server, attached to the signed-in
/// user, and removed from disk.
///
/// The local copy is deleted ONLY after the server accepts it. A failure (the
/// RPC not connected yet, an offline launch) leaves the keychain untouched and
/// the migration runs again next launch — the alternative is deleting the only
/// copy of a token nobody else has.
final legacyCredentialMigrationProvider = Provider<void>((ref) {
  unawaited(_migrate(ref));
});

Future<void> _migrate(Ref ref) async {
  final store = ref.read(secureStoreProvider);
  final client = ref.read(rpcClientProvider);

  Future<void> move({
    required String key,
    required String op,
    required Map<String, Object?> args,
  }) async {
    final token = await store.read(key: key) ?? '';
    if (token.isEmpty) {
      return;
    }
    try {
      await client.call(op, {...args, 'token': token});
      await store.delete(key: key);
    } on Object {
      // Keep the local copy and try again next launch.
    }
  }

  await move(
    key: githubTokenKey,
    op: 'credentials.setForgeToken',
    args: {'forge': ForgeHost.github.wire},
  );
  await move(
    key: ticketingApiKeyKey,
    op: 'credentials.setTicketingToken',
    // The ticketing key was stored without recording which vendor it belonged
    // to; Linear is the only remote vendor the old key could have been for.
    args: {'provider': TicketProvider.linear.toStorageString()},
  );
}
