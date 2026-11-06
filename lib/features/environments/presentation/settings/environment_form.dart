import 'package:cc_domain/features/environments/domain/value_objects/environment_definition.dart';
import 'package:cc_ui/cc_ui.dart';
import 'package:control_center/features/environments/presentation/settings/environment_editor_state.dart';
import 'package:flutter/widgets.dart';

/// The gap between two fields of a form.
const SizedBox environmentFieldGap = SizedBox(height: AppSpacing.md);

/// The face of a machine value in a field.
TextStyle environmentCodeStyle() =>
    CcFonts.code(textStyle: CcTypography.bodySm);

/// Reads and writes the draft for a form.
///
/// A form takes one of these rather than the notifier so it stays a plain
/// widget: every read and write goes through a path into the JSON, which is
/// what keeps the keys a form doesn't know about intact.
class EnvironmentForm {
  /// Creates an [EnvironmentForm].
  EnvironmentForm({
    required this.workspaceId,
    required this.state,
    required this.notifier,
    required this.enabled,
    Set<String>? linkedRepoIds,
  }) : issues = state.issuesFor(linkedRepoIds);

  /// The owning workspace.
  final String workspaceId;

  /// The current state.
  final EnvironmentEditorState state;

  /// Applies edits.
  final EnvironmentEditorNotifier notifier;

  /// False for someone who can read but not change definitions.
  final bool enabled;

  /// Every known problem with the draft.
  final List<EnvironmentDefinitionIssue> issues;

  /// The value at [path].
  Object? value(List<Object> path) => environmentJsonGet(state.draft, path);

  /// The text at [path].
  String text(List<Object> path) {
    final found = value(path);
    return found == null ? '' : '$found';
  }

  /// The list at [path], or an empty one.
  List<Object?> list(List<Object> path) {
    final found = value(path);
    return found is List ? List<Object?>.of(found) : <Object?>[];
  }

  /// The strings at [path].
  List<String> strings(List<Object> path) => [
    for (final item in list(path)) '$item',
  ];

  /// What the validator says about [path], or null.
  String? issue(List<Object> path) {
    final wanted = environmentIssuePath(path);
    for (final issue in issues) {
      if (issue.path == wanted) {
        return issue.message;
      }
    }
    return null;
  }

  /// Whether the validator has anything to say at or below [path]. A collapsed
  /// row can't show its fields' errors, so it has to admit to them.
  bool hasIssueUnder(List<Object> path) {
    final root = environmentIssuePath(path);
    return issues.any(
      (issue) =>
          issue.path == root ||
          issue.path.startsWith('$root.') ||
          issue.path.startsWith('$root['),
    );
  }

  /// A key that rebuilds a field when list positions move.
  Key key(List<Object> path) =>
      ValueKey('${state.revision}:${environmentIssuePath(path)}');
}
