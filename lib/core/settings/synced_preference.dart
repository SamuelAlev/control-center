import 'package:flutter_riverpod/flutter_riverpod.dart';

/// One preference key that follows the signed-in user across devices.
///
/// Deliberately carries **no codec**. Every local settings notifier in this app
/// already reads `AppPreferences` inside its `build()`, so a pulled value is
/// applied by writing the raw string into the local store and invalidating the
/// owning provider — the notifier re-reads and decodes it exactly as it would a
/// local write. That keeps the wire key equal to the local key, makes promotion
/// a plain string copy and makes adding a synced key one entry rather than an
/// encode/decode/apply triple that can be wired in one direction only.
class SyncedPreference {
  /// Declares [key] as user-scoped.
  const SyncedPreference(
    this.key, {
    this.onPulled,
    this.maxBytes = defaultMaxBytes,
  });

  /// Default per-value ceiling enforced client-side before pushing.
  ///
  /// Well under the server's own cap so an oversized value is reported here,
  /// where the offending key is known, rather than as a rejected RPC.
  static const int defaultMaxBytes = 64 * 1024;

  /// The `user_preferences` key, identical to the local `AppPreferences` key.
  final String key;

  /// Runs after a pulled value has been written to the local store, to refresh
  /// whatever caches it.
  ///
  /// Typically `(ref) => ref.invalidate(someProvider)`. Only surfaces that
  /// *cache* a read need one: a notifier that reads through to the store on
  /// every call (the notification preferences, for instance) needs nothing.
  final void Function(Ref ref)? onPulled;

  /// Largest value this key may push, in UTF-8 bytes.
  final int maxBytes;
}
