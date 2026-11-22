import 'dart:convert';
import 'dart:math';

import 'package:cc_domain/features/code_mode/domain/entities/code_execution_call.dart';
import 'package:cc_domain/features/code_mode/domain/services/utf8_bounds.dart';
import 'package:cc_domain/features/dispatch/domain/entities/agent_process_event.dart';
import 'package:cc_infra/src/util/command_redaction.dart';

/// What a run keeps of the calls a script makes: their transcript rows, run
/// log lines and live events all come from the events [bound] returns, so a
/// script that makes thousands of calls with arguments and results at their
/// size limits cannot write more than this into the server's memory, the
/// workspace database or the run's log.
///
/// The model never sees these rows (only the script's own result goes back),
/// so a preview loses nothing to the run. A row keeps the tool's name (at most
/// [maxToolNameChars]), its id, how it ended and a preview of its arguments
/// and result: at most [maxArgumentsBytes] and [maxResultBytes] each, and at
/// most [maxPreviewBytesPerScript] across all the calls one script makes.
/// Past that a row keeps no arguments and no result. A row keeps no images or
/// attachments and no partial output. The execution record keeps each call's
/// redacted arguments separately ([CodeExecutionCall.maxArgumentsBytes]).
class NestedCallRows {
  /// The most argument JSON one row keeps, in UTF-8 bytes: what the execution
  /// record keeps of a call.
  static const int maxArgumentsBytes = CodeExecutionCall.maxArgumentsBytes;

  /// The most result text one row keeps, in UTF-8 bytes.
  static const int maxResultBytes = 8 * 1024;

  /// The most argument and result preview the rows of one script keep
  /// together, in UTF-8 bytes.
  static const int maxPreviewBytesPerScript = 256 * 1024;

  /// The most characters of a tool name a row keeps (a script can name a
  /// tool that does not exist).
  static const int maxToolNameChars = 256;

  /// The most JSON values one row's kept argument structure holds: argument
  /// JSON made of empty objects takes far more memory than its size, so a
  /// value with more parts than this is kept as its JSON text.
  static const int maxArgumentValues = 256;

  /// What each value of a kept argument structure is charged at least, in
  /// bytes, against the row and the script: about what it takes in memory,
  /// so a script cannot keep megabytes of tiny values within a 256 KiB bound.
  static const int bytesPerKeptValue = 64;

  /// The most scripts whose spent preview is tracked at once; the oldest is
  /// forgotten past it.
  static const int maxTrackedScripts = 64;

  final Map<String, int> _spent = {};

  /// [event] as the run keeps it: unchanged unless it is a call a script made
  /// (`parentToolCallId` set) or the end of the call that ran one. Null for
  /// an event the run keeps nothing of (a nested call's partial output).
  AgentProcessEvent? bound(AgentProcessEvent event) {
    switch (event) {
      case ToolCallEvent(:final parentToolCallId?):
        final inputs = event.inputs;
        return ToolCallEvent(
          toolName: _name(event.toolName),
          toolCallId: event.toolCallId,
          inputs: inputs == null ? null : _inputs(parentToolCallId, inputs),
          parentToolCallId: parentToolCallId,
          callSite: event.callSite,
          timestamp: event.timestamp,
        );
      case ToolResultEvent(:final parentToolCallId?):
        if (event.isPartial) {
          return null;
        }
        final name = event.toolName;
        return ToolResultEvent(
          toolCallId: event.toolCallId,
          outputs: _text(parentToolCallId, event.outputs, maxResultBytes),
          toolName: name == null ? null : _name(name),
          isError: event.isError,
          parentToolCallId: parentToolCallId,
          outcome: event.outcome,
          timestamp: event.timestamp,
        );
      case ToolResultEvent(:final toolCallId) when !event.isPartial:
        // The call that ran a script ended: its scripts' rows are done.
        _spent.remove(toolCallId);
        return event;
      default:
        return event;
    }
  }

  static String _name(String name) => name.length <= maxToolNameChars
      ? name
      : '${name.substring(0, maxToolNameChars)}…';

  int _room(String parent, int cap) {
    final spent = _spent.remove(parent) ?? 0;
    _spent[parent] = spent;
    while (_spent.length > maxTrackedScripts) {
      _spent.remove(_spent.keys.first);
    }
    final left = maxPreviewBytesPerScript - spent;
    return left < cap ? left : cap;
  }

  void _spend(String parent, int bytes) {
    _spent[parent] = (_spent[parent] ?? 0) + bytes;
  }

  String _text(String parent, String text, int cap) {
    final kept = _fit(text, _room(parent, cap));
    if (kept == null) {
      return '';
    }
    _spend(parent, _jsonBytes(kept));
    return kept;
  }

  /// How far past a cut, in characters, text is redacted before it is cut,
  /// so a secret that straddles the cut is recognised whole and no prefix of
  /// it is kept. The longest single-line secrets the patterns describe
  /// (`token_patterns.dart`, `command_redaction.dart`) are a GitHub
  /// installation token (about 520 characters, kept to its `@` in an
  /// `x-access-token:` URL) and a signed JWT (an ID token runs to about
  /// 2 KiB); 4 KiB holds either with the user name or header before it. A
  /// shape with a fixed prefix (`ghp_`, `sk-`, …) needs only its minimum
  /// length, at most 33 characters. A private key block whose end lies
  /// beyond the window is redacted from its `BEGIN` line.
  static const int redactionReach = 4 * 1024;

  /// [text] whole when it takes at most [room] bytes as a JSON string (how a
  /// row is stored: a newline takes two bytes there, a control character
  /// six); otherwise redacted up to [redactionReach] past the cut, cut, and
  /// ended with a marker that names its full size. Null when not even the
  /// marker fits. Text kept whole is redacted where it is logged, whole.
  static String? _fit(String text, int room) {
    if (_jsonBytes(text) <= room) {
      return text;
    }
    final marker = '… [${utf8Length(text)} bytes, truncated]';
    final target = room - _jsonBytes(marker);
    if (target <= 0) {
      return null;
    }
    // Never more than the cut and the reach is redacted, however long the
    // text: a cut takes at most [room] bytes, so at most that many
    // characters.
    final window = redactSecrets(
      text.length <= room + redactionReach
          ? text
          : text.substring(0, room + redactionReach),
    );
    var limit = target;
    for (var tries = 0; tries < 5 && limit > 0; tries++) {
      final head = cutToUtf8Bytes(window, limit);
      // The JSON form of `head + marker` is the two parts' forms joined.
      final used = _jsonBytes(head) - 2;
      if (used <= target) {
        return '$head$marker';
      }
      // Each escaped byte takes at most six: the last try always fits.
      limit = tries < 3 ? limit * target ~/ used : target ~/ 6;
    }
    return null;
  }

  static int _jsonBytes(String text) => utf8Length(jsonEncode(text));

  Map<String, dynamic> _inputs(String parent, Map<String, dynamic> inputs) {
    var room = _room(parent, maxArgumentsBytes);
    final kept = <String, dynamic>{};
    var values = 0;
    var spent = 0;
    for (final MapEntry(:key, :value) in inputs.entries) {
      final keyBytes = utf8Length(key) + 4;
      if (room - keyBytes <= 0) {
        break;
      }
      room -= keyBytes;
      spent += keyBytes;
      final parts = _valueCount(value, maxArgumentValues - values + 1);
      final json = jsonEncode(value);
      final bytes = max(utf8Length(json), parts * bytesPerKeptValue);
      if (bytes <= room && values + parts <= maxArgumentValues) {
        kept[key] = value;
        values += parts;
        room -= bytes;
        spent += bytes;
        continue;
      }
      final cut = _fit(value is String ? value : json, room);
      if (cut == null) {
        break;
      }
      kept[key] = cut;
      values++;
      final cutBytes = _jsonBytes(cut);
      room -= cutBytes;
      spent += cutBytes;
    }
    _spend(parent, spent);
    return kept;
  }

  /// How many JSON values [value] holds, itself included, counting no
  /// further than [limit].
  static int _valueCount(Object? value, int limit) {
    var count = 1;
    final open = <Iterator<Object?>>[
      if (value is Map)
        value.values.iterator
      else if (value is List)
        value.iterator,
    ];
    while (open.isNotEmpty && count < limit) {
      final top = open.last;
      if (!top.moveNext()) {
        open.removeLast();
        continue;
      }
      count++;
      final next = top.current;
      if (next is Map) {
        open.add(next.values.iterator);
      } else if (next is List) {
        open.add(next.iterator);
      }
    }
    return count;
  }
}
