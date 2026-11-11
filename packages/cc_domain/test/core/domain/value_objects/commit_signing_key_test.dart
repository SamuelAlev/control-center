import 'package:cc_domain/core/domain/value_objects/commit_signing_key.dart';
import 'package:test/test.dart';

void main() {
  const publicKey = 'ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIA';

  test('parses the wire shape and keeps the instant in UTC', () {
    final key = CommitSigningKey.tryParse({
      'public_key': publicKey,
      'fingerprint': 'SHA256:abc',
      'created_at': '2026-11-10T09:30:00.000Z',
    });
    expect(key, isNotNull);
    expect(key!.publicKey, publicKey);
    expect(key.fingerprint, 'SHA256:abc');
    expect(key.createdAt, DateTime.utc(2026, 11, 10, 9, 30));
    expect(key.createdAt.isUtc, isTrue);
  });

  test('null and malformed answers read as no key', () {
    expect(CommitSigningKey.tryParse(null), isNull);
    expect(CommitSigningKey.tryParse('nope'), isNull);
    expect(
      CommitSigningKey.tryParse({
        'public_key': publicKey,
        'fingerprint': 'SHA256:abc',
      }),
      isNull,
    );
    expect(
      CommitSigningKey.tryParse({
        'public_key': 'not a key',
        'fingerprint': 'SHA256:abc',
        'created_at': '2026-11-10T09:30:00Z',
      }),
      isNull,
    );
  });

  test('construction refuses anything but an SSH public key line', () {
    expect(
      () => CommitSigningKey(
        publicKey: '-----BEGIN OPENSSH PRIVATE KEY-----',
        fingerprint: 'SHA256:abc',
        createdAt: DateTime.utc(2026),
      ),
      throwsArgumentError,
    );
    expect(
      () => CommitSigningKey(
        publicKey: publicKey,
        fingerprint: ' ',
        createdAt: DateTime.utc(2026),
      ),
      throwsArgumentError,
    );
  });

  test('equality is by value', () {
    CommitSigningKey make() => CommitSigningKey(
      publicKey: publicKey,
      fingerprint: 'SHA256:abc',
      createdAt: DateTime.utc(2026),
    );
    expect(make(), make());
    expect(make().hashCode, make().hashCode);
  });
}
