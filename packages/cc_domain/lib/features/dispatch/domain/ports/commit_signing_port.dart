/// Signs git commits for the people who set up a commit signing key.
///
/// The private key never leaves the implementation: callers hand over the
/// exact commit object and get back its signature.
abstract interface class CommitSigningPort {
  /// The `ssh-ed25519 <base64>` public key [userId]'s commits are signed
  /// with, or null when they have no signing key.
  Future<String?> publicKeyOf(String userId);

  /// The armored SSH signature (namespace `git`) of [commit], an unsigned
  /// commit object, under [userId]'s key, which must be [publicKey].
  ///
  /// One read decides both: throws [CommitSigningUnavailable] when they have
  /// no key, or when their key is no longer [publicKey] (deleted, or replaced
  /// since the caller learned it), and signs nothing.
  Future<String> sign(String userId, String publicKey, List<int> commit);
}

/// [CommitSigningPort.sign] signed nothing: the person has no key, or not
/// the one the caller named.
class CommitSigningUnavailable implements Exception {
  /// Creates the exception.
  const CommitSigningUnavailable(this.message);

  /// Why nothing was signed, in words the person can act on.
  final String message;

  @override
  String toString() => message;
}
