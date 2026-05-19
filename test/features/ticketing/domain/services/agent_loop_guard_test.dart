import 'package:control_center/features/ticketing/domain/services/agent_loop_guard.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('AgentLoopGuard', () {
    late AgentLoopGuard guard;

    setUp(() {
      guard = AgentLoopGuard();
    });

    test('does not suppress when trigger author differs from target agent',
        timeout: const Timeout.factor(2), () {
      expect(
        guard.shouldSuppress(
          triggerAuthorId: 'user-1',
          targetAgentId: 'agent-1',
          isAgentAuthor: false,
        ),
        isFalse,
      );
    });

    test('suppresses self-trigger (same agent triggers itself)',
        timeout: const Timeout.factor(2), () {
      expect(
        guard.shouldSuppress(
          triggerAuthorId: 'agent-1',
          targetAgentId: 'agent-1',
          isAgentAuthor: true,
        ),
        isTrue,
      );
    });

    test('suppresses self-trigger regardless of isAgentAuthor',
        timeout: const Timeout.factor(2), () {
      expect(
        guard.shouldSuppress(
          triggerAuthorId: 'agent-1',
          targetAgentId: 'agent-1',
          isAgentAuthor: false,
        ),
        isTrue,
      );
    });

    test(
        'suppresses when agent author and target is in recent participants',
        timeout: const Timeout.factor(2), () {
      expect(
        guard.shouldSuppress(
          triggerAuthorId: 'agent-A',
          targetAgentId: 'agent-B',
          isAgentAuthor: true,
          recentAgentParticipants: {'agent-B', 'agent-C'},
        ),
        isTrue,
      );
    });

    test(
        'does not suppress when agent author but target not in recent participants',
        timeout: const Timeout.factor(2), () {
      expect(
        guard.shouldSuppress(
          triggerAuthorId: 'agent-A',
          targetAgentId: 'agent-B',
          isAgentAuthor: true,
          recentAgentParticipants: {'agent-C', 'agent-D'},
        ),
        isFalse,
      );
    });

    test(
        'does not suppress when human author even if target is in participants',
        timeout: const Timeout.factor(2), () {
      expect(
        guard.shouldSuppress(
          triggerAuthorId: 'user-1',
          targetAgentId: 'agent-1',
          isAgentAuthor: false,
          recentAgentParticipants: {'agent-1'},
        ),
        isFalse,
      );
    });

    test(
        'does not suppress when isAgentAuthor is true but recentParticipants is null',
        timeout: const Timeout.factor(2), () {
      expect(
        guard.shouldSuppress(
          triggerAuthorId: 'agent-A',
          targetAgentId: 'agent-B',
          isAgentAuthor: true,
          recentAgentParticipants: null,
        ),
        isFalse,
      );
    });

    test(
        'does not suppress when isAgentAuthor is true but recentParticipants is empty',
        timeout: const Timeout.factor(2), () {
      expect(
        guard.shouldSuppress(
          triggerAuthorId: 'agent-A',
          targetAgentId: 'agent-B',
          isAgentAuthor: true,
          recentAgentParticipants: {},
        ),
        isFalse,
      );
    });

    test('different agents triggering different targets are not suppressed',
        timeout: const Timeout.factor(2), () {
      expect(
        guard.shouldSuppress(
          triggerAuthorId: 'agent-A',
          targetAgentId: 'agent-B',
          isAgentAuthor: true,
          recentAgentParticipants: {'agent-C'},
        ),
        isFalse,
      );
    });

    test(
        'does not suppress when isAgentAuthor is false and recentParticipants is null',
        timeout: const Timeout.factor(2), () {
      expect(
        guard.shouldSuppress(
          triggerAuthorId: 'agent-A',
          targetAgentId: 'agent-B',
          isAgentAuthor: false,
          recentAgentParticipants: null,
        ),
        isFalse,
      );
    });

    test(
        'suppresses when trigger author is target agent and recent participants includes both',
        timeout: const Timeout.factor(2), () {
      expect(
        guard.shouldSuppress(
          triggerAuthorId: 'agent-1',
          targetAgentId: 'agent-1',
          isAgentAuthor: true,
          recentAgentParticipants: {'agent-1', 'agent-2'},
        ),
        isTrue,
      );
    });

    test('suppresses for identical empty string author and target',
        timeout: const Timeout.factor(2), () {
      expect(
        guard.shouldSuppress(
          triggerAuthorId: '',
          targetAgentId: '',
          isAgentAuthor: true,
        ),
        isTrue,
      );
    });

    test(
        'suppression when isAgentAuthor=false but participants is an empty set',
        timeout: const Timeout.factor(2), () {
      expect(
        guard.shouldSuppress(
          triggerAuthorId: 'agent-1',
          targetAgentId: 'agent-2',
          isAgentAuthor: false,
          recentAgentParticipants: {},
        ),
        isFalse,
      );
    });

    test('human author, participants null — not suppressed',
        timeout: const Timeout.factor(2), () {
      expect(
        guard.shouldSuppress(
          triggerAuthorId: 'user-1',
          targetAgentId: 'agent-1',
          isAgentAuthor: false,
          recentAgentParticipants: null,
        ),
        isFalse,
      );
    });
  });
}
