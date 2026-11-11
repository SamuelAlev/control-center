import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:cc_connect/src/private_file.dart';

/// The one server a Slack workspace is bound to.
final class SlackTeamBinding {
  /// Creates the binding.
  const SlackTeamBinding({
    required this.teamId,
    required this.installId,
    required this.botId,
    required this.appId,
    required this.boundAt,
    required this.botUserId,
  });

  /// Slack's team id.
  final String teamId;

  /// The bound install id.
  final String installId;

  /// The bot id from `auth.test`.
  final String botId;

  /// The bot's user id (`U…`), which Slack names in `tokens_revoked`.
  final String botUserId;

  /// The Slack app id.
  final String appId;

  /// When it was bound.
  final DateTime boundAt;

  /// The persisted form.
  Map<String, Object?> toJson() => {
    'install_id': installId,
    'bot_id': botId,
    'bot_user_id': botUserId,
    'app_id': appId,
    'bound_at': boundAt.toUtc().toIso8601String(),
  };

  /// Parses the persisted form; null when malformed (including a binding
  /// without `bot_user_id`).
  static SlackTeamBinding? fromJson(String teamId, Object? json) {
    if (json is! Map) {
      return null;
    }
    final install = json['install_id'];
    final bot = json['bot_id'];
    final app = json['app_id'];
    final at = json['bound_at'];
    final botUser = json['bot_user_id'];
    if (install is! String ||
        bot is! String ||
        app is! String ||
        at is! String ||
        botUser is! String ||
        botUser.isEmpty) {
      return null;
    }
    return SlackTeamBinding(
      teamId: teamId,
      installId: install,
      botId: bot,
      appId: app,
      boundAt: DateTime.tryParse(at)?.toUtc() ?? DateTime.utc(1970),
      botUserId: botUser,
    );
  }
}

/// The binding store is unreachable. Answered `provider_unavailable`.
final class BindingStoreUnavailable implements Exception {
  /// Creates the exception.
  const BindingStoreUnavailable(this.reason);

  /// A fixed reason.
  final String reason;

  @override
  String toString() => 'BindingStoreUnavailable($reason)';
}

/// Most install ids the retired set holds. Retiring is free for any install
/// (installs are free to mint), so the set is capped: a full set refuses
/// further retirements and logs an error for the operator.
const int maxRetiredInstalls = 100000;

/// The most Slack teams one install's retirement releases.
const int maxTeamsPerInstall = 1000;

/// Slack team-to-server bindings (`install_binding`) and the retired
/// installs: opaque ids only, never a token. GitHub has no binding: any
/// server a member signs in on may use the account's installation.
abstract interface class BindingStore {
  /// The binding for a Slack team, or null. [fresh] bypasses any cache: the
  /// Slack pre-check must never act on a stale "unbound".
  Future<SlackTeamBinding?> slack(String teamId, {bool fresh = false});

  /// Binds [binding]'s team to its install when the team is unbound or
  /// already bound to the same install (refreshing bot and app ids), and
  /// returns the binding in effect afterwards. A different `installId` in
  /// the result means the team is bound elsewhere and nothing changed.
  Future<SlackTeamBinding> bindSlack(SlackTeamBinding binding);

  /// Releases the team's binding. With [installId], only when bound to it.
  /// True when a binding was removed.
  Future<bool> releaseSlack(String teamId, {String? installId});

  /// The teams bound to [installId] (at most [maxTeamsPerInstall]), read
  /// from the backend.
  Future<List<String>> slackTeamsOf(String installId);

  /// Whether [installId] was retired ([retireInstall]).
  Future<bool> isRetired(String installId);

  /// Records [installId] as retired, for good: every later request it signs
  /// is refused. True when it is retired now (also when it already was);
  /// false when the set already holds [maxRetiredInstalls] ids and nothing
  /// was recorded.
  Future<bool> retireInstall(String installId);

  /// Proves the backend answers (boot and `/readyz`). Throws
  /// [BindingStoreUnavailable].
  Future<void> probe();

  /// Releases resources.
  Future<void> close();
}

/// Bindings and retired installs in a JSON file under `CONNECT_DATA_DIR`
/// (`{"slack": {...}, "retired": [...]}`, both keys required), held in
/// memory and
/// rewritten atomically on each change ([writePrivateFile]: created 0600,
/// then renamed). For one instance; a multi-instance deploy uses Firestore.
/// [open] takes an exclusive lock on `bindings.lock` in the directory, so a
/// second Connect on the same directory refuses to start instead of
/// overwriting the first one's bindings from its own stale copy.
///
/// Every change is compare-and-set against the in-memory map and is undone
/// when the file write fails, so memory never answers a binding the disk
/// does not hold.
final class FileBindingStore implements BindingStore {
  FileBindingStore._(this._file, this._lock, this._lockPath);

  /// Paths locked by this process: a file lock does not exclude its own
  /// process.
  static final Set<String> _lockedHere = {};

  /// Opens (or creates) `bindings.json` in [dataDir]. Throws
  /// [BindingStoreUnavailable] when another Connect holds the directory.
  static Future<FileBindingStore> open(String dataDir) async {
    final dir = Directory(dataDir);
    await dir.create(recursive: true);
    await _restrictDirectory(dir.path);
    final lockFile = File('${dir.path}${Platform.pathSeparator}bindings.lock');
    final lockPath = lockFile.absolute.path;
    if (!_lockedHere.add(lockPath)) {
      throw const BindingStoreUnavailable(_heldElsewhere);
    }
    final RandomAccessFile lock;
    try {
      lock = await lockFile.open(mode: FileMode.append);
    } on Object {
      _lockedHere.remove(lockPath);
      rethrow;
    }
    try {
      await lock.lock(FileLock.exclusive);
    } on FileSystemException {
      _lockedHere.remove(lockPath);
      await lock.close();
      throw const BindingStoreUnavailable(_heldElsewhere);
    }
    final store = FileBindingStore._(
      File('${dir.path}${Platform.pathSeparator}bindings.json'),
      lock,
      lockPath,
    );
    try {
      await store._load();
    } on Object {
      await store.close();
      rethrow;
    }
    return store;
  }

  static const String _heldElsewhere =
      'another Connect holds this directory; run one instance per data '
      'directory, or Firestore bindings for several';

  final File _file;
  final RandomAccessFile _lock;
  final String _lockPath;
  bool _closed = false;
  final Map<String, SlackTeamBinding> _slack = {};
  final Set<String> _retired = {};
  Future<void> _writes = Future.value();

  Future<void> _load() async {
    if (!_file.existsSync()) {
      return;
    }
    final Object? decoded;
    try {
      decoded = jsonDecode(await _file.readAsString());
    } on FormatException {
      throw const BindingStoreUnavailable('bindings.json is corrupt');
    }
    if (decoded is! Map ||
        decoded.length != 2 ||
        decoded['slack'] is! Map ||
        decoded['retired'] is! List) {
      throw const BindingStoreUnavailable('bindings.json is corrupt');
    }
    final slack = decoded['slack'] as Map;
    for (final id in decoded['retired'] as List) {
      if (id is! String || id.isEmpty || id.length > 64) {
        throw const BindingStoreUnavailable('bindings.json is corrupt');
      }
      _retired.add(id);
    }
    slack.forEach((key, value) {
      final binding = SlackTeamBinding.fromJson('$key', value);
      if (binding == null) {
        throw const BindingStoreUnavailable('bindings.json is corrupt');
      }
      _slack['$key'] = binding;
    });
  }

  Map<String, Object?> _snapshot() => {
    'slack': {for (final b in _slack.values) b.teamId: b.toJson()},
    'retired': [..._retired]..sort(),
  };

  Future<void> _persist() {
    final snapshot = utf8.encode(
      const JsonEncoder.withIndent('  ').convert(_snapshot()),
    );
    final next = _writes.then((_) => writePrivateFile(_file.path, snapshot));
    _writes = next.catchError((Object _) {});
    return next.catchError((Object _) {
      throw const BindingStoreUnavailable('bindings.json write failed');
    });
  }

  /// Applies [change] (already decided against the current map), persists,
  /// and puts the map back when the write fails.
  Future<void> _commit(void Function() change, void Function() undo) async {
    change();
    try {
      await _persist();
    } on Object {
      undo();
      rethrow;
    }
  }

  @override
  Future<SlackTeamBinding?> slack(String teamId, {bool fresh = false}) async =>
      _slack[teamId];

  @override
  Future<SlackTeamBinding> bindSlack(SlackTeamBinding binding) async {
    final existing = _slack[binding.teamId];
    if (existing != null && existing.installId != binding.installId) {
      return existing;
    }
    await _commit(
      () => _slack[binding.teamId] = binding,
      () => existing == null
          ? _slack.remove(binding.teamId)
          : _slack[binding.teamId] = existing,
    );
    return binding;
  }

  @override
  Future<bool> releaseSlack(String teamId, {String? installId}) async {
    final existing = _slack[teamId];
    if (existing == null ||
        (installId != null && existing.installId != installId)) {
      return false;
    }
    await _commit(() => _slack.remove(teamId), () => _slack[teamId] = existing);
    return true;
  }

  @override
  Future<List<String>> slackTeamsOf(String installId) async => [
    for (final binding in _slack.values)
      if (binding.installId == installId) binding.teamId,
  ].take(maxTeamsPerInstall).toList();

  @override
  Future<bool> isRetired(String installId) async =>
      _retired.contains(installId);

  @override
  Future<bool> retireInstall(String installId) async {
    if (_retired.contains(installId)) {
      return true;
    }
    if (_retired.length >= maxRetiredInstalls) {
      return false;
    }
    await _commit(
      () => _retired.add(installId),
      () => _retired.remove(installId),
    );
    return true;
  }

  /// Loaded at [open]; nothing remote to reach.
  @override
  Future<void> probe() async {}

  @override
  Future<void> close() async {
    if (_closed) {
      return;
    }
    _closed = true;
    await _writes;
    try {
      await _lock.unlock();
    } on FileSystemException {
      // Closing releases it anyway.
    }
    await _lock.close();
    _lockedHere.remove(_lockPath);
  }
}

/// Makes [path] owner-only (0700). The directory is created by the image
/// (`install -m 0700`) or the operator; this only narrows one made wider.
Future<void> _restrictDirectory(String path) async {
  if (Platform.isWindows) {
    return;
  }
  try {
    await Process.run('chmod', ['700', path]);
  } on Object {
    // Best effort: every file in it is created owner-only regardless.
  }
}

/// An in-memory read cache in front of a remote [BindingStore]. Positive
/// Slack entries are cached for [ttl]; misses always go to the backend, and
/// `slack(fresh: true)` always does. A retired install is remembered for
/// good (retiring is permanent); "not retired" is trusted for [ttl], so a
/// retirement on another instance applies here within it.
final class CachedBindingStore implements BindingStore {
  /// Creates the cache.
  CachedBindingStore(
    this._inner, {
    this.ttl = const Duration(seconds: 30),
    DateTime Function()? clock,
  }) : _clock = clock ?? DateTime.now;

  final BindingStore _inner;

  /// How long a positive entry is trusted.
  final Duration ttl;
  final DateTime Function() _clock;
  final Map<String, (SlackTeamBinding, DateTime)> _slack = {};
  final Set<String> _retired = {};
  final Map<String, DateTime> _notRetired = {};

  bool _fresh(DateTime at) => _clock().difference(at) < ttl;

  @override
  Future<bool> isRetired(String installId) async {
    if (_retired.contains(installId)) {
      return true;
    }
    final checked = _notRetired[installId];
    if (checked != null && _fresh(checked)) {
      return false;
    }
    final retired = await _inner.isRetired(installId);
    if (retired) {
      _retired.add(installId);
      _notRetired.remove(installId);
    } else {
      if (_notRetired.length >= 10000) {
        // Only ever costs a backend read.
        _notRetired.clear();
      }
      _notRetired[installId] = _clock();
    }
    return retired;
  }

  @override
  Future<bool> retireInstall(String installId) async {
    final retired = await _inner.retireInstall(installId);
    if (retired) {
      _retired.add(installId);
      _notRetired.remove(installId);
    }
    return retired;
  }

  @override
  Future<SlackTeamBinding?> slack(String teamId, {bool fresh = false}) async {
    final hit = _slack[teamId];
    if (!fresh && hit != null && _fresh(hit.$2)) {
      return hit.$1;
    }
    final value = await _inner.slack(teamId, fresh: true);
    if (value != null) {
      _slack[teamId] = (value, _clock());
    } else {
      _slack.remove(teamId);
    }
    return value;
  }

  @override
  Future<SlackTeamBinding> bindSlack(SlackTeamBinding binding) async {
    final result = await _inner.bindSlack(binding);
    _slack[binding.teamId] = (result, _clock());
    return result;
  }

  @override
  Future<bool> releaseSlack(String teamId, {String? installId}) async {
    try {
      return await _inner.releaseSlack(teamId, installId: installId);
    } finally {
      // After the backend answered: a read racing the release cannot put
      // the released binding back.
      _slack.remove(teamId);
    }
  }

  @override
  Future<List<String>> slackTeamsOf(String installId) =>
      _inner.slackTeamsOf(installId);

  @override
  Future<void> probe() => _inner.probe();

  @override
  Future<void> close() => _inner.close();
}
