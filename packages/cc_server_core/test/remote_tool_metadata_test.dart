import 'package:cc_domain/core/domain/repositories/agent_repository.dart';
import 'package:cc_domain/features/mcp/domain/services/mcp_tool_registry.dart';
import 'package:cc_domain/features/messaging/domain/repositories/messaging_repository.dart';
import 'package:cc_domain/features/ticketing/domain/repositories/ticket_repository.dart';
import 'package:cc_domain/features/ticketing/domain/services/ticket_workflow_service.dart';
import 'package:cc_host/src/policy/remote_tool_policy.dart';
import 'package:cc_mcp/src/tools/get_messages_tool.dart';
import 'package:cc_mcp/src/tools/list_agents_tool.dart';
import 'package:cc_mcp/src/tools/list_spaces_tool.dart';
import 'package:cc_mcp/src/tools/send_message_tool.dart';
import 'package:cc_mcp/src/tools/ticket_crud_tools.dart';
import 'package:cc_mcp/src/tools/ticket_orchestration_tools.dart';
import 'package:test/test.dart';

class _Agents implements AgentRepository {
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _Messages implements MessagingRepository {
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _Tickets implements TicketRepository {
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _Workflow implements TicketWorkflowService {
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  test(
    'the remote tool allow-list agrees with registered mutation metadata',
    () {
      final messages = _Messages();
      final tickets = _Tickets();
      final workflow = _Workflow();
      final registry = McpToolRegistry([
        ListTicketsTool(repository: tickets),
        GetTicketTool(repository: tickets),
        ListAgentsTool(repository: _Agents()),
        ListSpacesTool(repository: messages, hiddenSpaces: _noHiddenSpaces),
        GetSpaceMessagesTool(
          repository: messages,
          hiddenSpaces: _noHiddenSpaces,
        ),
        UpdateTicketTool(service: workflow, repository: tickets),
        AssignTicketTool(service: workflow),
        SendSpaceMessageTool(repository: messages),
      ]);

      for (final name in RemoteToolPolicy.readOnly) {
        expect(
          registry.resolve(name, includePersonal: false)?.isMutating,
          isFalse,
          reason: name,
        );
      }
      for (final name in RemoteToolPolicy.mutating) {
        expect(
          registry.resolve(name, includePersonal: false)?.isMutating,
          isTrue,
          reason: name,
        );
      }
      expect(
        registry.resolve('nonexistent', includePersonal: false)?.isMutating,
        isNull,
      );
    },
  );
}

Future<Set<String>> _noHiddenSpaces({
  required String workspaceId,
  required String? callerConversationId,
}) async => const {};
