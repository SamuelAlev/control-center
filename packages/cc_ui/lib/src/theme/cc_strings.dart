import 'package:flutter/foundation.dart';

/// The words cc_ui itself puts in front of a person or a screen reader: the
/// accessible names of controls the package draws on its own (a dialog's close
/// button, a chip's remove button, a spinner) and the few labels it paints.
///
/// cc_ui has no localization of its own, so the host supplies these through
/// `CcThemeData.strings`. [CcStrings.english] is what the package uses when it
/// runs alone (the gallery, package tests); an app with translations passes
/// its own.
@immutable
class CcStrings {
  /// Creates a set of strings.
  const CcStrings({
    required this.close,
    required this.dismiss,
    required this.loading,
    required this.progress,
    required this.breadcrumb,
    required this.dialog,
    required this.clear,
    required this.clearAll,
    required this.resize,
    required this.notifications,
    required this.noMatches,
    required this.selectedCount,
    required this.remove,
    required this.unverified,
  });

  /// English, for the package on its own.
  const CcStrings.english()
    : close = 'Close',
      dismiss = 'Dismiss',
      loading = 'Loading',
      progress = 'Progress',
      breadcrumb = 'Breadcrumb',
      dialog = 'Dialog',
      clear = 'Clear',
      clearAll = 'Clear all',
      resize = 'Resize',
      notifications = 'Notifications',
      noMatches = 'No matches',
      selectedCount = _englishSelectedCount,
      remove = _englishRemove,
      unverified = _englishUnverified;

  static String _englishSelectedCount(int count) => '$count selected';
  static String _englishRemove(String label) => 'Remove $label';
  static String _englishUnverified(String label) => '$label (unverified)';

  /// Name of a button that closes the surface it sits on.
  final String close;

  /// Name of a button that dismisses a message, and of a dismiss barrier.
  final String dismiss;

  /// Name of an indeterminate busy indicator.
  final String loading;

  /// Name of a progress bar that was given no label.
  final String progress;

  /// Name of a breadcrumb trail.
  final String breadcrumb;

  /// Name of a dialog that has no title.
  final String dialog;

  /// Name of a button that empties a field.
  final String clear;

  /// Label of the action that removes every selection.
  final String clearAll;

  /// Name of a divider that resizes the panes beside it.
  final String resize;

  /// Name of the region that holds toast messages.
  final String notifications;

  /// Shown in a list whose filter matches nothing.
  final String noMatches;

  /// Summary of how many options are selected.
  final String Function(int count) selectedCount;

  /// Name of a button that removes the item called `label`.
  final String Function(String label) remove;

  /// A diagram label marked as not verified.
  final String Function(String label) unverified;
}
