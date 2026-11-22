import 'package:cc_domain/features/dispatch/domain/modes/read_only_run_profile.dart';
import 'package:cc_harness/context.dart';
import 'package:cc_harness/tools.dart';
import 'package:cc_infra/src/dispatch/run_private_output_store.dart';
import 'package:cc_infra/src/harness/harness_tool_surface.dart';
import 'package:test/test.dart';

class _Tool extends HarnessTool {
  _Tool(
    this.name, {
    this.approvalTier = ToolApprovalTier.read,
    this.actionClasses = const {},
  });

  @override
  final String name;
  @override
  final ToolApprovalTier approvalTier;
  @override
  final Set<ActionClass> actionClasses;

  @override
  String get description => 'The $name operation.';

  @override
  Map<String, dynamic> get inputSchema => const {'type': 'object'};

  @override
  Future<HarnessToolResult> execute(
    Map<String, dynamic> args,
    HarnessToolContext context,
  ) async => HarnessToolResult.success('$name ran');
}

/// The built-in harness's read-only surface: what the run is shown, and
/// what a `repl` script of the run can reach (its script lane is built from
/// the same admitted set), is only what `ReadOnlyRunProfile` admits.
void main() {
  final tools = [
    _Tool('read'),
    _Tool('search'),
    _Tool('todo_read'),
    _Tool('get_ticket'),
    _Tool('repl'),
    _Tool('submit_output'),
    _Tool(
      'write',
      approvalTier: ToolApprovalTier.write,
      actionClasses: {ActionClass.fileWriteOutsideWorktree},
    ),
    _Tool(
      'bash',
      approvalTier: ToolApprovalTier.exec,
      actionClasses: {ActionClass.processSpawn},
    ),
    _Tool('todo_write', approvalTier: ToolApprovalTier.write),
    _Tool('task'),
    _Tool('vibe_spawn'),
    _Tool('ask_user'),
    _Tool('send_message'),
    _Tool('wake_me'),
    _Tool('update_space_notes'),
    _Tool('a_tool_nobody_decided'),
  ];

  test('the run and its scripts reach only reads and the output verb', () {
    final registry = HarnessToolRegistry.of(tools);
    for (final residency in [
      const ToolResidencySpec.allResident(),
      const ToolResidencySpec(enabled: true),
    ]) {
      final surface = materializeHarnessToolSurface(
        registry: registry,
        surface: ReadOnlyRunProfile.toolSurfaceOver(registry.tools),
        residency: residency,
      );
      final reached = {for (final t in surface.all) t.name};
      expect(
        reached.difference({
          'read',
          'search',
          'todo_read',
          'get_ticket',
          'repl',
          'submit_output',
          // The discovery browser a deferred surface adds over the same set.
          'search_tools',
        }),
        isEmpty,
      );
      expect(reached, containsAll(['read', 'submit_output']));
      for (final t in surface.scriptOnly) {
        expect(
          ReadOnlyRunProfile.admits(t.name, t.actionClasses),
          isTrue,
          reason: '${t.name} is reachable from a script',
        );
      }
    }
  });

  test('a script lane, when there is one, holds no state change', () {
    final registry = HarnessToolRegistry.of(tools);
    final surface = materializeHarnessToolSurface(
      registry: registry,
      surface: ReadOnlyRunProfile.toolSurfaceOver(registry.tools),
      residency: const ToolResidencySpec(enabled: true),
    );
    final lane = {for (final t in surface.scriptOnly) t.name};
    expect(
      lane.intersection({
        'write',
        'bash',
        'todo_write',
        'task',
        'vibe_spawn',
        'ask_user',
        'send_message',
        'wake_me',
        'update_space_notes',
        'a_tool_nobody_decided',
      }),
      isEmpty,
    );
  });

  test(
    'what a read-only run stores stays in its own scope: the worker of '
    'the same conversation and agent lists and loads none of it, and it '
    "is gone when the run ends; the run reads the worker's outputs too",
    () async {
      final store = InMemoryToolOutputStore();
      const worker = ToolOutputScope(
        workspaceId: 'ws-1',
        conversationId: 'conv-1',
        agentId: 'agent-1',
      );
      final workerHandle = (await store.put(
        const ToolOutputWrite(scope: worker, toolName: 'bash', content: 'ev'),
      ))!.handle;
      final reviewer = runOutputStore(store, readOnly: true, runId: 'run-r')!;
      expect(
        runOutputStore(store, readOnly: false, runId: 'run-w'),
        same(store),
      );
      // An over-budget repl result (the repl sink) and a cut observation (the
      // loop's ingest) both write under the tool context's scope: the worker's.
      final handles = [
        for (final tool in ['repl', 'bash'])
          (await reviewer.put(
            ToolOutputWrite(scope: worker, toolName: tool, content: 'x' * 5000),
          ))!.handle,
      ];
      // The reviewer reads its own back, as read_output, outputs() and
      // loadOutput do with the same scope.
      expect(
        (await reviewer.list(worker)).map((e) => e.handle),
        unorderedEquals([...handles, workerHandle]),
      );
      expect((await reviewer.read(worker, handles.first)).isOk, isTrue);
      // A read-only run may read: the worker's cut output, by the handle its
      // transcript shows, loads in the reviewer.
      final evidence = await reviewer.read(worker, workerHandle);
      expect(evidence.isOk, isTrue);
      expect(evidence.chunk!.text, 'ev');
      // The worker's next segment lists and loads nothing of the reviewer's.
      expect(
        [for (final e in await store.list(worker)) e.handle],
        [workerHandle],
      );
      for (final handle in handles) {
        expect(
          (await store.read(worker, handle)).isOk,
          isFalse,
          reason: 'the worker never reads the private scope',
        );
      }
      // Clearing goes to the private scope only.
      await reviewer.clearConversation(worker);
      expect((await store.read(worker, workerHandle)).isOk, isTrue);
      final again = (await reviewer.put(
        const ToolOutputWrite(scope: worker, toolName: 'repl', content: 'r'),
      ))!.handle;
      await reviewer.clearScope(worker);
      expect((await reviewer.read(worker, again)).isOk, isFalse);
      expect((await store.read(worker, workerHandle)).isOk, isTrue);
      await (reviewer as RunPrivateOutputStore).retire();
      expect(
        [for (final e in await reviewer.list(worker)) e.handle],
        [workerHandle],
      );
    },
  );
}
