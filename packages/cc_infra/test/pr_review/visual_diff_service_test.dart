import 'dart:io';

import 'package:cc_domain/core/domain/ports/git_command_port.dart';
import 'package:cc_domain/features/pr_review/domain/repositories/review_studio_repository.dart';
import 'package:cc_domain/features/pr_review/domain/value_objects/visual_diff.dart';
import 'package:cc_harness/cancellation.dart';
import 'package:cc_infra/src/pr_review/visual_diff_service.dart';
import 'package:cc_infra/src/util/cc_paths.dart';
import 'package:test/test.dart';

class _RecordingRepo implements VisualDiffRepository {
  final List<(String, VisualDiffSnapshot)> stored = [];
  @override
  Future<List<VisualDiffSnapshot>> forPr(
    String workspaceId,
    String prExternalId,
  ) async => const [];
  @override
  Stream<List<VisualDiffSnapshot>> watchForPr(
    String workspaceId,
    String prExternalId,
  ) async* {
    yield const [];
  }

  @override
  Future<void> upsert(String workspaceId, VisualDiffSnapshot snapshot) async {
    stored.add((workspaceId, snapshot));
  }

  @override
  Future<void> setStatus(
    String workspaceId,
    String snapshotId,
    VisualDiffStatus status,
  ) async {}
}

/// A git port that throws if called — the early-unavailable paths never reach
/// git, so this guards against accidental invocation.
class _ThrowingGit implements GitCommandPort {
  @override
  Future<GitResult> run(
    List<String> args, {
    required String workdir,
    Map<String, String>? env,
    void Function(String line)? onProgress,
    CancellationToken? cancel,
  }) async => throw StateError('git should not be called in these paths');

  @override
  Stream<String> runStreaming(
    List<String> args, {
    required String workdir,
    Map<String, String>? env,
  }) async* {
    throw StateError('git should not be called in these paths');
  }
}

Future<Directory> _tempDir() async {
  final d = await Directory.systemTemp.createTemp('visual_diff_test_');
  return d;
}

void main() {
  late Directory temp;

  setUp(() async {
    temp = await _tempDir();
  });

  tearDown(() async {
    if (temp.existsSync()) {
      await temp.delete(recursive: true);
    }
  });

  VisualDiffService service({
    required _RecordingRepo repo,
    String? flutterBinary,
  }) => VisualDiffService(
    repository: repo,
    paths: CcPaths(temp.path),
    flutterBinary: flutterBinary,
  );

  Future<File> makeFlutter() async {
    // _resolveFlutter only probes existence of the binary path (it doesn't
    // execute it), so a plain file is enough.
    final bin = File('${temp.path}/flutter');
    await bin.writeAsString('stub');
    return bin;
  }

  group('VisualDiffService.hostHasFlutter', () {
    test('true when binary path exists', () async {
      final bin = await makeFlutter();
      final svc = service(repo: _RecordingRepo(), flutterBinary: bin.path);
      expect(await svc.hostHasFlutter(), isTrue);
    });

    test('returns a bool without throwing when binary missing', () async {
      final svc = service(
        repo: _RecordingRepo(),
        flutterBinary: '/no/such/flutter',
      );
      // The host may have flutter on PATH, so we only assert no throw.
      expect(await svc.hostHasFlutter(), anyOf(true, false));
    });
  });

  group('VisualDiffService.unavailableReason', () {
    test('no Widgetbook when Flutter present but no widgetbook dep', () async {
      final bin = await makeFlutter();
      final svc = service(repo: _RecordingRepo(), flutterBinary: bin.path);
      final repoPath = '${temp.path}/repo';
      await Directory(repoPath).create(recursive: true);
      await File('$repoPath/pubspec.yaml').writeAsString('name: demo\n');
      expect(
        await svc.unavailableReason(repoPath),
        'no Widgetbook app in repo',
      );
    });

    test('null when root pubspec has widgetbook', () async {
      final bin = await makeFlutter();
      final svc = service(repo: _RecordingRepo(), flutterBinary: bin.path);
      final repoPath = '${temp.path}/repo';
      await Directory(repoPath).create(recursive: true);
      await File(
        '$repoPath/pubspec.yaml',
      ).writeAsString('name: demo\ndependencies:\n  widgetbook: ^1.0\n');
      expect(await svc.unavailableReason(repoPath), isNull);
    });

    test('null when sub-package has widgetbook', () async {
      final bin = await makeFlutter();
      final svc = service(repo: _RecordingRepo(), flutterBinary: bin.path);
      final repoPath = '${temp.path}/repo';
      final subPkg = Directory('$repoPath/packages/widget');
      await subPkg.create(recursive: true);
      await File('$repoPath/pubspec.yaml').writeAsString('name: demo\n');
      await File(
        '${subPkg.path}/pubspec.yaml',
      ).writeAsString('name: w\ndependencies:\n  widgetbook: ^1.0\n');
      expect(await svc.unavailableReason(repoPath), isNull);
    });

    test('no Widgetbook when repo path missing', () async {
      final bin = await makeFlutter();
      final svc = service(repo: _RecordingRepo(), flutterBinary: bin.path);
      expect(
        await svc.unavailableReason('${temp.path}/missing'),
        'no Widgetbook app in repo',
      );
    });

    test('widgetbook detection checks apps/ subdirectory too', () async {
      final bin = await makeFlutter();
      final svc = service(repo: _RecordingRepo(), flutterBinary: bin.path);
      final repoPath = '${temp.path}/repo';
      final subPkg = Directory('$repoPath/apps/widget');
      await subPkg.create(recursive: true);
      await File('$repoPath/pubspec.yaml').writeAsString('name: demo\n');
      await File(
        '${subPkg.path}/pubspec.yaml',
      ).writeAsString('name: w\ndependencies:\n  widgetbook: ^1.0\n');
      expect(await svc.unavailableReason(repoPath), isNull);
    });
  });

  group('VisualDiffService.compute', () {
    test('returns unavailable when no Widgetbook', () async {
      final bin = await makeFlutter();
      final repoPath = '${temp.path}/repo';
      await Directory(repoPath).create(recursive: true);
      await File('$repoPath/pubspec.yaml').writeAsString('name: demo\n');
      final svc = service(repo: _RecordingRepo(), flutterBinary: bin.path);
      final outcome = await svc.compute(
        workspaceId: 'ws',
        repoId: 'r',
        prExternalId: 'pr_1',
        repoPath: repoPath,
        git: _ThrowingGit(),
        baseSha: 'aaa',
        headSha: 'bbb',
      );
      expect(outcome.available, isFalse);
      expect(outcome.reason, 'no Widgetbook app in repo');
    });

    test(
      'returns unavailable when repo path missing and no widgetbook',
      () async {
        final bin = await makeFlutter();
        final svc = service(repo: _RecordingRepo(), flutterBinary: bin.path);
        final outcome = await svc.compute(
          workspaceId: 'ws',
          repoId: 'r',
          prExternalId: 'pr_1',
          repoPath: '${temp.path}/missing',
          git: _ThrowingGit(),
          baseSha: 'aaa',
          headSha: 'bbb',
        );
        expect(outcome.available, isFalse);
        expect(
          outcome.reason,
          anyOf('no Flutter SDK on host', 'no Widgetbook app in repo'),
        );
      },
    );
  });
}
