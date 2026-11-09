import 'package:cc_domain/features/chat_bridge/domain/value_objects/chat_bridge_connection.dart';
import 'package:cc_domain/features/chat_bridge/domain/value_objects/chat_provider.dart';
import 'package:test/test.dart';

/// Which app a chat connection runs on travels with the connection and its
/// status: the settings surface offers different actions for an own app (edit
/// the bot, paste new tokens) than for the shared Control Center app.
void main() {
  ChatBridgeConnection connection({
    ChatConnectionMode mode = ChatConnectionMode.connect,
  }) => ChatBridgeConnection(
    provider: ChatProvider.slack,
    workspaceId: 'w-1',
    credentials: const {'grant': '{"seal":"s-1"}'},
    mode: mode,
    appId: 'A1',
    teamId: 'T1',
    teamName: 'Acme',
    botUserId: 'UBOT',
    botId: 'B1',
    botName: 'controlcenter',
    connectedAt: DateTime.utc(2026),
  );

  test('a connection round-trips its mode and bot id', () {
    final original = connection();

    final decoded = ChatBridgeConnection.fromJson(original.toJson());

    expect(decoded, original);
    expect(decoded.mode, ChatConnectionMode.connect);
    expect(decoded.botId, 'B1');
  });

  test('the mode and bot id are part of equality', () {
    expect(connection(), isNot(connection(mode: ChatConnectionMode.own)));
    expect(connection(), isNot(connection().copyWith(botId: 'B2')));
  });

  test('an unknown or absent mode reads as an own app', () {
    final json = connection().toJson()
      ..remove('mode')
      ..remove('botId');

    final decoded = ChatBridgeConnection.fromJson(json);
    expect(decoded.mode, ChatConnectionMode.own);
    expect(decoded.botId, '');
    expect(ChatConnectionMode.fromWire('teams'), ChatConnectionMode.own);
  });

  test('a status carries the mode only when something is stored', () {
    const shared = ChatConnectionStatus(
      provider: ChatProvider.slack,
      state: ChatConnectionState.connected,
      mode: ChatConnectionMode.connect,
    );

    expect(
      ChatConnectionStatus.fromJson(shared.toJson()).mode,
      ChatConnectionMode.connect,
    );
    expect(
      ChatConnectionStatus.fromJson(
        ChatConnectionStatus.none(ChatProvider.slack).toJson(),
      ).mode,
      isNull,
    );
  });
}
