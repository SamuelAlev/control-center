import 'dart:io';

import 'package:test/test.dart';

/// Non-agentRun JobKinds are lease-plumbing probes, not real runners
/// (QUALITY.md P1.8). This pins the dispatch so a new kind cannot silently
/// inherit `_executeProbe` without naming it.
void main() {
  test('non-agentRun kinds dispatch to _executeProbe', () {
    final file = File('${_pkgRoot()}/lib/src/job_executor.dart');
    expect(file.existsSync(), isTrue);
    final src = file.readAsStringSync();
    for (final kind in [
      'pipelineStep',
      'codeIndex',
      'goldenRender',
      'benchmark',
      'evalBatch',
    ]) {
      expect(
        src.contains('case JobKind.$kind:'),
        isTrue,
        reason: 'JobKind.$kind must stay in the executor switch',
      );
    }
    expect(
      src.contains('return _executeProbe(workDir, kind);'),
      isTrue,
      reason:
          'Non-agentRun kinds must stay on _executeProbe until a real runner '
          'lands. Do not let them fall through to agentRun.',
    );
  });
}

String _pkgRoot() {
  var dir = Directory.current;
  while (true) {
    if (File('${dir.path}/lib/src/job_executor.dart').existsSync() &&
        File('${dir.path}/pubspec.yaml').existsSync()) {
      return dir.path;
    }
    final parent = dir.parent;
    if (parent.path == dir.path) {
      return Directory.current.path;
    }
    dir = parent;
  }
}
