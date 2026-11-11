import 'dart:async';
import 'dart:convert';

import 'package:cc_domain/features/dispatch/domain/ports/commit_signing_port.dart';
import 'package:cc_host/cc_host.dart' show CcHostLog;
import 'package:cc_infra/cc_infra.dart' show SshSigningKey;
import 'package:cc_server_core/src/file_secrets_store.dart';

/// A person's commit signing key, as clients see it: never the private half.
class CommitSigningKeyInfo {
  /// Creates the description.
  const CommitSigningKeyInfo({
    required this.publicKey,
    required this.fingerprint,
    required this.createdAt,
  });

  /// `ssh-ed25519 <base64>`: what the person adds to their forge account as
  /// a signing key.
  final String publicKey;

  /// `SHA256:<base64>`, as forges list the key.
  final String fingerprint;

  /// When the key was created.
  final DateTime createdAt;
}

/// Each person's commit signing key ([CommitSigningPort]).
///
/// A person who wants their commits verified asks the server for a key
/// ([create]) and adds its public half to their own forge account as a
/// **signing key**. Nothing registers it for them: the forge then shows a
/// commit as verified only because that person chose to trust this server's
/// key, and they can withdraw that on the forge at any time. One key per
/// person per server, for every workspace and forge.
///
/// The private half (a 32-byte Ed25519 seed) lives in the server's 0600
/// secrets file under [keyFor] and is used only by [sign]. It is never
/// returned over RPC, never logged and never enters a sandbox: a run's git
/// posts the commit to the agent run gateway, which signs it here.
final class CommitSigningKeys implements CommitSigningPort {
  /// Creates the store over the server's secrets file.
  CommitSigningKeys(this._secrets, {DateTime Function()? now})
    : _now = now ?? DateTime.now;

  final FileSecretsStore _secrets;
  final DateTime Function() _now;

  /// Parsed keys by their stored record, so a signature does not re-derive
  /// the key pair. Bounded: one entry per person who signs.
  final Map<String, _StoredKey> _parsed = {};

  /// The last create or delete per person, so two at once (a double click,
  /// two clients) run one after the other: the second create then finds the
  /// first one's key instead of overwriting it.
  final Map<String, Future<void>> _writes = {};

  /// Secrets-file key of [userId]'s signing key.
  static String keyFor(String userId) => 'user_commit_signing_$userId';

  /// [userId]'s signing key, or null when they have none.
  Future<CommitSigningKeyInfo?> describe(String userId) async =>
      (await _read(userId))?.info;

  /// Creates [userId]'s signing key and returns it. Throws [StateError] when
  /// they already have one: a key a forge account trusts is replaced only by
  /// deleting it first, deliberately.
  // Async so that a refused user id is the future's error, like every other
  // failure of this call; the write is still queued before the first await.
  Future<CommitSigningKeyInfo> create(String userId) async {
    if (userId.isEmpty) {
      throw ArgumentError.value(userId, 'userId', 'must name a person');
    }
    return _serialized(userId, () => _create(userId));
  }

  Future<CommitSigningKeyInfo> _create(String userId) async {
    if (await _read(userId) != null) {
      throw StateError('This person already has a commit signing key.');
    }
    final key = await SshSigningKey.generate();
    final createdAt = _now().toUtc();
    await _secrets.writePsk(
      keyFor(userId),
      jsonEncode({
        'seed': base64.encode(key.seed),
        'public_key': key.publicKey,
        'created_at': createdAt.toIso8601String(),
      }),
    );
    CcHostLog.info(
      'commit signing: created a key for user $userId (${key.fingerprint})',
    );
    return CommitSigningKeyInfo(
      publicKey: key.publicKey,
      fingerprint: key.fingerprint,
      createdAt: createdAt,
    );
  }

  /// Deletes [userId]'s signing key. Returns whether there was one. Commits
  /// are unsigned from then on; the public half on their forge account is
  /// theirs to remove.
  Future<bool> delete(String userId) =>
      _serialized(userId, () => _delete(userId));

  Future<bool> _delete(String userId) async {
    final existing = await _read(userId);
    await _secrets.deletePsk(keyFor(userId));
    _parsed.removeWhere((_, key) => key.userId == userId);
    if (existing != null) {
      CcHostLog.info(
        'commit signing: deleted the key of user $userId '
        '(${existing.info.fingerprint})',
      );
    }
    return existing != null;
  }

  /// Runs [write] after every earlier create or delete for [userId] ended.
  Future<T> _serialized<T>(String userId, Future<T> Function() write) {
    final previous = _writes[userId] ?? Future<void>.value();
    final result = previous.then((_) => write());
    final settled = result.then<void>((_) {}, onError: (Object _) {});
    _writes[userId] = settled;
    unawaited(
      settled.whenComplete(() {
        if (identical(_writes[userId], settled)) {
          _writes.remove(userId);
        }
      }),
    );
    return result;
  }

  @override
  Future<String?> publicKeyOf(String userId) async =>
      (await _read(userId))?.info.publicKey;

  @override
  Future<String> sign(
    String userId,
    String publicKey,
    List<int> commit,
  ) async {
    final key = await _read(userId);
    if (key == null) {
      throw const CommitSigningUnavailable(
        'this person has no commit signing key any more.',
      );
    }
    if (key.info.publicKey != publicKey) {
      throw const CommitSigningUnavailable(
        'this person\'s commit signing key changed.',
      );
    }
    return key.key.sign(commit);
  }

  Future<_StoredKey?> _read(String userId) async {
    if (userId.isEmpty) {
      return null;
    }
    final raw = await _secrets.readFresh(keyFor(userId));
    if (raw == null || raw.isEmpty) {
      return null;
    }
    final known = _parsed[raw];
    if (known != null) {
      return known;
    }
    try {
      final json = jsonDecode(raw);
      if (json is! Map) {
        throw const FormatException('not an object');
      }
      final seed = json['seed'];
      final createdAt = json['created_at'];
      if (seed is! String || createdAt is! String) {
        throw const FormatException('missing fields');
      }
      final key = await SshSigningKey.fromSeed(base64.decode(seed));
      if (key.publicKey != json['public_key']) {
        throw const FormatException('public key does not match the seed');
      }
      final stored = _StoredKey(
        userId,
        key,
        CommitSigningKeyInfo(
          publicKey: key.publicKey,
          fingerprint: key.fingerprint,
          createdAt: DateTime.parse(createdAt).toUtc(),
        ),
      );
      if (_parsed.length >= 512) {
        _parsed.clear();
      }
      return _parsed[raw] = stored;
    } on Object catch (e) {
      // An unreadable record signs nothing: the person sees "no key" and
      // creates a new one. The value itself is never logged.
      CcHostLog.warning(
        'commit signing: the stored key of user $userId is unreadable '
        '(${e.runtimeType}); treating it as absent.',
      );
      return null;
    }
  }
}

class _StoredKey {
  const _StoredKey(this.userId, this.key, this.info);

  final String userId;
  final SshSigningKey key;
  final CommitSigningKeyInfo info;
}
