import 'dart:async';
import 'dart:convert';
import 'dart:io';

/// The servers allowed to mint against one GitHub installation.
final class GitHubInstallationBinding {
  /// Creates the binding.
  const GitHubInstallationBinding({
    required this.installationId,
    required this.installIds,
    required this.boundAt,
  });

  /// GitHub's installation id.
  final int installationId;

  /// The bound install ids.
  final Set<String> installIds;

  /// When the binding last changed.
  final DateTime boundAt;
}

/// The one server a Slack workspace is bound to.
final class SlackTeamBinding {
  /// Creates the binding.
  const SlackTeamBinding({
    required this.teamId,
    required this.installId,
    required this.botId,
    required this.appId,
    required this.boundAt,
  });

  /// Slack's team id.
  final String teamId;

  /// The bound install id.
  final String installId;

  /// The bot id from `auth.test`.
  final String botId;

  /// The Slack app id.
  final String appId;

  /// When it was bound.
  final DateTime boundAt;

  /// The persisted form.
  Map<String, Object?> toJson() => {
    'install_id': installId,
    'bot_id': botId,
    'app_id': appId,
    'bound_at': boundAt.toUtc().toIso8601String(),
  };

  /// Parses the persisted form; null when malformed.
  static SlackTeamBinding? fromJson(String teamId, Object? json) {
    if (json is! Map) {
      return null;
    }
    final install = json['install_id'];
    final bot = json['bot_id'];
    final app = json['app_id'];
    final at = json['bound_at'];
    if (install is! String ||
        bot is! String ||
        app is! String ||
        at is! String) {
      return null;
    }
    return SlackTeamBinding(
      teamId: teamId,
      installId: install,
      botId: bot,
      appId: app,
      boundAt: DateTime.tryParse(at)?.toUtc() ?? DateTime.utc(1970),
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

/// Tenant-to-server bindings (`install_binding`): opaque ids only, never a
/// token.
abstract interface class BindingStore {
  /// The binding for a GitHub installation, or null.
  Future<GitHubInstallationBinding?> github(int installationId);

  /// Adds [installId] to the installation's binding.
  Future<void> addGitHub(int installationId, String installId);

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

  /// Releases resources.
  Future<void> close();
}

/// Bindings in a JSON file under `CONNECT_DATA_DIR`, held in memory and
/// rewritten atomically (temp file + rename, mode 0600) on each change. For
/// one instance; a multi-instance deploy uses Firestore.
final class FileBindingStore implements BindingStore {
  FileBindingStore._(this._file, {DateTime Function()? clock})
    : _clock = clock ?? DateTime.now;

  /// Opens (or creates) `bindings.json` in [dataDir].
  static Future<FileBindingStore> open(
    String dataDir, {
    DateTime Function()? clock,
  }) async {
    final dir = Directory(dataDir);
    await dir.create(recursive: true);
    await _chmod('700', dir.path);
    final store = FileBindingStore._(
      File('${dir.path}${Platform.pathSeparator}bindings.json'),
      clock: clock,
    );
    await store._load();
    return store;
  }

  final File _file;
  final DateTime Function() _clock;
  final Map<int, GitHubInstallationBinding> _github = {};
  final Map<String, SlackTeamBinding> _slack = {};
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
    if (decoded is! Map) {
      throw const BindingStoreUnavailable('bindings.json is corrupt');
    }
    final github = decoded['github'];
    if (github is Map) {
      github.forEach((key, value) {
        final id = int.tryParse('$key');
        if (id == null || value is! Map) {
          return;
        }
        final ids = value['install_ids'];
        final at = value['bound_at'];
        _github[id] = GitHubInstallationBinding(
          installationId: id,
          installIds: {
            if (ids is List)
              for (final i in ids)
                if (i is String) i,
          },
          boundAt: at is String
              ? DateTime.tryParse(at)?.toUtc() ?? DateTime.utc(1970)
              : DateTime.utc(1970),
        );
      });
    }
    final slack = decoded['slack'];
    if (slack is Map) {
      slack.forEach((key, value) {
        final binding = SlackTeamBinding.fromJson('$key', value);
        if (binding != null) {
          _slack['$key'] = binding;
        }
      });
    }
  }

  Map<String, Object?> _snapshot() => {
    'v': 1,
    'github': {
      for (final b in _github.values)
        '${b.installationId}': {
          'install_ids': b.installIds.toList()..sort(),
          'bound_at': b.boundAt.toUtc().toIso8601String(),
        },
    },
    'slack': {for (final b in _slack.values) b.teamId: b.toJson()},
  };

  Future<void> _persist() {
    final snapshot = const JsonEncoder.withIndent('  ').convert(_snapshot());
    final next = _writes.then((_) async {
      final tmp = File('${_file.path}.tmp');
      await tmp.writeAsString(snapshot, flush: true);
      await _chmod('600', tmp.path);
      await tmp.rename(_file.path);
    });
    _writes = next.catchError((Object _) {});
    return next.catchError((Object _) {
      throw const BindingStoreUnavailable('bindings.json write failed');
    });
  }

  @override
  Future<GitHubInstallationBinding?> github(int installationId) async =>
      _github[installationId];

  @override
  Future<void> addGitHub(int installationId, String installId) async {
    final existing = _github[installationId];
    if (existing != null && existing.installIds.contains(installId)) {
      return;
    }
    _github[installationId] = GitHubInstallationBinding(
      installationId: installationId,
      installIds: {...?existing?.installIds, installId},
      boundAt: _clock().toUtc(),
    );
    await _persist();
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
    _slack[binding.teamId] = binding;
    await _persist();
    return binding;
  }

  @override
  Future<bool> releaseSlack(String teamId, {String? installId}) async {
    final existing = _slack[teamId];
    if (existing == null ||
        (installId != null && existing.installId != installId)) {
      return false;
    }
    _slack.remove(teamId);
    await _persist();
    return true;
  }

  @override
  Future<void> close() => _writes;
}

Future<void> _chmod(String mode, String path) async {
  if (Platform.isWindows) {
    return;
  }
  try {
    await Process.run('chmod', [mode, path]);
  } on Object {
    // Best effort: the directory mode already keeps other users out.
  }
}

/// An in-memory read cache in front of a remote [BindingStore]. Positive
/// GitHub and Slack entries are cached for [ttl]; misses always go to the
/// backend, and `slack(fresh: true)` always does.
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
  final Map<int, (GitHubInstallationBinding, DateTime)> _github = {};
  final Map<String, (SlackTeamBinding, DateTime)> _slack = {};

  bool _fresh(DateTime at) => _clock().difference(at) < ttl;

  @override
  Future<GitHubInstallationBinding?> github(int installationId) async {
    final hit = _github[installationId];
    if (hit != null && _fresh(hit.$2)) {
      return hit.$1;
    }
    final value = await _inner.github(installationId);
    if (value != null) {
      _github[installationId] = (value, _clock());
    } else {
      _github.remove(installationId);
    }
    return value;
  }

  @override
  Future<void> addGitHub(int installationId, String installId) async {
    await _inner.addGitHub(installationId, installId);
    _github.remove(installationId);
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
    _slack.remove(teamId);
    return _inner.releaseSlack(teamId, installId: installId);
  }

  @override
  Future<void> close() => _inner.close();
}
