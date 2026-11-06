import 'package:control_center/features/environments/presentation/settings/environment_editor_state.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// The editing session the URL's definition is open on.
class EnvironmentEditorSelection extends Notifier<EnvironmentEditorSeed?> {
  @override
  EnvironmentEditorSeed? build() => null;

  /// Starts a session on [seed].
  void open(EnvironmentEditorSeed seed) => state = seed;
}

/// The session of the definition open on the settings page.
///
/// Which definition is open is the URL's to say. Only an open definition watches
/// this, so leaving one for the list drops its session rather than reopening a
/// stale draft next time. That also drops anything written while nothing is
/// open: opening one goes through [environmentEditorRequestProvider] instead.
final environmentEditorSelectionProvider =
    NotifierProvider.autoDispose<
      EnvironmentEditorSelection,
      EnvironmentEditorSeed?
    >(EnvironmentEditorSelection.new);

/// The seed to open a definition's URL on, when the caller already has one.
class EnvironmentEditorRequest extends Notifier<EnvironmentEditorSeed?> {
  @override
  EnvironmentEditorSeed? build() => null;

  /// Asks the settings page to open [seed]; null clears it.
  void request(EnvironmentEditorSeed? seed) => state = seed;
}

/// What the settings page should open next. Outlives the page, so the request
/// is still here when the URL lands on the definition.
final environmentEditorRequestProvider =
    NotifierProvider<EnvironmentEditorRequest, EnvironmentEditorSeed?>(
      EnvironmentEditorRequest.new,
    );

/// A repo whose definition Settings → Repositories asked to open.
class EnvironmentRepoFocus extends Notifier<String?> {
  @override
  String? build() => null;

  /// Asks the settings page to open [repoId]'s definition; null clears it.
  void focus(String? repoId) => state = repoId;
}

/// The repo the settings page should open next.
final environmentRepoFocusProvider =
    NotifierProvider<EnvironmentRepoFocus, String?>(EnvironmentRepoFocus.new);
