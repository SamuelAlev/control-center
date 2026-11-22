// A script's reads of its run's past (history, outputs, loadOutput), its
// kept values (keep) and storedKeys, through the REAL runner
// (CC_CODEMODE_RUNNER) and the host's ScriptPastCalls over a RunScriptPast:
// every read is scoped from the run, bounded per call, per script and per
// run, and every argument is checked before any work.
import 'dart:convert';

import 'package:cc_domain/features/code_mode/domain/ports/code_execution_port.dart';
import 'package:cc_domain/features/code_mode/domain/ports/script_past_port.dart';
import 'package:cc_domain/features/code_mode/domain/services/script_fix_hints.dart';
import 'package:cc_domain/features/code_mode/domain/services/script_result_formatter.dart';
import 'package:cc_domain/features/code_mode/domain/value_objects/code_execution_status.dart';
import 'package:cc_domain/features/code_mode/domain/value_objects/code_mode_limits.dart';
import 'package:cc_domain/features/code_mode/domain/value_objects/script_tool_descriptor.dart';
import 'package:cc_domain/features/messaging/domain/ports/conversation_transcript_port.dart';
import 'package:cc_harness/context.dart';
import 'package:cc_infra/src/code_mode/code_execution_service.dart';
import 'package:cc_infra/src/code_mode/code_sandbox_process.dart';
import 'package:cc_infra/src/code_mode/run_script_past.dart';
import 'package:cc_infra/src/code_mode/script_lookups.dart';
import 'package:cc_infra/src/code_mode/script_past_calls.dart';
import 'package:test/test.dart';

import 'code_mode_test_support.dart';

final _tools = [
  ScriptToolDescriptor(
    name: 'read',
    namespace: ScriptToolNamespace.builtin,
    description: 'A read tool.',
    inputSchema: const {'type': 'object'},
  ),
];

/// `probe(f)` records each call's value, or `ERR <message>` when it
/// rejected, in `out`.
const _probe =
    'const out = [];\n'
    'async function probe(f) {\n'
    '  try { out.push(await f()); } catch (e) { out.push("ERR " + String(e.message)); }\n'
    '}\n';

TranscriptRow _row(
  String id,
  TranscriptRole role,
  String text, {
  String? tool,
  bool cut = false,
  int? fullLength,
  String? handle,
}) => TranscriptRow(
  id: id,
  messageId: id.split(':').first,
  role: role,
  authorId: null,
  runId: null,
  tool: tool,
  text: text,
  folded: false,
  cut: cut,
  fullLength: fullLength,
  outputHandle: handle,
  outputLost: false,
  at: DateTime.utc(2026, 11, 19),
);

/// Transcripts by workspace and conversation, and by workspace and run,
/// paged as the port promises (50 rows, 64 KiB of text).
class _Transcripts implements ConversationTranscriptPort {
  final Map<String, List<TranscriptRow>> conversations = {};
  final Map<String, List<TranscriptRow>> runs = {};
  final Map<String, String> fullTexts = {};
  final List<String> asked = [];

  /// A page of [all] from [from]; places here are indexes into the rows
  /// that pass the filters, in decimal (the port's are opaque).
  TranscriptPage _page(
    List<TranscriptRow> all,
    String? from,
    int limit,
    Set<TranscriptRole>? roles,
    Set<String>? tools,
  ) {
    final rows = [
      for (final r in all)
        if ((roles == null || roles.contains(r.role)) &&
            (tools == null || tools.contains(r.tool)))
          r,
    ];
    final start = from == null ? 0 : int.parse(from);
    final page = <TranscriptRow>[];
    var bytes = 0;
    for (var i = start; i < rows.length; i++) {
      final size = utf8.encode(rows[i].text).length;
      if (page.length == limit ||
          (page.isNotEmpty &&
              bytes + size > ConversationTranscriptPort.maxPageBytes)) {
        break;
      }
      page.add(rows[i]);
      bytes += size;
    }
    final next = start + page.length;
    return TranscriptPage(
      rows: page,
      messageCount: all.length,
      nextStart: next < rows.length ? '$next' : null,
    );
  }

  TranscriptSlice? _slice(String rowId, int offset) {
    final full = fullTexts[rowId];
    if (full == null || offset > full.length) {
      return null;
    }
    final end = (offset + ConversationTranscriptPort.maxRowChars).clamp(
      0,
      full.length,
    );
    return TranscriptSlice(
      rowId: rowId,
      offset: offset,
      text: full.substring(offset, end),
      fullLength: full.length,
      nextOffset: end < full.length ? end : null,
    );
  }

  @override
  Future<TranscriptPage> page({
    required String workspaceId,
    required String conversationId,
    required String? start,
    required int limit,
    required Set<TranscriptRole>? roles,
    required Set<String>? tools,
  }) async {
    asked.add('page $workspaceId/$conversationId');
    return _page(
      conversations['$workspaceId/$conversationId'] ?? const [],
      start,
      limit,
      roles,
      tools,
    );
  }

  @override
  Future<TranscriptSlice?> slice({
    required String workspaceId,
    required String conversationId,
    required String rowId,
    required int offset,
  }) async {
    asked.add('slice $workspaceId/$conversationId');
    final rows = conversations['$workspaceId/$conversationId'] ?? const [];
    return rows.any((r) => r.id == rowId) ? _slice(rowId, offset) : null;
  }

  @override
  Future<TranscriptPage> pageRun({
    required String workspaceId,
    required String runId,
    required String? start,
    required int limit,
    required Set<TranscriptRole>? roles,
    required Set<String>? tools,
  }) async {
    asked.add('pageRun $workspaceId/$runId');
    return _page(
      runs['$workspaceId/$runId'] ?? const [],
      start,
      limit,
      roles,
      tools,
    );
  }

  @override
  Future<TranscriptSlice?> sliceRun({
    required String workspaceId,
    required String runId,
    required String rowId,
    required int offset,
  }) async {
    asked.add('sliceRun $workspaceId/$runId');
    final rows = runs['$workspaceId/$runId'] ?? const [];
    return rows.any((r) => r.id == rowId) ? _slice(rowId, offset) : null;
  }
}

void main() {
  final runner = realRunnerPath();
  late CodeSandboxProcess process;
  late CodeExecutionService service;
  late _Transcripts transcripts;
  late InMemoryToolOutputStore outputs;
  late MemoryStore store;
  late Set<String> hidden;
  late ScriptPastSources sources;
  const scope = ToolOutputScope(
    workspaceId: 'ws-1',
    conversationId: 'conv-1',
    agentId: 'agent-1',
  );

  setUp(() async {
    process = CodeSandboxProcess(executable: runner);
    expect((await process.selfTest()).isAvailable, isTrue);
    store = MemoryStore();
    service = CodeExecutionService(
      sandbox: process,
      executions: MemoryExecutions(),
      store: store,
      serverProcessCap: 2,
    );
    transcripts = _Transcripts();
    outputs = InMemoryToolOutputStore();
    hidden = {};
    sources = ScriptPastSources(
      transcripts: transcripts,
      hiddenSpaces:
          ({required String workspaceId, String? callerConversationId}) async =>
              hidden,
    );
  });

  tearDown(() async {
    await service.dispose();
    expect(process.liveProcessCount, 0);
  });

  ScriptPastPort mainPast() => sources.forRun(
    workspaceId: 'ws-1',
    conversationId: 'conv-1',
    spaceId: 'space-1',
    store: outputs,
    scope: scope,
  );

  Future<CodeExecutionResult> execute(
    String code, {
    ScriptPastPort? past,
    bool noPast = false,
    bool readOnly = false,
    CodeModeLimits? limits,
    CodeExecutionService? on,
    String runId = 'run-1',
  }) => (on ?? service).execute(
    CodeExecutionRequest(
      readOnly: readOnly,
      past: noPast ? null : past ?? mainPast(),
      workspaceId: 'ws-1',
      runId: runId,
      parentToolCallId: 'call_${code.hashCode.abs()}',
      surface: CodeExecutionSurface.harness,
      code: code,
      description: 'the past',
      limits: limits ?? CodeModeLimits(),
      tools: _tools,
      conversationId: 'conv-1',
      agentId: 'agent-1',
      spaceId: 'space-1',
    ),
    callNested: (_) async =>
        NestedCallOutcome(status: NestedCallStatus.completed, value: const {}),
  );

  Future<List<Object?>> probe(
    String body, {
    ScriptPastPort? past,
    bool noPast = false,
    bool readOnly = false,
    CodeExecutionService? on,
  }) async {
    final r = await execute(
      '$_probe$body\ntext("OUT" + JSON.stringify(out) + "END");',
      past: past,
      noPast: noPast,
      readOnly: readOnly,
      on: on,
    );
    expect(
      r.execution.status,
      CodeExecutionStatus.completed,
      reason: r.result.text,
    );
    final match = RegExp('OUT(.*)END', dotAll: true).firstMatch(r.result.text);
    expect(match, isNotNull, reason: r.result.text);
    return (jsonDecode(match!.group(1)!) as List).cast<Object?>();
  }

  group('history', () {
    setUp(() {
      transcripts.conversations['ws-1/conv-1'] = [
        for (var i = 0; i < 120; i++)
          if (i == 60)
            _row('c', TranscriptRole.compaction, 'Summary of turns 0 to 59.')
          else
            _row(
              'm$i:0',
              i.isEven ? TranscriptRole.person : TranscriptRole.tool,
              'row $i',
              tool: i.isEven ? null : 'bash',
            ),
      ];
      transcripts.conversations['ws-1/conv-2'] = [
        _row('x:0', TranscriptRole.person, 'ANOTHER CONVERSATION'),
      ];
      transcripts.conversations['ws-2/conv-1'] = [
        _row('y:0', TranscriptRole.person, 'ANOTHER WORKSPACE'),
      ];
    });

    test('pages the run conversation with its message count; never another '
        "conversation's or workspace's rows", () async {
      final out = await probe('''
await probe(() => history());
await probe(() => history({ start: "50", limit: 5 }));
await probe(() => history({ start: "118" }));
await probe(() => history({ role: "tool", tool: "bash", limit: 2 }));
await probe(() => history({ role: ["compaction"] }));
await probe(() => history({ start: 0, limit: 1 }));
''');
      final first = out[0]! as Map;
      expect(first['rows'], hasLength(50));
      expect(first['message_count'], 120);
      expect(first['next_start'], '50');
      final second = out[1]! as Map;
      expect(
        [for (final r in _maps(second['rows'])) r['id']],
        ['m50:0', 'm51:0', 'm52:0', 'm53:0', 'm54:0'],
      );
      expect(second['next_start'], '55');
      final last = out[2]! as Map;
      expect(last['rows'], hasLength(2));
      expect(last['next_start'], isNull);
      final tools = out[3]! as Map;
      expect(tools['message_count'], 120);
      expect(
        [for (final r in _maps(tools['rows'])) r['tool']],
        ['bash', 'bash'],
      );
      // The compaction stands where it happened, between rows 59 and 61.
      final compaction = out[4]! as Map;
      expect(compaction['message_count'], 120);
      expect(_maps(compaction['rows']).single['text'], contains('Summary'));
      // 0 is the first page, as no start is.
      expect(_maps((out[5]! as Map)['rows']).single['id'], 'm0:0');
      final whole = await probe('''
let start; const ids = [];
for (;;) { const p = await history({ start }); for (const r of p.rows) ids.push(r.id); if (p.next_start === null) break; start = p.next_start; }
out.push(ids);
''');
      final ids = (whole.single! as List).cast<String>();
      expect(ids, hasLength(120));
      expect(ids.indexOf('c'), 60);
      expect(ids, isNot(contains('x:0')));
      expect(ids, isNot(contains('y:0')));
      expect(transcripts.asked.toSet(), {'page ws-1/conv-1'});
    });

    test('a cut row has its length and its handle, and reads on by row and '
        'offset', () async {
      final full = 'z' * 40000;
      transcripts.fullTexts['m1:0'] = full;
      transcripts.conversations['ws-1/conv-1']![1] = _row(
        'm1:0',
        TranscriptRole.tool,
        full.substring(0, ConversationTranscriptPort.maxRowChars),
        tool: 'bash',
        cut: true,
        fullLength: full.length,
        handle: 'out_abcdefgh',
      );
      final out = await probe('''
const brief = (s) => ({ offset: s.offset, next_offset: s.next_offset, full_length: s.full_length, len: s.text.length });
await probe(() => history({ start: "1", limit: 1 }).then((p) => { const r = p.rows[0]; return { cut: r.cut, full_length: r.full_length, output_handle: r.output_handle, len: r.text.length }; }));
await probe(() => history({ row: "m1:0", offset: 16384 }).then(brief));
await probe(() => history({ row: "m1:0", offset: 32768 }).then(brief));
await probe(() => history({ row: "nope", offset: 0 }));
''');
      final row = out[0]! as Map;
      expect(row['len'], ConversationTranscriptPort.maxRowChars);
      expect(row['cut'], isTrue);
      expect(row['full_length'], 40000);
      expect(row['output_handle'], 'out_abcdefgh');
      final next = out[1]! as Map;
      expect(next['offset'], 16384);
      expect(next['next_offset'], 32768);
      expect(next['len'], ConversationTranscriptPort.maxRowChars);
      expect(out[2]! as Map, containsPair('next_offset', null));
      expect(out[2]! as Map, containsPair('len', 40000 - 32768));
      expect(out[3], startsWith('ERR No row "nope"'));
    });

    test('a 64 KiB page cuts before 50 rows', () async {
      transcripts.conversations['ws-1/conv-1'] = [
        for (var i = 0; i < 10; i++)
          _row('b$i:0', TranscriptRole.agent, 'b' * 16000),
      ];
      final out = await probe(
        'await probe(() => history().then((p) => ({ rows: p.rows.length, '
        'message_count: p.message_count, next_start: p.next_start })));',
      );
      final page = out.single! as Map;
      expect(page['rows'], 4);
      expect(page['message_count'], 10);
      expect(page['next_start'], '4');
    });

    test('a subagent pages its own run, not its parent conversation', () async {
      transcripts.runs['ws-1/child-1'] = [
        _row('child-1:0', TranscriptRole.agent, 'CHILD'),
      ];
      final ledger = RunOutputLedger();
      final out = await probe(
        'await probe(() => history());',
        past: sources.forSubagent(
          workspaceId: 'ws-1',
          runId: 'child-1',
          conversationId: 'conv-1',
          spaceId: 'space-1',
          store: outputs,
          scope: scope,
          ledger: ledger,
        ),
      );
      final page = out.single! as Map;
      expect([for (final r in _maps(page['rows'])) r['text']], ['CHILD']);
      expect(transcripts.asked, ['pageRun ws-1/child-1']);
    });

    test("a space the run's person cannot read is refused", () async {
      hidden = {'space-1'};
      final out = await probe('''
await probe(() => history());
await probe(() => outputs());
await probe(() => loadOutput("${newToolOutputHandle()}"));
''');
      for (final o in out) {
        expect(o, 'ERR ${RunScriptPast.hiddenSpace}');
      }
      expect(transcripts.asked, isEmpty);
    });

    test('hostile arguments are refused before any read', () async {
      final out = await probe('''
await probe(() => history({ limit: 51 }));
await probe(() => history({ limit: 0 }));
await probe(() => history({ start: -1 }));
await probe(() => history({ start: "1.2.x" }));
await probe(() => history({ role: "root" }));
await probe(() => history({ tool: 5 }));
await probe(() => history({ tool: Array(33).fill("bash") }));
await probe(() => history({ tool: "x".repeat(257) }));
await probe(() => history({ row: 7 }));
await probe(() => history({ row: "r".repeat(513) }));
await probe(() => history({ row: "m1:0", offset: -3 }));
await probe(() => history("all"));
''');
      expect(out, hasLength(12));
      for (final o in out.take(4)) {
        expect(o, startsWith('ERR history({ start, limit, role, tool })'));
      }
      expect(
        out[4],
        'ERR history role must be person, agent, tool, system '
        'or compaction.',
      );
      for (final o in out.skip(5).take(6)) {
        expect(o, startsWith('ERR history('));
      }
      expect(
        out[11],
        startsWith(
          'ERR history({ start, limit, role, tool }) '
          'options must be an object',
        ),
      );
      expect(transcripts.asked, isEmpty);
    });
  });

  group('outputs and loadOutput', () {
    late List<String> handles;
    late String foreign;

    setUp(() async {
      handles = [
        for (var i = 0; i < 3; i++)
          (await outputs.put(
            ToolOutputWrite(
              scope: scope,
              toolName: i == 1 ? 'grep' : 'bash',
              content: 'output $i ${'q' * 20000}',
            ),
          ))!.handle,
      ];
      foreign = (await outputs.put(
        const ToolOutputWrite(
          scope: ToolOutputScope(
            workspaceId: 'ws-1',
            conversationId: 'conv-2',
            agentId: 'agent-1',
          ),
          toolName: 'bash',
          content: 'SECRET OF ANOTHER CONVERSATION',
        ),
      ))!.handle;
    });

    test('lists the run scope newest first and reads a page at a time; '
        "another scope's handle is not found", () async {
      final out = await probe('''
await probe(() => outputs());
await probe(() => outputs({ tool: "bash", limit: 1 }));
await probe(() => loadOutput("${handles.first}"));
await probe(() => loadOutput("${handles.first}", { offset: 16384, limit: 100 }));
await probe(() => loadOutput("$foreign"));
await probe(() => loadOutput("../../etc/passwd"));
await probe(() => loadOutput("${handles.first}", { limit: 16385 }));
await probe(() => outputs({ limit: 0 }));
''');
      final all = out[0]! as Map;
      expect(all['total'], 3);
      expect(
        [for (final e in _maps(all['outputs'])) e['handle']],
        [...handles.reversed],
      );
      expect(((all['outputs'] as List).first as Map)['chars'], 20009);
      final bash = out[1]! as Map;
      expect(bash['total'], 2);
      expect(bash['outputs'], hasLength(1));
      final page = out[2]! as Map;
      expect(
        (page['text'] as String).length,
        CodeModeLimits.maxLoadOutputChars,
      );
      expect(page['next_offset'], CodeModeLimits.maxLoadOutputChars);
      expect(page['total_chars'], 20009);
      final second = out[3]! as Map;
      expect((second['text'] as String).length, 100);
      expect(out[4], 'ERR No stored output "$foreign" that this run can read.');
      expect(out[5], startsWith('ERR loadOutput(handle, { offset, limit })'));
      expect(out[6], startsWith('ERR loadOutput(handle, { offset, limit })'));
      expect(out[7], startsWith('ERR outputs({ limit, tool })'));
    });

    test('a subagent lists and reads only what its own run stored', () async {
      final ledger = RunOutputLedger();
      final own =
          (await ledger
                  .over(outputs)!
                  .put(
                    const ToolOutputWrite(
                      scope: scope,
                      toolName: 'bash',
                      content: 'CHILD OUTPUT',
                    ),
                  ))!
              .handle;
      final out = await probe(
        '''
await probe(() => outputs());
await probe(() => loadOutput("$own"));
await probe(() => loadOutput("${handles.first}"));
''',
        past: sources.forSubagent(
          workspaceId: 'ws-1',
          runId: 'child-1',
          conversationId: 'conv-1',
          spaceId: 'space-1',
          store: outputs,
          scope: scope,
          ledger: ledger,
        ),
      );
      expect(
        [for (final e in _maps((out[0]! as Map)['outputs'])) e['handle']],
        [own],
      );
      expect((out[1]! as Map)['text'], 'CHILD OUTPUT');
      expect(out[2], startsWith('ERR No stored output'));
    });

    test('a script makes at most maxPastReads reads', () async {
      const max = CodeModeLimits.maxPastReads;
      final out = await probe('''
for (let i = 0; i < ${max + 3}; i++) await probe(() => outputs({ limit: 1 }));
''');
      expect(out.take(max).every((o) => o is Map), isTrue);
      for (final refused in out.skip(max)) {
        expect(refused, contains('reads of the run\'s past'));
      }
    });

    test('what a script reads is bounded per script, and per run across '
        'its scripts', () async {
      transcripts.conversations['ws-1/conv-1'] = [
        for (var i = 0; i < 4; i++)
          _row('big$i:0', TranscriptRole.agent, 'b' * 16000),
      ];
      // 64 KB a call: the 4 MiB of one script end within 70 calls.
      final out = await probe('''
for (let i = 0; i < 70; i++) await probe(() => history().then((p) => p.message_count));
''');
      final refusedAt = out.indexWhere((o) => o is String);
      expect(refusedAt, inInclusiveRange(60, 66), reason: '$out');
      expect(out[refusedAt], contains('This script has read 4 MiB'));
      // The run's total: a run near its 16 MiB is refused its next read.
      final past = mainPast();
      past.usage.readBytes = CodeModeLimits.maxPastReadBytesPerRun - 100;
      final near = await probe('await probe(() => history());', past: past);
      expect(near.single, contains("This run's scripts have read 16 MiB"));
    });

    test('a workspace whose lookup bucket is empty is refused', () async {
      final buckets = WorkspaceLookupBuckets()..charge('ws-1', 60 * 1000000);
      final drained = CodeExecutionService(
        sandbox: process,
        executions: MemoryExecutions(),
        store: store,
        serverProcessCap: 2,
        lookupBuckets: buckets,
      );
      final out = await probe('await probe(() => outputs());', on: drained);
      expect(out.single, contains('The lookup budget of this workspace'));
      await drained.dispose();
    });
  });

  group('keep', () {
    test('is readable at once, saved when the script completes and listed '
        'with its label for later scripts', () async {
      final past = mainPast();
      final out = await probe('''
const k = await keep({ rows: [1, 2, 3] }, "parsed rows");
out.push(k);
await probe(() => loadOutput(k.handle));
await probe(() => keep("plain text", "a note"));
''', past: past);
      final kept = out[0]! as Map;
      expect(kept['label'], 'parsed rows');
      expect((out[1]! as Map)['text'], '{"rows":[1,2,3]}');
      final listed = await outputs.list(scope);
      expect([for (final e in listed) e.label], ['a note', 'parsed rows']);
      expect(listed.every((e) => e.toolName == 'keep'), isTrue);
      expect(past.usage.keeps, 2);
      final later = await probe('''
const list = await outputs({ tool: "keep" });
out.push(list.outputs.map((e) => e.label));
await probe(() => loadOutput("${kept['handle']}").then((p) => JSON.parse(p.text).rows));
''', past: past);
      expect(later[0], ['a note', 'parsed rows']);
      expect(later[1], [1, 2, 3]);
    });

    test('a script that does not complete saves nothing it kept', () async {
      final r = await execute(
        'await keep({ a: 1 }, "draft"); throw new Error("stop");',
      );
      expect(r.execution.status, CodeExecutionStatus.failed);
      expect(await outputs.list(scope), isEmpty);
      expect(
        r.result.text,
        contains(
          'The 1 value passed to keep() were not saved, because the '
          'script did not complete',
        ),
      );
    });

    test('a run keeps at most maxKeepsPerRun values', () async {
      const max = CodeModeLimits.maxKeepsPerRun;
      final out = await probe('''
for (let i = 0; i < ${max + 2}; i++) await probe(() => keep(i, "k" + i).then(() => "ok"));
''');
      expect(out.take(max).toSet(), {'ok'});
      for (final refused in out.skip(max)) {
        expect(refused, contains('may keep $max values'));
      }
      expect(await outputs.list(scope), hasLength(max));
    });

    test('labels and values are checked', () async {
      final out = await probe('''
await probe(() => keep(1, ""));
await probe(() => keep(1, "two\\nlines"));
await probe(() => keep(1, "l".repeat(201)));
await probe(() => keep(undefined, "nothing"));
await probe(() => keep(1, 2));
''');
      for (final o in out.take(3)) {
        expect(o, startsWith('ERR keep() needs a label of 1 to 200'));
      }
      expect(
        out[3],
        'ERR keep(value, label) needs a JSON value and a string '
        'label.',
      );
      expect(out[4], 'ERR keep(value, label) needs a string label');
      expect(await outputs.list(scope), isEmpty);
    });
  });

  test('a run with no output store refuses keep() before handing out a '
      'handle', () async {
    final out = await probe(
      'await probe(() => keep(1, "x"));',
      past: sources.forRun(
        workspaceId: 'ws-1',
        conversationId: 'conv-1',
        spaceId: 'space-1',
        store: null,
        scope: null,
      ),
    );
    expect(out.single, 'ERR ${RunScriptPast.noOutputStore}');
  });

  group('a read-only run', () {
    setUp(() {
      store.values['conv-1|agent-1'] = {'plan': '{"step":2}'};
    });

    test('reads what earlier runs stored; store and keep are refused and '
        'nothing is saved', () async {
      final r = await execute(
        '$_probe'
        'await probe(() => storedKeys());\n'
        'await probe(() => load("plan"));\n'
        'try { store("plan", 3); out.push("stored"); } catch (e) { out.push(e.name); }\n'
        'await probe(() => keep(1, "x"));\n'
        'text("OUT" + JSON.stringify(out) + "END");',
        readOnly: true,
      );
      expect(r.execution.status, CodeExecutionStatus.completed);
      final out =
          jsonDecode(RegExp('OUT(.*)END').firstMatch(r.result.text)!.group(1)!)
              as List;
      expect(out[0], [
        {'key': 'plan', 'bytes': 10},
      ]);
      expect(out[1], {'step': 2});
      expect(out[2], 'RangeError');
      expect(out[3], 'ERR ${ScriptPastCalls.readOnlyKeep}');
      expect(r.result.text, contains(ScriptPastCalls.readOnlyStore));
      expect(store.commits, 0);
      expect(store.values['conv-1|agent-1'], {'plan': '{"step":2}'});
      expect(await outputs.list(scope), isEmpty);
    });
  });

  test('storedKeys lists the snapshot and this script\'s writes', () async {
    store.values['conv-1|agent-1'] = {'b': '"two"', 'a': '1'};
    final out = await probe('''
out.push(storedKeys());
store("c", { long: "é" });
store("a", undefined);
out.push(storedKeys());
''');
    expect(out[0], [
      {'key': 'a', 'bytes': 1},
      {'key': 'b', 'bytes': 5},
    ]);
    expect(out[1], [
      {'key': 'b', 'bytes': 5},
      {'key': 'c', 'bytes': 13},
    ]);
  });

  test('without a past (an evaluation run) the calls say why; storedKeys '
      'still answers', () async {
    final out = await probe('''
await probe(() => history());
await probe(() => outputs());
await probe(() => loadOutput("out_abcdefgh"));
await probe(() => keep(1, "x"));
out.push(storedKeys());
''', noPast: true);
    for (final o in out.take(4)) {
      expect(o, 'ERR ${ScriptPastCalls.unavailable}');
    }
    expect(out[4], isEmpty);
  });

  group('on the MCP endpoint (Claude Code, ACP)', () {
    // ReplMcpTool binds the port from the attested scope with forMcpRun
    // (repl_tool_test.dart pins that binding); these run its scripts.
    ScriptPastPort mcpPast({String? conversationId = 'conv-1'}) =>
        sources.forMcpRun(
          workspaceId: 'ws-1',
          conversationId: conversationId,
          spaceId: 'space-1',
        );

    setUp(() {
      transcripts.conversations['ws-1/conv-1'] = [
        _row('m0:0', TranscriptRole.person, 'MINE'),
        _row('m1:0', TranscriptRole.agent, 'ALSO MINE'),
      ];
      transcripts.fullTexts['m1:0'] = 'ALSO MINE';
      transcripts.conversations['ws-1/conv-2'] = [
        _row('x:0', TranscriptRole.person, 'ANOTHER CONVERSATION'),
      ];
      transcripts.fullTexts['x:0'] = 'ANOTHER CONVERSATION';
      transcripts.conversations['ws-2/conv-1'] = [
        _row('y:0', TranscriptRole.person, 'ANOTHER WORKSPACE'),
      ];
      transcripts.runs['ws-1/run-1'] = [
        _row('r:0', TranscriptRole.agent, 'A RUN TRANSCRIPT'),
      ];
    });

    test("history reads the scope's conversation; arguments naming another "
        'conversation or workspace change nothing', () async {
      final out = await probe('''
await probe(() => history());
await probe(() => history({ conversation_id: "conv-2", workspace_id: "ws-2", run_id: "run-1", space_id: "s" }));
await probe(() => history({ row: "x:0" }));
await probe(() => history({ row: "m1:0" }));
''', past: mcpPast());
      for (final o in out.take(2)) {
        final page = o! as Map;
        expect(
          [for (final r in _maps(page['rows'])) r['text']],
          ['MINE', 'ALSO MINE'],
        );
        expect(page['message_count'], 2);
      }
      expect(out[2], startsWith('ERR '));
      expect((out[3]! as Map)['text'], 'ALSO MINE');
      expect(jsonEncode(out), isNot(contains('ANOTHER')));
      expect(jsonEncode(out), isNot(contains('A RUN TRANSCRIPT')));
      expect(transcripts.asked.toSet(), {
        'page ws-1/conv-1',
        'slice ws-1/conv-1',
      });
    });

    test('a run keeps one port across its scripts, so its per-run bound '
        'holds there too', () async {
      final pasts = McpRunScriptPasts(sources);
      ScriptPastPort port() => pasts.forRun(
        runLogId: 'log-1',
        workspaceId: 'ws-1',
        conversationId: 'conv-1',
        spaceId: 'space-1',
      );
      await probe('await probe(() => history());', past: port());
      final run = port() as RunScriptPast;
      final afterOne = run.usage.readBytes;
      expect(afterOne, greaterThan(0));
      await probe('await probe(() => history());', past: port());
      expect(run.usage.readBytes, 2 * afterOne);
      run.usage.readBytes = CodeModeLimits.maxPastReadBytesPerRun - 10;
      final near = await probe('await probe(() => history());', past: port());
      expect(near.single, contains("This run's scripts have read 16 MiB"));
      pasts.drop('log-1');
      expect(port(), isNot(same(run)));
      expect(pasts.length, 1);
    });

    test('a run without a conversation of its own reads none', () async {
      final out = await probe(
        'await probe(() => history());',
        past: mcpPast(conversationId: null),
      );
      expect(
        out.single,
        'ERR This run has no conversation, so history() has no transcript '
        'to read.',
      );
      expect(transcripts.asked, isEmpty);
    });

    test("a space the run's person cannot read is refused", () async {
      hidden = {'space-1'};
      final out = await probe('await probe(() => history());', past: mcpPast());
      expect(out.single, 'ERR ${RunScriptPast.hiddenSpace}');
      expect(transcripts.asked, isEmpty);
    });

    test('outputs, loadOutput and keep say why (no output store there) and '
        'what to use instead', () async {
      final out = await probe('''
await probe(() => outputs());
await probe(() => loadOutput("${newToolOutputHandle()}"));
await probe(() => keep({ a: 1 }, "x"));
''', past: mcpPast());
      expect(out, hasLength(3));
      for (final o in out) {
        expect(o, 'ERR ${RunScriptPast.noOutputStoreMcp}');
      }
      expect(RunScriptPast.noOutputStoreMcp, contains('store()'));
      expect(RunScriptPast.noOutputStoreMcp, contains('history()'));
      expect(await outputs.list(scope), isEmpty);
    });

    test(
      'a read-only run reads history; keep is refused as read-only',
      () async {
        final out = await probe(
          '''
await probe(() => history());
await probe(() => keep(1, "x"));
''',
          past: mcpPast(),
          readOnly: true,
        );
        expect((out[0]! as Map)['message_count'], 2);
        expect(out[1], 'ERR ${ScriptPastCalls.readOnlyKeep}');
      },
    );

    test('history is charged to the lookup bucket', () async {
      final buckets = WorkspaceLookupBuckets()..charge('ws-1', 60 * 1000000);
      final drained = CodeExecutionService(
        sandbox: process,
        executions: MemoryExecutions(),
        store: store,
        serverProcessCap: 2,
        lookupBuckets: buckets,
      );
      final out = await probe(
        'await probe(() => history());',
        past: mcpPast(),
        on: drained,
      );
      expect(out.single, contains('The lookup budget of this workspace'));
      expect(transcripts.asked, isEmpty);
      await drained.dispose();
    });
  });

  group('limits().returnBudgetChars', () {
    test('is the longest output the result keeps whole', () async {
      final limits = CodeModeLimits();
      final budget = const ScriptResultFormatter().returnBudgetChars(
        limits.maxOutputTokens,
      );
      final r = await execute('return limits().returnBudgetChars;');
      expect(r.result.text.split('\n').last, '$budget');
      final whole = await execute('text("x".repeat($budget));');
      expect(whole.result.truncated, isFalse);
      expect(whole.result.text, contains('x' * budget));
      final over = await execute('text("x".repeat(${budget + 1}));');
      expect(over.result.truncated, isTrue);
    });

    test('follows the max_output_tokens the call asked for', () async {
      final limits = CodeModeLimits(maxOutputTokens: 2000);
      final r = await execute(
        'return limits().returnBudgetChars;',
        limits: limits,
      );
      expect(r.result.text.split('\n').last, '${(2000 * 3.8).floor()}');
    });
  });

  group('a limit names its fix', () {
    test('the wall clock', () async {
      final r = await execute(
        'await sleep(60000);',
        limits: CodeModeLimits(wallClockMs: 1000),
      );
      expect(r.execution.status, CodeExecutionStatus.timedOut);
      expect(r.result.text, contains(ScriptFixHints.timeout(stores: true)));
    });

    test('the CPU budget', () async {
      final r = await execute(
        'for (;;) {}',
        limits: CodeModeLimits(cpuMs: 1000),
      );
      expect(r.execution.status, CodeExecutionStatus.timedOut);
      expect(r.result.text, contains(ScriptFixHints.timeout(stores: true)));
    });

    test('the call limit', () async {
      final r = await execute(
        '$_probe'
        'for (let i = 0; i < 3; i++) await probe(() => tools.read({}));\n'
        'return out[2];',
        limits: CodeModeLimits(maxNestedCalls: 2),
      );
      expect(
        r.result.text,
        contains(ScriptFixHints.callLimit(2, stores: true)),
      );
    });

    test('the interpreter output cap', () async {
      final r = await execute(
        'const s = "y".repeat(1 << 20); for (;;) text(s);',
      );
      expect(r.execution.status, CodeExecutionStatus.outputExceeded);
      expect(r.result.text, contains(ScriptFixHints.output(keeps: true)));
    });

    test('a read-only run is not told to store or keep', () async {
      final r = await execute(
        'const s = "y".repeat(1 << 20); for (;;) text(s);',
        readOnly: true,
      );
      expect(r.result.text, contains(ScriptFixHints.output(keeps: false)));
      final calls = await execute(
        '$_probe'
        'for (let i = 0; i < 3; i++) await probe(() => tools.read({}));\n'
        'return out[2];',
        limits: CodeModeLimits(maxNestedCalls: 2),
        readOnly: true,
      );
      expect(
        calls.result.text,
        contains(ScriptFixHints.callLimit(2, stores: false)),
      );
    });

    test('a run with no output store is not told to keep', () async {
      final r = await execute(
        'const s = "y".repeat(1 << 20); for (;;) text(s);',
        past: sources.forMcpRun(
          workspaceId: 'ws-1',
          conversationId: 'conv-1',
          spaceId: 'space-1',
        ),
      );
      expect(r.result.text, contains(ScriptFixHints.output(keeps: false)));
    });
  });
}

List<Map<String, Object?>> _maps(Object? list) =>
    (list! as List).cast<Map<String, Object?>>();
