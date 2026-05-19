import 'dart:io';

import 'package:cc_domain/features/meetings/domain/services/conferencing_apps.dart';
import 'package:cc_domain/features/meetings/domain/services/meeting_detection.dart';
import 'package:cc_domain/features/meetings/domain/services/meeting_signal_collector.dart';

/// Emits a [MeetingSignalKind.conferencingApp] signal when a per-meeting
/// conferencing client (Zoom, Webex, …) is running. Cross-platform via `ps`
/// (macOS/Linux) or `tasklist` (Windows). Persistent always-on clients (Teams,
/// Slack, Discord) are deliberately ignored — see [ConferencingApp.persistent];
/// they need the native frontmost-window / audio seam to detect reliably.
class ProcessMeetingSignalCollector implements MeetingSignalCollector {
  /// Creates a [ProcessMeetingSignalCollector].
  ///
  /// [runProcessList] is injectable for testing; it defaults to the real
  /// platform command and returns the raw stdout lines.
  ProcessMeetingSignalCollector({Future<List<String>> Function()? runProcessList})
      : _runProcessList = runProcessList ?? _defaultProcessList;

  final Future<List<String>> Function() _runProcessList;

  @override
  Future<List<MeetingSignal>> sample(DateTime now) async {
    final List<String> lines;
    try {
      lines = await _runProcessList();
    } on Object {
      return const [];
    }
    // One signal per distinct app, even if it spawns several helper processes.
    final seen = <String>{};
    final signals = <MeetingSignal>[];
    for (final line in lines) {
      final app = matchPerMeetingProcess(line);
      if (app != null && seen.add(app.name)) {
        signals.add(MeetingSignal(
          kind: MeetingSignalKind.conferencingApp,
          active: true,
          at: now,
          label: app.name,
        ));
      }
    }
    return signals;
  }

  static Future<List<String>> _defaultProcessList() async {
    if (Platform.isWindows) {
      final result = await Process.run('tasklist', ['/fo', 'csv', '/nh']);
      return _splitLines(result.stdout);
    }
    // macOS + Linux: list every process's command name/path.
    final result = await Process.run('ps', ['-axo', 'comm']);
    return _splitLines(result.stdout);
  }

  static List<String> _splitLines(Object? stdout) {
    if (stdout is! String) {
      return const [];
    }
    return stdout
        .split('\n')
        .map((l) => l.trim())
        .where((l) => l.isNotEmpty)
        .toList(growable: false);
  }
}
