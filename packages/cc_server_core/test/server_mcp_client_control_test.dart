import 'dart:io';

import 'package:cc_domain/features/mcp/domain/services/mcp_tool_registry.dart';
import 'package:cc_mcp/cc_mcp.dart';
import 'package:cc_mcp_client/cc_mcp_client.dart';
// Import the control directly rather than via the cc_server_core barrel: the
// barrel also exports `server_mcp_registry.dart`, which an UNRELATED in-flight
// refactor (ProposeFactTool → RecordMemoryFactUseCase) currently leaves stale
// and non-compiling. This control does not depend on that file.
// ignore: implementation_imports
import 'package:cc_server_core/src/server_mcp_client_control.dart';
import 'package:test/test.dart';

void main() {
  group('ServerMcpClientControl', () {
    late Directory tmp;

    setUp(() {
      tmp = Directory.systemTemp.createTempSync('mcp_client_control_test');
    });
    tearDown(() => tmp.deleteSync(recursive: true));

    ({ServerMcpClientControl control, McpToolDispatcher dispatcher}) build() {
      final registry = McpToolRegistry(const []);
      final service = McpClientService(registry: registry);
      final dispatcher = McpToolDispatcher(registry: registry);
      final control = ServerMcpClientControl(
        service: service,
        dispatcher: dispatcher,
        dataDir: tmp.path,
      );
      return (control: control, dispatcher: dispatcher);
    }

    test('defaults to always-ask and reports no servers', () async {
      final b = build();
      expect(await b.control.approvalMode(), ApprovalMode.alwaysAsk);
      expect(await b.control.servers(), isEmpty);
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

    test('authorize throws for an unknown server', () {
      final b = build();
      expect(
        () => b.control.authorize('ghost'),
        throwsA(isA<StateError>()),
      );
    });
  });
}
