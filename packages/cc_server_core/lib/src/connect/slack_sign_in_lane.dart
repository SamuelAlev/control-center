import 'package:cc_connect_core/cc_connect_core.dart';
import 'package:cc_domain/cc_domain.dart' show AuthException;
import 'package:cc_domain/features/chat_bridge/domain/value_objects/chat_bridge_connection.dart';
import 'package:cc_domain/features/chat_bridge/domain/value_objects/chat_provider.dart';
import 'package:cc_infra/cc_infra.dart' show SlackApiException;
import 'package:cc_server_core/src/chat/chat_connector.dart';
import 'package:cc_server_core/src/chat/slack_chat_provider_plugin.dart';
import 'package:cc_server_core/src/connect/sign_in_service.dart';

/// The `slack` lane of the browser sign-in: installing the shared Control
/// Center Slack app into a workspace through Connect.
///
/// The lane never runs an own-app OAuth flow. A workspace on its own Slack app
/// pastes Socket Mode tokens instead (the `chat.connect` op), and while it does
/// this lane refuses to route through Connect at all — the two modes never mix
/// in one workspace. The grant belongs to the workspace, never to the admin
/// who installed it.
final class SlackSignInLane implements SignInLaneBinding {
  /// Creates the lane over the chat connector that will run the connection.
  SlackSignInLane({required this._connector, required this._plugin});

  final ChatConnector _connector;
  final SlackChatProviderPlugin _plugin;

  @override
  ConnectOAuthLane get lane => ConnectOAuthLane.slack;

  @override
  Future<OwnOAuthApp?> ownApp(String? workspaceId) async => null;

  @override
  Future<bool> allowsConnect(String? workspaceId) async {
    if (!_plugin.supportsConnect || workspaceId == null) {
      return false;
    }
    final existing = await _connector.connectionFor(
      workspaceId,
      ChatProvider.slack,
    );
    return existing?.mode != ChatConnectionMode.own;
  }

  @override
  Future<String?> slotFor(String? workspaceId) async {
    if (workspaceId == null || workspaceId.isEmpty) {
      throw const AuthException(
        'Slack connects to a workspace. Open a workspace and try again.',
      );
    }
    return workspaceId;
  }

  @override
  Future<SignInIdentity> identify(String accessToken) =>
      throw UnsupportedError('The shared Slack app has no own-app exchange.');

  @override
  Future<void> store(SignInResult result) async {
    final workspaceId = result.slot;
    final grant = result.grant;
    if (workspaceId == null || workspaceId.isEmpty || grant == null) {
      throw const FormatException('slack: no workspace or grant');
    }
    if (!await allowsConnect(workspaceId)) {
      throw const AuthException(
        'This workspace runs its own Slack app. Disconnect it before adding '
        'the Control Center app.',
      );
    }
    final ChatBridgeConnection connection;
    try {
      connection = await _plugin.connectionFromGrant(
        workspaceId: workspaceId,
        token: result.token,
        grant: grant,
      );
    } on SlackApiException catch (e) {
      // Slack could not vouch for the token just issued: report the sign-in
      // as failed rather than leaving it pending.
      throw FormatException('slack: auth.test failed (${e.error})');
    }
    await _connector.adoptConnection(connection);
  }

  @override
  Future<LaneConnection?> connection(String userId, String? workspaceId) async {
    if (workspaceId == null) {
      return null;
    }
    final connection = await _connector.connectionFor(
      workspaceId,
      ChatProvider.slack,
    );
    if (connection == null || connection.mode != ChatConnectionMode.connect) {
      return null;
    }
    return LaneConnection(
      lane: lane,
      connected: true,
      account: connection.teamName,
      accountId: connection.teamId,
      workspaceSlot: true,
      source: SignInMode.connect,
    );
  }

  @override
  Future<void> disconnect(String userId, String? workspaceId) async {
    if (workspaceId == null) {
      return;
    }
    final connection = await _connector.connectionFor(
      workspaceId,
      ChatProvider.slack,
    );
    // Only the shared app is this lane's to remove; an own app is disconnected
    // from the chat settings.
    if (connection?.mode == ChatConnectionMode.connect) {
      await _connector.disconnect(workspaceId, ChatProvider.slack);
    }
  }
}
