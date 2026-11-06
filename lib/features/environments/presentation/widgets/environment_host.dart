import 'package:flutter/widgets.dart';

/// Marks a terminal tab as where a stopped start finishes, so it can say why it
/// opened. Kept in the tab's args, which survive a restored layout.
const kEnvironmentSetupTabArg = 'environmentSetup';

/// What the surface hosting an environment section can open.
///
/// The IDE and the PR page own different tab vocabularies, so each publishes
/// one of these through [EnvironmentHostScope]. A surface with no editor finds
/// none, and the section drops the actions that need one.
@immutable
class EnvironmentHost {
  /// Creates an [EnvironmentHost].
  const EnvironmentHost({
    required this.openUrl,
    required this.openBrowserVm,
    required this.openLogs,
    required this.openProvisioningLogs,
    required this.openProcess,
    required this.openSetup,
    required this.openViewer,
    required this.openPrefilledTerminal,
    required this.showsSpace,
  });

  /// Opens a URL in a webview tab.
  final void Function({required String url, required String label}) openUrl;

  /// Focuses the space's Browser (VM) tab.
  final void Function({required String spaceId}) openBrowserVm;

  /// Opens the logs tab of a process or service.
  final void Function({
    required String spaceId,
    required String target,
    required String label,
  })
  openLogs;

  /// Opens the tab following what a space's workspace preparation prints.
  final void Function({required String spaceId}) openProvisioningLogs;

  /// Opens a terminal tab attached to a process's PTY session.
  final void Function({
    required String spaceId,
    required String sessionId,
    required String label,
  })
  openProcess;

  /// Opens the terminal tab a stopped start finishes in: [openProcess], with a
  /// notice on the tab saying why it appeared.
  final void Function({
    required String spaceId,
    required String sessionId,
    required String label,
  })
  openSetup;

  /// Opens the viewer tab of a desktop app.
  final void Function({
    required String spaceId,
    required String componentId,
    required String label,
  })
  openViewer;

  /// Opens a space terminal with a command typed at the prompt, not run.
  final void Function({required String spaceId, required String command})
  openPrefilledTerminal;

  /// Whether this surface is still up and on `spaceId`. A Start can take long
  /// enough for someone to have left by the time it answers.
  final bool Function(String spaceId) showsSpace;
}

/// Publishes an [EnvironmentHost] to a subtree.
class EnvironmentHostScope extends InheritedWidget {
  /// Creates an [EnvironmentHostScope].
  const EnvironmentHostScope({
    super.key,
    required this.host,
    required super.child,
  });

  /// The host's actions.
  final EnvironmentHost host;

  /// The nearest host, or null outside an editor layout.
  static EnvironmentHost? maybeOf(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<EnvironmentHostScope>()?.host;

  @override
  bool updateShouldNotify(EnvironmentHostScope oldWidget) =>
      oldWidget.host != host;
}
