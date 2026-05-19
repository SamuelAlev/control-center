import 'package:control_center/core/domain/value_objects/sandbox_event.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('SandboxEventType', () {
    test('has all 7 values', () {
      expect(SandboxEventType.values, hasLength(7));
      expect(SandboxEventType.values, containsAll([
        SandboxEventType.stdout,
        SandboxEventType.stderr,
        SandboxEventType.exit,
        SandboxEventType.starting,
        SandboxEventType.ready,
        SandboxEventType.killed,
        SandboxEventType.violation,
      ]));
    });
  });

  group('SandboxEvent', () {
    test('default content is empty string', () {
      const event = SandboxEvent(type: SandboxEventType.ready);
      expect(event.content, '');
      expect(event.exitCode, isNull);
      expect(event.violation, isNull);
    });

    test('equality with same fields', () {
      const a = SandboxEvent(type: SandboxEventType.stdout, content: 'hello');
      const b = SandboxEvent(type: SandboxEventType.stdout, content: 'hello');
      expect(a, equals(b));
    });

    test('inequality with different type', () {
      const a = SandboxEvent(type: SandboxEventType.stdout, content: 'x');
      const b = SandboxEvent(type: SandboxEventType.stderr, content: 'x');
      expect(a, isNot(equals(b)));
    });

    test('inequality with different content', () {
      const a = SandboxEvent(type: SandboxEventType.stdout, content: 'a');
      const b = SandboxEvent(type: SandboxEventType.stdout, content: 'b');
      expect(a, isNot(equals(b)));
    });

    test('inequality with different exitCode', () {
      const a = SandboxEvent(type: SandboxEventType.exit, exitCode: 0);
      const b = SandboxEvent(type: SandboxEventType.exit, exitCode: 1);
      expect(a, isNot(equals(b)));
    });

    test('inequality with different violation', () {
      const v = SandboxViolation(action: 'file-read', target: '/etc/passwd');
      const a = SandboxEvent(type: SandboxEventType.violation, violation: v);
      const b = SandboxEvent(type: SandboxEventType.violation);
      expect(a, isNot(equals(b)));
    });

    test('hashCode consistency', () {
      const a = SandboxEvent(type: SandboxEventType.exit, content: '', exitCode: 42);
      const b = SandboxEvent(type: SandboxEventType.exit, content: '', exitCode: 42);
      expect(a.hashCode, equals(b.hashCode));
    });

    test('with violation compares correctly', () {
      const violation = SandboxViolation(
        action: 'network-outbound',
        target: 'example.com',
        suggestedCapability: 'canNetwork',
        raw: 'deny network-outbound example.com',
      );
      const a = SandboxEvent(type: SandboxEventType.violation, violation: violation);
      const b = SandboxEvent(type: SandboxEventType.violation, violation: violation);
      expect(a, equals(b));
      expect(a.hashCode, equals(b.hashCode));
    });
  });

  group('SandboxViolation', () {
    test('construction with all fields', () {
      const v = SandboxViolation(
        action: 'file-write',
        target: '/tmp/log',
        suggestedCapability: 'canWriteTemp',
        raw: 'deny file-write /tmp/log',
      );
      expect(v.action, 'file-write');
      expect(v.target, '/tmp/log');
      expect(v.suggestedCapability, 'canWriteTemp');
      expect(v.raw, 'deny file-write /tmp/log');
    });

    test('construction with only required fields', () {
      const v = SandboxViolation(action: 'exec', target: '/bin/sh');
      expect(v.suggestedCapability, isNull);
      expect(v.raw, isNull);
    });

    test('equality with same fields', () {
      const a = SandboxViolation(
        action: 'file-read',
        target: '/etc/hosts',
        suggestedCapability: 'canReadEtc',
        raw: 'deny file-read /etc/hosts',
      );
      const b = SandboxViolation(
        action: 'file-read',
        target: '/etc/hosts',
        suggestedCapability: 'canReadEtc',
        raw: 'deny file-read /etc/hosts',
      );
      expect(a, equals(b));
    });

    test('inequality with different action', () {
      const a = SandboxViolation(action: 'file-read', target: '/x');
      const b = SandboxViolation(action: 'file-write', target: '/x');
      expect(a, isNot(equals(b)));
    });

    test('inequality with different target', () {
      const a = SandboxViolation(action: 'exec', target: '/bin/sh');
      const b = SandboxViolation(action: 'exec', target: '/bin/bash');
      expect(a, isNot(equals(b)));
    });

    test('inequality with different suggestedCapability', () {
      const a = SandboxViolation(action: 'net', target: 'x', suggestedCapability: 'a');
      const b = SandboxViolation(action: 'net', target: 'x', suggestedCapability: 'b');
      expect(a, isNot(equals(b)));
    });

    test('inequality with different raw', () {
      const a = SandboxViolation(action: 'net', target: 'x', raw: 'line1');
      const b = SandboxViolation(action: 'net', target: 'x', raw: 'line2');
      expect(a, isNot(equals(b)));
    });

    test('hashCode consistency', () {
      const a = SandboxViolation(
        action: 'exec',
        target: '/bin/sh',
        suggestedCapability: 'canExec',
        raw: 'deny exec /bin/sh',
      );
      const b = SandboxViolation(
        action: 'exec',
        target: '/bin/sh',
        suggestedCapability: 'canExec',
        raw: 'deny exec /bin/sh',
      );
      expect(a.hashCode, equals(b.hashCode));
    });
  });
}
