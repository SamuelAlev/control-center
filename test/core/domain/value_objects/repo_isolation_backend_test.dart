import 'package:control_center/core/domain/value_objects/repo_isolation_backend.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('RepoIsolationBackend', () {
    test('fromName("rift") returns rift', () {
      expect(RepoIsolationBackend.fromName('rift'), RepoIsolationBackend.rift);
    });

    test('fromName("gitWorktree") returns gitWorktree', () {
      expect(
        RepoIsolationBackend.fromName('gitWorktree'),
        RepoIsolationBackend.gitWorktree,
      );
    });

    test('fromName(null) returns rift (default)', () {
      expect(RepoIsolationBackend.fromName(null), RepoIsolationBackend.rift);
    });

    test('fromName("unknown") returns rift (default)', () {
      expect(
        RepoIsolationBackend.fromName('unknown'),
        RepoIsolationBackend.rift,
      );
    });

    test('values have correct names', () {
      expect(RepoIsolationBackend.rift.name, 'rift');
      expect(RepoIsolationBackend.gitWorktree.name, 'gitWorktree');
    });
  });
}
