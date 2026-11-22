import 'dart:convert';

import 'package:cc_domain/core/domain/value_objects/script_call_origin.dart';
import 'package:cc_domain/features/code_mode/domain/entities/code_execution.dart';
import 'package:cc_domain/features/code_mode/domain/entities/code_execution_call.dart';
import 'package:cc_domain/features/code_mode/domain/services/json_weight.dart';
import 'package:cc_domain/features/code_mode/domain/value_objects/code_execution_status.dart';
import 'package:cc_domain/features/code_mode/domain/value_objects/code_mode_limits.dart';
import 'package:cc_domain/features/code_mode/domain/value_objects/code_mode_store_write.dart';
import 'package:cc_domain/features/code_mode/domain/value_objects/script_call_site.dart';
import 'package:cc_domain/features/code_mode/domain/value_objects/script_outcome.dart';
import 'package:cc_domain/features/code_mode/domain/value_objects/script_tool_descriptor.dart';
import 'package:cc_domain/src/errors/app_exceptions.dart';
import 'package:cc_harness/tools.dart';
import 'package:test/test.dart';

final _hash = 'a' * 64;

CodeExecutionCall _call({
  int sequence = 1,
  NestedCallStatus status = NestedCallStatus.completed,
  ScriptCallSite? site,
}) => CodeExecutionCall(
  executionId: 'exec-1',
  sequence: sequence,
  toolCallId: CodeExecutionCall.nestedToolCallId('call-9', sequence),
  toolName: 'search',
  startOffsetMs: 10,
  durationMs: 40,
  status: status,
  gateDecision: NestedCallGateDecision.allowed,
  approvalWaitMs: 5,
  argumentBytes: 20,
  resultBytes: 400,
  argumentsJson: '{"pattern":"x"}',
  error: status == NestedCallStatus.completed ? null : 'boom',
  site: site,
);

void main() {
  group('status vocabularies', () {
    test('execution status wire names are the CHECK values', () {
      expect(CodeExecutionStatus.wireNames, [
        'running',
        'completed',
        'failed',
        'timed_out',
        'cancelled',
        'memory_exceeded',
        'output_exceeded',
        'sandbox_error',
        'refused',
      ]);
      for (final s in CodeExecutionStatus.values) {
        expect(CodeExecutionStatus.parse(s.wire), s);
      }
      expect(CodeExecutionStatus.tryParse('ok'), isNull);
      expect(() => CodeExecutionStatus.parse('ok'), throwsArgumentError);
      expect(CodeExecutionStatus.completed.isError, isFalse);
      expect(CodeExecutionStatus.refused.isError, isTrue);
      expect(CodeExecutionStatus.running.isTerminal, isFalse);
      expect(
        [
          for (final s in CodeExecutionStatus.values)
            if (!s.isTerminal) s,
        ],
        [CodeExecutionStatus.running],
      );
    });

    test('nested call status wire names and labels', () {
      expect(NestedCallStatus.wireNames, [
        'completed',
        'failed',
        'denied',
        'cancelled',
        'timed_out',
        'unknown_tool',
        'invalid_args',
      ]);
      expect(NestedCallStatus.completed.label, 'ok');
      expect(NestedCallStatus.unknownTool.label, 'failed');
      expect(NestedCallStatus.timedOut.label, 'timed out');
      expect(NestedCallStatus.completed.resolves, isTrue);
      expect(NestedCallStatus.denied.resolves, isFalse);
    });

    test('surface and gate decision wire names', () {
      expect(CodeExecutionSurface.wireNames, ['harness', 'mcp']);
      expect(CodeExecutionSurface.parse('mcp'), CodeExecutionSurface.mcp);
      expect(NestedCallGateDecision.wireNames, [
        'allowed',
        'approved',
        'denied',
      ]);
      expect(
        NestedCallGateDecision.tryParse('approved'),
        NestedCallGateDecision.approved,
      );
    });
  });

  group('ScriptCallOrigin', () {
    test('round-trips through JSON', () {
      final o = ScriptCallOrigin(parentToolCallId: 'call-1', executionId: 'e');
      expect(o.toJson(), {
        'parent_tool_call_id': 'call-1',
        'execution_id': 'e',
      });
      expect(ScriptCallOrigin.fromJson(o.toJson()), o);
      expect(ScriptCallOrigin.fromJson(o.toJson()).hashCode, o.hashCode);
    });

    test('names no execution for a call with no record (an eval cell)', () {
      final o = ScriptCallOrigin(parentToolCallId: 'call_eval');
      expect(o.executionId, isNull);
      expect(o.toJson(), {'parent_tool_call_id': 'call_eval'});
      expect(ScriptCallOrigin.fromJson(o.toJson()), o);
    });

    test('is tolerant of malformed JSON and strict on construction', () {
      expect(ScriptCallOrigin.fromJson(null), isNull);
      expect(ScriptCallOrigin.fromJson(const {'execution_id': 'e'}), isNull);
      expect(
        ScriptCallOrigin.fromJson(const {'parent_tool_call_id': ''}),
        isNull,
      );
      // A bad execution id is dropped: the card still says a script asked.
      for (final bad in [null, '', 7]) {
        expect(
          ScriptCallOrigin.fromJson({
            'parent_tool_call_id': 'x',
            'execution_id': bad,
          }),
          ScriptCallOrigin(parentToolCallId: 'x'),
        );
      }
      expect(
        () => ScriptCallOrigin(parentToolCallId: '', executionId: 'e'),
        throwsArgumentError,
      );
      expect(
        () => ScriptCallOrigin(parentToolCallId: 'x', executionId: ''),
        throwsArgumentError,
      );
    });
  });

  group('ScriptToolDescriptor', () {
    test('round-trips through JSON', () {
      final d = ScriptToolDescriptor(
        name: 'push',
        namespace: ScriptToolNamespace.controlCenter,
        description: 'Push a branch.',
        inputSchema: const {
          'type': 'object',
          'properties': {
            'branch': {'type': 'string'},
          },
        },
        outputSchema: const {'type': 'object'},
        resultNote: 'Text: the pushed ref.',
        tier: ToolApprovalTier.write,
        effects: const {ActionClass.processSpawn, ActionClass.gitPush},
      );
      final json = d.toJson();
      expect(json['result_note'], 'Text: the pushed ref.');
      expect(json['effects'], ['gitPush', 'processSpawn']);
      expect(json['tier'], 'write');
      final back = ScriptToolDescriptor.fromJson(json);
      expect(back, d);
      expect(back.hashCode, d.hashCode);
      expect(d.isExternal, isFalse);
    });

    test('external namespaces are anything not first-party', () {
      expect(ScriptToolNamespace.isExternal('builtin'), isFalse);
      expect(ScriptToolNamespace.isExternal('control-center'), isFalse);
      expect(ScriptToolNamespace.isExternal('github'), isTrue);
    });

    test('refuses an empty name and malformed JSON', () {
      expect(
        () => ScriptToolDescriptor(
          name: '',
          namespace: 'builtin',
          description: '',
          inputSchema: const {},
        ),
        throwsArgumentError,
      );
      expect(
        () => ScriptToolDescriptor.fromJson(const {'name': 'x'}),
        throwsFormatException,
      );
      final good = ScriptToolDescriptor(
        name: 'x',
        namespace: 'builtin',
        description: '',
        inputSchema: const {'type': 'object'},
      ).toJson();
      expect(
        () => ScriptToolDescriptor.fromJson({...good, 'tier': 'root'}),
        throwsFormatException,
      );
      expect(
        () => ScriptToolDescriptor.fromJson({
          ...good,
          'effects': ['teleport'],
        }),
        throwsFormatException,
      );
    });
  });

  group('CodeExecutionCall', () {
    test('round-trips through JSON with equality', () {
      final c = _call(status: NestedCallStatus.denied);
      final back = CodeExecutionCall.fromJson(c.toJson());
      expect(back, c);
      expect(back.hashCode, c.hashCode);
      expect(c.toolCallId, 'call-9/1');
    });

    test('carries its call site as [line, column], absent when none', () {
      final at = _call(site: ScriptCallSite(3, 14));
      expect(at.toJson()['site'], [3, 14]);
      final back = CodeExecutionCall.fromJson(at.toJson());
      expect(back, at);
      expect(back.hashCode, at.hashCode);
      expect(back.site, ScriptCallSite(3, 14));

      final none = _call();
      expect(none.toJson().containsKey('site'), isFalse);
      expect(none, isNot(at));
      expect(CodeExecutionCall.fromJson(none.toJson()).site, isNull);
    });

    test('a malformed site on the wire is dropped, the call kept', () {
      for (final raw in <Object?>[
        [0, 1],
        [1, 2, 3],
        {'line': 1},
        [1, '2'],
      ]) {
        final json = _call().toJson()..['site'] = raw;
        expect(CodeExecutionCall.fromJson(json), _call(), reason: '$raw');
      }
    });

    test('validates', () {
      expect(() => _call(sequence: 0), throwsArgumentError);
      expect(
        () => CodeExecutionCall(
          executionId: 'e',
          sequence: 1,
          toolCallId: 't',
          toolName: 'x',
          startOffsetMs: 0,
          durationMs: 0,
          status: NestedCallStatus.failed,
          error: 'x' * 501,
        ),
        throwsArgumentError,
      );
      expect(
        () => CodeExecutionCall(
          executionId: 'e',
          sequence: 1,
          toolCallId: 't',
          toolName: 'x',
          startOffsetMs: 0,
          durationMs: 0,
          status: NestedCallStatus.completed,
          argumentsJson: 'x' * 8193,
        ),
        throwsArgumentError,
      );
      expect(
        () => CodeExecutionCall.nestedToolCallId('', 1),
        throwsArgumentError,
      );
    });

    test('bounding helpers fit the caps', () {
      final args = CodeExecutionCall.boundArguments('é' * 9000);
      expect(args.length, lessThan(9000));
      expect(args, endsWith('bytes, truncated]'));
      CodeExecutionCall(
        executionId: 'e',
        sequence: 1,
        toolCallId: 't',
        toolName: 'x',
        startOffsetMs: 0,
        durationMs: 0,
        status: NestedCallStatus.completed,
        argumentsJson: args,
      );
      expect(CodeExecutionCall.boundArguments('{}'), '{}');
      final error = CodeExecutionCall.boundError('😀' * 400);
      expect(error.length, lessThanOrEqualTo(500));
      expect(error, endsWith('…'));
      // No lone surrogate at the cut.
      expect(
        error.codeUnitAt(error.length - 2),
        isNot(inInclusiveRange(0xD800, 0xDBFF)),
      );
    });
  });

  group('CodeExecution', () {
    CodeExecution build({String? hash, int questions = 0}) => CodeExecution(
      id: 'exec-1',
      runId: 'run-1',
      toolCallId: 'call-9',
      surface: CodeExecutionSurface.harness,
      startedAt: DateTime.utc(2026, 11, 17, 9),
      durationMs: 2400,
      status: CodeExecutionStatus.failed,
      sourceHash: hash ?? _hash,
      sourceBytes: 120,
      limits: CodeModeLimits(wallClockMs: 60000),
      conversationId: 'conv-1',
      agentId: 'agent-1',
      spaceId: 'space-1',
      description: 'Find the failing tests',
      errorKind: CodeExecutionErrorKind.scriptError,
      cpuMs: 300,
      peakHeapBytes: 4096,
      callCounts: NestedCallCounts.of([
        _call(),
        _call(sequence: 2, status: NestedCallStatus.failed),
      ]),
      questionCount: questions,
      outputBytes: 900,
      outputTruncated: true,
      engineVersion: 'quickjs-ng 0.10.1',
      lockdown: const {'level': 'full', 'os': 'macos'},
    );

    test('round-trips through JSON with equality', () {
      final e = build();
      final back = CodeExecution.fromJson(e.toJson());
      expect(back, e);
      expect(back.hashCode, e.hashCode);
      expect(e.callCounts.total, 2);
      expect(e.callCounts.of(NestedCallStatus.failed), 1);
      expect(e.toJson()['call_counts'], {
        'completed': 1,
        'failed': 1,
        'denied': 0,
        'cancelled': 0,
        'timed_out': 0,
        'unknown_tool': 0,
        'invalid_args': 0,
      });
    });

    test('stores time in UTC', () {
      final e = CodeExecution(
        id: 'x',
        runId: 'r',
        toolCallId: 't',
        surface: CodeExecutionSurface.mcp,
        startedAt: DateTime(2026),
        durationMs: 0,
        status: CodeExecutionStatus.refused,
        sourceHash: _hash,
        sourceBytes: 0,
        limits: CodeModeLimits.defaults,
        errorKind: CodeExecutionErrorKind.runBusy,
      );
      expect(e.startedAt.isUtc, isTrue);
    });

    test('validates', () {
      expect(() => build(hash: 'ABC'), throwsArgumentError);
      // The kind is the host's fixed vocabulary, never a script's name.
      expect(
        () => CodeExecution(
          id: 'x',
          runId: 'r',
          toolCallId: 't',
          surface: CodeExecutionSurface.mcp,
          startedAt: DateTime.utc(2026),
          durationMs: 0,
          status: CodeExecutionStatus.failed,
          sourceHash: _hash,
          sourceBytes: 0,
          limits: CodeModeLimits.defaults,
          errorKind: 'TypeError',
        ),
        throwsArgumentError,
      );
      // A description is one line of at most 200 characters.
      expect(
        CodeExecution.boundDescription('a\nb${'c' * 400}'),
        allOf(isNot(contains('\n')), hasLength(lessThanOrEqualTo(200))),
      );
      expect(() => build(questions: 11), throwsArgumentError);
      expect(() => NestedCallCounts(failed: -1), throwsArgumentError);
    });
  });

  group('CodeExecutionPayload', () {
    test('round-trips and bounds its fields', () {
      final p = CodeExecutionPayload.bounded(
        executionId: 'e',
        source: 'return 1',
        output: 'x' * (300 * 1024),
        console: '[log] hi',
      );
      expect(p.output.length, lessThan(300 * 1024));
      expect(CodeExecutionPayload.fromJson(p.toJson()), p);
      expect(
        () => CodeExecutionPayload(
          executionId: 'e',
          source: '',
          console: 'x' * (65 * 1024),
        ),
        throwsArgumentError,
      );
    });
  });

  group('ScriptOutputItem', () {
    test('round-trips every kind', () {
      final items = <ScriptOutputItem>[
        const ScriptTextOutput('hi'),
        const ScriptConsoleOutput(level: ScriptConsoleLevel.warn, text: 'w'),
        const ScriptImageOutput(mediaType: 'image/png', data: 'AAAA'),
      ];
      for (final i in items) {
        expect(ScriptOutputItem.fromJson(i.toJson()), i);
      }
      expect(
        () => ScriptOutputItem.fromJson(const {'kind': 'video'}),
        throwsFormatException,
      );
    });

    test('value renders strings raw and everything else as JSON', () {
      expect(ScriptOutputItem.value('plain'), const ScriptTextOutput('plain'));
      expect(
        ScriptOutputItem.value({'a': 1}),
        const ScriptTextOutput('{\n  "a": 1\n}'),
      );
      expect(ScriptOutputItem.value(null), const ScriptTextOutput('null'));
    });
  });

  group('ScriptQuestionRecord', () {
    test('reads a structured answer', () {
      final q = ScriptQuestionRecord.fromNestedCall(
        arguments: {
          'question': ' Which database? ',
          'options': [
            {'label': 'Postgres'},
            {'label': 'SQLite'},
          ],
        },
        status: NestedCallStatus.completed,
        value: {
          'selected': ['Postgres'],
          'text': 'The managed one.',
          'skipped': false,
        },
      );
      expect(q.question, 'Which database?');
      expect(q.options, ['Postgres', 'SQLite']);
      expect(q.selected, ['Postgres']);
      expect(q.text, 'The managed one.');
      expect(q.answered, isTrue);
      expect(ScriptQuestionRecord.fromJson(q.toJson()), q);
    });

    test('a call that did not complete is unanswered', () {
      final q = ScriptQuestionRecord.fromNestedCall(
        arguments: const {'question': 'Ship?'},
        status: NestedCallStatus.timedOut,
      );
      expect(q.answered, isFalse);
      expect(ScriptQuestionRecord.fromJson(q.toJson()).answered, isFalse);
    });

    test('an answer that arrives as JSON text is read decoded', () {
      final q = ScriptQuestionRecord.fromNestedCall(
        arguments: const {'question': 'Ship?'},
        status: NestedCallStatus.completed,
        value: scriptResultOfText(
          '{"selected": ["Yes"], "text": "", "skipped": false}',
        ),
      );
      expect(q.answered, isTrue);
      expect(q.selected, ['Yes']);
    });

    test('a plain string answer is typed text', () {
      final q = ScriptQuestionRecord.fromNestedCall(
        arguments: const {'question': 'Name?'},
        status: NestedCallStatus.completed,
        value: 'Ada',
      );
      expect(q.text, 'Ada');
    });

    test('keeps a bounded part of what the script and the answer chose', () {
      final long = 'é' * 100000;
      int bytes(String s) => utf8.encode(s).length;
      final q = ScriptQuestionRecord.fromNestedCall(
        arguments: {
          'question': long,
          'options': [
            for (var i = 0; i < 1000; i++) {'label': '$i$long'},
          ],
        },
        status: NestedCallStatus.completed,
        value: {
          'selected': [for (var i = 0; i < 1000; i++) long],
          'text': long,
        },
      );
      expect(
        bytes(q.question),
        lessThanOrEqualTo(ScriptQuestionRecord.maxTextBytes),
      );
      expect(
        bytes(q.text!),
        lessThanOrEqualTo(ScriptQuestionRecord.maxTextBytes),
      );
      expect(q.options, hasLength(ScriptQuestionRecord.maxOptions));
      expect(q.selected, hasLength(ScriptQuestionRecord.maxOptions));
      for (final o in [...q.options, ...q.selected]) {
        expect(
          bytes(o),
          lessThanOrEqualTo(ScriptQuestionRecord.maxOptionBytes),
        );
      }
      expect(q.options.first, startsWith('0é'));
      expect(
        ScriptQuestionRecord.fromNestedCall(
          arguments: {'question': long},
          status: NestedCallStatus.completed,
          value: long,
        ).text,
        hasLength(ScriptQuestionRecord.maxTextBytes ~/ 2),
      );
    });
  });

  group('CodeModeStoreRules', () {
    test('applies writes in order and deletes', () {
      final next = CodeModeStoreRules.apply(
        {'a': '1', 'b': '2'},
        const [
          CodeModeStoreWrite(key: 'a', valueJson: '3'),
          CodeModeStoreWrite(key: 'b'),
          CodeModeStoreWrite(key: 'c', valueJson: '"x"'),
        ],
      );
      expect(next, {'a': '3', 'c': '"x"'});
    });

    test('refuses an empty key, an oversized value and an oversized total', () {
      expect(
        CodeModeStoreRules.checkWrite(const CodeModeStoreWrite(key: '')),
        isNotNull,
      );
      final big = '"${'x' * (256 * 1024)}"';
      expect(
        () => CodeModeStoreRules.apply(const {}, [
          CodeModeStoreWrite(key: 'k', valueJson: big),
        ]),
        throwsA(
          isA<ValidationException>().having(
            (e) => e.code,
            'code',
            'code_mode_store_limit',
          ),
        ),
      );
      final quarter = 'x' * (250 * 1024);
      final current = {for (var i = 0; i < 4; i++) 'k$i': quarter};
      expect(
        () => CodeModeStoreRules.apply(current, [
          CodeModeStoreWrite(key: 'k4', valueJson: quarter),
        ]),
        throwsA(isA<ValidationException>()),
      );
      expect(CodeModeStoreRules.totalBytes({'ab': 'é'}), 4);
    });
  });
}
