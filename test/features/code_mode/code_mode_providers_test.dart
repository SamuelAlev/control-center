import 'package:cc_domain/cc_domain.dart' show RpcErrorCodes;
import 'package:cc_domain/features/code_mode/domain/ports/code_execution_repository.dart';
import 'package:cc_rpc/cc_rpc.dart' show RemoteRpcException;
import 'package:control_center/di/providers.dart';
import 'package:control_center/features/code_mode/providers/code_executions_list_provider.dart';
import 'package:control_center/features/code_mode/providers/code_mode_providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'code_mode_fakes.dart';

void main() {
  late FakeCodeModeRepository repo;
  late ProviderContainer container;

  setUp(() {
    repo = FakeCodeModeRepository();
    container = ProviderContainer(
      overrides: [codeModeRepositoryProvider.overrideWithValue(repo)],
    );
    addTearDown(container.dispose);
  });

  group('record for a transcript call', () {
    final rowStart = DateTime.utc(2026, 11, 17, 9, 30);

    Future<String?> lookup({String? runId, String? conversationId}) =>
        findCodeExecutionForCall(repo.listExecutions, (
          workspaceId: 'ws1',
          runId: runId,
          conversationId: conversationId,
          toolCallId: 'call_0',
          startedAt: rowStart,
        ));

    test('one request, narrowed to the call id in the run', () async {
      repo.onList = (_) async => CodeExecutionPage(
        items: [codeExecution(id: 'run-1/call_0', toolCallId: 'call_0')],
        nextCursor: 'more',
      );
      expect(await lookup(runId: 'run-1'), 'run-1/call_0');
      final query = repo.queries.single;
      expect(query.toolCallId, 'call_0');
      expect(query.runId, 'run-1');
      expect(query.conversationId, isNull);
      expect(query.cursor, isNull);
      // Records that started well after or well before the row are not
      // read: a run that repeats the id more than a page's worth on either
      // side cannot crowd the row's own record out.
      expect(query.until!.isAfter(rowStart), isTrue);
      expect(query.since!.isBefore(rowStart), isTrue);
      expect(
        query.until!.difference(query.since!),
        lessThanOrEqualTo(const Duration(minutes: 20)),
      );
    });

    test('among several matches, the start nearest the row wins', () async {
      repo.onList = (_) async => CodeExecutionPage(
        items: [
          codeExecution(
            id: 'run-1/call_0#3',
            toolCallId: 'call_0',
            startedAt: rowStart.add(const Duration(minutes: 4)),
          ),
          codeExecution(
            id: 'run-1/call_0#2',
            toolCallId: 'call_0',
            startedAt: rowStart.add(const Duration(milliseconds: 40)),
          ),
          codeExecution(
            id: 'run-1/call_0',
            toolCallId: 'call_0',
            startedAt: rowStart.subtract(const Duration(minutes: 2)),
          ),
        ],
      );
      expect(await lookup(runId: 'run-1'), 'run-1/call_0#2');
      expect(repo.queries, hasLength(1));
    });

    test('scopes to the conversation when there is no run', () async {
      expect(await lookup(conversationId: 'conv-1'), isNull);
      expect(repo.queries.single.conversationId, 'conv-1');
      expect(repo.queries.single.runId, isNull);
    });

    test('no scope, no request', () async {
      expect(await lookup(), isNull);
      expect(repo.queries, isEmpty);
    });

    test('a failure is the caller\'s to handle', () async {
      repo.onList = (_) async =>
          throw RemoteRpcException(RpcErrorCodes.unauthorized, 'no');
      await expectLater(lookup(runId: 'run-1'), throwsA(isA<Exception>()));
    });
  });

  group('record resolves', () {
    Future<bool> resolves(String id) {
      final key = (workspaceId: 'ws1', executionId: id);
      final sub = container.listen(
        codeExecutionResolvesProvider(key),
        (_, _) {},
      );
      addTearDown(sub.close);
      return container.read(codeExecutionResolvesProvider(key).future);
    }

    test('a readable record resolves', () async {
      repo.details['run-1/call-1'] = CodeExecutionDetail(
        execution: codeExecution(),
        calls: const [],
      );
      expect(await resolves('run-1/call-1'), isTrue);
    });

    test('a missing or refused record does not', () async {
      expect(await resolves('run-1/none'), isFalse);
      repo.detailError = RemoteRpcException(RpcErrorCodes.unauthorized, 'no');
      expect(await resolves('run-1/call-2'), isFalse);
    });
  });

  test('the list filter is a value', () {
    expect(
      const CodeExecutionsFilter(workspaceId: 'ws1', runId: 'r'),
      // Not const, so a distinct instance.
      CodeExecutionsFilter(workspaceId: 'ws1', runId: ['r'].single),
    );
    expect(const CodeExecutionsFilter(workspaceId: 'ws1').isScoped, isFalse);
  });
}
