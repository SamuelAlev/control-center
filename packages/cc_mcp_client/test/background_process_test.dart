import 'dart:io';

import 'package:cc_mcp_client/cc_mcp_client.dart';
import 'package:test/test.dart';

void main() {
  group('BackgroundProcessManager', () {
    test('sandbox gate refuses start/restart while sandboxed', () async {
      final manager = BackgroundProcessManager(sandboxed: () => true);
      addTearDown(manager.dispose);
      expect(
        () => manager.start(command: 'echo hi'),
        throwsA(isA<BackgroundProcessException>()),
      );
    });

    test('starts, captures output, reaches ready on a pattern probe', () async {
      final manager = BackgroundProcessManager();
      addTearDown(manager.dispose);
      final info = await manager.start(
        command: r"printf 'BOOT_OK\n'; sleep 2",
        ready: const ReadyProbe(pattern: 'BOOT_OK'),
        description: 'test server',
      );
      expect(info.status, BackgroundProcessStatus.ready);
      expect(info.ready, isTrue);

      expect(manager.list(), hasLength(1));
      final logs = manager.logs(info.id);
      expect(logs, contains('BOOT_OK'));

      final stopped = await manager.stop(info.id);
      expect(stopped!.status, BackgroundProcessStatus.stopped);
    }, testOn: 'posix');

    test('status/logs return null for an unknown id', () {
      final manager = BackgroundProcessManager();
      addTearDown(manager.dispose);
      expect(manager.status('nope'), isNull);
      expect(manager.logs('nope'), isNull);
    });

    test('dispose terminates all processes', () async {
      final manager = BackgroundProcessManager();
      await manager.start(command: 'sleep 30');
      await manager.start(command: 'sleep 30');
      expect(manager.list(), hasLength(2));
      await manager.dispose();
      expect(manager.list(), isEmpty);
    }, testOn: 'posix');
  });

  group('BackgroundProcessTool', () {
    test('start is exec-tier, list is read-tier', () {
      final tool = BackgroundProcessTool(
        manager: BackgroundProcessManager(),
      );
      expect(tool.toolApproval({'action': 'start'}).tier, CapabilityTier.exec);
      expect(tool.toolApproval({'action': 'list'}).tier, CapabilityTier.read);
    });

    test('list action returns process snapshots', () async {
      final manager = BackgroundProcessManager();
      addTearDown(manager.dispose);
      final tool = BackgroundProcessTool(manager: manager);
      final result = await tool.run({'action': 'list'});
      expect(result.isError, isFalse);
      expect(result.content.first.text, contains('processes'));
    });

    test('start without command errors', () async {
      final tool = BackgroundProcessTool(
        manager: BackgroundProcessManager(),
      );
      final result = await tool.run({'action': 'start'});
      expect(result.isError, isTrue);
    });
  });

  // Ensure the platform check above is meaningful on the dev OS.
  test('platform sanity', () {
    expect(Platform.isWindows || Platform.isMacOS || Platform.isLinux, isTrue);
  });
}
