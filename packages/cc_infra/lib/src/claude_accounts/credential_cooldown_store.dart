import 'dart:convert';
import 'dart:io';

import 'package:cc_infra/src/log/cc_infra_log.dart';
import 'package:path/path.dart' as p;

/// Remembers which harness credentials are out of quota, and until when.
///
/// ## Why this exists separately from the account registry
///
/// A Claude Code account's cooldown lives on its registry row, because there
/// the directory IS the account and there is already a file describing it. A
/// harness credential has no such file — the credential store holds secrets and
/// nothing about their recent behaviour — so the cooldown needs a home of its
/// own. Both lanes mean the same thing by it; only the storage differs, and
/// that difference is the shape of what each lane already persists.
///
/// ## Why it is persisted at all
///
/// `FallbackProvider` already advances past an exhausted key WITHIN a turn, so
/// nothing breaks without this. What it buys is not paying that 429 again on
/// every subsequent dispatch: a serial rotation with no memory re-enters the
/// spent key each time, discovers the same limit, and moves on — correct, but
/// one wasted request per turn for as long as the window is closed.
class CredentialCooldownStore {
  /// Creates a store rooted at [dataDir].
  CredentialCooldownStore({required String dataDir, DateTime Function()? now})
    : _file = File(p.join(dataDir, 'credential-cooldowns.json')),
      _now = now ?? DateTime.now;

  final File _file;
  final DateTime Function() _now;

  Map<String, DateTime>? _cache;

  /// How long a credential is parked when the provider reported no reset time.
  ///
  /// Deliberately short. An over-long guess sidelines a working key for hours
  /// on one misread error; the cost of guessing short is a single extra request
  /// once it expires, which is the same cost as having no memory at all.
  static const Duration defaultCooldown = Duration(minutes: 20);

  static String _key(String providerId, String credentialId) =>
      '$providerId:$credentialId';

  /// Marks [credentialId] of [providerId] as out of quota until [until].
  Future<void> mark(
    String providerId,
    String credentialId, {
    DateTime? until,
  }) async {
    final map = await _load();
    map[_key(providerId, credentialId)] = until ?? _now().add(defaultCooldown);
    await _flush(map);
  }

  /// Clears a cooldown early.
  Future<void> clear(String providerId, String credentialId) async {
    final map = await _load();
    if (map.remove(_key(providerId, credentialId)) != null) {
      await _flush(map);
    }
  }

  /// When [credentialId] frees up, or null if it is not cooling off.
  Future<DateTime?> cooldownFor(String providerId, String credentialId) async {
    final map = await _load();
    final at = map[_key(providerId, credentialId)];
    return at != null && at.isAfter(_now()) ? at : null;
  }

  /// Every live cooldown for [providerId], keyed by credential id.
  Future<Map<String, DateTime>> activeFor(String providerId) async {
    final map = await _load();
    final now = _now();
    final prefix = '$providerId:';
    return {
      for (final e in map.entries)
        if (e.key.startsWith(prefix) && e.value.isAfter(now))
          e.key.substring(prefix.length): e.value,
    };
  }

  Future<Map<String, DateTime>> _load() async {
    final cached = _cache;
    if (cached != null) {
      return cached;
    }
    final map = <String, DateTime>{};
    if (_file.existsSync()) {
      try {
        final decoded = jsonDecode(await _file.readAsString());
        if (decoded is Map) {
          for (final e in decoded.entries) {
            final at = DateTime.tryParse('${e.value}');
            if (at != null) {
              map['${e.key}'] = at;
            }
          }
        }
      } on Object catch (e) {
        // A corrupt file costs one extra request per key, never a failed run.
        CcInfraLog.warning(
          'CredentialCooldownStore: could not read ${_file.path}: $e',
        );
      }
    }
    return _cache = map;
  }

  Future<void> _flush(Map<String, DateTime> map) async {
    // Drop expired entries on every write, so the file cannot grow without
    // bound across a long-lived install.
    final now = _now();
    map.removeWhere((_, at) => !at.isAfter(now));
    _cache = map;
    try {
      _file.parent.createSync(recursive: true);
      final tmp = File('${_file.path}.tmp');
      tmp.writeAsStringSync(
        jsonEncode({
          for (final e in map.entries) e.key: e.value.toIso8601String(),
        }),
        flush: true,
      );
      tmp.renameSync(_file.path);
    } on Object catch (e) {
      // In-memory still holds, so the current process keeps the benefit.
      CcInfraLog.warning(
        'CredentialCooldownStore: could not write ${_file.path}: $e',
      );
    }
  }
}
