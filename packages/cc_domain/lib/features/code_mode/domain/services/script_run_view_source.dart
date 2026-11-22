import 'dart:collection';

import 'package:cc_domain/features/code_mode/domain/entities/script_outline.dart';
import 'package:cc_domain/features/code_mode/domain/services/script_outline_parser.dart';
import 'package:cc_domain/features/code_mode/domain/services/script_run_view.dart';

/// How many script texts [cachedScriptOutline] remembers.
const int scriptOutlineCacheSize = 32;

final LinkedHashMap<String, ScriptOutline> _outlines =
    LinkedHashMap<String, ScriptOutline>();

/// [parseScriptOutline] of [source], parsed once while it is among the
/// [scriptOutlineCacheSize] texts asked for most recently. A conversation
/// rebuilds on every streamed token; the script text does not change.
ScriptOutline cachedScriptOutline(String source) {
  final hit = _outlines.remove(source);
  if (hit != null) {
    _outlines[source] = hit;
    return hit;
  }
  final outline = parseScriptOutline(source);
  _outlines[source] = outline;
  if (_outlines.length > scriptOutlineCacheSize) {
    _outlines.remove(_outlines.keys.first);
  }
  return outline;
}

/// The view of a script's [calls], or null when they are better listed flat
/// in the order made.
///
/// Flat when there is no script text, when the outline is unparsed, when
/// calls were made but none says where (a runner that reports no sites: a
/// tree would show every made call as unplaced and every node as not
/// reached), and when calls were made but the script has no call node. A
/// script with no call node and no call gives an empty view: nothing to
/// show.
ScriptRunView<T>? scriptRunViewOrFlat<T>({
  required String? source,
  required List<ScriptRunCall<T>> calls,
  required bool ended,
}) {
  if (source == null || source.trim().isEmpty) {
    return null;
  }
  final outline = cachedScriptOutline(source);
  if (outline.unparsed) {
    return null;
  }
  if (calls.isNotEmpty &&
      (outline.nodes.isEmpty || calls.every((call) => call.line == null))) {
    return null;
  }
  return cachedScriptRunView(outline: outline, calls: calls, ended: ended);
}

/// How many views [cachedScriptRunView] remembers.
const int scriptRunViewCacheSize = 32;

final LinkedHashMap<_ViewKey, Object> _views =
    LinkedHashMap<_ViewKey, Object>();

/// [buildScriptRunView], built once while its inputs are the same and among
/// the [scriptRunViewCacheSize] asked for most recently: the same outline
/// object, [ended], and calls with the same payloads (the same objects, or
/// equal ones: a record around the same segment), names, positions and
/// states. A streaming conversation rebuilds the open script
/// row on every token; comparing the inputs costs a pass over the calls,
/// building the view much more.
ScriptRunView<T> cachedScriptRunView<T>({
  required ScriptOutline outline,
  required List<ScriptRunCall<T>> calls,
  required bool ended,
}) {
  final key = _ViewKey(outline, calls, ended, T);
  final hit = _views.remove(key);
  if (hit is ScriptRunView<T>) {
    _views[key] = hit;
    return hit;
  }
  final view = buildScriptRunView(outline: outline, calls: calls, ended: ended);
  _views[key] = view;
  if (_views.length > scriptRunViewCacheSize) {
    _views.remove(_views.keys.first);
  }
  return view;
}

final class _ViewKey {
  _ViewKey(this.outline, this.calls, this.ended, this.type)
    : hashCode = Object.hash(
        identityHashCode(outline),
        ended,
        type,
        Object.hashAll([
          for (final call in calls)
            // Payloads are compared, not hashed: hashing a segment reads its
            // whole input.
            Object.hash(
              call.toolName,
              call.line,
              call.column,
              call.running,
              call.failed,
              call.startMs,
              call.endMs,
            ),
        ]),
      );

  final ScriptOutline outline;
  final List<ScriptRunCall<Object?>> calls;
  final bool ended;
  final Type type;

  @override
  final int hashCode;

  @override
  bool operator ==(Object other) {
    if (other is! _ViewKey ||
        other.hashCode != hashCode ||
        !identical(other.outline, outline) ||
        other.ended != ended ||
        other.type != type ||
        other.calls.length != calls.length) {
      return false;
    }
    for (var i = 0; i < calls.length; i++) {
      final a = calls[i];
      final b = other.calls[i];
      if (!(identical(a.payload, b.payload) || a.payload == b.payload) ||
          a.toolName != b.toolName ||
          a.line != b.line ||
          a.column != b.column ||
          a.running != b.running ||
          a.failed != b.failed ||
          a.startMs != b.startMs ||
          a.endMs != b.endMs) {
        return false;
      }
    }
    return true;
  }
}
