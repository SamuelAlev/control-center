import 'package:cc_connect_core/cc_connect_core.dart' show ConnectOAuthLane;
import 'package:cc_data/cc_data.dart' show SignInLaneInfo;
import 'package:cc_domain/core/domain/value_objects/workspace_role.dart';
import 'package:control_center/core/providers/rpc_client_provider.dart';
import 'package:control_center/features/auth/providers/oauth_providers.dart';
import 'package:control_center/features/auth/providers/provider_sign_in_controller.dart';
import 'package:control_center/features/identity/providers/identity_providers.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../helpers/active_workspace.dart';
import '../../../helpers/fake_rpc_client.dart';
import '../../../helpers/test_wrap.dart';

/// The member every chat-bridge test signs in as.
const kChatTestUserId = 'u-me';

/// One `chat.providers` entry for Slack. A null [state] is a workspace with
/// nothing stored.
Map<String, dynamic> slackProviderEntry({
  String? state = 'connected',
  String mode = 'own',
  bool canManageApp = true,
}) => {
  'descriptor': {
    'provider': 'slack',
    'commandName': 'cc',
    'supportsGuidedSetup': true,
    'supportsBotCustomization': true,
  },
  if (state != null)
    'status': {
      'provider': 'slack',
      'state': state,
      'mode': mode,
      'teamName': 'Acme',
      'botName': 'Control Center',
      'canManageApp': canManageApp,
    },
};

/// A fake server that records every `repo/call` and answers through
/// [answer]; anything [answer] does not know fails the call.
class ChatTestServer {
  /// Creates the server with [answer] as its op handler.
  ChatTestServer(this.answer) {
    host.onCall = (op, args) {
      calls.add((op: op, args: args));
      return answer(op, args) ?? (throw StateError('unexpected op $op'));
    };
  }

  /// Answers one op, or null when the op is not expected.
  final Map<String, dynamic>? Function(String op, Map<String, dynamic> args)
  answer;

  /// The wire host the test client talks to.
  final host = FakeRpcHost();

  /// Every call the client made, in order.
  final calls = <({String op, Map<String, dynamic> args})>[];

  /// The args of every call to [op].
  List<Map<String, dynamic>> argsOf(String op) => [
    for (final c in calls)
      if (c.op == op) c.args,
  ];
}

/// Pumps [child] against [server] as a [role] of the test workspace.
Future<void> pumpChat(
  WidgetTester tester,
  ChatTestServer server,
  Widget child, {
  WorkspaceRole role = WorkspaceRole.admin,
  Map<ConnectOAuthLane, SignInLaneInfo> lanes = const {},
  TextDirection? textDirection,
  bool Function(String url)? openUrl,
}) async {
  final rpc = server.host.client();
  addTearDown(rpc.close);
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        rpcClientProvider.overrideWithValue(rpc),
        activeWorkspaceIdOverride(),
        currentUserIdProvider.overrideWithValue(kChatTestUserId),
        myWorkspaceRoleProvider.overrideWith((ref, workspaceId) => role),
        oauthLanesProvider.overrideWith((ref, workspaceId) async => lanes),
        if (openUrl != null)
          externalUrlOpenerProvider.overrideWithValue(openUrl),
      ],
      // Settings pages scroll; the test viewport is short.
      child: testWrap(
        SingleChildScrollView(child: child),
        textDirection: textDirection,
      ),
    ),
  );
  await settle(tester);
}

/// Lets RPC round trips and frames land without waiting on the spinners,
/// which never settle.
Future<void> settle(WidgetTester tester) async {
  for (var i = 0; i < 5; i++) {
    await tester.pump(const Duration(milliseconds: 100));
  }
}
