import 'package:cc_data/cc_data.dart';
import 'package:cc_domain/core/domain/value_objects/forge_connection.dart';
import 'package:cc_harness/provider.dart';
import 'package:cc_remote/providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Global harness credentials stay on the host; only summaries reach the phone.
final remoteHarnessProvidersProvider =
    FutureProvider<List<HarnessProviderInfo>>((ref) async {
      final client = await ref.watch(rpcClientProvider.future);
      return RpcHarnessProviderRepository(client).listProviders();
    });

/// The caller's forge identity in the selected workspace overlay.
final remoteForgeConnectionsProvider = FutureProvider<List<ForgeConnection>>((
  ref,
) async {
  final client = await ref.watch(rpcClientProvider.future);
  final workspaceId = await ref.watch(activeWorkspaceIdProvider.future);
  if (workspaceId == null) return const [];
  final data = await client.call('forge.listConnections', {
    'workspace_id': workspaceId,
  });
  return [
    for (final row in data['connections'] as List? ?? const [])
      if (row is Map) ForgeConnection.fromJson(row.cast<String, dynamic>()),
  ];
});

/// The caller's remote ticketing identities (local tickets need no token).
final remoteTicketConnectionsProvider =
    FutureProvider<Map<String, ({bool connected, String username})>>((
      ref,
    ) async {
      final client = await ref.watch(rpcClientProvider.future);
      final workspaceId = await ref.watch(activeWorkspaceIdProvider.future);
      if (workspaceId == null) return const {};
      final data = await client.call('ticketing.listConnections', {
        'workspace_id': workspaceId,
      });
      return {
        for (final row in data['connections'] as List? ?? const [])
          if (row is Map && row['provider'] is String)
            row['provider'] as String: (
              connected: row['connected'] == true,
              username: row['username'] as String? ?? '',
            ),
      };
    });

/// Server-advertised sign-in methods vary by workspace and installed apps.
final remoteSignInProvidersProvider =
    FutureProvider<Map<String, ({String flow, String redirectUri})>>((
      ref,
    ) async {
      final client = await ref.watch(rpcClientProvider.future);
      final workspaceId = await ref.watch(activeWorkspaceIdProvider.future);
      if (workspaceId == null) return const {};
      final data = await client.call('oauth.providers', {
        'workspace_id': workspaceId,
      });
      return {
        for (final row in data['providers'] as List? ?? const [])
          if (row is Map && row['provider'] is String)
            row['provider'] as String: (
              flow: row['flow'] as String? ?? '',
              redirectUri: row['redirect_uri'] as String? ?? '',
            ),
      };
    });

/// The host CLI owns Claude Code sign-in; its status is informational on a phone.
final remoteClaudeAccountsProvider = FutureProvider((ref) async {
  final client = await ref.watch(rpcClientProvider.future);
  return RpcClaudeAccountsRepository(client).list();
});

/// A redirect callback must be reachable outside the host. Localhost/private
/// origins advertised by a desktop server cannot complete from a phone tab.
bool phoneCanUseRedirect(String redirectUri) {
  final uri = Uri.tryParse(redirectUri);
  if (uri == null || uri.scheme != 'https' || uri.host.isEmpty) return false;
  final host = uri.host.toLowerCase();
  if (!host.contains('.') ||
      host.contains(':') ||
      host == 'localhost' ||
      host == 'localhost.' ||
      host.endsWith('.localhost') ||
      host.endsWith('.localhost.') ||
      host.endsWith('.local') ||
      host.endsWith('.local.') ||
      host.endsWith('.internal') ||
      host.endsWith('.lan') ||
      host.endsWith('.home.arpa') ||
      host == '127.0.0.1') {
    return false;
  }
  final ip = _parseIpv4(host);
  if (ip != null) {
    return !(ip[0] == 10 ||
        ip[0] == 127 ||
        ip[0] == 0 ||
        (ip[0] == 172 && ip[1] >= 16 && ip[1] <= 31) ||
        (ip[0] == 192 && ip[1] == 168) ||
        (ip[0] == 169 && ip[1] == 254));
  }
  return true;
}

// The web build cannot import dart:io for a four-byte host check.
List<int>? _parseIpv4(String host) {
  final parts = host.split('.');
  if (parts.length != 4) return null;
  final bytes = <int>[];
  for (final part in parts) {
    final byte = int.tryParse(part);
    if (byte == null || byte < 0 || byte > 255 || part != '$byte') return null;
    bytes.add(byte);
  }
  return bytes;
}
