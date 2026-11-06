import 'dart:async';
import 'dart:collection';

import 'package:cc_domain/core/domain/ports/space_provisioning_log_port.dart';
import 'package:cc_infra/src/environments/environment_log_ring.dart';
import 'package:cc_infra/src/util/command_redaction.dart';

/// `Receiving objects:  45% (9/20)`: a line git rewrites as it advances.
final RegExp _progressLine = RegExp(r'^(.+?):\s+\d{1,3}%');

/// [elapsed] the way a log line says it: `8s`, `2m 05s`.
String provisioningElapsed(Duration elapsed) {
  final seconds = elapsed.inSeconds;
  if (seconds < 60) {
    return '${seconds}s';
  }
  return '${seconds ~/ 60}m ${(seconds % 60).toString().padLeft(2, '0')}s';
}

/// [SpaceProvisioningLogPort] held in memory.
///
/// The one place preparation output passes through, so it is where lines are
/// redacted and stripped of terminal control. Up to [maxCharsPerSpace] stays
/// per space, for the [maxSpaces] spaces touched most recently; a space being
/// followed is never evicted.
class InMemorySpaceProvisioningLog implements SpaceProvisioningLogPort {
  /// Creates an [InMemorySpaceProvisioningLog].
  InMemorySpaceProvisioningLog({
    this.maxCharsPerSpace = 256 * 1024,
    this.maxSpaces = 32,
    this.maxLineChars = 8 * 1024,
  });

  /// Retained characters per space.
  final int maxCharsPerSpace;

  /// Spaces kept, oldest touched dropped first.
  final int maxSpaces;

  /// A longer line is cut, so one minified bundle can't evict the whole log.
  final int maxLineChars;

  final LinkedHashMap<(String, String), _SpaceLog> _logs = LinkedHashMap();

  @override
  void write(String workspaceId, String spaceId, String text) {
    final log = _touch(workspaceId, spaceId);
    for (final raw in text.split('\n')) {
      final line = redactSecrets(terminalVisibleLine(raw)).trimRight();
      if (line.isEmpty) {
        continue;
      }
      log.add(
        line.length > maxLineChars
            ? '${line.substring(0, maxLineChars)}…'
            : line,
        maxChars: maxCharsPerSpace,
      );
    }
  }

  @override
  Stream<SpaceProvisioningLogLine> follow(String workspaceId, String spaceId) {
    late final StreamController<SpaceProvisioningLogLine> controller;
    _SpaceLog? log;
    StreamSubscription<SpaceProvisioningLogLine>? changes;
    controller = StreamController(
      onListen: () {
        final opened = log = _touch(workspaceId, spaceId);
        opened.followers++;
        // One synchronous step, so nothing written in between is lost.
        opened.lines.forEach(controller.add);
        changes = opened.changes.listen(controller.add);
      },
      onCancel: () async {
        log?.followers--;
        await changes?.cancel();
        await controller.close();
      },
    );
    return controller.stream;
  }

  /// The log of a space, moved to the recent end, evicting past [maxSpaces].
  _SpaceLog _touch(String workspaceId, String spaceId) {
    final key = (workspaceId, spaceId);
    final log = _logs.remove(key) ?? _SpaceLog();
    _logs[key] = log;
    if (_logs.length > maxSpaces) {
      final idle = _logs.entries
          .where((entry) => entry.value.followers == 0 && entry.value != log)
          .take(_logs.length - maxSpaces)
          .map((entry) => entry.key)
          .toList();
      idle.forEach(_logs.remove);
    }
    return log;
  }
}

class _SpaceLog {
  final ListQueue<SpaceProvisioningLogLine> lines = ListQueue();
  final StreamController<SpaceProvisioningLogLine> _changes =
      StreamController.broadcast(sync: true);

  int followers = 0;
  int _chars = 0;

  /// Starts from the clock, so a log rebuilt after a restart or an eviction
  /// numbers past anything a reconnecting reader has already seen.
  int _nextSeq = DateTime.now().microsecondsSinceEpoch;
  String? _progressLabel;

  Stream<SpaceProvisioningLogLine> get changes => _changes.stream;

  void add(String text, {required int maxChars}) {
    // Only the last state of a progress bar is news: a fetch would otherwise
    // push everything before it out of the log with its own percentages.
    final label = _progressLine.firstMatch(text)?.group(1);
    final int seq;
    if (label != null && label == _progressLabel && lines.isNotEmpty) {
      final previous = lines.removeLast();
      _chars -= previous.text.length + 1;
      seq = previous.seq;
    } else {
      seq = _nextSeq++;
    }
    _progressLabel = label;
    final line = SpaceProvisioningLogLine(seq: seq, text: text);
    lines.addLast(line);
    _chars += text.length + 1;
    while (_chars > maxChars && lines.length > 1) {
      _chars -= lines.removeFirst().text.length + 1;
    }
    _changes.add(line);
  }
}
