import 'package:cc_domain/core/domain/ports/agent_question_port.dart';
import 'package:cc_domain/core/domain/ports/confirmation_port.dart';
import 'package:cc_domain/core/domain/value_objects/mode.dart';
import 'package:cc_domain/core/domain/value_objects/script_call_origin.dart';
import 'package:cc_domain/core/domain/value_objects/transcript_segment.dart';
import 'package:cc_domain/features/code_mode/domain/value_objects/script_call_site.dart';
import 'package:cc_domain/features/dispatch/domain/entities/agent_process_event.dart';
import 'package:cc_domain/features/dispatch/domain/entities/agent_process_event_codec.dart';
import 'package:cc_domain/features/dispatch/domain/modes/mode_capability_profile.dart';
import 'package:cc_domain/features/dispatch/domain/prompts/capability_preamble.dart';
import 'package:cc_domain/features/mcp/domain/value_objects/mode_tool_policy.dart';
import 'package:test/test.dart';

/// The additive code mode fields on types other features own: nested tool
/// events, nested transcript segments, the script origin on approval cards and
/// questions, the policy sets and the capability preamble.
void main() {
  group('tool events carry their parent', () {
    test('ToolCallEvent round-trips parentToolCallId through the codec', () {
      final event = ToolCallEvent(
        toolName: 'search',
        toolCallId: 'call-1/2',
        inputs: const {'pattern': 'x'},
        parentToolCallId: 'call-1',
        timestamp: DateTime.utc(2026),
      );
      final wire = AgentProcessEventCodec.toWire(event);
      expect(wire['parentToolCallId'], 'call-1');
      final back = AgentProcessEventCodec.fromWire(wire) as ToolCallEvent;
      expect(back.parentToolCallId, 'call-1');
      expect(back.toolCallId, 'call-1/2');
      expect(event.metadata['parentToolCallId'], 'call-1');
    });

    test('ToolResultEvent round-trips parentToolCallId through the codec', () {
      final event = ToolResultEvent(
        toolCallId: 'call-1/2',
        outputs: 'ok',
        toolName: 'search',
        parentToolCallId: 'call-1',
        timestamp: DateTime.utc(2026),
      );
      final wire = AgentProcessEventCodec.toWire(event);
      expect(wire['parentToolCallId'], 'call-1');
      final back = AgentProcessEventCodec.fromWire(wire) as ToolResultEvent;
      expect(back.parentToolCallId, 'call-1');
      expect(event.metadata['parentToolCallId'], 'call-1');
    });

    test('a direct call omits the key everywhere', () {
      final call = ToolCallEvent(toolName: 'read', toolCallId: 'c');
      final result = ToolResultEvent(toolCallId: 'c', outputs: '');
      expect(call.parentToolCallId, isNull);
      expect(call.metadata.containsKey('parentToolCallId'), isFalse);
      expect(result.metadata.containsKey('parentToolCallId'), isFalse);
      expect(
        AgentProcessEventCodec.toWire(call).containsKey('parentToolCallId'),
        isFalse,
      );
      expect(
        AgentProcessEventCodec.toWire(result).containsKey('parentToolCallId'),
        isFalse,
      );
    });

    test('equality still ignores metadata, the parent included', () {
      // AgentProcessEvent equality compares kind and payload only (it already
      // ignored toolCallId); the parent is metadata of the same kind.
      expect(
        ToolCallEvent(toolName: 'read', toolCallId: 'a', parentToolCallId: 'p'),
        ToolCallEvent(toolName: 'read', toolCallId: 'a'),
      );
    });
  });

  group('ToolSegment carries its parent', () {
    final started = DateTime.fromMillisecondsSinceEpoch(1000);

    test('round-trips through JSON and survives copyWith', () {
      final segment = ToolSegment(
        toolName: 'edit',
        toolCallId: 'call-1/3',
        startedAt: started,
        parentToolCallId: 'call-1',
      );
      expect(segment.toJson()['parentToolCallId'], 'call-1');
      final back = TranscriptSegment.fromJson(segment.toJson()) as ToolSegment;
      expect(back, segment);
      expect(back.hashCode, segment.hashCode);
      expect(back.isNested, isTrue);
      final copied = segment.copyWith(status: ToolSegmentStatus.ok);
      expect(copied.parentToolCallId, 'call-1');
    });

    test('the parent is part of equality and omitted when null', () {
      final direct = ToolSegment(
        toolName: 'edit',
        toolCallId: 'x',
        startedAt: started,
      );
      final nested = ToolSegment(
        toolName: 'edit',
        toolCallId: 'x',
        startedAt: started,
        parentToolCallId: 'p',
      );
      expect(direct, isNot(nested));
      expect(direct.toJson().containsKey('parentToolCallId'), isFalse);
      expect(direct.isNested, isFalse);
    });
  });

  group('ToolSegment carries its call site', () {
    final started = DateTime.fromMillisecondsSinceEpoch(1000);
    ToolSegment nested({ScriptCallSite? site}) => ToolSegment(
      toolName: 'edit',
      toolCallId: 'call-1/3',
      startedAt: started,
      parentToolCallId: 'call-1',
      callSite: site,
    );

    test('round-trips through JSON and survives copyWith', () {
      final segment = nested(site: ScriptCallSite(7, 12));
      expect(segment.toJson()['callSite'], [7, 12]);
      final back = TranscriptSegment.fromJson(segment.toJson()) as ToolSegment;
      expect(back, segment);
      expect(back.hashCode, segment.hashCode);
      expect(back.callSite, ScriptCallSite(7, 12));
      final copied = segment.copyWith(
        status: ToolSegmentStatus.ok,
        outputs: 'done',
        outcome: 'completed',
      );
      expect(copied.callSite, ScriptCallSite(7, 12));
      expect(copied.parentToolCallId, 'call-1');
    });

    test('the site is part of equality and omitted when null', () {
      final without = nested();
      final at = nested(site: ScriptCallSite(1, 1));
      expect(without, isNot(at));
      expect(at, isNot(nested(site: ScriptCallSite(1, 2))));
      expect(without.toJson().containsKey('callSite'), isFalse);
      expect(
        (TranscriptSegment.fromJson(without.toJson()) as ToolSegment).callSite,
        isNull,
      );
    });

    test('a malformed site on the wire is dropped, the segment kept', () {
      for (final raw in <Object?>[
        [0, 1],
        [1],
        'line 3',
        [2, 1.5],
      ]) {
        final json = nested().toJson()..['callSite'] = raw;
        final back = TranscriptSegment.fromJson(json) as ToolSegment;
        expect(back.callSite, isNull, reason: '$raw');
        expect(back, nested(), reason: '$raw');
      }
    });
  });

  group('script origin on cards and questions', () {
    final origin = ScriptCallOrigin(
      parentToolCallId: 'call-1',
      executionId: 'exec-1',
    );

    test('ConfirmationRequest and AgentQuestionRequest carry it', () {
      final request = ConfirmationRequest(
        spaceId: 's',
        title: 't',
        detail: 'd',
        origin: origin,
      );
      expect(request.origin, origin);
      const direct = ConfirmationRequest(spaceId: 's', title: 't', detail: 'd');
      expect(direct.origin, isNull);
      final question = AgentQuestionRequest(
        workspaceId: 'w',
        spaceId: 's',
        conversationId: 'c',
        question: 'q',
        origin: origin,
      );
      expect(question.origin, origin);
    });

    test('ConfirmationRequestDto reads it from the wire', () {
      final dto = ConfirmationRequestDto.fromJson({
        'id': '1',
        'space_id': 's',
        'title': 't',
        'detail': 'd',
        'severity': 'warning',
        'created_at': '2026-11-17T00:00:00Z',
        'origin': origin.toJson(),
      });
      expect(dto.origin, origin);
      final plain = ConfirmationRequestDto.fromJson(const {'id': '2'});
      expect(plain.origin, isNull);
    });
  });

  group('ModeToolPolicy', () {
    test('repl is a run-mechanics tool admitted in every mode', () {
      expect(ModeToolPolicy.runMechanicsTools, contains('repl'));
      for (final mode in Mode.values) {
        expect(ModeToolPolicy.isAllowed('repl', mode), isTrue, reason: '$mode');
      }
    });

    test('the direct set', () {
      expect(ModeToolPolicy.directTools, {
        'read',
        'write',
        'edit',
        'search',
        'find',
        'bash',
        'read_output',
        'ask_user',
        'task',
        'todo_write',
        'search_memory',
        'send_message',
      });
    });

    test('each mode adds its own loop to the direct set', () {
      expect(
        ModeToolPolicy.directNamesFor(Mode.chat),
        ModeToolPolicy.directTools,
      );
      expect(
        ModeToolPolicy.directNamesFor(Mode.review),
        containsAll(['add_review_node', 'resolve_review_node']),
      );
      expect(ModeToolPolicy.directNamesFor(Mode.plan), contains('submit_plan'));
      expect(
        ModeToolPolicy.directNamesFor(Mode.orchestrate),
        contains('propose_orchestration'),
      );
      for (final mode in Mode.values) {
        expect(
          ModeToolPolicy.directNamesFor(mode),
          isNot(anyOf(contains('repl'), contains('todo_read'))),
          reason: '$mode',
        );
      }
    });

    test('the residency spec adds the discovery, pinned and interaction '
        'verbs', () {
      for (final mode in Mode.values) {
        final profile = modeCapabilityProfiles[mode]!;
        expect(profile.toToolResidencySpec().residentNames, {
          ...ModeToolPolicy.directNamesFor(mode),
          ...ModeToolPolicy.residentDiscovery,
          ...profile.pinnedVerbs,
          ...ModeCapabilityProfile.interactionVerbs,
        }, reason: '$mode');
      }
    });
  });

  group('buildCapabilityPreamble with repl', () {
    final profile = modeCapabilityProfiles[Mode.chat]!;

    test('without repl it refuses script-only names', () {
      expect(
        () => buildCapabilityPreamble(
          profile,
          materializedToolNames: const ['read'],
          scriptToolNames: const ['create_ticket'],
        ),
        throwsArgumentError,
      );
    });

    test('introduces script-only tools as callable from repl', () {
      final text = buildCapabilityPreamble(
        profile,
        materializedToolNames: const ['read', 'repl'],
        hasRepl: true,
        scriptToolNames: const ['create_ticket', 'search_memory'],
      );
      expect(text, contains('These 2 tools are loaded and ready to call:'));
      expect(text, contains('2 more tools are callable from `repl`'));
      expect(text, contains('`create_ticket`'));
      expect(text, isNot(contains('not loaded yet')));
      expect(text, isNot(contains('You have exactly')));
      // When to write a script, in one sentence, only with repl.
      const rule = 'never wrap a single direct call in a script.';
      expect(text, contains(rule));
      expect(
        buildCapabilityPreamble(profile, materializedToolNames: const ['read']),
        isNot(contains(rule)),
      );
    });

    test('a required verb that is script-only is not reported missing', () {
      final plan = modeCapabilityProfiles[Mode.plan]!;
      final text = buildCapabilityPreamble(
        plan,
        materializedToolNames: const ['repl'],
        hasRepl: true,
        scriptToolNames: plan.requiredVerbs.toList(),
      );
      expect(text, isNot(contains('WARNING')));
    });
  });
}
