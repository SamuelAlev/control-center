import 'package:cc_domain/core/domain/entities/workspace_member.dart';
import 'package:cc_domain/core/domain/events/domain_event_bus.dart';
import 'package:cc_domain/core/domain/events/pr_events.dart';
import 'package:cc_domain/core/domain/ports/confirmation_port.dart';
import 'package:cc_domain/core/domain/value_objects/agent_role.dart';
import 'package:cc_domain/core/domain/value_objects/agent_run_role.dart';
import 'package:cc_domain/core/domain/value_objects/entity_ref.dart';
import 'package:cc_domain/core/domain/value_objects/file_search_hit.dart';
import 'package:cc_domain/core/domain/value_objects/message_attachment.dart';
import 'package:cc_domain/core/domain/value_objects/mode.dart';
import 'package:cc_domain/core/domain/value_objects/output_contract_mode.dart';
import 'package:cc_domain/core/domain/value_objects/principal.dart';
import 'package:cc_domain/core/domain/value_objects/retry_meta.dart';
import 'package:cc_domain/core/domain/value_objects/transcript_segment.dart';
import 'package:cc_domain/core/domain/value_objects/transcript_update.dart';
import 'package:cc_domain/core/domain/value_objects/workspace_role.dart';
import 'package:test/test.dart';

/// Coverage for the core/domain enums, value objects, events, ports, and small
/// entities that had no dedicated test. Exercises every factory/parse method
/// (including the null/unknown fallbacks), equality, and the event-bus plumbing.
void main() {
  group('AgentRunRole', () {
    test('tryParse maps known names and falls back to main', () {
      expect(AgentRunRole.tryParse('main'), AgentRunRole.main);
      expect(AgentRunRole.tryParse('sub'), AgentRunRole.sub);
      expect(AgentRunRole.tryParse('advisor'), AgentRunRole.advisor);
      expect(AgentRunRole.tryParse(null), AgentRunRole.main);
      expect(AgentRunRole.tryParse('bogus'), AgentRunRole.main);
    });
  });

  group('Mode', () {
    test('fromDbValue round-trips and falls back to chat', () {
      for (final m in Mode.values) {
        expect(Mode.fromDbValue(m.toDbValue()), m);
      }
      expect(Mode.fromDbValue(null), Mode.chat);
      expect(Mode.fromDbValue('bogus'), Mode.chat);
    });
  });

  group('OutputContractMode', () {
    test('fromStorage round-trips; null defaults to strict', () {
      expect(OutputContractMode.fromStorage(null), OutputContractMode.strict);
      expect(
        OutputContractMode.fromStorage('permissive'),
        OutputContractMode.permissive,
      );
      expect(OutputContractMode.strict.toStorageString(), 'strict');
    });

    test('fromStorage throws on unknown value', () {
      expect(
        () => OutputContractMode.fromStorage('bogus'),
        throwsA(isA<ArgumentError>()),
      );
    });
  });

  group('AgentRole', () {
    test('tryParse is case-insensitive; null/unknown -> null', () {
      expect(AgentRole.tryParse('CEO'), AgentRole.ceo);
      expect(AgentRole.tryParse('coder'), AgentRole.coder);
      expect(AgentRole.tryParse(null), isNull);
      expect(AgentRole.tryParse('bogus'), isNull);
    });

    test('every role has a label and description', () {
      for (final r in AgentRole.values) {
        expect(r.label, isNotEmpty);
        expect(r.description, isNotEmpty);
      }
    });
  });

  group('FileSearchHit', () {
    const full = FileSearchHit(
      absolutePath: '/a',
      relativePath: 'r',
      rootPath: '/root',
      isDirectory: true,
      score: 1.5,
    );

    test('fromJson round-trips and tolerates missing fields', () {
      final dto = FileSearchHit.fromJson({
        'absolutePath': '/a',
        'relativePath': 'r',
        'rootPath': '/root',
        'isDirectory': true,
        'score': 1.5,
      });
      expect(dto, full);
      expect(dto.toJson(), {
        'absolutePath': '/a',
        'relativePath': 'r',
        'rootPath': '/root',
        'isDirectory': true,
        'score': 1.5,
      });
      final bare = FileSearchHit.fromJson({});
      expect(bare.absolutePath, '');
      expect(bare.isDirectory, isFalse);
      expect(bare.score, 0);
    });

    test('equality + hashCode', () {
      expect(
        full,
        const FileSearchHit(
          absolutePath: '/a',
          relativePath: 'r',
          rootPath: '/root',
          isDirectory: true,
          score: 1.5,
        ),
      );
      expect(
        full ==
            const FileSearchHit(
              absolutePath: '/a',
              relativePath: 'r',
              rootPath: '/root',
              isDirectory: true,
              score: 0,
            ),
        isFalse,
      );
      expect(
        full.hashCode,
        const FileSearchHit(
          absolutePath: '/a',
          relativePath: 'r',
          rootPath: '/root',
          isDirectory: true,
          score: 1.5,
        ).hashCode,
      );
    });
  });

  group('WorkspaceRole', () {
    test('rank ordering and predicates', () {
      expect(WorkspaceRole.owner.atLeast(WorkspaceRole.admin), isTrue);
      expect(WorkspaceRole.guest.atLeast(WorkspaceRole.member), isFalse);
      expect(WorkspaceRole.member.canWrite, isTrue);
      expect(WorkspaceRole.viewer.canWrite, isFalse);
      expect(WorkspaceRole.admin.isAdmin, isTrue);
      expect(WorkspaceRole.member.isAdmin, isFalse);
      expect(WorkspaceRole.viewer.isReadOnly, isTrue);
      expect(WorkspaceRole.member.isReadOnly, isFalse);
    });

    test('fromWire + wireName round-trip; unknown -> null', () {
      for (final r in WorkspaceRole.values) {
        expect(WorkspaceRole.fromWire(r.wireName), r);
      }
      expect(WorkspaceRole.fromWire(null), isNull);
      expect(WorkspaceRole.fromWire('bogus'), isNull);
    });
  });

  group('Principal', () {
    test('factory + wire + predicates', () {
      final u = Principal.of(PrincipalType.user, 'u1');
      final a = Principal.of(PrincipalType.agent, 'a1');
      expect(u.isUser, isTrue);
      expect(u.isAgent, isFalse);
      expect(a.isAgent, isTrue);
      expect(u.wire, 'user:u1');
      expect(a.wire, 'agent:a1');
      expect(u.toString(), 'user:u1');
    });

    test('PrincipalType fromWire + wireName', () {
      expect(PrincipalType.fromWire('user'), PrincipalType.user);
      expect(PrincipalType.fromWire('agent'), PrincipalType.agent);
      expect(PrincipalType.fromWire('bogus'), isNull);
      expect(PrincipalType.fromWire(null), isNull);
      expect(PrincipalType.user.wireName, 'user');
    });

    test('tryParse handles all shapes', () {
      expect(Principal.tryParse('user:u1'), const UserPrincipal('u1'));
      expect(Principal.tryParse('agent:a1'), const AgentPrincipal('a1'));
      expect(Principal.tryParse(null), isNull);
      // no colon
      expect(Principal.tryParse('user'), isNull);
      // colon at start (type empty)
      expect(Principal.tryParse(':u1'), isNull);
      // colon at end (id empty)
      expect(Principal.tryParse('user:'), isNull);
      // unknown type
      expect(Principal.tryParse('bogus:u1'), isNull);
    });

    test('parse throws on malformed, returns on valid', () {
      expect(() => Principal.parse('nope'), throwsA(isA<FormatException>()));
      expect(Principal.parse('agent:a1'), const AgentPrincipal('a1'));
    });

    test('equality distinguishes by type + id', () {
      expect(const UserPrincipal('u1'), const UserPrincipal('u1'));
      expect(const UserPrincipal('u1') == const AgentPrincipal('u1'), isFalse);
      expect(
        const UserPrincipal('u1').hashCode,
        const UserPrincipal('u1').hashCode,
      );
    });
  });

  group('EntityRef', () {
    test('tryFromJson + toJson round-trip', () {
      const ref = EntityRef(
        type: EntityRefType.pullRequest,
        id: '5',
        label: 'L',
        repoFullName: 'o/r',
      );
      expect(EntityRef.tryFromJson(ref.toJson()), ref);
      final out = ref.toJson();
      expect(out['label'], 'L');
      expect(out['repoFullName'], 'o/r');
    });

    test('tryFromJson null cases', () {
      expect(EntityRef.tryFromJson({'type': 'bogus', 'id': '1'}), isNull);
      expect(EntityRef.tryFromJson({'type': 'ticket', 'id': ''}), isNull);
      expect(EntityRef.tryFromJson({'type': 'ticket'}), isNull);
    });

    test('EntityRefType.tryParse', () {
      expect(EntityRefType.tryParse('ticket'), EntityRefType.ticket);
      expect(EntityRefType.tryParse('pullRequest'), EntityRefType.pullRequest);
      expect(EntityRefType.tryParse('meeting'), EntityRefType.meeting);
      expect(EntityRefType.tryParse('bogus'), isNull);
      expect(EntityRefType.tryParse(null), isNull);
    });

    test('equality + hashCode omit label/repo optionally', () {
      const a = EntityRef(type: EntityRefType.ticket, id: '1', label: 'L');
      const b = EntityRef(type: EntityRefType.ticket, id: '1', label: 'L');
      expect(a, b);
      expect(a.hashCode, b.hashCode);
      expect(
        a == const EntityRef(type: EntityRefType.ticket, id: '1'),
        isFalse,
      );
    });
  });

  group('RetryMeta', () {
    test('nextAttempt increments', () {
      const m = RetryMeta(parentRunId: 'p', attempt: 1);
      final n = m.nextAttempt();
      expect(n.attempt, 2);
      expect(n.parentRunId, 'p');
    });

    test('equality + hashCode', () {
      expect(
        const RetryMeta(parentRunId: 'p', attempt: 1),
        const RetryMeta(parentRunId: 'p', attempt: 1),
      );
      expect(
        const RetryMeta(parentRunId: 'p', attempt: 1) ==
            const RetryMeta(attempt: 1),
        isFalse,
      );
      expect(
        const RetryMeta(parentRunId: 'p', attempt: 1).hashCode,
        const RetryMeta(parentRunId: 'p', attempt: 1).hashCode,
      );
    });
  });

  group('MessageAttachment', () {
    const full = MessageAttachment(
      id: 'i',
      path: '/p',
      name: 'n',
      kind: AttachmentKind.image,
      size: 10,
      order: 2,
    );

    test('fromJson + toJson round-trip', () {
      final dto = MessageAttachment.fromJson({
        'id': 'i',
        'path': '/p',
        'name': 'n',
        'kind': 'image',
        'size': 10,
        'order': 2,
      });
      expect(dto, full);
      expect(dto.toJson(), {
        'id': 'i',
        'path': '/p',
        'name': 'n',
        'kind': 'image',
        'size': 10,
        'order': 2,
      });
    });

    test('fromJson defaults', () {
      final dto = MessageAttachment.fromJson({
        'id': 'i',
        'path': '/p',
        'name': 'n',
      });
      expect(dto.kind, AttachmentKind.file);
      expect(dto.size, isNull);
      expect(dto.order, 0);
      final out = dto.toJson();
      expect(out.containsKey('size'), isFalse);
    });

    test('equality + hashCode', () {
      expect(
        full.hashCode,
        const MessageAttachment(
          id: 'i',
          path: '/p',
          name: 'n',
          kind: AttachmentKind.image,
          size: 10,
          order: 2,
        ).hashCode,
      );
      expect(
        full ==
            const MessageAttachment(
              id: 'i',
              path: '/p',
              name: 'n',
              kind: AttachmentKind.file,
              size: 10,
              order: 2,
            ),
        isFalse,
      );
    });
  });

  group('TranscriptUpdate variants', () {
    final seg = TextSegment(text: 'hi', startedAt: DateTime(2025, 1, 1));
    final seg2 = ToolSegment(
      toolName: 't',
      toolCallId: 'c',
      status: ToolSegmentStatus.running,
      startedAt: DateTime(2025, 1, 1),
    );

    test('SegmentOpened equality + index', () {
      final a = SegmentOpened(0, seg);
      final b = SegmentOpened(0, seg);
      expect(a.index, 0);
      expect(a, b);
      expect(a == SegmentOpened(1, seg), isFalse);
      expect(a.hashCode, b.hashCode);
    });

    test('SegmentDelta equality', () {
      const a = SegmentDelta(0, 'd');
      expect(a.delta, 'd');
      expect(a, const SegmentDelta(0, 'd'));
      expect(a == const SegmentDelta(0, 'x'), isFalse);
      expect(a.hashCode, const SegmentDelta(0, 'd').hashCode);
    });

    test('SegmentClosed equality', () {
      final a = SegmentClosed(2, seg2);
      expect(a.segment, seg2);
      expect(a, SegmentClosed(2, seg2));
      expect(a == SegmentClosed(2, seg), isFalse);
    });

    test('TurnFinished equality + outcome', () {
      const a = TurnFinished(3, TurnOutcome.completed);
      expect(a.outcome, TurnOutcome.completed);
      expect(a, const TurnFinished(3, TurnOutcome.completed));
      expect(a == const TurnFinished(3, TurnOutcome.failed), isFalse);
    });
  });

  group('DomainEventBus + Pr events', () {
    test('publish / on<T> type filtering + dispose', () async {
      final bus = DomainEventBus();
      final published = <PullRequestPublished>[];
      final allPr = <DomainEvent>[];
      bus.on<PullRequestPublished>().listen(published.add);
      bus.on<DomainEvent>().listen(allPr.add);
      final e = PullRequestPublished(
        prId: 'p1',
        workspaceId: 'w',
        repoOwner: 'o',
        repoName: 'r',
        occurredAt: DateTime(2025, 1, 1),
      );
      bus.publish(e);
      bus.publish(
        PrMerged(
          prId: 'p2',
          workspaceId: 'w',
          agentId: 'a',
          occurredAt: DateTime(2025, 1, 2),
        ),
      );
      bus.publish(
        PullRequestStatusChanged(
          status: 'closed',
          occurredAt: DateTime(2025, 1, 3),
        ),
      );
      await Future<void>.delayed(Duration.zero);
      expect(published, [e]);
      // on<DomainEvent> receives every event (3 published).
      expect(allPr.length, 3);
      bus.dispose();
    });

    test('PullRequestStatusChanged field round-trip', () {
      final e = PullRequestStatusChanged(
        status: 'merged',
        occurredAt: DateTime(2025, 1, 1),
        prId: 'p',
        workspaceId: 'w',
        repoFullName: 'o/r',
        prNumber: 5,
      );
      expect(e.status, 'merged');
      expect(e.prNumber, 5);
    });

    test('ExternalPrDetected field round-trip', () {
      final e = ExternalPrDetected(
        repoOwner: 'o',
        repoName: 'r',
        prNumber: 1,
        prTitle: 'T',
        author: 'a',
        workspaceId: null,
        occurredAt: DateTime(2025, 1, 1),
      );
      expect(e.workspaceId, isNull);
      expect(e.author, 'a');
    });

    test('ExternalPrMerged field round-trip', () {
      final e = ExternalPrMerged(
        workspaceId: 'w',
        repoOwner: 'o',
        repoName: 'r',
        prNumber: 1,
        prTitle: 'T',
        occurredAt: DateTime(2025, 1, 1),
      );
      expect(e.workspaceId, 'w');
      expect(e.repoOwner, 'o');
      expect(e.repoName, 'r');
      expect(e.prNumber, 1);
      expect(e.prTitle, 'T');
      expect(e.occurredAt, DateTime(2025, 1, 1));
    });
  });

  group('ConfirmationPort surface', () {
    test('ConfirmationRequest defaults', () {
      const req = ConfirmationRequest(
        conversationId: 'c',
        title: 'T',
        detail: 'D',
      );
      expect(req.severity, ConfirmationSeverity.warning);
      expect(req.kind, ConfirmationKind.command);
      expect(req.rememberChoice, isNull);
      expect(req.command, isNull);
    });

    test('ConfirmationRequestDto.fromJson + defaults', () {
      final dto = ConfirmationRequestDto.fromJson({
        'id': 'i',
        'conversation_id': 'c',
        'title': 'T',
        'detail': 'D',
        'severity': 'destructive',
        'command': 'rm',
        'created_at': 'ca',
      });
      expect(dto.severity, 'destructive');
      expect(dto.command, 'rm');
      final bare = ConfirmationRequestDto.fromJson({'id': 'i'});
      expect(bare.conversationId, '');
      expect(bare.severity, 'warning');
      expect(bare.createdAt, '');
    });

    test('every enum value exists', () {
      expect(ConfirmationSeverity.values.length, 3);
      expect(ConfirmationKind.values.length, 4);
      expect(RememberScope.values.length, 4);
    });
  });

  group('WorkspaceMember', () {
    final m = WorkspaceMember(
      id: 'm1',
      workspaceId: 'w',
      userId: 'u',
      role: WorkspaceRole.admin,
      invitedBy: 'inv',
      joinedAt: DateTime(2025, 1, 1),
    );

    test('field round-trip + equality', () {
      expect(m.id, 'm1');
      expect(m.invitedBy, 'inv');
      expect(
        m,
        WorkspaceMember(
          id: 'm1',
          workspaceId: 'w',
          userId: 'u',
          role: WorkspaceRole.admin,
          invitedBy: 'inv',
          joinedAt: DateTime(2025, 1, 1),
        ),
      );
      expect(
        m ==
            WorkspaceMember(
              id: 'm1',
              workspaceId: 'w',
              userId: 'u',
              role: WorkspaceRole.member,
              invitedBy: 'inv',
              joinedAt: DateTime(2025, 1, 1),
            ),
        isFalse,
      );
    });

    test('copyWith preserves untouched fields and overrides given ones', () {
      final next = m.copyWith(role: WorkspaceRole.owner, invitedBy: 'x');
      expect(next.role, WorkspaceRole.owner);
      expect(next.invitedBy, 'x');
      expect(next.id, 'm1');
      expect(next.workspaceId, 'w');
      expect(next.userId, 'u');
      expect(next.joinedAt, DateTime(2025, 1, 1));
      expect(m.copyWith(), m);
    });
  });
}
