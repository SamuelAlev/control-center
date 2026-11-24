import 'dart:io';

import 'package:cc_domain/core/domain/ports/secret_store_port.dart';
import 'package:cc_domain/features/mcp/domain/services/mcp_tool_registry.dart';
import 'package:cc_domain/features/mcp/domain/value_objects/capability_tier.dart';
import 'package:cc_mcp/cc_mcp.dart';
// ignore: implementation_imports
import 'package:cc_server_core/src/mcp_servers/mcp_server_secrets.dart';
// ignore: implementation_imports
import 'package:cc_server_core/src/server_mcp_client_control.dart';
import 'package:path/path.dart' as p;
import 'package:test/test.dart';

void main() {
  group('ServerMcpClientControl', () {
    late Directory tmp;

    setUp(() {
      tmp = Directory.systemTemp.createTempSync('mcp_client_control_test');
    });
    tearDown(() => tmp.deleteSync(recursive: true));

    ({ServerMcpClientControl control, McpToolDispatcher dispatcher}) build() {
      final dispatcher = McpToolDispatcher(registry: McpToolRegistry(const []));
      final control = ServerMcpClientControl(
        dispatcher: dispatcher,
        dataDir: tmp.path,
      );
      return (control: control, dispatcher: dispatcher);
    }

    test('defaults to always-ask', () async {
      final b = build();
      expect(await b.control.approvalMode(), ApprovalMode.alwaysAsk);
      expect(b.dispatcher.approvalMode, ApprovalMode.alwaysAsk);
    });

    test('setApprovalMode re-points the dispatcher gate and persists', () async {
      final b = build();
      await b.control.setApprovalMode(ApprovalMode.yolo);
      expect(await b.control.approvalMode(), ApprovalMode.yolo);
      expect(b.dispatcher.approvalMode, ApprovalMode.yolo);

      // A fresh control over the SAME data dir loads the persisted posture and
      // applies it to ITS dispatcher on init() — proving cross-restart survival.
      final b2 = build();
      await b2.control.init();
      expect(await b2.control.approvalMode(), ApprovalMode.yolo);
      expect(b2.dispatcher.approvalMode, ApprovalMode.yolo);
    });

    test('what the owner\'s personal servers of earlier releases kept is '
        'deleted, and the approval posture stays', () async {
      final b = build();
      await b.control.setApprovalMode(ApprovalMode.write);
      for (final name in ServerMcpClientControl.legacyPersonalFiles) {
        File(p.join(tmp.path, name)).writeAsStringSync('{}');
      }
      final secrets = InMemorySecretStore()
        ..values['mcp_server:personal:srv-1:env:TOKEN'] = 'old'
        ..values['mcp_server:ws:ws-1:srv-2:env:TOKEN'] = 'kept'
        ..values['mcp_oauth:wsu:ws-1:user-1:https://mcp.example.com'] = '{}';

      await b.control.deleteLegacyPersonalFiles();
      await McpServerSecrets(secrets).deleteLegacyPersonal();
      // A second boot finds nothing to delete.
      await b.control.deleteLegacyPersonalFiles();

      expect(
        [for (final f in tmp.listSync()) p.basename(f.path)],
        ['mcp_client_config.json'],
      );
      expect(secrets.values.keys, {
        'mcp_server:ws:ws-1:srv-2:env:TOKEN',
        'mcp_oauth:wsu:ws-1:user-1:https://mcp.example.com',
      });
      expect(await build().control.approvalMode(), ApprovalMode.write);
    });
  });
}
