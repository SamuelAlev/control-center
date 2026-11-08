import 'dart:convert';
import 'dart:io';

import 'package:cc_domain/features/settings/domain/entities/claude_session_settings.dart';
import 'package:cc_infra/src/log/cc_infra_log.dart';

/// Keeps the server's [ClaudeSessionSettings] in its data directory.
class ClaudeSessionSettingsStore {
  /// Creates a store over `<dataDir>/claude_session_settings.json`.
  ClaudeSessionSettingsStore({required String dataDir})
    : _file = File('$dataDir/claude_session_settings.json');

  final File _file;
  ClaudeSessionSettings? _loaded;

  /// The current settings. A file that cannot be read means the defaults: a
  /// preference must never be what stops a run.
  ClaudeSessionSettings read() => _loaded ??= _load();

  ClaudeSessionSettings _load() {
    try {
      if (_file.existsSync()) {
        final decoded = jsonDecode(_file.readAsStringSync());
        if (decoded is Map<String, dynamic>) {
          return ClaudeSessionSettings.fromJson(decoded);
        }
      }
    } on Object catch (e) {
      CcInfraLog.warning('claude session settings unreadable: $e');
    }
    return ClaudeSessionSettings();
  }

  /// Replaces the settings. Written through a rename, so a crash leaves the
  /// previous file rather than half of a new one.
  Future<void> write(ClaudeSessionSettings settings) async {
    await _file.parent.create(recursive: true);
    final temp = File('${_file.path}.tmp');
    await temp.writeAsString(jsonEncode(settings.toJson()));
    await temp.rename(_file.path);
    _loaded = settings;
  }
}
