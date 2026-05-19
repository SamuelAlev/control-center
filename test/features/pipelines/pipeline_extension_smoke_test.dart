import 'package:cc_domain/core/domain/events/messaging_events.dart';
import 'package:cc_domain/core/domain/events/observability_events.dart';
import 'package:cc_domain/core/domain/events/pr_events.dart';
import 'package:cc_domain/core/domain/events/ticketing_events.dart';
import 'package:cc_domain/features/pipelines/domain/entities/step_kind.dart';
import 'package:cc_domain/features/pipelines/domain/services/event_payload_mapper.dart';
import 'package:cc_domain/features/pipelines/domain/services/node_type_library.dart';
import 'package:cc_domain/features/pipelines/domain/templates/builtin_template_seeds.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const workspaceId = 'ws-test';

  group('EventPayloadMapper', () {
    test('maps PrMerged to payload with dedup key', () {
      final event = PrMerged(
        prId: 'pr-123',
        workspaceId: workspaceId,
        agentId: 'agent-abc',
        occurredAt: DateTime.now(),
      );
      final payload = EventPayloadMapper.toPayload(event);
      expect(payload, isNotNull);
      expect(payload!['prId'], 'pr-123');
      expect(payload['workspaceId'], workspaceId);
      expect(EventPayloadMapper.dedupKeyFor(event), 'pr-123');
      expect(
        EventPayloadMapper.knownEventTypes,
        contains('PrMerged'),
      );
    });

    test('maps MessageReceived to payload with dedup key', () {
      final event = MessageReceived(
        channelId: 'ch-1',
        messageId: 'msg-1',
        senderName: 'testuser',
        contentPreview: 'hello',
        isAgentMessage: false,
        workspaceId: 'ws-1',
        occurredAt: DateTime.now(),
      );
      final payload = EventPayloadMapper.toPayload(event);
      expect(payload, isNotNull);
      expect(payload!['channelId'], 'ch-1');
      expect(payload['contentPreview'], 'hello');
      expect(EventPayloadMapper.dedupKeyFor(event), 'msg-1');
      expect(
        EventPayloadMapper.knownEventTypes,
        contains('MessageReceived'),
      );
    });

    test('maps TicketCompleted to payload with dedup key', () {
      final event = TicketCompleted(
        ticketId: 'ticket-1',
        occurredAt: DateTime.now(),
      );
      final payload = EventPayloadMapper.toPayload(event);
      expect(payload, isNotNull);
      expect(payload!['ticketId'], 'ticket-1');
      expect(EventPayloadMapper.dedupKeyFor(event), 'ticket-1');
      expect(
        EventPayloadMapper.knownEventTypes,
        contains('TicketCompleted'),
      );
    });

    test('maps TicketFailed to payload', () {
      final event = TicketFailed(
        ticketId: 'ticket-2',
        errorMessage: 'boom',
        occurredAt: DateTime.now(),
      );
      final payload = EventPayloadMapper.toPayload(event);
      expect(payload, isNotNull);
      expect(payload!['ticketId'], 'ticket-2');
      expect(payload['errorMessage'], 'boom');
      expect(EventPayloadMapper.dedupKeyFor(event), 'ticket-2');
      expect(EventPayloadMapper.knownEventTypes, contains('TicketFailed'));
    });

    test('maps BudgetThresholdCrossed to payload', () {
      final event = BudgetThresholdCrossed(
        scopeType: 'workspace',
        scopeId: 'ws-1',
        spentCents: 1500,
        budgetCents: 1000,
        isHardStop: true,
        occurredAt: DateTime.now(),
      );
      final payload = EventPayloadMapper.toPayload(event);
      expect(payload, isNotNull);
      expect(payload!['scopeType'], 'workspace');
      expect(payload['spentCents'], 1500);
      expect(payload['isHardStop'], isTrue);
      expect(EventPayloadMapper.dedupKeyFor(event), 'workspace/ws-1');
      expect(
        EventPayloadMapper.knownEventTypes,
        contains('BudgetThresholdCrossed'),
      );
    });
  });

  group('BuiltInBodyKeys', () {
    test('messagingPostChannel key is defined', () {
      expect(BuiltInBodyKeys.messagingPostChannel, 'messaging.postChannel');
    });
  });

  group('builtInTemplateSeeds', () {
    test('returns 13 seeds', () {
      const agentIds = BuiltInAgentIds(
        qa: 'qa-id',
        architect: 'arch-id',
        engineer: 'eng-id',
        librarian: 'lib-id',
        ceo: 'ceo-id',
      );
      final seeds = builtInTemplateSeeds(
        workspaceId: workspaceId,
        agentIds: agentIds,
      );
      expect(seeds.length, 13);
    });

    test('all seeds have unique templateIds', () {
      const agentIds = BuiltInAgentIds(
        qa: 'qa-id',
        architect: 'arch-id',
        engineer: 'eng-id',
        librarian: 'lib-id',
        ceo: 'ceo-id',
      );
      final seeds = builtInTemplateSeeds(
        workspaceId: workspaceId,
        agentIds: agentIds,
      );
      final ids = seeds.map((s) => s.templateId).toSet();
      expect(ids.length, seeds.length);
    });

    test('all seeds have at least one step and one terminal step', () {
      const agentIds = BuiltInAgentIds(
        qa: 'qa-id',
        architect: 'arch-id',
        engineer: 'eng-id',
        librarian: 'lib-id',
        ceo: 'ceo-id',
      );
      final seeds = builtInTemplateSeeds(
        workspaceId: workspaceId,
        agentIds: agentIds,
      );
      for (final seed in seeds) {
        expect(seed.steps.isNotEmpty, isTrue,
            reason: '${seed.templateId} has no steps');
        final terminalSteps =
            seed.steps.where((s) => s.kind == StepKind.terminal);
        expect(terminalSteps.isNotEmpty, isTrue,
            reason: '${seed.templateId} has no terminal step');
      }
    });

    test('all seeds start with a start step', () {
      const agentIds = BuiltInAgentIds(
        qa: 'qa-id',
        architect: 'arch-id',
        engineer: 'eng-id',
        librarian: 'lib-id',
        ceo: 'ceo-id',
      );
      final seeds = builtInTemplateSeeds(
        workspaceId: workspaceId,
        agentIds: agentIds,
      );
      for (final seed in seeds) {
        // Every pipeline must begin with exactly one trigger entry node.
        final triggers =
            seed.steps.where((s) => s.kind == StepKind.trigger).toList();
        expect(triggers.length, 1,
            reason: '${seed.templateId} must have exactly one trigger step');
      }
    });

    test('new templates are disabled by default', () {
      const agentIds = BuiltInAgentIds(
        qa: 'qa-id',
        architect: 'arch-id',
        engineer: 'eng-id',
        librarian: 'lib-id',
        ceo: 'ceo-id',
      );
      final seeds = builtInTemplateSeeds(
        workspaceId: workspaceId,
        agentIds: agentIds,
      );
      final seedMap = {for (final s in seeds) s.templateId: s};
      // Existing built-ins remain enabled.
      expect(seedMap['pr_review']!.isEnabled, isTrue);
      expect(seedMap['hello']!.isEnabled, isTrue);
      // New templates start disabled.
      expect(seedMap['external_pr_welcome']!.isEnabled, isFalse);
      expect(seedMap['pr_merged_cleanup']!.isEnabled, isFalse);
      expect(seedMap['cross_review']!.isEnabled, isFalse);
    });

    test('seeds reference only registered body keys', () {
      final validBodyKeys = {
        BuiltInBodyKeys.trigger,
        BuiltInBodyKeys.bashScript,
        BuiltInBodyKeys.promptAgent,
        BuiltInBodyKeys.prReviewComment,
        BuiltInBodyKeys.messagingPostChannel,
        BuiltInBodyKeys.condition,
        BuiltInBodyKeys.teamDispatch,
        BuiltInBodyKeys.humanGate,
        BuiltInBodyKeys.cleanupRepos,
        BuiltInBodyKeys.helloGreet,
        BuiltInBodyKeys.helloWorld,
        BuiltInBodyKeys.indexCode,
        BuiltInBodyKeys.meetingDiarize,
        BuiltInBodyKeys.meetingIdentifySpeakers,
        BuiltInBodyKeys.meetingUpdateTranscript,
        BuiltInBodyKeys.meetingAssemblePlayback,
        BuiltInBodyKeys.meetingSaveNotes,
        BuiltInBodyKeys.meetingAddActionItems,
        BuiltInBodyKeys.meetingAddDecisions,
      };
      const agentIds = BuiltInAgentIds(
        qa: 'qa-id',
        architect: 'arch-id',
        engineer: 'eng-id',
        librarian: 'lib-id',
        ceo: 'ceo-id',
      );
      final seeds = builtInTemplateSeeds(
        workspaceId: workspaceId,
        agentIds: agentIds,
      );
      for (final seed in seeds) {
        for (final step in seed.steps) {
          if (step.kind == StepKind.terminal) {
            // Terminal steps use synthetic body keys like _terminal_<id>
            expect(step.bodyKey.startsWith('_terminal_'), isTrue,
                reason:
                    'Terminal step ${step.id} has non-terminal body key: ${step.bodyKey}');
          } else {
            expect(validBodyKeys, contains(step.bodyKey),
                reason:
                    'Step ${step.id} in ${seed.templateId} uses unregistered body key: ${step.bodyKey}');
          }
        }
      }
    });
  });

  group('NodeTypeLibrary', () {
    test('contains messaging.postChannel node type', () {
      final lib = defaultNodeTypeLibrary();
      final node = lib.byId('messaging.postChannel');
      expect(node, isNotNull);
      expect(node!.defaultBodyKey, BuiltInBodyKeys.messagingPostChannel);
      expect(node.defaultKind, StepKind.listen);
    });
  });
}
