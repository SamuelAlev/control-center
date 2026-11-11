/// A person's commit signing key as a client sees it
/// (`credentials.commitSigningKey`): only the public half, its fingerprint
/// and when it was made. The private half never leaves the server.
///
/// The person adds [publicKey] to their own forge account as a **signing
/// key**; the forge then shows the commits the server signs for them as
/// verified, for as long as the key stays on that account.
final class CommitSigningKey {
  /// Creates a [CommitSigningKey]. Throws [ArgumentError] when [publicKey]
  /// is not an OpenSSH public key line or [fingerprint] is empty.
  CommitSigningKey({
    required this.publicKey,
    required this.fingerprint,
    required DateTime createdAt,
  }) : createdAt = createdAt.toUtc() {
    if (!publicKey.startsWith('ssh-') || !publicKey.contains(' ')) {
      throw ArgumentError.value(publicKey, 'publicKey', 'not an SSH key');
    }
    if (fingerprint.trim().isEmpty) {
      throw ArgumentError.value(fingerprint, 'fingerprint', 'empty');
    }
  }

  /// Reads the `key` object of a `credentials.*CommitSigningKey` answer;
  /// null when it is absent or malformed.
  static CommitSigningKey? tryParse(Object? json) {
    if (json is! Map) {
      return null;
    }
    final publicKey = json['public_key'];
    final fingerprint = json['fingerprint'];
    final createdAt = DateTime.tryParse(json['created_at'] as String? ?? '');
    if (publicKey is! String || fingerprint is! String || createdAt == null) {
      return null;
    }
    try {
      return CommitSigningKey(
        publicKey: publicKey,
        fingerprint: fingerprint,
        createdAt: createdAt,
      );
    } on ArgumentError {
      return null;
    }
  }

  /// `ssh-ed25519 <base64>`: what the person pastes into their forge account.
  final String publicKey;

  /// `SHA256:<base64>`, as forges list the key.
  final String fingerprint;

  /// When the key was created, in UTC.
  final DateTime createdAt;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CommitSigningKey &&
          publicKey == other.publicKey &&
          fingerprint == other.fingerprint &&
          createdAt == other.createdAt;

  @override
  int get hashCode => Object.hash(publicKey, fingerprint, createdAt);
}
