import 'package:control_center/features/dashboard/domain/entities/dashboard_status.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('DashboardStatus constructor', () {
    test('creates with zero count', () {
      const status = DashboardStatus(totalWorkspaces: 0);
      expect(status.totalWorkspaces, 0);
    });

    test('creates with non-zero count', () {
      const status = DashboardStatus(totalWorkspaces: 10);
      expect(status.totalWorkspaces, 10);
    });

    test('throws assertion error for negative totalWorkspaces', () {
      expect(
        () => DashboardStatus(totalWorkspaces: -1),
        throwsA(isA<AssertionError>()),
      );
    });
  });

  group('DashboardStatus == and hashCode', () {
    test('identical statuses are equal', () {
      const a = DashboardStatus(totalWorkspaces: 5);
      const b = DashboardStatus(totalWorkspaces: 5);
      expect(a, equals(b));
      expect(a.hashCode, equals(b.hashCode));
    });

    test('different total workspaces makes unequal', () {
      const a = DashboardStatus(totalWorkspaces: 5);
      const b = DashboardStatus(totalWorkspaces: 4);
      expect(a, isNot(equals(b)));
    });

    test('self equality', () {
      const a = DashboardStatus(totalWorkspaces: 1);
      expect(a, equals(a));
    });
  });

  group('DashboardStatus toString', () {
    test('produces expected format', () {
      const status = DashboardStatus(totalWorkspaces: 5);
      expect(
        status.toString(),
        'DashboardStatus(workspaces: 5)',
      );
    });
  });

  group('ActiveProcessInfo constructor', () {
    test('creates with all fields', () {
      final info = ActiveProcessInfo(
        agentName: 'kilo',
        workspaceName: 'my-workspace',
        pid: 12345,
        command: 'claude',
        startTime: DateTime(2025),
      );
      expect(info.agentName, 'kilo');
      expect(info.workspaceName, 'my-workspace');
      expect(info.pid, 12345);
      expect(info.command, 'claude');
    });
  });

  group('ActiveProcessInfo == and hashCode', () {
    final time = DateTime(2025, 1, 15);

    test('identical processes are equal', () {
      final a = ActiveProcessInfo(
        agentName: 'kilo',
        workspaceName: 'ws-1',
        pid: 1,
        command: 'claude',
        startTime: time,
      );
      final b = ActiveProcessInfo(
        agentName: 'kilo',
        workspaceName: 'ws-1',
        pid: 1,
        command: 'claude',
        startTime: time,
      );
      expect(a, equals(b));
      expect(a.hashCode, equals(b.hashCode));
    });

    test('different pid makes unequal', () {
      final a = ActiveProcessInfo(
        agentName: 'kilo',
        workspaceName: 'ws-1',
        pid: 1,
        command: 'claude',
        startTime: time,
      );
      final b = ActiveProcessInfo(
        agentName: 'kilo',
        workspaceName: 'ws-1',
        pid: 2,
        command: 'claude',
        startTime: time,
      );
      expect(a, isNot(equals(b)));
    });

    test('self equality', () {
      final a = ActiveProcessInfo(
        agentName: 'kilo',
        workspaceName: 'ws-1',
        pid: 1,
        command: 'claude',
        startTime: time,
      );
      expect(a, equals(a));
    });
  });
}
