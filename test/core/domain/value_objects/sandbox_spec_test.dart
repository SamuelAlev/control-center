import 'package:control_center/core/domain/value_objects/conversation_mode.dart';
import 'package:control_center/core/domain/value_objects/sandbox_spec.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('SandboxBindMount', () {
    test('constructs with required fields, default readOnly is false', () {
      const mount = SandboxBindMount(
        hostPath: '/host/path',
        guestPath: '/guest/path',
      );

      expect(mount.hostPath, '/host/path');
      expect(mount.guestPath, '/guest/path');
      expect(mount.readOnly, false);
    });

    test('constructs with readOnly true', () {
      const mount = SandboxBindMount(
        hostPath: '/host',
        guestPath: '/guest',
        readOnly: true,
      );

      expect(mount.readOnly, true);
    });

    test('equal when all fields match', () {
      const a = SandboxBindMount(
        hostPath: '/h',
        guestPath: '/g',
        readOnly: true,
      );
      const b = SandboxBindMount(
        hostPath: '/h',
        guestPath: '/g',
        readOnly: true,
      );

      expect(a, equals(b));
    });

    test('not equal when hostPath differs', () {
      const a = SandboxBindMount(hostPath: '/a', guestPath: '/g');
      const b = SandboxBindMount(hostPath: '/b', guestPath: '/g');

      expect(a, isNot(equals(b)));
    });

    test('not equal when guestPath differs', () {
      const a = SandboxBindMount(hostPath: '/h', guestPath: '/a');
      const b = SandboxBindMount(hostPath: '/h', guestPath: '/b');

      expect(a, isNot(equals(b)));
    });

    test('not equal when readOnly differs', () {
      const a = SandboxBindMount(hostPath: '/h', guestPath: '/g', readOnly: false);
      const b = SandboxBindMount(hostPath: '/h', guestPath: '/g', readOnly: true);

      expect(a, isNot(equals(b)));
    });

    test('hashCode consistent with equality', () {
      const a = SandboxBindMount(hostPath: '/h', guestPath: '/g', readOnly: true);
      const b = SandboxBindMount(hostPath: '/h', guestPath: '/g', readOnly: true);

      expect(a.hashCode, equals(b.hashCode));
    });

    test('hashCode differs for unequal instances', () {
      const a = SandboxBindMount(hostPath: '/a', guestPath: '/g');
      const b = SandboxBindMount(hostPath: '/b', guestPath: '/g');

      expect(a.hashCode, isNot(equals(b.hashCode)));
    });
  });

  group('SandboxSpec', () {
    test('defaults: networkEnabled=true, egressAllowlist=[], mode=chat, agentId=null, guestWorkdir=null', () {
      const spec = SandboxSpec(
        sessionId: 's1',
        workspaceId: 'w1',
        bindMounts: [],
      );

      expect(spec.networkEnabled, true);
      expect(spec.egressAllowlist, isEmpty);
      expect(spec.mode, ConversationMode.chat);
      expect(spec.agentId, isNull);
      expect(spec.guestWorkdir, isNull);
    });

    test('constructs with all fields', () {
      const mount = SandboxBindMount(hostPath: '/h', guestPath: '/g');
      const spec = SandboxSpec(
        sessionId: 's1',
        workspaceId: 'w1',
        bindMounts: [mount],
        agentId: 'agent-1',
        networkEnabled: false,
        egressAllowlist: ['*.example.com'],
        guestWorkdir: '/work',
        mode: ConversationMode.plan,
      );

      expect(spec.sessionId, 's1');
      expect(spec.workspaceId, 'w1');
      expect(spec.bindMounts, const [mount]);
      expect(spec.agentId, 'agent-1');
      expect(spec.networkEnabled, false);
      expect(spec.egressAllowlist, const ['*.example.com']);
      expect(spec.guestWorkdir, '/work');
      expect(spec.mode, ConversationMode.plan);
    });

    test('equal when all fields match', () {
      const mount = SandboxBindMount(hostPath: '/h', guestPath: '/g');
      const a = SandboxSpec(
        sessionId: 's1',
        workspaceId: 'w1',
        bindMounts: [mount],
        agentId: 'a1',
        networkEnabled: false,
        egressAllowlist: ['*.example.com'],
        guestWorkdir: '/work',
        mode: ConversationMode.review,
      );
      const b = SandboxSpec(
        sessionId: 's1',
        workspaceId: 'w1',
        bindMounts: [mount],
        agentId: 'a1',
        networkEnabled: false,
        egressAllowlist: ['*.example.com'],
        guestWorkdir: '/work',
        mode: ConversationMode.review,
      );

      expect(a, equals(b));
    });

    test('not equal when sessionId differs', () {
      const a = SandboxSpec(sessionId: 's1', workspaceId: 'w1', bindMounts: []);
      const b = SandboxSpec(sessionId: 's2', workspaceId: 'w1', bindMounts: []);

      expect(a, isNot(equals(b)));
    });

    test('not equal when workspaceId differs', () {
      const a = SandboxSpec(sessionId: 's1', workspaceId: 'w1', bindMounts: []);
      const b = SandboxSpec(sessionId: 's1', workspaceId: 'w2', bindMounts: []);

      expect(a, isNot(equals(b)));
    });

    test('not equal when agentId differs', () {
      const a = SandboxSpec(sessionId: 's1', workspaceId: 'w1', bindMounts: [], agentId: 'a1');
      const b = SandboxSpec(sessionId: 's1', workspaceId: 'w1', bindMounts: [], agentId: 'a2');

      expect(a, isNot(equals(b)));
    });

    test('not equal when networkEnabled differs', () {
      const a = SandboxSpec(sessionId: 's1', workspaceId: 'w1', bindMounts: [], networkEnabled: true);
      const b = SandboxSpec(sessionId: 's1', workspaceId: 'w1', bindMounts: [], networkEnabled: false);

      expect(a, isNot(equals(b)));
    });

    test('not equal when bindMounts differ', () {
      const m1 = SandboxBindMount(hostPath: '/a', guestPath: '/a');
      const m2 = SandboxBindMount(hostPath: '/b', guestPath: '/b');
      const a = SandboxSpec(sessionId: 's1', workspaceId: 'w1', bindMounts: [m1]);
      const b = SandboxSpec(sessionId: 's1', workspaceId: 'w1', bindMounts: [m2]);

      expect(a, isNot(equals(b)));
    });

    test('not equal when egressAllowlist differs', () {
      const a = SandboxSpec(sessionId: 's1', workspaceId: 'w1', bindMounts: [], egressAllowlist: ['a.com']);
      const b = SandboxSpec(sessionId: 's1', workspaceId: 'w1', bindMounts: [], egressAllowlist: ['b.com']);

      expect(a, isNot(equals(b)));
    });

    test('not equal when guestWorkdir differs', () {
      const a = SandboxSpec(sessionId: 's1', workspaceId: 'w1', bindMounts: [], guestWorkdir: '/a');
      const b = SandboxSpec(sessionId: 's1', workspaceId: 'w1', bindMounts: [], guestWorkdir: '/b');

      expect(a, isNot(equals(b)));
    });

    test('not equal when mode differs', () {
      const a = SandboxSpec(sessionId: 's1', workspaceId: 'w1', bindMounts: [], mode: ConversationMode.chat);
      const b = SandboxSpec(sessionId: 's1', workspaceId: 'w1', bindMounts: [], mode: ConversationMode.plan);

      expect(a, isNot(equals(b)));
    });

    test('hashCode consistent with equality', () {
      const mount = SandboxBindMount(hostPath: '/h', guestPath: '/g');
      const a = SandboxSpec(
        sessionId: 's1',
        workspaceId: 'w1',
        bindMounts: [mount],
        egressAllowlist: ['*.example.com'],
      );
      const b = SandboxSpec(
        sessionId: 's1',
        workspaceId: 'w1',
        bindMounts: [mount],
        egressAllowlist: ['*.example.com'],
      );

      expect(a.hashCode, equals(b.hashCode));
    });

    test('hashCode differs for unequal instances', () {
      const a = SandboxSpec(sessionId: 's1', workspaceId: 'w1', bindMounts: []);
      const b = SandboxSpec(sessionId: 's2', workspaceId: 'w1', bindMounts: []);

      expect(a.hashCode, isNot(equals(b.hashCode)));
    });
  });
}
