import 'package:cc_domain/cc_domain.dart'
    show NotFoundException, RepoOpKind, ValidationException;
import 'package:cc_domain/core/domain/entities/user.dart';
import 'package:cc_domain/core/domain/repositories/user_repository.dart';
import 'package:cc_domain/core/domain/value_objects/workspace_role.dart';
import 'package:cc_domain/features/chat_bridge/domain/entities/chat_user_link.dart';
import 'package:cc_domain/features/chat_bridge/domain/value_objects/chat_bot_profile.dart';
import 'package:cc_domain/features/chat_bridge/domain/value_objects/chat_provider.dart';
import 'package:cc_harness/tools.dart' show ActionClass;
import 'package:cc_host/cc_host.dart';
import 'package:cc_server_core/src/chat/chat_connector.dart';

/// Serializes a [ChatUserLink] for the settings roster, joined with the user it
/// points at so the table can show a human instead of a uuid.
Map<String, dynamic> chatUserLinkToWire(ChatUserLink link, User? user) => {
  'id': link.id,
  'provider': link.provider.wire,
  'externalTeamId': link.externalTeamId,
  'externalUserId': link.externalUserId,
  'userId': link.userId,
  'userHandle': user?.handle,
  'userDisplayName': user?.displayName,
  'method': link.method.wire,
  'linkedAt': link.linkedAt.toIso8601String(),
};

/// The workspace-scoped chat-bridge ops.
///
/// Every op reads its workspace from the session (`ctx.workspaceId!`), never from
/// an argument, and the connect/disconnect pair is admin-only: a chat app speaks
/// for the whole workspace, so wiring one is a workspace-settings change, not a
/// member action. Credentials travel *in* over these ops and never come back out
/// — `chat.providers`/`chat.status` answer with connection metadata only.
///
/// Nothing here names a provider. `chat.providers` hands the client the
/// descriptors, the client posts back a `provider` plus a credentials map, and the
/// descriptor validates it — which is why adding Discord touches no op.
List<RepoOp> buildChatOps({
  required ChatConnector connector,
  required UserRepository users,
}) => [
  RepoOp(
    name: 'chat.providers',
    kind: RepoOpKind.read,
    handler: (ctx) async {
      final statuses = await connector.statuses(ctx.workspaceId!);
      final byProvider = {for (final s in statuses) s.provider: s};
      return {
        'providers': [
          for (final descriptor in connector.registry.descriptors)
            {
              'descriptor': descriptor.toJson(),
              if (byProvider[descriptor.provider] case final status?)
                'status': status.toJson(),
            },
        ],
      };
    },
  ),
  RepoOp(
    name: 'chat.status',
    kind: RepoOpKind.read,
    requiredArgs: const ['provider'],
    handler: (ctx) async {
      final status = await connector.status(
        ctx.workspaceId!,
        _provider(ctx.args),
      );
      return {'status': status.toJson()};
    },
  ),
  RepoOp(
    name: 'chat.connect',
    kind: RepoOpKind.mutate,
    minRole: WorkspaceRole.admin,
    requiredArgs: const ['provider', 'credentials'],
    // Stores credentials and dials the provider: honest about both effects.
    actionClasses: const {ActionClass.secretAccess, ActionClass.networkEgress},
    handler: (ctx) async {
      final status = await connector.connect(
        workspaceId: ctx.workspaceId!,
        provider: _provider(ctx.args),
        credentials: _credentials(ctx.args),
      );
      return {'status': status.toJson()};
    },
  ),
  RepoOp(
    name: 'chat.disconnect',
    kind: RepoOpKind.destructive,
    minRole: WorkspaceRole.admin,
    requiredArgs: const ['provider'],
    actionClasses: const {ActionClass.secretAccess},
    handler: (ctx) async {
      await connector.disconnect(ctx.workspaceId!, _provider(ctx.args));
      return {'ok': true};
    },
  ),
  RepoOp(
    name: 'chat.listUserLinks',
    kind: RepoOpKind.read,
    handler: (ctx) async {
      final links = await connector.listUserLinks(
        ctx.workspaceId!,
        // Absent means every provider: the roster is one table.
        provider: _optionalProvider(ctx.args),
      );
      return {'links': await _linksToWire(links, users)};
    },
  ),
  RepoOp(
    name: 'chat.beginUserLink',
    kind: RepoOpKind.mutate,
    requiredArgs: const ['provider'],
    handler: (ctx) async {
      // Always the CALLER's own identity: a code that could be minted for
      // somebody else would be an account-takeover primitive.
      final code = connector.beginUserLink(
        workspaceId: ctx.workspaceId!,
        provider: _provider(ctx.args),
        userId: ctx.userId,
      );
      return {
        'code': code.code,
        'expires_at': code.expiresAt.toIso8601String(),
      };
    },
  ),
  RepoOp(
    name: 'chat.unlinkUser',
    kind: RepoOpKind.mutate,
    requiredArgs: const ['provider'],
    handler: (ctx) async {
      final target = (ctx.args['user_id'] as String?) ?? ctx.userId;
      // Unlinking yourself is a member action; unlinking a teammate is an
      // administrative one.
      if (target != ctx.userId && !(ctx.role?.isAdmin ?? false)) {
        throw const ValidationException(
          'Only an admin can unlink another member’s chat account.',
        );
      }
      final removed = await connector.unlinkUser(
        ctx.workspaceId!,
        target,
        provider: _provider(ctx.args),
      );
      if (removed == 0) {
        throw const NotFoundException('No chat link for that user.');
      }
      return {'ok': true};
    },
  ),
  RepoOp(
    name: 'chat.createApp',
    kind: RepoOpKind.mutate,
    minRole: WorkspaceRole.admin,
    requiredArgs: const ['provider', 'management_credential'],
    // Mints a provider-side app from a pasted secret: both classes are real here.
    actionClasses: const {ActionClass.secretAccess, ActionClass.networkEgress},
    handler: (ctx) async {
      final provider = _provider(ctx.args);
      final plugin = connector.registry.of(provider);
      final field = plugin.managementCredentialField;
      if (field == null) {
        throw ValidationException(
          '${provider.displayName} apps cannot be created from Control Center.',
        );
      }
      final credential = (ctx.args['management_credential'] as String).trim();
      // The descriptor owns the format rule, so the client and the server refuse
      // the same paste with the same sentence.
      final spec = plugin.descriptor.credentialFields.firstWhere(
        (f) => f.id == field,
      );
      plugin.descriptor.validated({field: credential}, spec);
      final creation = await connector.createApp(
        workspaceId: ctx.workspaceId!,
        provider: provider,
        managementCredential: credential,
        profile: _profileFromArgs(ctx.args),
      );
      // Deep links, not secrets: the remaining steps happen in the provider's own
      // UI because it exposes no API for them.
      return {'creation': creation.toJson()};
    },
  ),
  RepoOp(
    name: 'chat.setupLink',
    kind: RepoOpKind.read,
    minRole: WorkspaceRole.admin,
    requiredArgs: const ['provider'],
    // Composes a URL from the profile and stops there: no secret is read and
    // nothing is dialed, so it declares no action class. The user's own browser
    // makes the only request.
    handler: (ctx) async {
      final provider = _provider(ctx.args);
      final plugin = connector.registry.of(provider);
      final url = plugin.setupLinkFor(_profileFromArgs(ctx.args));
      if (url == null) {
        throw ValidationException(
          '${provider.displayName} has no app-creation link.',
        );
      }
      return {'url': url};
    },
  ),
  RepoOp(
    name: 'chat.botProfile',
    kind: RepoOpKind.read,
    minRole: WorkspaceRole.admin,
    requiredArgs: const ['provider'],
    // Reads the live app from the provider, which costs a token rotation.
    actionClasses: const {ActionClass.networkEgress},
    handler: (ctx) async {
      final profile = await connector.botProfile(
        ctx.workspaceId!,
        _provider(ctx.args),
      );
      return {'profile': profile.toJson()};
    },
  ),
  RepoOp(
    name: 'chat.updateBotProfile',
    kind: RepoOpKind.mutate,
    minRole: WorkspaceRole.admin,
    requiredArgs: const ['provider'],
    actionClasses: const {ActionClass.networkEgress},
    handler: (ctx) async {
      final remaining = await connector.updateBotProfile(
        workspaceId: ctx.workspaceId!,
        provider: _provider(ctx.args),
        profile: _profileFromArgs(ctx.args),
      );
      // Absent means the edit is live. When it is present the client shows the
      // step verbatim, which is how a reinstall link stays provider-agnostic.
      return {if (remaining != null) 'remaining_step': remaining.toJson()};
    },
  ),
];

/// The chat-bridge reactive queries.
///
/// Only the roster is watched, and it is watched because the *other* side makes
/// the change: a member types the link code in the chat app, so no client
/// request can carry the answer back. Everything else here is request/response —
/// connections change only when somebody presses a button in settings.
List<WatchQuery> buildChatWatchQueries({
  required ChatConnector connector,
  required UserRepository users,
}) => [
  WatchQuery(
    name: 'chat.watchUserLinks',
    handler: (ctx) => connector
        .watchUserLinks(
          ctx.workspaceId!,
          // Absent means every provider: the roster is one table.
          provider: _optionalProvider(ctx.args),
        )
        .asyncMap((links) async => {'links': await _linksToWire(links, users)}),
  ),
];

/// Joins each link to the user it points at, so a client renders a human instead
/// of a uuid.
Future<List<Map<String, dynamic>>> _linksToWire(
  List<ChatUserLink> links,
  UserRepository users,
) async {
  final wire = <Map<String, dynamic>>[];
  for (final link in links) {
    wire.add(chatUserLinkToWire(link, await users.getById(link.userId)));
  }
  return wire;
}

/// Reads the required `provider` argument, refusing an unknown one here rather
/// than letting it reach the registry as a lookup miss.
ChatProvider _provider(Map<String, dynamic> args) {
  final raw = (args['provider'] as String? ?? '').trim();
  final provider = ChatProvider.tryFromWire(raw);
  if (provider == null) {
    throw ValidationException('Unknown chat provider: $raw');
  }
  return provider;
}

/// Reads an optional `provider` argument (absent = every provider).
ChatProvider? _optionalProvider(Map<String, dynamic> args) {
  final raw = (args['provider'] as String? ?? '').trim();
  if (raw.isEmpty) {
    return null;
  }
  return _provider(args);
}

/// Reads the credentials map, dropping anything that is not a string. The
/// descriptor decides which keys matter and drops the rest, so a client cannot
/// smuggle an extra secret into the credentials file.
Map<String, String> _credentials(Map<String, dynamic> args) {
  final raw = args['credentials'];
  if (raw is! Map) {
    throw const ValidationException('credentials must be an object.');
  }
  return {
    for (final entry in raw.entries)
      if (entry.value is String) '${entry.key}': entry.value as String,
  };
}

/// Reads a bot profile out of op arguments, falling back to the defaults a new
/// Control Center app starts from.
ChatBotProfile _profileFromArgs(Map<String, dynamic> args) {
  final defaults = ChatBotProfile.initial(
    workspaceName: (args['workspace_name'] as String?)?.trim(),
  );
  final raw = args['profile'];
  if (raw is! Map) {
    return defaults;
  }
  final profile = ChatBotProfile.fromJson(raw.cast<String, dynamic>());
  // An empty box means "leave it alone", not "clear it" — a provider would refuse
  // an empty name anyway, and refusing here would be a worse error message.
  return ChatBotProfile(
    appName: profile.appName.isEmpty ? defaults.appName : profile.appName,
    botDisplayName: profile.botDisplayName.isEmpty
        ? defaults.botDisplayName
        : profile.botDisplayName,
    description: profile.description.isEmpty
        ? defaults.description
        : profile.description,
    agentDescription: profile.agentDescription.isEmpty
        ? defaults.agentDescription
        : profile.agentDescription,
    command: profile.command,
    agentEnabled: profile.agentEnabled,
  );
}
