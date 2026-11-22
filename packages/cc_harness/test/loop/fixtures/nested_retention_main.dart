/// Run by `nested_call_retention_test.dart` under a small heap cap
/// (`--old_gen_heap_size`): one model call whose tool makes many nested
/// calls with large arguments, each built fresh and dropped by the caller as
/// soon as its call returns. It prints `ok` when the run completes. If the
/// loop kept the calls' arguments until the turn ended, the heap would run out
/// before that.
///
/// The first argument is the shape: `strings` (about 1 MB of one string per
/// call), `maps` (a list of empty objects per call: little JSON, a large heap),
/// or `checklist` (the calls are checklist writes with long lists).
library;

import 'dart:io';

import 'package:cc_harness/loop.dart';
import 'package:cc_harness/messages.dart';
import 'package:cc_harness/provider.dart';
import 'package:cc_harness/tools.dart';

Future<void> main(List<String> args) async {
  final shape = args.single;
  final calls = switch (shape) {
    'strings' => 300,
    'maps' => 150,
    'checklist' => 150,
    _ => throw ArgumentError(shape),
  };
  final nestedName = shape == 'checklist' ? 'todo_write' : 'noop';
  var made = 0;
  final parent = _Tool('parent', selfGuards: true, (context) async {
    final reentry = context.reentry!;
    for (var i = 0; i < calls; i++) {
      final outcome = await reentry.call(nestedName, _argsFor(shape, i));
      if (outcome.status == ToolReentryStatus.completed) {
        made++;
      }
    }
    return HarnessToolResult.success('made $made calls');
  });
  final nested = _Tool(nestedName, (_) async => HarnessToolResult.success('.'));
  await const AgentLoopRunner()
      .run(
        history: <HarnessMessage>[],
        userMessage: 'Run the script.',
        tools: [parent, nested],
        provider: _Provider(),
      )
      .drain<void>();
  if (made != calls) {
    stderr.writeln('only $made of $calls calls completed');
    exit(1);
  }
  stdout.writeln('ok');
}

Map<String, dynamic> _argsFor(String shape, int i) => switch (shape) {
  'strings' => {'path': 'f$i', 'content': '${'x' * 1000000}$i'},
  'maps' => {
    'pad': [for (var k = 0; k < 20000; k++) <String, dynamic>{}],
  },
  _ => {
    'todos': [
      for (var k = 0; k < 4000; k++)
        {'content': 'Item $k of write $i ${'y' * 200}', 'status': 'pending'},
    ],
  },
};

class _Tool extends HarnessTool {
  _Tool(this.name, this._body, {this.selfGuards = false});

  @override
  final String name;
  @override
  final bool selfGuards;
  final Future<HarnessToolResult> Function(HarnessToolContext context) _body;

  @override
  String get description => 'A fixture tool.';
  @override
  Map<String, dynamic> get inputSchema => const {'type': 'object'};
  @override
  ToolApprovalTier get approvalTier => ToolApprovalTier.read;
  @override
  bool get parallelSafe => false;

  @override
  Future<HarnessToolResult> execute(
    Map<String, dynamic> args,
    HarnessToolContext context,
  ) => _body(context);
}

class _Provider extends LlmProviderPort {
  var _calls = 0;

  @override
  String get displayName => 'Retention fixture';
  @override
  String get defaultModel => 'fixture';
  @override
  Future<List<ProviderModel>> listModels() async => const [];

  @override
  Stream<LlmEvent> complete({
    required List<HarnessMessage> messages,
    List<LlmToolSchema> tools = const [],
    LlmCompleteConfig config = const LlmCompleteConfig(),
  }) async* {
    if (_calls++ == 0) {
      yield const LlmToolUseDelta(
        id: 'call_parent',
        name: 'parent',
        argumentsJson: '{}',
      );
      yield const LlmDone(stopReason: LlmStopReason.toolUse);
    } else {
      yield const LlmTextDelta('Done.');
      yield const LlmDone(stopReason: LlmStopReason.endTurn);
    }
  }
}
