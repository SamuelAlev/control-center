import 'dart:async';

import 'package:cc_connect_core/cc_connect_core.dart' show SealedGrant;
import 'package:cc_domain/cc_domain.dart' show ValidationException;
import 'package:cc_domain/features/chat_bridge/domain/value_objects/chat_app_creation.dart';
import 'package:cc_domain/features/chat_bridge/domain/value_objects/chat_bot_profile.dart';
import 'package:cc_domain/features/chat_bridge/domain/value_objects/chat_bridge_connection.dart';
import 'package:cc_domain/features/chat_bridge/domain/value_objects/chat_provider.dart';
import 'package:cc_domain/features/chat_bridge/domain/value_objects/chat_provider_descriptor.dart';
import 'package:cc_infra/cc_infra.dart';
import 'package:cc_server_core/src/chat/chat_provider_plugin.dart';
import 'package:cc_server_core/src/chat/slack_connect.dart';
import 'package:cc_server_core/src/identity/provider_token.dart';
import 'package:rhttp/rhttp.dart';

/// Slack, as one plugin among (eventually) several.
///
/// Everything that used to be spelled out in the connector and the RPC ops —
/// which tokens Slack needs, what their prefixes are, that `auth.test` is how an
/// identity is proven, that the app is reshaped through the App Manifest API —
/// is stated here instead. That is what makes the layers above provider-blind.
///
/// Two modes, one per [ChatConnectionMode]:
///
///  * **own** — an admin pasted their own app's `xoxb-` (or rotating
///    `xoxe.xoxb-`) bot token and `xapp-` app token. Socket Mode dials Slack
///    directly; the guided manifest flow can create and edit the app.
///  * **connect** — the shared Control Center app, installed through
///    Connect's sign-in. Only the sealed grant is stored; the 12-hour bot token
///    lives in memory, is renewed through Connect and events arrive as
///    references through the Connect relay.
class SlackChatProviderPlugin implements ChatProviderPlugin {
  /// Creates the Slack plugin. [_httpClientFactory] hands out a configured HTTP
  /// client per call site, so a probe never shares state with a live
  /// connection. [_connect] is absent on a server without Connect, which then
  /// offers own apps only.
  SlackChatProviderPlugin({
    required this._httpClientFactory,
    this._connect,
    SlackConfigTokenCache? configTokens,
  }) : _configTokens = configTokens ?? SlackConfigTokenCache();

  /// The credential field holding the bot user OAuth token.
  static const botTokenField = 'botToken';

  /// The credential field holding the app-level (Socket Mode) token.
  static const appTokenField = 'appToken';

  /// The credential field holding the app-configuration refresh token, which is
  /// what makes the app manageable from here.
  static const configTokenField = 'configRefreshToken';

  /// The credential a Connect-mode connection stores: the sealed grant
  /// ([ProviderToken.encode], which never carries the access token).
  static const grantField = 'grant';

  /// Slack's public shape, as the settings UI renders it.
  ///
  /// The prefix rules live here rather than in an op: they are a property of
  /// Slack's token formats and stating them once means the client can pre-check
  /// a paste and the server can refuse the same value with the same sentence.
  static const slackDescriptor = ChatProviderDescriptor(
    provider: ChatProvider.slack,
    credentialFields: [
      ChatCredentialField(
        id: botTokenField,
        label: 'Bot user OAuth token',
        hint: 'OAuth & Permissions → Bot User OAuth Token',
        // With token rotation on, Slack issues `xoxe.xoxb-` bot tokens.
        acceptedPrefixes: ['xoxb-', slackRotatingBotTokenPrefix],
        prefixError:
            'A bot user OAuth token starts with `xoxb-` (or `xoxe.xoxb-` with '
            'token rotation). Copy it from OAuth & Permissions in your Slack '
            'app settings.',
      ),
      ChatCredentialField(
        id: appTokenField,
        label: 'App-level token',
        hint: 'Basic Information → App-Level Tokens, scope connections:write',
        acceptedPrefixes: ['xapp-'],
        prefixError:
            'An app-level token starts with `xapp-`. Generate one with the '
            '`connections:write` scope under Basic Information.',
      ),
      ChatCredentialField(
        id: configTokenField,
        label: 'App configuration refresh token',
        hint: 'Optional — lets Control Center edit the app for you',
        required: false,
        acceptedPrefixes: ['xoxe-'],
        prefixError:
            'An app configuration refresh token starts with `xoxe-`. Generate a '
            'pair at api.slack.com/apps under “Manage app configuration '
            'tokens”.',
      ),
    ],
    capabilities: slackChatCapabilities,
    consoleUrl: 'https://api.slack.com/apps',
    docsUrl: 'https://api.slack.com/apis/connections/socket',
    managementCredentialField: configTokenField,
    supportsGuidedSetup: true,
    supportsBotCustomization: true,
    supportsSetupLink: true,
  );

  final RhttpClient Function() _httpClientFactory;
  final SlackConnectGrants? _connect;

  /// Configuration access tokens, single-flight per workspace (S2).
  final SlackConfigTokenCache _configTokens;

  /// Access tokens minted by a sign-in that just completed, handed from
  /// [connectionFromGrant] to the [createAdapter] that follows so the first
  /// Slack call does not spend a refresh. Keyed by workspace, matched on the
  /// seal.
  final Map<String, ProviderToken> _freshGrants = {};

  /// The live Connect sessions, by workspace, so [release] can revoke with the
  /// newest seal.
  final Map<String, SlackConnectSession> _sessions = {};

  @override
  ChatProviderDescriptor get descriptor => slackDescriptor;

  @override
  ChatProvider get provider => ChatProvider.slack;

  @override
  String? get managementCredentialField =>
      slackDescriptor.managementCredentialField;

  /// Whether this server can run Connect-mode connections at all.
  bool get supportsConnect => _connect != null;

  @override
  Future<ChatBridgeConnection> connectionFrom({
    required String workspaceId,
    required Map<String, String> credentials,
    ChatBridgeConnection? existing,
  }) async {
    final clean = descriptor.validate(credentials);
    // `auth.test` is the only cheap proof that the bot token is real, which team
    // it belongs to and who the bot is; `bots.info` adds the app id, which
    // `auth.test` never reports. The app-level token cannot be verified here —
    // `apps.connections.open` is the only call that accepts it — so it is
    // proven by the socket and surfaces through the connection's status.
    final identity = await SlackApiClient(
      httpClient: _httpClientFactory(),
      botToken: clean[botTokenField] ?? '',
    ).identify();
    final previous = existing?.mode == ChatConnectionMode.own ? existing : null;
    return ChatBridgeConnection(
      provider: ChatProvider.slack,
      workspaceId: workspaceId,
      credentials: {...?previous?.credentials, ...clean},
      appId: identity.appId ?? previous?.appId ?? '',
      teamId: identity.teamId,
      teamName: identity.teamName,
      botUserId: identity.userId,
      botId: identity.botId ?? '',
      botName: identity.botName,
      connectedAt: DateTime.now(),
    );
  }

  /// The Connect-mode connection a finished shared-app sign-in describes.
  ///
  /// The grant's ids are taken from Connect's claim and then proven with the
  /// bot token itself: `auth.test` must name the same team, bot user and bot
  /// id, or nothing is stored.
  Future<ChatBridgeConnection> connectionFromGrant({
    required String workspaceId,
    required ProviderToken token,
    required SealedGrant grant,
  }) async {
    if (_connect == null) {
      throw const ValidationException(
        'Control Center Connect is not available on this server.',
      );
    }
    if (!token.isSealed ||
        !token.accessToken.startsWith(slackRotatingBotTokenPrefix) ||
        grant.teamId.isEmpty ||
        grant.botUserId.isEmpty ||
        grant.botId.isEmpty) {
      throw const FormatException('slack: incomplete grant');
    }
    final identity = await SlackApiClient(
      httpClient: _httpClientFactory(),
      botToken: token.accessToken,
    ).authTest();
    if (identity.teamId != grant.teamId ||
        identity.userId != grant.botUserId ||
        identity.botId != grant.botId) {
      throw const FormatException('slack: grant does not match its token');
    }
    _freshGrants[workspaceId] = token;
    return ChatBridgeConnection(
      provider: ChatProvider.slack,
      workspaceId: workspaceId,
      credentials: {grantField: token.encode()},
      mode: ChatConnectionMode.connect,
      appId: grant.appId,
      teamId: grant.teamId,
      teamName: grant.teamName.isNotEmpty ? grant.teamName : identity.teamName,
      botUserId: grant.botUserId,
      botId: grant.botId,
      botName: identity.botName,
      connectedAt: DateTime.now(),
    );
  }

  @override
  ChatProviderAdapter createAdapter(
    ChatBridgeConnection connection,
    ChatAdapterContext context,
  ) => switch (connection.mode) {
    ChatConnectionMode.own => _ownAdapter(connection),
    ChatConnectionMode.connect => _connectAdapter(connection, context),
  };

  SlackChatAdapter _ownAdapter(ChatBridgeConnection connection) {
    final api = SlackApiClient(
      httpClient: _httpClientFactory(),
      botToken: connection.credential(botTokenField) ?? '',
    );
    return SlackChatAdapter(
      workspaceId: connection.workspaceId,
      api: api,
      transport: SlackChatAdapter.socketMode(
        workspaceId: connection.workspaceId,
        api: api,
        appToken: connection.credential(appTokenField) ?? '',
      ),
      botUserId: connection.botUserId,
      botId: connection.botId,
      botName: connection.botName,
      teamId: connection.teamId,
    );
  }

  SlackChatAdapter _connectAdapter(
    ChatBridgeConnection connection,
    ChatAdapterContext context,
  ) {
    final grants = _connect;
    if (grants == null) {
      throw const ValidationException(
        'Control Center Connect is not available on this server.',
      );
    }
    final stored = ProviderToken.tryParse(connection.credential(grantField));
    if (stored == null || !stored.isSealed) {
      throw const ValidationException(
        'The shared Slack app connection is damaged. Disconnect and connect '
        'again.',
      );
    }
    final fresh = _freshGrants.remove(connection.workspaceId);
    final workspaceId = connection.workspaceId;
    late final SlackConnectSession session;
    session = SlackConnectSession(
      connection: connection,
      token: fresh != null && fresh.seal == stored.seal ? fresh : stored,
      grants: grants,
      authTest: (token) => SlackApiClient(
        httpClient: _httpClientFactory(),
        botToken: token,
      ).authTest(),
      persist: (token) => context.persist(
        connection.copyWith(credentials: {grantField: token.encode()}),
      ),
      onRejected: (reason) {
        if (identical(_sessions[workspaceId], session)) {
          _sessions.remove(workspaceId);
        }
        context.onRejected(reason);
      },
    );
    _sessions[workspaceId] = session;
    final api = SlackApiClient.withTokenSource(
      httpClient: _httpClientFactory(),
      tokenSource: session.botToken,
    );
    return SlackChatAdapter(
      workspaceId: workspaceId,
      api: api,
      transport: ({required onEnvelope, required onStateChanged}) =>
          SlackRelayTransport(
            workspaceId: workspaceId,
            teamId: connection.teamId,
            api: api,
            attach: grants.attach,
            onEnvelope: onEnvelope,
            onStateChanged: onStateChanged,
          ),
      botUserId: connection.botUserId,
      botId: connection.botId,
      botName: connection.botName,
      teamId: connection.teamId,
    );
  }

  @override
  Future<void> release(ChatBridgeConnection connection) async {
    if (connection.mode != ChatConnectionMode.connect) {
      return;
    }
    final grants = _connect;
    final session = _sessions.remove(connection.workspaceId);
    final token =
        session?.token ??
        ProviderToken.tryParse(connection.credential(grantField));
    if (grants == null || token == null || !token.isSealed) {
      return;
    }
    try {
      await grants.revoke(token, workspaceId: connection.workspaceId);
    } on Object catch (e) {
      CcInfraLog.warning(
        'Slack(${connection.workspaceId}): releasing the shared app failed: $e',
      );
    }
  }

  @override
  String? setupLinkFor(ChatBotProfile profile) =>
      SlackManifestService.manifestCreateUrl(profile);

  @override
  ChatAppManager appManager(ChatAppContext context) => _SlackAppManager(
    context: context,
    service: SlackManifestService(
      // Manifest calls authenticate per call with the configuration token; the
      // bot token has no authority here and is deliberately absent.
      api: SlackApiClient(httpClient: _httpClientFactory(), botToken: ''),
      readRefreshToken: context.readCredential,
      writeRefreshToken: context.writeCredential,
      tokenCache: _configTokens,
      cacheKey: context.workspaceId,
    ),
  );
}

/// Slack's App Manifest API behind the generic app-management interface.
class _SlackAppManager implements ChatAppManager {
  _SlackAppManager({required this.context, required this.service});

  final ChatAppContext context;
  final SlackManifestService service;

  @override
  Future<ChatAppCreation> createApp(ChatBotProfile profile) async {
    final creation = await service.createApp(profile);
    return ChatAppCreation(
      appId: creation.appId,
      settingsUrl: creation.settingsUrl,
      // The two things Slack has no API for. Naming them as steps (rather than
      // as two more URL fields on the result) is what keeps the client's
      // finish-setup screen provider-agnostic.
      remainingSteps: [
        ChatSetupStep(
          id: 'appToken',
          title: 'Generate an app-level token',
          url: creation.appTokenUrl,
          hint:
              'Basic Information → App-Level Tokens, with the '
              '`connections:write` scope.',
        ),
        ChatSetupStep(
          id: 'install',
          title: 'Install the app to your workspace',
          url: creation.installPageUrl,
          hint: 'Install App → copy the bot user OAuth token.',
        ),
      ],
    );
  }

  @override
  Future<ChatBotProfile> readProfile() async =>
      service.profile(await context.appId());

  @override
  Future<ChatSetupStep?> writeProfile(ChatBotProfile profile) async {
    final appId = await context.appId();
    final result = await service.updateProfile(appId: appId, profile: profile);
    if (!result.permissionsUpdated) {
      return null;
    }
    // Slack applies a manifest immediately but keeps the *grant* at whatever was
    // installed, so a scope change does nothing until the app is reinstalled.
    return ChatSetupStep(
      id: 'install',
      title: 'Reinstall the app to your workspace',
      url: 'https://api.slack.com/apps/$appId/install-on-team',
      hint: 'Install App → Reinstall to Workspace.',
    );
  }
}
