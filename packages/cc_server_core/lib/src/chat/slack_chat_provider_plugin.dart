import 'package:cc_domain/features/chat_bridge/domain/value_objects/chat_app_creation.dart';
import 'package:cc_domain/features/chat_bridge/domain/value_objects/chat_bot_profile.dart';
import 'package:cc_domain/features/chat_bridge/domain/value_objects/chat_bridge_connection.dart';
import 'package:cc_domain/features/chat_bridge/domain/value_objects/chat_provider.dart';
import 'package:cc_domain/features/chat_bridge/domain/value_objects/chat_provider_descriptor.dart';
import 'package:cc_infra/cc_infra.dart';
import 'package:cc_server_core/src/chat/chat_provider_plugin.dart';
import 'package:dio/dio.dart';

/// Slack, as one plugin among (eventually) several.
///
/// Everything that used to be spelled out in the connector and the RPC ops —
/// which tokens Slack needs, what their prefixes are, that `auth.test` is how an
/// identity is proven, that the app is reshaped through the App Manifest API —
/// is stated here instead. That is what makes the layers above provider-blind.
class SlackChatProviderPlugin implements ChatProviderPlugin {
  /// Creates the Slack plugin. [dioFactory] hands out a configured HTTP client
  /// per call site, so a probe never shares state with a live connection.
  SlackChatProviderPlugin({required Dio Function() dioFactory})
    : _dioFactory = dioFactory;

  /// The credential field holding the bot user OAuth token.
  static const botTokenField = 'botToken';

  /// The credential field holding the app-level (Socket Mode) token.
  static const appTokenField = 'appToken';

  /// The credential field holding the app-configuration refresh token, which is
  /// what makes the app manageable from here.
  static const configTokenField = 'configRefreshToken';

  /// Slack's public shape, as the settings UI renders it.
  ///
  /// The prefix rules live here rather than in an op: they are a property of
  /// Slack's token formats, and stating them once means the client can pre-check
  /// a paste and the server can refuse the same value with the same sentence.
  static const slackDescriptor = ChatProviderDescriptor(
    provider: ChatProvider.slack,
    credentialFields: [
      ChatCredentialField(
        id: botTokenField,
        label: 'Bot user OAuth token',
        hint: 'OAuth & Permissions → Bot User OAuth Token',
        expectedPrefix: 'xoxb-',
        prefixError:
            'A bot user OAuth token starts with `xoxb-`. Copy it from OAuth & '
            'Permissions in your Slack app settings.',
      ),
      ChatCredentialField(
        id: appTokenField,
        label: 'App-level token',
        hint: 'Basic Information → App-Level Tokens, scope connections:write',
        expectedPrefix: 'xapp-',
        prefixError:
            'An app-level token starts with `xapp-`. Generate one with the '
            '`connections:write` scope under Basic Information.',
      ),
      ChatCredentialField(
        id: configTokenField,
        label: 'App configuration refresh token',
        hint: 'Optional — lets Control Center edit the app for you',
        required: false,
        expectedPrefix: 'xoxe',
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

  final Dio Function() _dioFactory;

  @override
  ChatProviderDescriptor get descriptor => slackDescriptor;

  @override
  ChatProvider get provider => ChatProvider.slack;

  @override
  String? get managementCredentialField =>
      slackDescriptor.managementCredentialField;

  @override
  Future<ChatBridgeConnection> connectionFrom({
    required String workspaceId,
    required Map<String, String> credentials,
    ChatBridgeConnection? existing,
  }) async {
    final clean = descriptor.validate(credentials);
    // `auth.test` is the only cheap proof that the bot token is real, which team
    // it belongs to and who the bot is. The app-level token cannot be verified
    // here — `apps.connections.open` is the only call that accepts it — so it is
    // proven by the socket and surfaces through the connection's status.
    final identity = await SlackApiClient(
      dio: _dioFactory(),
      botToken: clean[botTokenField] ?? '',
    ).authTest();
    return ChatBridgeConnection(
      provider: ChatProvider.slack,
      workspaceId: workspaceId,
      credentials: {...?existing?.credentials, ...clean},
      appId: identity.appId ?? existing?.appId ?? '',
      teamId: identity.teamId,
      teamName: identity.teamName,
      botUserId: identity.userId,
      botName: identity.botName,
      connectedAt: DateTime.now(),
    );
  }

  @override
  ChatProviderAdapter createAdapter(ChatBridgeConnection connection) =>
      SlackChatAdapter(
        workspaceId: connection.workspaceId,
        api: SlackApiClient(
          dio: _dioFactory(),
          botToken: connection.credential(botTokenField) ?? '',
        ),
        appToken: connection.credential(appTokenField) ?? '',
        botUserId: connection.botUserId,
        botName: connection.botName,
        teamId: connection.teamId,
      );

  @override
  String? setupLinkFor(ChatBotProfile profile) =>
      SlackManifestService.manifestCreateUrl(profile);

  @override
  ChatAppManager appManager(ChatAppContext context) => _SlackAppManager(
    context: context,
    service: SlackManifestService(
      // Manifest calls authenticate per call with the configuration token; the
      // bot token has no authority here and is deliberately absent.
      api: SlackApiClient(dio: _dioFactory(), botToken: ''),
      readRefreshToken: context.readCredential,
      writeRefreshToken: context.writeCredential,
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
