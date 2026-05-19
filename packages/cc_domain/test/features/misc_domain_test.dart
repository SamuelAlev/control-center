import 'dart:math';

import 'package:cc_domain/features/evals/domain/entities/evals_entities.dart';
import 'package:cc_domain/features/evals/domain/value_objects/eval_outcome.dart';
import 'package:cc_domain/features/mcp/domain/value_objects/capability_tier.dart';
import 'package:cc_domain/features/model_routing/domain/entities/credential_account.dart';
import 'package:cc_domain/features/model_routing/domain/entities/rate_limit.dart';
import 'package:cc_domain/features/ticketing/domain/entities/ticket_link.dart';
import 'package:cc_domain/src/rpc/action_determinism.dart';
import 'package:cc_domain/src/rpc/protocol.dart';
import 'package:cc_harness/context.dart';
import 'package:cc_harness/loop.dart';
import 'package:test/test.dart';

/// Coverage for assorted feature-domain types that had no dedicated test:
/// rpc protocol vocabulary, ticket links, mcp capability tiers, model-routing
/// credential/rate-limit types, dispatch steering and evals entities.
void main() {
  group('Rpc protocol', () {
    test('RpcErrorCodes / RpcMethods / RepoOpKind are stable constants', () {
      expect(RpcErrorCodes.notFound, -33001);
      expect(RpcErrorCodes.conflict, -33004);
      expect(RpcMethods.repoCall, 'repo/call');
      expect(RpcMethods.subscribe, 'sub/subscribe');
      expect(RepoOpKind.values.length, 3);
    });

    test('UndoClass fromWire + isUndoable', () {
      expect(UndoClass.fromWire('reversible'), UndoClass.reversible);
      expect(UndoClass.fromWire('compensable'), UndoClass.compensable);
      expect(UndoClass.fromWire('irreversible'), UndoClass.irreversible);
      expect(UndoClass.fromWire(null), UndoClass.irreversible);
      expect(UndoClass.fromWire('bogus'), UndoClass.irreversible);
      expect(UndoClass.reversible.isUndoable, isTrue);
      expect(UndoClass.compensable.isUndoable, isTrue);
      expect(UndoClass.irreversible.isUndoable, isFalse);
    });

    test('HostCapabilities fromJson + toJson round-trip + defaults', () {
      final json = {
        'os': 'macos',
        'sandbox_backends': ['seatbelt'],
        'audio_capture': true,
        'embeddings': true,
        'git': true,
        'pty': true,
        'code_graph': true,
        'repo_rpc_catalog_version': 2,
        'subscriptions': true,
        'max_subscriptions_per_session': 5,
      };
      final caps = HostCapabilities.fromJson(json);
      expect(caps.os, 'macos');
      expect(caps.sandboxBackends, ['seatbelt']);
      expect(caps.repoRpcCatalogVersion, 2);
      expect(caps.maxSubscriptionsPerSession, 5);
      final rebuilt = HostCapabilities.fromJson(caps.toJson());
      expect(rebuilt.os, caps.os);
      expect(rebuilt.sandboxBackends, caps.sandboxBackends);
      expect(rebuilt.audioCapture, caps.audioCapture);
      expect(rebuilt.repoRpcCatalogVersion, caps.repoRpcCatalogVersion);
      expect(
        rebuilt.maxSubscriptionsPerSession,
        caps.maxSubscriptionsPerSession,
      );

      final bare = HostCapabilities.fromJson({});
      expect(bare.os, 'unknown');
      expect(bare.sandboxBackends, isEmpty);
      expect(bare.git, isFalse);
    });
  });

  group('action_determinism', () {
    test('newIdempotencyKey is unique v7', () {
      final a = newIdempotencyKey();
      final b = newIdempotencyKey();
      expect(a, isNot(b));
      expect(a.length, greaterThan(10));
    });

    test('bulkItemIdempotencyKey composes', () {
      expect(bulkItemIdempotencyKey('bulk', 'item1'), 'bulk/item1');
    });

    test('ActionPreview round-trip + defaults', () {
      const full = ActionPreview(
        summary: 's',
        filesTouched: ['a'],
        estimatedCostUsd: 1.5,
        blastRadiusSymbols: ['b'],
        warnings: ['w'],
        reversible: true,
      );
      final rebuilt = ActionPreview.fromJson(full.toJson());
      expect(rebuilt.summary, 's');
      expect(rebuilt.filesTouched, ['a']);
      expect(rebuilt.estimatedCostUsd, 1.5);
      expect(rebuilt.blastRadiusSymbols, ['b']);
      expect(rebuilt.warnings, ['w']);
      expect(rebuilt.reversible, isTrue);

      final bare = ActionPreview.fromJson({});
      expect(bare.summary, '');
      expect(bare.filesTouched, isEmpty);
      expect(bare.estimatedCostUsd, isNull);
      expect(bare.reversible, isFalse);
      expect(bare.toJson().containsKey('estimated_cost_usd'), isFalse);
    });
  });

  group('TicketLink', () {
    test('TicketLinkType fromStorage + toStorageString', () {
      expect(TicketLinkType.fromStorage('blocks'), TicketLinkType.blocks);
      expect(
        TicketLinkType.fromStorage('relates_to'),
        TicketLinkType.relatesTo,
      );
      expect(
        TicketLinkType.fromStorage('duplicate_of'),
        TicketLinkType.duplicateOf,
      );
      expect(TicketLinkType.fromStorage(null), isNull);
      expect(TicketLinkType.fromStorage('bogus'), isNull);
      expect(TicketLinkType.blocks.toStorageString(), 'blocks');
    });

    final link = TicketLink(
      id: 'l',
      workspaceId: 'w',
      sourceTicketId: 'src',
      targetTicketId: 'tgt',
      type: TicketLinkType.blocks,
      createdAt: DateTime(2025, 1, 1),
    );

    test('relationFor returns null when subject not an endpoint', () {
      expect(link.relationFor('other'), isNull);
    });

    test('relationFor across all types and endpoints', () {
      // blocks: source -> blocking, target -> blockedBy
      expect(link.relationFor('src')!.kind, TicketRelationKind.blocking);
      expect(link.relationFor('src')!.otherTicketId, 'tgt');
      expect(link.relationFor('tgt')!.kind, TicketRelationKind.blockedBy);

      final rel = TicketLink(
        id: 'l',
        workspaceId: 'w',
        sourceTicketId: 's',
        targetTicketId: 't',
        type: TicketLinkType.relatesTo,
        createdAt: DateTime(2025, 1, 1),
      );
      expect(rel.relationFor('s')!.kind, TicketRelationKind.relatedTo);
      expect(rel.relationFor('t')!.kind, TicketRelationKind.relatedTo);

      final dup = TicketLink(
        id: 'l',
        workspaceId: 'w',
        sourceTicketId: 's',
        targetTicketId: 't',
        type: TicketLinkType.duplicateOf,
        createdAt: DateTime(2025, 1, 1),
      );
      expect(dup.relationFor('s')!.kind, TicketRelationKind.duplicateOf);
      expect(dup.relationFor('t')!.kind, TicketRelationKind.duplicatedBy);
    });

    test('equality + hashCode', () {
      final same = TicketLink(
        id: 'l',
        workspaceId: 'diff',
        sourceTicketId: 'src',
        targetTicketId: 'tgt',
        type: TicketLinkType.blocks,
        createdAt: DateTime(2030),
      );
      expect(link, same);
      expect(link.hashCode, same.hashCode);
      expect(
        link ==
            TicketLink(
              id: 'l',
              workspaceId: 'w',
              sourceTicketId: 'x',
              targetTicketId: 'tgt',
              type: TicketLinkType.blocks,
              createdAt: DateTime(2025, 1, 1),
            ),
        isFalse,
      );
    });
  });

  group('capability_tier', () {
    test('CapabilityTier rank + wire + fromWire', () {
      expect(CapabilityTier.read.rank, lessThan(CapabilityTier.write.rank));
      expect(CapabilityTier.write.rank, lessThan(CapabilityTier.exec.rank));
      expect(CapabilityTier.fromWire('read'), CapabilityTier.read);
      expect(CapabilityTier.fromWire('bogus'), CapabilityTier.exec);
      expect(CapabilityTier.fromWire(null), CapabilityTier.exec);
    });

    test('ApprovalMode ceiling + approves + wire + fromWire', () {
      expect(ApprovalMode.alwaysAsk.ceiling, CapabilityTier.read);
      expect(ApprovalMode.write.ceiling, CapabilityTier.write);
      expect(ApprovalMode.yolo.ceiling, CapabilityTier.exec);
      expect(ApprovalMode.write.approves(CapabilityTier.read), isTrue);
      expect(ApprovalMode.write.approves(CapabilityTier.exec), isFalse);
      expect(ApprovalMode.fromWire('write'), ApprovalMode.write);
      expect(ApprovalMode.fromWire('yolo'), ApprovalMode.yolo);
      expect(ApprovalMode.fromWire('bogus'), ApprovalMode.alwaysAsk);
      expect(ApprovalMode.write.wire, 'write');
    });

    test('ToolApproval static constants + override/reason', () {
      expect(ToolApproval.read.tier, CapabilityTier.read);
      expect(ToolApproval.write.tier, CapabilityTier.write);
      expect(ToolApproval.exec.tier, CapabilityTier.exec);
      const o = ToolApproval(CapabilityTier.read, override: true, reason: 'r');
      expect(o.override, isTrue);
      expect(o.reason, 'r');
    });

    test('resolveApproval matrix', () {
      // yolo: allow unless override
      expect(
        resolveApproval(ToolApproval.exec, ApprovalMode.yolo),
        ApprovalDecision.allow,
      );
      expect(
        resolveApproval(
          const ToolApproval(CapabilityTier.read, override: true),
          ApprovalMode.yolo,
        ),
        ApprovalDecision.prompt,
      );
      // override forces prompt in non-yolo too
      expect(
        resolveApproval(
          const ToolApproval(CapabilityTier.read, override: true),
          ApprovalMode.alwaysAsk,
        ),
        ApprovalDecision.prompt,
      );
      // alwaysAsk auto-approves read only
      expect(
        resolveApproval(ToolApproval.read, ApprovalMode.alwaysAsk),
        ApprovalDecision.allow,
      );
      expect(
        resolveApproval(ToolApproval.write, ApprovalMode.alwaysAsk),
        ApprovalDecision.prompt,
      );
      // write mode auto-approves read+write
      expect(
        resolveApproval(ToolApproval.write, ApprovalMode.write),
        ApprovalDecision.allow,
      );
      expect(
        resolveApproval(ToolApproval.exec, ApprovalMode.write),
        ApprovalDecision.prompt,
      );
    });
  });

  group('CredentialAccount + AccountBlockState', () {
    test('accountKey precedence email->id', () {
      expect(
        const CredentialAccount(
          id: 'a',
          providerId: 'p',
          email: 'e',
        ).accountKey,
        'e',
      );
      expect(const CredentialAccount(id: 'a', providerId: 'p').accountKey, 'a');
    });

    test('equality + toString', () {
      const a = CredentialAccount(id: 'a', providerId: 'p');
      const b = CredentialAccount(
        id: 'a',
        providerId: 'p',
        email: 'e',
      ); // email not in equality
      expect(a, b);
      expect(a.toString(), 'CredentialAccount(p/a)');
      expect(
        a == const CredentialAccount(id: 'a', providerId: 'other'),
        isFalse,
      );
    });

    test('AccountBlockState.isActiveAt + equality', () {
      final state = AccountBlockState(
        accountId: 'a',
        blockedUntil: DateTime(2025, 1, 2),
        scope: 'family',
      );
      expect(state.isActiveAt(DateTime(2025, 1, 1)), isTrue);
      expect(state.isActiveAt(DateTime(2025, 1, 3)), isFalse);
      expect(
        state,
        AccountBlockState(
          accountId: 'a',
          blockedUntil: DateTime(2025, 1, 2),
          scope: 'family',
        ),
      );
      expect(
        state.hashCode,
        AccountBlockState(
          accountId: 'a',
          blockedUntil: DateTime(2025, 1, 2),
          scope: 'family',
        ).hashCode,
      );

      final noScope = AccountBlockState(
        accountId: 'a',
        blockedUntil: DateTime(2025, 1, 2),
      );
      expect(noScope.scope, isNull);
    });
  });

  group('RateLimit', () {
    test('RateLimitReason id', () {
      expect(RateLimitReason.quotaExhausted.id, 'quotaExhausted');
    });

    test('effectiveBackoff no jitter returns base', () {
      const c = RateLimitClassification(
        reason: RateLimitReason.serverError,
        baseBackoff: Duration(seconds: 1),
        shouldRotate: true,
      );
      expect(c.effectiveBackoff(), const Duration(seconds: 1));
    });

    test('effectiveBackoff with jitter is base + [0, maxJitter]', () {
      const c = RateLimitClassification(
        reason: RateLimitReason.modelCapacity,
        baseBackoff: Duration(seconds: 2),
        shouldRotate: false,
        maxJitter: Duration(seconds: 10),
      );
      final b = c.effectiveBackoff(Random(0));
      expect(b.inSeconds, greaterThanOrEqualTo(2));
      expect(b.inSeconds, lessThanOrEqualTo(12));
    });

    test('equality + toString', () {
      const a = RateLimitClassification(
        reason: RateLimitReason.unknown,
        baseBackoff: Duration(seconds: 1),
        shouldRotate: false,
      );
      const b = RateLimitClassification(
        reason: RateLimitReason.unknown,
        baseBackoff: Duration(seconds: 1),
        shouldRotate: false,
      );
      expect(a, b);
      expect(a.toString(), contains('unknown'));
    });
  });

  group('SteeringMessage + SteeringChannel', () {
    test('construction + equality + toString', () {
      final m = SteeringMessage(
        content: 'hi',
        channel: SteeringChannel.aside,
        enqueuedAt: DateTime(2025, 1, 1),
        source: 'job',
      );
      expect(m.channel, SteeringChannel.aside);
      expect(m.source, 'job');
      final same = SteeringMessage(
        content: 'hi',
        channel: SteeringChannel.aside,
        enqueuedAt: DateTime(2025, 1, 1),
        source: 'job',
      );
      expect(m, same);
      expect(m.hashCode, same.hashCode);
      expect(m.toString(), contains('aside'));
      expect(SteeringChannel.values.length, 3);
    });
  });

  group('EvalOutcome', () {
    test('signalBool + toJson', () {
      const o = EvalOutcome(
        completed: true,
        costCents: 5,
        turnCount: 3,
        toolCalls: ['read'],
        sandboxViolations: 1,
        filesTouched: ['a.dart'],
        durationMs: 100,
        signals: {'testsPassed': true, 'count': 2},
        error: null,
      );
      expect(o.signalBool('testsPassed'), isTrue);
      expect(o.signalBool('missing'), isFalse);
      final json = o.toJson();
      expect(json['completed'], isTrue);
      expect(json['costCents'], 5);
      expect(json['error'], isNull);
    });

    test('defaults', () {
      const o = EvalOutcome(completed: false, error: 'boom');
      expect(o.costCents, 0);
      expect(o.toolCalls, isEmpty);
      expect(o.signals, isEmpty);
      expect(o.toJson()['error'], 'boom');
    });
  });

  group('Evals entities construction', () {
    test('SessionRecording defaults', () {
      final r = SessionRecording(
        id: 's',
        workspaceId: 'w',
        runLogId: 'r',
        configHash: 'h',
        createdAt: DateTime(2025, 1, 1),
      );
      expect(r.eventCount, 0);
      expect(r.hashVersion, 1);
      expect(r.title, '');
    });

    test('GoldenSession defaults', () {
      final g = GoldenSession(
        id: 'g',
        workspaceId: 'w',
        agentId: 'a',
        recordingId: 'r',
        blessedAt: DateTime(2025, 1, 1),
      );
      expect(g.mode, 'deterministic');
      expect(g.enabled, isTrue);
      expect(g.lastStatus, 'unknown');
    });

    test('EvalSuite defaults', () {
      final s = EvalSuite(
        id: 's',
        workspaceId: 'w',
        name: 'n',
        createdAt: DateTime(2025, 1, 1),
        updatedAt: DateTime(2025, 1, 2),
      );
      expect(s.taskJson, '{}');
      expect(s.gradersJson, '[]');
      expect(s.defaultBatchSize, 1);
    });

    test('EvalRun defaults', () {
      final r = EvalRun(
        id: 'e',
        workspaceId: 'w',
        suiteId: 's',
        configHash: 'h',
        createdAt: DateTime(2025, 1, 1),
      );
      expect(r.status, 'queued');
      expect(r.triggeredBy, 'manual');
      expect(r.passRate, 0);
    });

    test('AgentConfigVersion defaults', () {
      final v = AgentConfigVersion(
        id: 'v',
        workspaceId: 'w',
        agentId: 'a',
        configHash: 'h',
        createdAt: DateTime(2025, 1, 1),
      );
      expect(v.status, 'live');
      expect(v.hashVersion, 1);
      expect(v.configJson, '{}');
    });
  });

  group('CompactionConfig', () {
    test('defaults + copyWith', () {
      expect(CompactionConfig.defaults.auto, isTrue);
      expect(CompactionConfig.defaults.keepTurns, 3);
      expect(CompactionConfig.defaults.buffer, 8000);
      final next = CompactionConfig.defaults.copyWith(
        keepTurns: 5,
        keepTokens: 1000,
      );
      expect(next.keepTurns, 5);
      expect(next.keepTokens, 1000);
      expect(next.auto, isTrue);
    });
  });
}
