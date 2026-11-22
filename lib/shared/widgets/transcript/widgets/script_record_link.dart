import 'package:cc_domain/core/domain/value_objects/transcript_segment.dart';
import 'package:flutter/widgets.dart';

/// Builds the "open record" link for a finished `repl` call, or null when the
/// surface has nowhere to look for its record. The link resolves the record
/// when pressed, never while the transcript renders.
typedef ScriptRecordLinkBuilder =
    Widget? Function(BuildContext context, ToolSegment call);

/// Lets the surface around a transcript give each `repl` row a way to its
/// durable execution record.
///
/// The row knows its call, not the run or the conversation it belongs to,
/// and the shared transcript may not reach into a feature to look a record
/// up. The conversation pane and the run drawer know where they are, so they
/// provide the builder here and the row asks for it. Without a scope the row
/// offers no link.
class ScriptRecordLinkScope extends InheritedWidget {
  /// Provides [builder] to the `repl` rows under [child].
  const ScriptRecordLinkScope({
    super.key,
    required this.builder,
    required super.child,
  });

  /// Builds the link for one call.
  final ScriptRecordLinkBuilder builder;

  /// The builder of the nearest scope, or null.
  static ScriptRecordLinkBuilder? maybeOf(BuildContext context) => context
      .dependOnInheritedWidgetOfExactType<ScriptRecordLinkScope>()
      ?.builder;

  @override
  bool updateShouldNotify(ScriptRecordLinkScope oldWidget) =>
      oldWidget.builder != builder;
}
