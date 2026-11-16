import 'dart:io';

import 'package:cc_domain/core/domain/ports/secret_store_port.dart';
import 'package:cc_domain/features/mcp/domain/entities/mcp_server_definition.dart';
import 'package:cc_domain/features/mcp/domain/ports/mcp_client_control.dart';
import 'package:cc_domain/features/mcp/domain/services/mcp_tool_registry.dart';
import 'package:cc_domain/features/mcp/domain/value_objects/capability_tier.dart';
import 'package:cc_domain/features/mcp/domain/value_objects/mcp_server_draft.dart';
import 'package:cc_mcp/cc_mcp.dart';
import 'package:cc_mcp_client/cc_mcp_client.dart';
// Import the control directly rather than via the cc_server_core barrel: the
// barrel also exports `server_mcp_registry.dart`, which an UNRELATED in-flight
// refactor (ProposeFactTool → RecordMemoryFactUseCase) currently leaves stale
// and non-compiling. This control does not depend on that file.
// ignore: implementation_imports
import 'package:cc_server_core/src/mcp_servers/file_personal_mcp_server_repository.dart';
// ignore: implementation_imports
import 'package:cc_server_core/src/mcp_servers/mcp_server_secrets.dart';
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

    late InMemorySecretStore secrets;

    ({ServerMcpClientControl control, McpToolDispatcher dispatcher}) build() {
      secrets = InMemorySecretStore();
      final registry = McpToolRegistry(const []);
      final service = McpClientService(publishTools: registry.setPersonalTools);
      final dispatcher = McpToolDispatcher(registry: registry);
      final control = ServerMcpClientControl(
        service: service,
        dispatcher: dispatcher,
        dataDir: tmp.path,
        repository: FilePersonalMcpServerRepository(dataDir: tmp.path),
        secrets: McpServerSecrets(secrets),
        homeDir: null,
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
      expect(() => b.control.authorize('ghost'), throwsA(isA<StateError>()));
    });

    test('a hand-added server is listed with its definition, values kept '
        'out of it, and goes with its values', () async {
      final b = build();
      final saved = await b.control.saveServer(
        McpServerDraft(
          name: 'linear',
          transport: McpServerTransport.http,
          url: 'https://mcp.example.com/mcp',
          enabled: false,
          headerSet: const {'Authorization': 'Bearer secret'},
        ),
      );
      expect(saved.headerNames, ['Authorization']);
      expect(saved.toJson().toString(), isNot(contains('secret')));
      expect(secrets.values.values, contains('Bearer secret'));

      final listed = await b.control.servers();
      expect(listed, hasLength(1));
      expect(listed.single.source, McpExternalServerInfo.handAddedSource);
      expect(listed.single.definition, saved);
      expect(listed.single.lifecycle, 'disabled');

      // An edit that names no header keeps the stored value.
      final renamed = await b.control.saveServer(
        McpServerDraft(
          id: saved.id,
          name: 'linear2',
          transport: McpServerTransport.http,
          url: 'https://mcp.example.com/mcp',
          enabled: false,
        ),
      );
      expect(renamed.headerNames, ['Authorization']);
      expect(secrets.values.values, contains('Bearer secret'));

      await b.control.deleteServer(saved.id);
      expect(await b.control.servers(), isEmpty);
      expect(secrets.values, isEmpty);
    });

    test('a name clash among hand-added servers is refused', () async {
      final b = build();
      McpServerDraft draft() => McpServerDraft(
        name: 'dup',
        transport: McpServerTransport.stdio,
        command: 'true',
        enabled: false,
      );
      await b.control.saveServer(draft());
      await expectLater(
        b.control.saveServer(draft()),
        throwsA(
          isA<McpServerDefinitionException>().having(
            (e) => e.code,
            'code',
            'mcp_server.name_taken',
          ),
        ),
      );
    });

    test('editing or deleting an unknown server is not found', () async {
      final b = build();
      await expectLater(
        b.control.deleteServer('ghost'),
        throwsA(isA<McpServerNotFoundException>()),
      );
      await expectLater(
        b.control.saveServer(
          McpServerDraft(
            id: 'ghost',
            name: 'x',
            transport: McpServerTransport.stdio,
            command: 'true',
          ),
        ),
        throwsA(isA<McpServerNotFoundException>()),
      );
    });
  });
}
