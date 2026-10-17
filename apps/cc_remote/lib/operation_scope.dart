import 'package:cc_domain/cc_domain.dart';
import 'package:cc_domain/core/domain/value_objects/workspace_role.dart';
import 'package:cc_remote/providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Authenticated identity. A server owner is not implicitly a workspace member.
class RemoteIdentity {
  const RemoteIdentity({
    required this.userId,
    required this.deviceId,
    required this.isServerOwner,
  });

  final String userId;
  final String deviceId;
  final bool isServerOwner;
}

final remoteIdentityProvider = FutureProvider<RemoteIdentity?>((ref) async {
  final client = ref.watch(rpcClientProvider).value;
  if (client == null) return null;
  final result = await client.call('identity.me', const {});
  final user = result['user'] as Map;
  return RemoteIdentity(
    userId: user['id'] as String,
    deviceId: result['device_id'] as String,
    isServerOwner: result['is_server_owner'] == true,
  );
});

/// Optional global identity labels, shared across conversation views.
final remoteUserNamesProvider = FutureProvider<Map<String, String>>((
  ref,
) async {
  final client = ref.watch(rpcClientProvider).value;
  if (client == null) return const {};
  final result = await client.call('users.list', const {});
  return {
    for (final row in (result['users'] as List? ?? const []).whereType<Map>())
      if (row['id'] is String)
        row['id'] as String: (row['display_name'] as String?) ?? '',
  };
});

/// Membership updates immediately remove phone mutation affordances on revoke.
/// The server independently authorizes every operation; this is presentation.
final workspaceRoleProvider = StreamProvider<WorkspaceRole?>((ref) {
  final client = ref.watch(rpcClientProvider).value;
  final workspaceId = ref.watch(activeWorkspaceIdProvider).value;
  final userId = ref.watch(remoteIdentityProvider).value?.userId;
  if (client == null || workspaceId == null || userId == null) {
    return const Stream.empty();
  }
  return client
      .subscribe('members.watchForWorkspace', {'workspace_id': workspaceId})
      .map((result) {
        final members = (result['members'] as List? ?? const [])
            .whereType<Map>()
            .map(
              (row) => WorkspaceMemberDto.fromJson(row.cast<String, dynamic>()),
            );
        final member = members.where((row) => row.userId == userId).firstOrNull;
        return member == null ? null : WorkspaceRole.fromWire(member.role);
      });
});

/// Relative, URI-encoded mobile links retain all identities across reconnects.
String remoteSpaceLocation({
  required String workspaceId,
  required String spaceId,
  String? conversationId,
  String? messageId,
}) => Uri(
  pathSegments: ['', 'spaces', spaceId],
  queryParameters: {
    'workspace_id': workspaceId,
    'conversation_id': ?conversationId,
    'message_id': ?messageId,
  },
).toString();

/// Adds an explicit workspace without discarding an existing query or fragment.
String remoteWorkspaceLocation(String location, String workspaceId) {
  final uri = Uri.parse(location);
  if (uri.hasScheme || uri.hasAuthority || !uri.path.startsWith('/')) {
    throw ArgumentError.value(
      location,
      'location',
      'Expected a relative route',
    );
  }
  return uri
      .replace(
        queryParameters: {...uri.queryParameters, 'workspace_id': workspaceId},
      )
      .toString();
}
