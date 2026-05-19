import 'dart:convert';
import 'dart:io';

import 'package:cc_domain/features/chat_bridge/domain/value_objects/chat_bridge_connection.dart';
import 'package:cc_domain/features/chat_bridge/domain/value_objects/chat_provider.dart';
import 'package:cc_persistence/cc_persistence.dart' show workspaceDirPath;
import 'package:path/path.dart' as p;

/// A provider-side app Control Center created but that is not usable yet.
///
/// Guided create ends in the middle: the provider has the app and Control Center
/// holds the app-management credential it must never lose — but there is no bot
/// token until the user installs the app, so there is no connection to store it
/// on. This is that gap, written down: the next `chat.connect` picks the tokens up
/// and the file is deleted.
class ChatAppSetup {
  /// Creates a [ChatAppSetup].
  const ChatAppSetup({
    required this.managementCredential,
    this.appId,
    this.installUrl,
  });

  /// Parses from the stored JSON.
  factory ChatAppSetup.fromJson(Map<String, dynamic> json) => ChatAppSetup(
    // `configRefreshToken` is the pre-generalization key, still read so a
    // half-finished Slack setup survives the rename.
    managementCredential:
        json['managementCredential'] as String? ??
        json['configRefreshToken'] as String? ??
        '',
    appId: json['appId'] as String?,
    installUrl: json['installUrl'] as String?,
  );

  /// The current app-management credential (rotated on every use).
  final String managementCredential;

  /// The app the provider created, once it has answered.
  final String? appId;

  /// The provider's install URL for the new app, when it returned one.
  final String? installUrl;

  /// Returns a copy with the given fields replaced.
  ChatAppSetup copyWith({
    String? managementCredential,
    String? appId,
    String? installUrl,
  }) => ChatAppSetup(
    managementCredential: managementCredential ?? this.managementCredential,
    appId: appId ?? this.appId,
    installUrl: installUrl ?? this.installUrl,
  );

  /// Serializes to the stored JSON shape (secrets included).
  Map<String, dynamic> toJson() => {
    'managementCredential': managementCredential,
    if (appId != null) 'appId': appId,
    if (installUrl != null) 'installUrl': installUrl,
  };
}

/// Per-workspace, per-provider credential store:
/// `<dataDir>/<workspaceId>/chat_credentials/<provider>.json`.
///
/// The credentials live in the workspace's **own directory, beside its
/// database**, for two reasons that are easy to lose later:
///
///  * Deleting a workspace unlinks that directory, so its chat tokens go with it
///    — no orphaned credentials for a workspace that no longer exists.
///  * `workspace.export` / backup copy `workspace.db`, not the directory, so a
///    workspace handed to somebody else does **not** carry live bot tokens inside
///    it. (Same reasoning as keeping the Google refresh token out of Drift.)
///
/// One file per provider rather than one file with a provider map: a revoked
/// Slack app is deleted by unlinking its file and a corrupt file costs one
/// provider instead of all of them.
///
/// Writes are atomic (temp file + rename) and tightened to owner-only, matching
/// the Google credentials store next door.
class FileChatConnectionStore {
  /// Creates a store rooted at [dataDir].
  FileChatConnectionStore({required String dataDir}) : _dataDir = dataDir;

  final String _dataDir;

  /// Legacy single-provider file names, from before the store was generalized.
  /// Read once and migrated in place; a developer machine has one of these.
  static const _legacyNames = {
    ChatProvider.slack: (
      credentials: 'slack_credentials.json',
      setup: 'slack_app_setup.json',
    ),
  };

  String _dirFor(String workspaceId) =>
      p.join(workspaceDirPath(_dataDir, workspaceId), 'chat_credentials');

  File _fileFor(String workspaceId, ChatProvider provider) =>
      File(p.join(_dirFor(workspaceId), '${provider.wire}.json'));

  File _setupFileFor(String workspaceId, ChatProvider provider) =>
      File(p.join(_dirFor(workspaceId), '${provider.wire}_setup.json'));

  File? _legacyFileFor(String workspaceId, ChatProvider provider) {
    final names = _legacyNames[provider];
    if (names == null) {
      return null;
    }
    return File(
      p.join(workspaceDirPath(_dataDir, workspaceId), names.credentials),
    );
  }

  File? _legacySetupFileFor(String workspaceId, ChatProvider provider) {
    final names = _legacyNames[provider];
    if (names == null) {
      return null;
    }
    return File(p.join(workspaceDirPath(_dataDir, workspaceId), names.setup));
  }

  /// The connection stored for [workspaceId] on [provider], or null when it is
  /// not connected there.
  Future<ChatBridgeConnection?> load(
    String workspaceId,
    ChatProvider provider,
  ) async {
    final file = _fileFor(workspaceId, provider);
    if (!file.existsSync()) {
      return _migrateLegacy(workspaceId, provider);
    }
    final map = await _readJson(file);
    if (map == null) {
      return null;
    }
    try {
      // A file that predates a rename, or was hand-edited, must not out-vote the
      // directory it lives in or the file name it was read from.
      map['workspaceId'] = workspaceId;
      map['provider'] = provider.wire;
      return ChatBridgeConnection.fromJson(map);
    } on Object {
      return null;
    }
  }

  /// Whether credentials exist for [workspaceId] on [provider] (cheap boot probe:
  /// no parse, no workspace database opened).
  bool has(String workspaceId, ChatProvider provider) =>
      _fileFor(workspaceId, provider).existsSync() ||
      (_legacyFileFor(workspaceId, provider)?.existsSync() ?? false);

  /// Persists [connection], replacing whatever was stored for its provider.
  Future<void> save(ChatBridgeConnection connection) => _write(
    _fileFor(connection.workspaceId, connection.provider),
    {...connection.toJson()},
  );

  /// Removes the stored connection (disconnect).
  Future<void> clear(String workspaceId, ChatProvider provider) async {
    await _delete(_fileFor(workspaceId, provider));
    await _delete(_legacyFileFor(workspaceId, provider));
  }

  /// The half-finished guided create, if any.
  Future<ChatAppSetup?> loadSetup(
    String workspaceId,
    ChatProvider provider,
  ) async {
    final file = _setupFileFor(workspaceId, provider);
    final map = file.existsSync()
        ? await _readJson(file)
        : await _readLegacySetup(workspaceId, provider);
    if (map == null) {
      return null;
    }
    final setup = ChatAppSetup.fromJson(map);
    return setup.managementCredential.isEmpty ? null : setup;
  }

  /// Persists the in-progress guided create.
  ///
  /// Written on every credential rotation, so it is on the hot path of app
  /// management: an unpersisted rotation costs the user their ability to manage
  /// the app at all.
  Future<void> saveSetup(
    String workspaceId,
    ChatProvider provider,
    ChatAppSetup setup,
  ) => _write(_setupFileFor(workspaceId, provider), setup.toJson());

  /// Forgets the in-progress guided create (it completed, or was abandoned).
  Future<void> clearSetup(String workspaceId, ChatProvider provider) async {
    await _delete(_setupFileFor(workspaceId, provider));
    await _delete(_legacySetupFileFor(workspaceId, provider));
  }

  /// Reads a pre-generalization Slack file, rewrites it in the new shape and
  /// deletes the old one.
  ///
  /// The typed token fields become entries in the credentials map under the ids
  /// the Slack descriptor declares — which is exactly what the connect op would
  /// have written today, so a developer machine keeps its working connection
  /// across the rename instead of silently going quiet.
  Future<ChatBridgeConnection?> _migrateLegacy(
    String workspaceId,
    ChatProvider provider,
  ) async {
    final legacy = _legacyFileFor(workspaceId, provider);
    if (legacy == null || !legacy.existsSync()) {
      return null;
    }
    final map = await _readJson(legacy);
    if (map == null) {
      return null;
    }
    final credentials = {
      for (final key in const ['botToken', 'appToken', 'configRefreshToken'])
        if ((map[key] as String? ?? '').isNotEmpty) key: map[key] as String,
    };
    if (credentials.isEmpty) {
      return null;
    }
    final ChatBridgeConnection connection;
    try {
      connection = ChatBridgeConnection(
        provider: provider,
        workspaceId: workspaceId,
        credentials: credentials,
        appId: map['appId'] as String? ?? '',
        teamId: map['teamId'] as String? ?? '',
        teamName: map['teamName'] as String? ?? '',
        botUserId: map['botUserId'] as String? ?? '',
        botName: map['botName'] as String? ?? '',
        enabled: map['enabled'] as bool? ?? true,
        connectedAt:
            DateTime.tryParse(map['connectedAt'] as String? ?? '') ??
            DateTime.now(),
      );
    } on Object {
      return null;
    }
    await save(connection);
    await _delete(legacy);
    return connection;
  }

  Future<Map<String, dynamic>?> _readLegacySetup(
    String workspaceId,
    ChatProvider provider,
  ) async {
    final legacy = _legacySetupFileFor(workspaceId, provider);
    if (legacy == null || !legacy.existsSync()) {
      return null;
    }
    return _readJson(legacy);
  }

  Future<Map<String, dynamic>?> _readJson(File file) async {
    try {
      final decoded = jsonDecode(await file.readAsString());
      return decoded is Map ? decoded.cast<String, dynamic>() : null;
    } on Object {
      return null;
    }
  }

  Future<void> _write(File file, Map<String, dynamic> json) async {
    await file.parent.create(recursive: true);
    final tmp = File('${file.path}.tmp');
    await tmp.writeAsString(jsonEncode(json));
    await tmp.rename(file.path);
    await _restrictPerms(file);
  }

  Future<void> _delete(File? file) async {
    if (file != null && file.existsSync()) {
      await file.delete();
    }
  }

  /// Tightens a credentials file to owner-only where `chmod` exists (macOS/Linux;
  /// Windows ACLs out of scope). `writeAsString` honors the umask, which is
  /// usually 0644. Best-effort.
  Future<void> _restrictPerms(File file) async {
    if (Platform.isWindows) {
      return;
    }
    try {
      await Process.run('chmod', ['600', file.path]);
    } on Object {
      // The tokens are written either way; the host umask applies.
    }
  }
}
