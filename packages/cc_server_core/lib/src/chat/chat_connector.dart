import 'dart:async';

import 'package:cc_domain/cc_domain.dart'
    show NotFoundException, ValidationException;
import 'package:cc_domain/core/domain/entities/agent.dart';
import 'package:cc_domain/core/domain/events/domain_event_bus.dart';
import 'package:cc_domain/core/domain/repositories/agent_repository.dart';
import 'package:cc_domain/core/domain/repositories/user_repository.dart';
import 'package:cc_domain/core/domain/repositories/workspace_membership_repository.dart';
import 'package:cc_domain/core/domain/services/active_stream_registry.dart';
import 'package:cc_domain/core/domain/value_objects/agent_role.dart';
import 'package:cc_domain/features/chat_bridge/domain/entities/chat_user_link.dart';
import 'package:cc_domain/features/chat_bridge/domain/repositories/chat_link_repositories.dart';
import 'package:cc_domain/features/chat_bridge/domain/value_objects/chat_app_creation.dart';
import 'package:cc_domain/features/chat_bridge/domain/value_objects/chat_bot_profile.dart';
import 'package:cc_domain/features/chat_bridge/domain/value_objects/chat_bridge_connection.dart';
import 'package:cc_domain/features/chat_bridge/domain/value_objects/chat_link_method.dart';
import 'package:cc_domain/features/chat_bridge/domain/value_objects/chat_provider.dart';
import 'package:cc_domain/features/messaging/domain/repositories/messaging_repository.dart';
import 'package:cc_domain/features/ticketing/domain/entities/ticket.dart';
import 'package:cc_domain/features/ticketing/domain/entities/ticket_status.dart';
import 'package:cc_domain/features/ticketing/domain/services/ticket_workflow_service.dart';
import 'package:cc_infra/cc_infra.dart';
import 'package:cc_server_core/src/chat/chat_provider_plugin.dart';
import 'package:cc_server_core/src/chat/file_chat_connection_store.dart';
import 'package:uuid/uuid.dart';

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
    required this._registry,
    required this._store,
    required this._streamRegistry,
    required this._messaging,
    required this._messages,
    required this._agents,
    required this._spaceLinks,
    required this._userLinks,
    required this._users,
    required this._members,
    required this._tickets,
    required this._listWorkspaceIds,
    this._eventBus,
    ChatLinkCodeStore? linkCodes,
    ChatTicketDraftStore? ticketDrafts,
    this._emailVerified,
    this._deepLinks,
  }) : linkCodes = linkCodes ?? ChatLinkCodeStore(),
       ticketDrafts = ticketDrafts ?? ChatTicketDraftStore();

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

  /// Whether a Control Center user's email is verified — the half of email
  /// auto-linking this server must vouch for. Null leaves email auto-linking
  /// off: members link by sending the bot a code instead.
  final ChatEmailVerifier? _emailVerified;

  /// Builds the "View in Control Center" links a bridge puts on its task cards.
  /// Null on a server with no advertised URL — the cards then carry no call to
  /// action rather than a link nothing can open.
  final ChatDeepLinks? _deepLinks;

  /// One-time codes for the "link my account" flow, shared across workspaces and
  /// providers (each code is scoped to both internally).
  final ChatLinkCodeStore linkCodes;

  /// Tickets drafted from chat commands, waiting for their reporter to create
  /// them in Control Center.
  final ChatTicketDraftStore ticketDrafts;

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
      mode: connection.mode,
      teamId: connection.teamId,
      teamName: connection.teamName,
      appId: connection.appId,
      botUserId: connection.botUserId,
      botName: connection.botName,
      lastError: runtime?.adapter.lastError,
      connectedAt: connection.connectedAt,
      streamingAvailable: runtime?.bridge.streamingAvailable,
      canManageApp:
          connection.mode == ChatConnectionMode.own &&
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

  /// Stores [credentials] for the workspace's own app and opens the
  /// connection, replacing any own-app connection already running for that
  /// workspace × provider.
  ///
  /// The plugin verifies the credentials *before* anything is written, so a typo
  /// is reported to the person pasting it rather than becoming a transport that
  /// quietly never works. A workspace on the shared Connect app must
  /// disconnect it first: the two never mix.
  Future<ChatConnectionStatus> connect({
    required String workspaceId,
    required ChatProvider provider,
    required Map<String, String> credentials,
  }) async {
    final plugin = _registry.of(provider);
    final existing = await _store.load(workspaceId, provider);
    if (existing?.mode == ChatConnectionMode.connect) {
      throw ValidationException(
        'This workspace uses the Control Center ${provider.displayName} app. '
        'Disconnect it before connecting your own app.',
      );
    }
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

  /// Stores a connection a provider sign-in produced (the shared Connect app)
  /// and opens it, replacing whatever shared-app connection the workspace had.
  ///
  /// A provider team is served by exactly one workspace on this server: the
  /// newest install wins, so any other workspace's shared-app connection to
  /// the same team is closed here — without revoking anything upstream, since
  /// the grant just issued rides the same team binding.
  Future<ChatConnectionStatus> adoptConnection(
    ChatBridgeConnection connection,
  ) async {
    if (connection.mode != ChatConnectionMode.connect) {
      throw ArgumentError.value(connection.mode, 'mode', 'not a shared app');
    }
    final workspaceId = connection.workspaceId;
    final provider = connection.provider;
    final plugin = _registry.of(provider);
    final existing = await connectionFor(workspaceId, provider);
    if (existing?.mode == ChatConnectionMode.own) {
      throw ValidationException(
        'This workspace runs its own ${provider.displayName} app. Disconnect '
        'it before adding the Control Center app.',
      );
    }
    // CROSS-WORKSPACE BY DESIGN: enforcing one workspace per provider team on
    // this server needs every workspace's connection metadata. Only shared-app
    // connections to the very team just installed are touched, and only to be
    // closed.
    for (final other in await _listWorkspaceIds()) {
      if (other == workspaceId || !_store.has(other, provider)) {
        continue;
      }
      final stale = await _store.load(other, provider);
      if (stale != null &&
          stale.mode == ChatConnectionMode.connect &&
          stale.teamId == connection.teamId) {
        CcInfraLog.info(
          'Chat(${provider.wire}): workspace $workspaceId took over team '
          '${connection.teamId} from workspace $other',
        );
        await _shutdownRuntime(other, provider);
        await _store.clear(other, provider);
      }
    }
    await _shutdownRuntime(workspaceId, provider);
    if (existing != null && existing.teamId != connection.teamId) {
      // The workspace moved to another team: the old team's install is ours
      // to give back.
      await plugin.release(existing);
    }
    await _store.save(connection);
    await _store.clearSetup(workspaceId, provider);
    await _spawn(connection);
    return status(workspaceId, provider);
  }

  /// Whether [workspaceId] runs its own app on [provider].
  Future<bool> hasOwnConnection(
    String workspaceId,
    ChatProvider provider,
  ) async {
    if (!_store.has(workspaceId, provider)) {
      return false;
    }
    final connection = await _store.load(workspaceId, provider);
    return connection?.mode == ChatConnectionMode.own;
  }

  /// Whether any workspace on this server runs its own app on [provider].
  Future<bool> anyOwnConnection(ChatProvider provider) async {
    // CROSS-WORKSPACE BY DESIGN: the server-wide "which app answers this
    // provider" switch reads only each workspace's connection mode.
    for (final workspaceId in await _listWorkspaceIds()) {
      if (!_store.has(workspaceId, provider)) {
        continue;
      }
      final connection = await _store.load(workspaceId, provider);
      if (connection?.mode == ChatConnectionMode.own) {
        return true;
      }
    }
    return false;
  }

  /// Closes the workspace's connection on [provider] and forgets its credentials.
  ///
  /// A shared-app connection is also released upstream (the bot is
  /// uninstalled from the team) before its grant is forgotten.
  ///
  /// The chat↔Control Center *links* survive on purpose: reconnecting the same
  /// app restores every bridged thread instead of stranding them and a workspace
  /// deletion removes the rows anyway (they live in its database).
  Future<void> disconnect(String workspaceId, ChatProvider provider) async {
    final connection = await connectionFor(workspaceId, provider);
    await _shutdownRuntime(workspaceId, provider);
    if (connection != null) {
      await _registry.of(provider).release(connection);
    }
    await _store.clear(workspaceId, provider);
    await _store.clearSetup(workspaceId, provider);
  }

  /// A grant the provider will never honour again: the connection is closed
  /// and forgotten, out of band from whatever call discovered it.
  void _onGrantRejected(ChatBridgeConnection connection, String reason) {
    unawaited(() async {
      final current = await _store.load(
        connection.workspaceId,
        connection.provider,
      );
      if (current == null || current.connectedAt != connection.connectedAt) {
        return; // Replaced meanwhile; the new connection is not affected.
      }
      CcInfraLog.warning(
        'Chat(${connection.provider.wire}/${connection.workspaceId}): '
        'connection closed, its grant was rejected ($reason)',
      );
      await _shutdownRuntime(connection.workspaceId, connection.provider);
      await _store.clear(connection.workspaceId, connection.provider);
    }());
  }

  /// Saves a connection whose credentials changed on their own (a renewed
  /// grant), without restarting the transport that is using it.
  Future<void> _persistInPlace(ChatBridgeConnection connection) async {
    final runtime =
        _runtimes[_key(connection.workspaceId, connection.provider)];
    if (runtime != null &&
        runtime.connection.connectedAt != connection.connectedAt) {
      return; // A stale runtime must not overwrite its replacement.
    }
    await _store.save(connection);
    runtime?.connection = connection;
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
    final creation = await (await _appManager(
      workspaceId,
      provider,
    )).createApp(profile);
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
  ) async => (await _appManager(workspaceId, provider)).readProfile();

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
    final remaining = await (await _appManager(
      workspaceId,
      provider,
    )).writeProfile(profile);
    // A rename changes what members type after `@`, so the settings card must
    // stop showing the old name. Best-effort: the edit already landed.
    await _refreshIdentity(workspaceId, provider);
    return remaining;
  }

  /// The app manager for a workspace × provider, refusing when the provider has
  /// no app-management API at all.
  Future<ChatAppManager> _appManager(
    String workspaceId,
    ChatProvider provider,
  ) async {
    final plugin = _registry.of(provider);
    final connection = await connectionFor(workspaceId, provider);
    if (connection?.mode == ChatConnectionMode.connect) {
      throw ValidationException(
        'The Control Center ${provider.displayName} app is managed by Control '
        'Center Connect and cannot be edited from here.',
      );
    }
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
    if (connection == null || connection.mode != ChatConnectionMode.own) {
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
          botId: refreshed.botId,
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

  /// Mints the one-time code a member sends to the bot in a direct message.
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

  /// [userId]'s outstanding link code on [provider], with the chat profile
  /// that sent it once one has.
  ChatLinkCode? pendingUserLink(
    String workspaceId,
    String userId, {
    required ChatProvider provider,
  }) => linkCodes.pendingFor(workspaceId, userId, provider: provider);

  /// Watches [userId]'s outstanding code: the claim arrives from the chat app,
  /// so the open "link my account" dialog has to be told.
  Stream<ChatLinkCode?> watchPendingUserLink(
    String workspaceId,
    String userId, {
    required ChatProvider provider,
  }) => _snapshots(
    read: () => pendingUserLink(workspaceId, userId, provider: provider),
    changes: linkCodes.changes.where(
      (change) =>
          change.workspaceId == workspaceId &&
          change.userId == userId &&
          change.provider == provider,
    ),
  );

  /// Links [userId] to the chat profile that sent their code, after they
  /// confirmed it is theirs.
  ///
  /// [externalUserId] is the profile the person saw and confirmed: a claim by
  /// anyone else is refused rather than linked, so a code read over somebody's
  /// shoulder cannot be confirmed by its owner into the wrong account. The
  /// claim must also be for the team the workspace is connected to right now.
  Future<ChatUserLink> confirmUserLink({
    required String workspaceId,
    required String userId,
    required ChatProvider provider,
    required String externalUserId,
  }) async {
    final connection = await connectionFor(workspaceId, provider);
    final pending = linkCodes.pendingFor(
      workspaceId,
      userId,
      provider: provider,
    );
    final claim = pending?.claim;
    if (connection == null ||
        claim == null ||
        claim.externalUserId != externalUserId ||
        claim.externalTeamId != connection.teamId) {
      throw const NotFoundException(
        'That link request is no longer valid. Generate a new code and send '
        'it to the bot again.',
      );
    }
    final taken = linkCodes.takeClaimed(
      workspaceId,
      userId,
      provider: provider,
      externalUserId: externalUserId,
    );
    if (taken == null) {
      throw const NotFoundException(
        'That link request is no longer valid. Generate a new code and send '
        'it to the bot again.',
      );
    }
    final existing = await _userLinks.forExternalUser(
      workspaceId,
      provider: provider,
      externalTeamId: claim.externalTeamId,
      externalUserId: claim.externalUserId,
    );
    final link = ChatUserLink(
      id: existing?.id ?? const Uuid().v4(),
      workspaceId: workspaceId,
      provider: provider,
      externalTeamId: claim.externalTeamId,
      externalUserId: claim.externalUserId,
      userId: userId,
      method: ChatLinkMethod.code,
      linkedAt: DateTime.now(),
    );
    await _userLinks.upsert(link);
    final user = await _users.getById(userId);
    final bridge = _runtimes[_key(workspaceId, provider)]?.bridge;
    if (bridge != null) {
      unawaited(
        bridge.announceLinked(
          conversationId: claim.conversationId,
          displayName: user?.displayName ?? user?.handle ?? userId,
        ),
      );
    }
    CcInfraLog.info(
      'Chat(${provider.wire}/$workspaceId): linked ${claim.externalUserId} to '
      '${user?.handle ?? userId} by code',
    );
    return link;
  }

  /// Refuses the chat profile that sent [userId]'s code and burns the code.
  void declineUserLink(
    String workspaceId,
    String userId, {
    required ChatProvider provider,
  }) => linkCodes.revokeForUser(workspaceId, userId, provider: provider);

  // ── Ticket drafts ──

  /// [userId]'s ticket drafts from chat in [workspaceId], oldest first.
  List<ChatTicketDraft> ticketDraftsFor(String workspaceId, String userId) =>
      ticketDrafts.forUser(workspaceId, userId);

  /// Watches [userId]'s drafts: they arrive from the chat app.
  Stream<List<ChatTicketDraft>> watchTicketDrafts(
    String workspaceId,
    String userId,
  ) => _snapshots(
    read: () => ticketDraftsFor(workspaceId, userId),
    changes: ticketDrafts.changes.where(
      (change) => change.workspaceId == workspaceId && change.userId == userId,
    ),
  );

  /// The current value, then a fresh read on every matching change. A plain
  /// controller rather than an `async*` generator so that cancelling the
  /// subscription detaches from [changes] at once instead of waiting for the
  /// next change to wake the generator.
  static Stream<T> _snapshots<T>({
    required T Function() read,
    required Stream<Object?> changes,
  }) {
    StreamSubscription<Object?>? source;
    late final StreamController<T> controller;
    controller = StreamController<T>(
      onListen: () {
        controller.add(read());
        source = changes.listen((_) => controller.add(read()));
      },
      onCancel: () async {
        // Not awaited: the done future of a cancelled controller waits on
        // this very callback.
        unawaited(controller.close());
        await source?.cancel();
      },
    );
    return controller.stream;
  }

  /// Creates the ticket [userId] drafted from chat, optionally with the title
  /// and description they corrected. The draft is consumed either way.
  Future<Ticket> confirmTicketDraft({
    required String workspaceId,
    required String userId,
    required String draftId,
    String? title,
    String? description,
  }) async {
    final pending = ticketDrafts
        .forUser(workspaceId, userId)
        .where((d) => d.id == draftId)
        .firstOrNull;
    if (pending == null) {
      throw const NotFoundException('That ticket draft is gone.');
    }
    // Checked before the draft is taken, so a rejected edit keeps it.
    final finalTitle = (title ?? pending.title).trim();
    if (finalTitle.isEmpty) {
      throw const ValidationException('A ticket needs a title.');
    }
    final finalDescription = (description ?? pending.description)?.trim();
    // Taken before the await: a second confirm racing this one finds nothing,
    // so one draft makes at most one ticket.
    final draft = ticketDrafts.take(workspaceId, userId, draftId);
    if (draft == null) {
      throw const NotFoundException('That ticket draft is gone.');
    }
    try {
      return await _tickets.createTicket(
        workspaceId: workspaceId,
        title: finalTitle,
        description: finalDescription == null || finalDescription.isEmpty
            ? null
            : finalDescription,
        // Unscheduled: the reporter decides what happens to it next.
        status: TicketStatus.backlog,
        // A chat app is a command surface, not a ticket vendor: the ticket is
        // a first-class local ticket reported by the linked human who
        // confirmed it.
        createdByType: 'user',
        createdById: userId,
      );
    } on Object {
      // A failed create must not cost the member their draft.
      ticketDrafts.restore(draft);
      rethrow;
    }
  }

  /// Drops [userId]'s draft without creating anything. False when it was
  /// already gone.
  bool discardTicketDraft(String workspaceId, String userId, String draftId) =>
      ticketDrafts.take(workspaceId, userId, draftId) != null;

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
    final adapter = plugin.createAdapter(
      connection,
      ChatAdapterContext(
        persist: _persistInPlace,
        onRejected: (reason) => _onGrantRejected(connection, reason),
      ),
    );
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
      ticketDrafts: ticketDrafts,
      emailVerified: _emailVerified,
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
