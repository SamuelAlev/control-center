import 'package:cc_infra/src/rigs/worktree_sync.dart';
import 'package:test/test.dart';

/// The sync-in exclusion list is a SECURITY surface, not a size optimisation.
///
/// Everything it does not name is streamed into a guest an agent drives and a
/// human may not be watching. The list shipped as `*.pem` + `*.key` + `.env`,
/// which covers a certificate and misses the two files that matter most: an
/// SSH private key is called `id_rsa` or `id_ed25519` and matches neither
/// pattern. This test pins the names so a future cleanup that "tidies" the
/// list has to argue for each deletion.
void main() {
  group('worktreeSyncExcludes', () {
    test('excludes SSH private keys by name', () {
      // The original hole: no extension to match on.
      for (final name in const [
        'id_rsa',
        'id_dsa',
        'id_ecdsa',
        'id_ed25519',
      ]) {
        expect(worktreeSyncExcludes, contains(name));
      }
    });

    test('excludes the extensionless credential files', () {
      for (final name in const [
        '.netrc',
        '.npmrc',
        '.envrc',
        '.git-credentials',
        '.pypirc',
      ]) {
        expect(worktreeSyncExcludes, contains(name));
      }
    });

    test('excludes the tool config dirs that hold long-lived tokens', () {
      for (final name in const [
        '.ssh',
        '.gnupg',
        '.aws',
        '.docker',
        '.kube',
        '.gcloud',
      ]) {
        expect(worktreeSyncExcludes, contains(name));
      }
    });

    test('keeps the original extension patterns', () {
      expect(
        worktreeSyncExcludes,
        containsAll(const ['.env', '.env.*', '*.pem', '*.key']),
      );
    });

    test('every pattern stays UNANCHORED', () {
      // GNU tar only matches a `./`-prefixed pattern at the archive root, so
      // an anchored form shipped every NESTED `.env` into the guest. A bare
      // component name matches at any depth under both bsdtar and GNU tar.
      for (final pattern in worktreeSyncExcludes) {
        expect(
          pattern.startsWith('./'),
          isFalse,
          reason:
              '"$pattern" is anchored to the archive root, so it will not '
              'match the same file one directory down.',
        );
        expect(pattern.startsWith('/'), isFalse, reason: pattern);
      }
    });

    test('has no duplicates', () {
      expect(worktreeSyncExcludes.toSet().length, worktreeSyncExcludes.length);
    });
  });
}
