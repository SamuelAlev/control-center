import 'dart:async';

import 'package:cc_domain/cc_domain.dart' show ValidationException;
import 'package:cc_domain/core/domain/entities/agent.dart';
import 'package:cc_domain/core/domain/events/domain_event_bus.dart';
import 'package:cc_domain/core/domain/repositories/agent_repository.dart';
import 'package:cc_domain/core/domain/repositories/user_repository.dart';
import 'package:cc_domain/core/domain/repositories/workspace_membership_repository.dart';
import 'package:cc_domain/core/domain/value_objects/agent_role.dart';
import 'package:cc_domain/features/chat_bridge/domain/entities/chat_user_link.dart';
import 'package:cc_domain/features/chat_bridge/domain/repositories/chat_link_repositories.dart';
import 'package:cc_domain/features/chat_bridge/domain/value_objects/chat_app_creation.dart';
import 'package:cc_domain/features/chat_bridge/domain/value_objects/chat_bot_profile.dart';
import 'package:cc_domain/features/chat_bridge/domain/value_objects/chat_bridge_connection.dart';
import 'package:cc_domain/features/chat_bridge/domain/value_objects/chat_provider.dart';
import 'package:cc_domain/features/messaging/domain/repositories/messaging_repository.dart';
import 'package:cc_domain/features/ticketing/domain/services/ticket_workflow_service.dart';
import 'package:cc_infra/cc_infra.dart';
import 'package:cc_server_core/src/chat/chat_provider_plugin.dart';
import 'package:cc_server_core/src/chat/file_chat_connection_store.dart';

/// Owns every workspace's chat connections: one adapter and one bridge per
/// (workspace × provider).
///
/// This is the composition seam the RPC ops and the boot reconciler talk to. It
/// exists because a chat connection has *lifecycle* — connect, reconnect,
/// disconnect, re-key — and that lifecycle belongs to the server, not to a
/// request handler: an op flips a switch here and returns, while the transport it
/// started keeps running until the process ends.
///
/// A workspace with no stored credentials costs nothing: no socket, no timers, no
/// provider traffic. Which providers exist at all is the registry's business, so
/// nothing in this class names Slack.
class ChatConnector {
  /// Creates a [ChatConnector].
  ChatConnector({
    required ChatProviderRegistry registry,
    required FileChatConnectionStore store,
    required ActiveStreamRegistry streamRegistry,
    required MessagingService messaging,
    required MessagingRepository messages,
    required AgentRepository agents,
    required ChatSpaceLinkRepository spaceLinks,
    required ChatUserLinkRepository userLinks,
    required UserRepository users,
    required WorkspaceMembershipRepository members,
    required TicketWorkflowService tickets,
    required Future<List<String>> Function() listWorkspaceIds,
    DomainEventBus? eventBus,
    ChatLinkCodeStore? linkCodes,
    ChatDeepLinks? deepLinks,
  }) : _registry = registry,
       _store = store,
       _streamRegistry = streamRegistry,
       _messaging = messaging,
       _messages = messages,
       _agents = agents,
       _spaceLinks = spaceLinks,
       _userLinks = userLinks,
       _users = users,
       _members = members,
       _tickets = tickets,
       _listWorkspaceIds = listWorkspaceIds,
       _eventBus = eventBus,
       _deepLinks = deepLinks,
       linkCodes = linkCodes ?? ChatLinkCodeStore();

  final ChatProviderRegistry _registry;
  final FileChatConnectionStore _store;
  final ActiveStreamRegistry _streamRegistry;
  final MessagingService _messaging;
  final MessagingRepository _messages;
  final AgentRepository _agents;
  final ChatSpaceLinkRepository _spaceLinks;
  final ChatUserLinkRepository _userLinks;
  final UserRepository _users;
  final WorkspaceMembershipRepository _members;
  final TicketWorkflowService _tickets;
  final Future<List<String>> Function() _listWorkspaceIds;
  final DomainEventBus? _eventBus;

  /// Builds the "View in Control Center" links a bridge puts on its task cards.
  /// Null on a server with no advertised URL — the cards then carry no call to
  /// action rather than a link nothing can open.
  final ChatDeepLinks? _deepLinks;

  /// One-time codes for the "link my account" flow, shared across workspaces and
  /// providers (each code is scoped to both internally).
  final ChatLinkCodeStore linkCodes;

  final Map<String, _ChatRuntime> _runtimes = {};

  /// The providers this server offers, for the settings surface.
  ChatProviderRegistry get registry => _registry;

  static String _key(String workspaceId, ChatProvider provider) =>
      '$workspaceId/${provider.wire}';

  /// Brings up every workspace × provider that has stored, enabled credentials.
  ///
  /// Called after the ready banner: a chat app that is slow to answer must never
  /// delay the server's boot and a workspace whose tokens were revoked must not
  /// prevent the others from connecting.
  Future<void> start() async {
    // CROSS-WORKSPACE BY DESIGN: a boot reconciler. It reads the global workspace
    // registry once and then works per workspace with that workspace's own id in
    // hand — no workspace ever sees another's links.
    final List<String> workspaceIds;
    try {
      workspaceIds = await _listWorkspaceIds();
    } on Object catch (e) {
      CcInfraLog.warning('Chat: could not enumerate workspaces: $e');
      return;
    }
    for (final workspaceId in workspaceIds) {
      for (final provider in _registry.providers) {
        // Cheap probe first: no parse and no workspace database opened for the
        // (usual) case of a workspace with no chat app.
        if (!_store.has(workspaceId, provider)) {
          continue;
        }
        final connection = await _store.load(workspaceId, provider);
        if (connection == null || !connection.enabled) {
          continue;
        }
        try {
          await _spawn(connection);
        } on Object catch (e) {
          CcInfraLog.error(
            'Chat(${provider.wire}): connecting workspace $workspaceId failed',
            e,
          );
        }
      }
    }
  }

  /// Tears every connection down (server shutdown).
  Future<void> stop() async {
    final runtimes = List.of(_runtimes.values);
    _runtimes.clear();
    for (final runtime in runtimes) {
      await runtime.dispose();
    }
  }

  /// The workspace's status on [provider], credentials excluded.
  Future<ChatConnectionStatus> status(
    String workspaceId,
    ChatProvider provider,
  ) async {
    final runtime = _runtimes[_key(workspaceId, provider)];
    final connection =
        runtime?.connection ?? await _store.load(workspaceId, provider);
    if (connection == null) {
      return ChatConnectionStatus.none(provider);
    }
    var linkedMembers = 0;
    try {
      linkedMembers = (await _userLinks.forWorkspace(
        workspaceId,
        provider: provider,
      )).length;
    } on Object {
      // A status read must not fail because the workspace database is busy.
    }
    final managementField = _registry
        .maybeOf(provider)
        ?.managementCredentialField;
    return ChatConnectionStatus(
      provider: provider,
      state: runtime?.adapter.state ?? ChatConnectionState.disconnected,
      teamId: connection.teamId,
      teamName: connection.teamName,
      appId: connection.appId,
      botUserId: connection.botUserId,
      botName: connection.botName,
      lastError: runtime?.adapter.lastError,
      connectedAt: connection.connectedAt,
      streamingAvailable: runtime?.bridge.streamingAvailable,
      canManageApp:
          managementField != null &&
          (connection.hasCredential(managementField) ||
              ((await _store.loadSetup(
                    workspaceId,
                    provider,
                  ))?.managementCredential.isNotEmpty ??
                  false)),
      linkedMemberCount: linkedMembers,
    );
  }

  /// Every offered provider's status for [workspaceId] — what the settings
  /// surface renders one card per.
  Future<List<ChatConnectionStatus>> statuses(String workspaceId) async {
    final result = <ChatConnectionStatus>[];
    for (final provider in _registry.providers) {
      result.add(await status(workspaceId, provider));
    }
    return result;
  }

  /// Stores [credentials] and opens the connection, replacing any connection
  /// already running for that workspace × provider.
  ///
  /// The plugin verifies the credentials *before* anything is written, so a typo
  /// is reported to the person pasting it rather than becoming a transport that
  /// quietly never works.
  Future<ChatConnectionStatus> connect({
    required String workspaceId,
    required ChatProvider provider,
    required Map<String, String> credentials,
  }) async {
    final plugin = _registry.of(provider);
    final existing = await _store.load(workspaceId, provider);
    // A guided create left the app-management credential (already rotated once)
    // and the new app's id behind, because there was no connection to hang them
    // on yet. This is where that hand-off completes.
    final setup = await _store.loadSetup(workspaceId, provider);
    final managementField = plugin.managementCredentialField;
    final withSetup = {
      if (managementField != null &&
          (credentials[managementField] ?? '').isEmpty &&
          (setup?.managementCredential ?? '').isNotEmpty)
        managementField: setup!.managementCredential,
      ...credentials,
    };
    final described = await plugin.connectionFrom(
      workspaceId: workspaceId,
      credentials: withSetup,
      existing: existing,
    );
    final connection =
        described.appId.isEmpty && (setup?.appId ?? '').isNotEmpty
        ? described.copyWith(appId: setup!.appId)
        : described;
    await _store.save(connection);
    await _store.clearSetup(workspaceId, provider);
    await _shutdownRuntime(workspaceId, provider);
    await _spawn(connection);
    return status(workspaceId, provider);
  }

  /// Closes the workspace's connection on [provider] and forgets its credentials.
  ///
  /// The chat↔Control Center *links* survive on purpose: reconnecting the same
  /// app restores every bridged thread instead of stranding them and a workspace
  /// deletion removes the rows anyway (they live in its database).
  Future<void> disconnect(String workspaceId, ChatProvider provider) async {
    await _shutdownRuntime(workspaceId, provider);
    await _store.clear(workspaceId, provider);
    await _store.clearSetup(workspaceId, provider);
  }

  /// Persists a changed connection (e.g. a rotated management credential) and
  /// restarts the transport when the credentials it dials with changed.
  Future<void> saveConnection(ChatBridgeConnection connection) async {
    await _store.save(connection);
    final runtime =
        _runtimes[_key(connection.workspaceId, connection.provider)];
    if (runtime == null) {
      return;
    }
    final rekeyed = !_sameCredentials(
      runtime.connection.credentials,
      connection.credentials,
    );
    if (rekeyed) {
      await _shutdownRuntime(connection.workspaceId, connection.provider);
      await _spawn(connection);
    } else {
      runtime.connection = connection;
    }
  }

  static bool _sameCredentials(Map<String, String> a, Map<String, String> b) {
    if (a.length != b.length) {
      return false;
    }
    for (final entry in a.entries) {
      if (b[entry.key] != entry.value) {
        return false;
      }
    }
    return true;
  }

  /// The stored connection — credentials included, so this is server-only (app
  /// management needs them).
  Future<ChatBridgeConnection?> connectionFor(
    String workspaceId,
    ChatProvider provider,
  ) async =>
      _runtimes[_key(workspaceId, provider)]?.connection ??
      await _store.load(workspaceId, provider);

  // ── Managing the provider-side app ──

  /// Creates the workspace's provider-side app from [profile], using an app
  /// management credential the owner pasted once.
  ///
  /// The result names whatever steps the provider has no API for and the rotated
  /// credential is persisted here rather than handed to the client: losing it
  /// would leave the app unmanageable forever.
  Future<ChatAppCreation> createApp({
    required String workspaceId,
    required ChatProvider provider,
    required String managementCredential,
    required ChatBotProfile profile,
  }) async {
    await _storeManagementCredential(
      workspaceId,
      provider,
      managementCredential,
    );
    final creation = await _appManager(
      workspaceId,
      provider,
    ).createApp(profile);
    final setup = await _store.loadSetup(workspaceId, provider);
    await _store.saveSetup(
      workspaceId,
      provider,
      ChatAppSetup(
        // Whatever the last rotation wrote, not what the caller pasted.
        managementCredential: setup?.managementCredential ?? '',
        appId: creation.appId,
        installUrl: creation.step('install')?.url,
      ),
    );
    return creation;
  }

  /// The customizable face of the workspace's provider-side app, read live.
  Future<ChatBotProfile> botProfile(
    String workspaceId,
    ChatProvider provider,
  ) => _appManager(workspaceId, provider).readProfile();

  /// Applies [profile] to the workspace's provider-side app.
  ///
  /// Returns the step left to finish — normally reinstalling the app after a
  /// permission change, which is inert until somebody does it: the bridge keeps
  /// running on the old grant, so the UI has to say so rather than implying the
  /// edit is live. Null means it is.
  Future<ChatSetupStep?> updateBotProfile({
    required String workspaceId,
    required ChatProvider provider,
    required ChatBotProfile profile,
  }) async {
    final remaining = await _appManager(
      workspaceId,
      provider,
    ).writeProfile(profile);
    // A rename changes what members type after `@`, so the settings card must
    // stop showing the old name. Best-effort: the edit already landed.
    await _refreshIdentity(workspaceId, provider);
    return remaining;
  }

  /// The app manager for a workspace × provider, refusing when the provider has
  /// no app-management API at all.
  ChatAppManager _appManager(String workspaceId, ChatProvider provider) {
    final plugin = _registry.of(provider);
    final manager = plugin.appManager(
      ChatAppContext(
        workspaceId: workspaceId,
        readCredential: () => _readManagementCredential(workspaceId, plugin),
        writeCredential: (value) =>
            _storeManagementCredential(workspaceId, provider, value),
        appId: () => _manageableAppId(workspaceId, provider),
      ),
    );
    if (manager == null) {
      throw ValidationException(
        '${provider.displayName} apps cannot be managed from Control Center.',
      );
    }
    return manager;
  }

  /// The app-management credential, from the connection when there is one and
  /// from the guided-create file before that.
  Future<String?> _readManagementCredential(
    String workspaceId,
    ChatProviderPlugin plugin,
  ) async {
    final field = plugin.managementCredentialField;
    if (field == null) {
      return null;
    }
    final connection = await connectionFor(workspaceId, plugin.provider);
    final stored = connection?.credential(field);
    if (stored != null) {
      return stored;
    }
    final setup = await _store.loadSetup(workspaceId, plugin.provider);
    final fromSetup = setup?.managementCredential ?? '';
    return fromSetup.isEmpty ? null : fromSetup;
  }

  /// Writes a rotated app-management credential wherever this workspace keeps it.
  ///
  /// Both destinations go through here so a rotation can never land in the setup
  /// file while the live connection serves a stale one.
  Future<void> _storeManagementCredential(
    String workspaceId,
    ChatProvider provider,
    String value,
  ) async {
    final field = _registry.of(provider).managementCredentialField;
    if (field == null) {
      return;
    }
    final connection = await connectionFor(workspaceId, provider);
    if (connection != null) {
      await saveConnection(connection.copyWith(credentials: {field: value}));
      return;
    }
    final setup = await _store.loadSetup(workspaceId, provider);
    await _store.saveSetup(
      workspaceId,
      provider,
      setup?.copyWith(managementCredential: value) ??
          ChatAppSetup(managementCredential: value),
    );
  }

  /// The app id manifest-style calls act on: the connection's, else the one a
  /// guided create recorded.
  Future<String> _manageableAppId(
    String workspaceId,
    ChatProvider provider,
  ) async {
    final fromConnection =
        (await connectionFor(workspaceId, provider))?.appId ?? '';
    if (fromConnection.isNotEmpty) {
      return fromConnection;
    }
    final fromSetup =
        (await _store.loadSetup(workspaceId, provider))?.appId ?? '';
    if (fromSetup.isNotEmpty) {
      return fromSetup;
    }
    throw ValidationException(
      'Control Center does not know which ${provider.displayName} app to edit. '
      'Reconnect the workspace, or create the app from here.',
    );
  }

  /// Re-reads the bot's identity from the provider after an app edit, so the name
  /// in settings matches the name in the chat app. Best-effort: a failure here
  /// means a stale label, not a broken connection.
  Future<void> _refreshIdentity(
    String workspaceId,
    ChatProvider provider,
  ) async {
    final connection = await connectionFor(workspaceId, provider);
    if (connection == null) {
      return;
    }
    try {
      final refreshed = await _registry
          .of(provider)
          .connectionFrom(
            workspaceId: workspaceId,
            credentials: connection.credentials,
            existing: connection,
          );
      await saveConnection(
        connection.copyWith(
          botName: refreshed.botName,
          botUserId: refreshed.botUserId,
          appId: refreshed.appId,
          teamName: refreshed.teamName,
        ),
      );
    } on Object catch (e) {
      CcInfraLog.warning(
        'Chat(${provider.wire}/$workspaceId): identity refresh failed: $e',
      );
    }
  }

  // ── Member links ──

  /// Mints the one-time code a member types as `/cc link CODE` in the chat app.
  ChatLinkCode beginUserLink({
    required String workspaceId,
    required ChatProvider provider,
    required String userId,
  }) => linkCodes.mint(
    workspaceId: workspaceId,
    provider: provider,
    userId: userId,
  );

  /// Every chat↔user link in the workspace, optionally for one provider (the
  /// settings roster).
  Future<List<ChatUserLink>> listUserLinks(
    String workspaceId, {
    ChatProvider? provider,
  }) => _userLinks.forWorkspace(workspaceId, provider: provider);

  /// Watches the same roster.
  ///
  /// A link is made *in the chat app*, so the client that minted the code has no
  /// way to know when it lands — it is not the one making the request. This is
  /// how the settings roster and the open "link my account" dialog learn, at the
  /// moment the row is written rather than on the next visit.
  Stream<List<ChatUserLink>> watchUserLinks(
    String workspaceId, {
    ChatProvider? provider,
  }) => _userLinks.watchForWorkspace(workspaceId, provider: provider);

  /// Drops a member's link on [provider]. They can no longer drive agents from
  /// that chat app until they link again.
  Future<int> unlinkUser(
    String workspaceId,
    String userId, {
    required ChatProvider provider,
  }) async {
    linkCodes.revokeForUser(workspaceId, userId, provider: provider);
    return _userLinks.deleteForUser(workspaceId, userId, provider: provider);
  }

  // ── Runtimes ──

  Future<void> _spawn(ChatBridgeConnection connection) async {
    final workspaceId = connection.workspaceId;
    final plugin = _registry.of(connection.provider);
    final adapter = plugin.createAdapter(connection);
    final bridge = ChatBridgeService(
      connection: connection,
      adapter: adapter,
      descriptor: plugin.descriptor,
      streamRegistry: _streamRegistry,
      messaging: _messaging,
      messages: _messages,
      spaceLinks: _spaceLinks,
      userLinks: _userLinks,
      users: _users,
      members: _members,
      linkCodes: linkCodes,
      eventBus: _eventBus,
      deepLinks: _deepLinks,
      createSpace:
          ({
            required String workspaceId,
            required String name,
            required String createdByUserId,
          }) async => _messaging.createSpace(
            workspaceId,
            name,
            await _frontDoorAgents(workspaceId),
            kind: connection.provider.spaceKind,
            createdByUserId: createdByUserId,
          ),
      createTicket:
          ({
            required String workspaceId,
            required String title,
            required String reporterUserId,
            String? description,
          }) async {
            final ticket = await _tickets.createTicket(
              workspaceId: workspaceId,
              title: title,
              description: description,
              // A chat app is a command surface, not a ticket vendor: the ticket is a
              // first-class local ticket reported by the linked human.
              createdByType: 'user',
              createdById: reporterUserId,
            );
            return (id: ticket.id, key: ticket.displayKey, title: ticket.title);
          },
    );
    _runtimes[_key(workspaceId, connection.provider)] = _ChatRuntime(
      connection: connection,
      bridge: bridge,
      adapter: adapter,
    );
    // The bridge owns the adapter's lifecycle: starting it arms the inbound
    // subscription first and only then opens the transport, so no event can
    // arrive before there is something listening.
    await bridge.start();
  }

  Future<void> _shutdownRuntime(
    String workspaceId,
    ChatProvider provider,
  ) async {
    final runtime = _runtimes.remove(_key(workspaceId, provider));
    await runtime?.dispose();
  }

  /// The agents a brand-new chat conversation should wake: the workspace's CEO
  /// agent when it has one (it can delegate onward), else its first agent.
  ///
  /// Empty for a workspace with no agents at all — the message is still stored, it
  /// simply has nobody to answer it yet.
  Future<List<String>> _frontDoorAgents(String workspaceId) async {
    final List<Agent> agents;
    try {
      agents = await _agents.watchByWorkspace(workspaceId).first;
    } on Object {
      return const [];
    }
    if (agents.isEmpty) {
      return const [];
    }
    final front = agents.firstWhere(
      (a) => a.role == AgentRole.ceo,
      orElse: () => agents.first,
    );
    return [front.id];
  }
}

class _ChatRuntime {
  _ChatRuntime({
    required this.connection,
    required this.bridge,
    required this.adapter,
  });

  ChatBridgeConnection connection;
  final ChatBridgeService bridge;
  final ChatProviderAdapter adapter;

  /// Stopping the bridge stops the adapter with it — one owner, so a shutdown
  /// cannot leave a transport running with nothing consuming it.
  Future<void> dispose() => bridge.stop();
}
