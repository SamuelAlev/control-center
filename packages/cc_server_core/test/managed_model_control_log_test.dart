import 'dart:async';

import 'package:cc_domain/features/settings/domain/model_control.dart';
import 'package:cc_server_core/src/models/managed_model_control.dart';
import 'package:dio/dio.dart';
import 'package:test/test.dart';

/// A first boot spends minutes fetching multi-hundred-megabyte models over the
/// network. These pin that the transfer NARRATES itself: silence there made a
/// slow link indistinguishable from a hung server.
void main() {
  /// Drains the control's own event stream until [predicate] holds, so a test
  /// never races the fire-and-forget install driver.
  Future<void> until(
    ManagedModelControl control,
    bool Function(ModelStatusSnapshot) predicate,
  ) =>
      control.watch().firstWhere(predicate).timeout(const Duration(seconds: 5));

  test('a real download logs start, progress and completion', () async {
    final lines = <String>[];
    final control = ManagedModelControl(
      probeInstalled: () async => false,
      runInstall: ({onProgress, cancelToken}) async {
        // Simulate a dio transfer's per-chunk firehose.
        for (var i = 0; i <= 100; i++) {
          onProgress?.call(i / 100, 'downloading');
        }
      },
      runUninstall: () async {},
      description: 'test-model, ~90 MB',
      onLog: (level, message) => lines.add('${level.name}: $message'),
    );

    await control.install();
    await until(control, (s) => s.status == ModelLifecycleStatus.installed);

    expect(lines.first, 'notice: downloading test-model, ~90 MB…');
    expect(lines.last, matches(r'^notice: installed in \d+\.\ds$'));
    expect(lines.every((l) => l.startsWith('notice: ')), isTrue);
    // Deciles, not chunks: 101 ticks must not become 101 lines. The opening 0%
    // is dropped — the download-started line above already said it.
    final progress = lines.where((l) => l.endsWith('%')).toList();
    expect(progress, hasLength(10));
    expect(progress.first, 'notice: downloading 10%');
    expect(progress.last, 'notice: downloading 100%');
  });

  test('a model already on disk logs nothing', () async {
    final lines = <String>[];
    final control = ManagedModelControl(
      probeInstalled: () async => true,
      runInstall: ({onProgress, cancelToken}) async =>
          fail('must not re-download an installed model'),
      runUninstall: () async {},
      onLog: (level, message) => lines.add(message),
    );

    await control.install();

    expect(lines, isEmpty);
  });

  test('a failed download logs at warning, not notice', () async {
    final lines = <String>[];
    final control = ManagedModelControl(
      probeInstalled: () async => false,
      runInstall: ({onProgress, cancelToken}) async =>
          throw StateError('connection reset'),
      runUninstall: () async {},
      onLog: (level, message) => lines.add('${level.name}: $message'),
    );

    await control.install();
    await until(control, (s) => s.status == ModelLifecycleStatus.error);

    expect(lines.last, contains('warning: install failed after '));
    expect(lines.last, contains('connection reset'));
  });

  test(
    'a cancelled download says so instead of looking like a failure',
    () async {
      final lines = <String>[];
      final control = ManagedModelControl(
        probeInstalled: () async => false,
        runInstall: ({onProgress, cancelToken}) async {
          final completer = Completer<void>();
          unawaited(
            cancelToken?.whenCancel.then((_) {
              completer.completeError(
                DioException.requestCancelled(
                  requestOptions: RequestOptions(),
                  reason: 'cancelled by client',
                ),
              );
            }),
          );
          return completer.future;
        },
        runUninstall: () async {},
        onLog: (level, message) => lines.add('${level.name}: $message'),
      );

      await control.install();
      await control.cancel();
      await until(
        control,
        (s) => s.status == ModelLifecycleStatus.notInstalled,
      );

      expect(lines.last, contains('notice: download cancelled after '));
    },
  );

  test('modelDescription states the size the wait is for', () {
    expect(
      modelDescription('all-MiniLM-L6-v2 (384-d)', 90 * 1024 * 1024),
      'all-MiniLM-L6-v2 (384-d), ~90 MB',
    );
  });
}
