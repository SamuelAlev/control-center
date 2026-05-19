import 'package:control_center/core/domain/entities/active_process_info.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final testStartTime = DateTime(2024, 3, 15, 10, 30, 0);

  ActiveProcessInfo createProcess({
    String agentName = 'agent-1',
    String workspaceName = 'ws-1',
    int pid = 1234,
    String command = 'claude --agent agent-1',
    DateTime? startTime,
  }) {
    return ActiveProcessInfo(
      agentName: agentName,
      workspaceName: workspaceName,
      pid: pid,
      command: command,
      startTime: startTime ?? testStartTime,
    );
  }

  group('ActiveProcessInfo', () {

    group('constructor', () {
      test('creates with all required fields', () {
        final info = createProcess();
        expect(info.agentName, 'agent-1');
        expect(info.workspaceName, 'ws-1');
        expect(info.pid, 1234);
        expect(info.command, 'claude --agent agent-1');
        expect(info.startTime, testStartTime);
      });

      test('creates with different values', () {
        final info = ActiveProcessInfo(
          agentName: 'reviewer',
          workspaceName: 'production',
          pid: 99999,
          command: 'claude review --pr 42',
          startTime: DateTime(2025, 1, 1),
        );
        expect(info.agentName, 'reviewer');
        expect(info.workspaceName, 'production');
        expect(info.pid, 99999);
        expect(info.command, 'claude review --pr 42');
        expect(info.startTime, DateTime(2025, 1, 1));
      });
    });

    group('== and hashCode', () {
      test('== returns true for identical values', () {
        final a = createProcess();
        final b = createProcess();
        expect(a, equals(b));
      });

      test('== returns true for same instance (identical)', () {
        final info = createProcess();
        expect(info, equals(info));
      });

      test('== returns false for different agentName', () {
        final a = createProcess(agentName: 'agent-1');
        final b = createProcess(agentName: 'agent-2');
        expect(a, isNot(equals(b)));
      });

      test('== returns false for different workspaceName', () {
        final a = createProcess(workspaceName: 'ws-1');
        final b = createProcess(workspaceName: 'ws-2');
        expect(a, isNot(equals(b)));
      });

      test('== returns false for different pid', () {
        final a = createProcess(pid: 100);
        final b = createProcess(pid: 200);
        expect(a, isNot(equals(b)));
      });

      test('== returns false for different command', () {
        final a = createProcess(command: 'cmd-a');
        final b = createProcess(command: 'cmd-b');
        expect(a, isNot(equals(b)));
      });

      test('== returns false for different startTime', () {
        final a = createProcess(startTime: DateTime(2024, 1, 1));
        final b = createProcess(startTime: DateTime(2024, 2, 1));
        expect(a, isNot(equals(b)));
      });

      test('== returns false for non-ActiveProcessInfo', () {
        final info = createProcess();
        expect(info, isNot(equals('not a process')));
      });

      test('hashCode matches for equal instances', () {
        final a = createProcess();
        final b = createProcess();
        expect(a.hashCode, equals(b.hashCode));
      });

      test('hashCode differs for different instances', () {
        final a = createProcess(pid: 100);
        final b = createProcess(pid: 200);
        expect(a.hashCode, isNot(equals(b.hashCode)));
      });
    });
  });
}
