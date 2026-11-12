/// One kind of row the `caches` table may hold.
///
/// The table is a staleness buffer and nothing else: a row of a declared kind
/// can be deleted at any time and the next read refetches it. That is what lets
/// the retention sweep delete untouched rows after [retention]. State whose
/// loss changes what the server does (who holds a take-over, who may not
/// approve a pull request) never goes here: it gets a table of its own.
final class CacheKind {
  /// Declares the kind [name], whose untouched rows are deleted after
  /// [retention].
  const CacheKind(this.name, {required this.retention});

  /// The value stored in `caches.kind`.
  final String name;

  /// How long a row of this kind may go unwritten before the retention sweep
  /// deletes it.
  final Duration retention;

  @override
  bool operator ==(Object other) =>
      other is CacheKind && other.name == name && other.retention == retention;

  @override
  int get hashCode => Object.hash(name, retention);

  @override
  String toString() => 'CacheKind($name, $retention)';
}
