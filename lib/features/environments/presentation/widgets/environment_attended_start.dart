import 'dart:async';

import 'package:cc_domain/features/environments/domain/entities/environment_definition_record.dart';
import 'package:control_center/features/environments/presentation/widgets/environment_host.dart';
import 'package:control_center/features/environments/providers/environment_providers.dart';
import 'package:control_center/l10n/app_localizations.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Whether a start of [record] can carry on at a terminal when its tool needs
/// a person: some verb of it is declared `interactive`.
bool environmentCanFinishOnTerminal(EnvironmentDefinitionRecord? record) {
  final definition = record == null ? null : environmentDefinitionOf(record);
  return definition?.canFinishOnTerminal ?? false;
}

/// A start someone pressed, followed to the terminal it may need.
///
/// A tool that wants a password can't ask through the pipe a start runs on.
/// Told that a person is there ([attended]), the server runs that step on a
/// terminal and the same start waits for it: the environment keeps reading
/// "starting", and names the session. [follow] opens that session as a tab
/// for the person who pressed, the moment it appears.
///
/// Everything is taken while the pressed widget is still there. It won't be
/// afterwards: the row a start creates replaces the Start button long before
/// the call returns, so nothing here goes back to that widget's context or
/// ref.
class AttendedStart {
  /// Takes what it needs from the widget being pressed.
  AttendedStart.of(BuildContext context, WidgetRef ref)
    : _host = EnvironmentHostScope.maybeOf(context),
      _label = AppLocalizations.of(context).environmentStartTerminalTab,
      _watch = ref.read(spaceEnvironmentsWatchProvider);

  final EnvironmentHost? _host;
  final String _label;
  final SpaceEnvironmentsWatch _watch;

  /// Whether this surface can show a terminal, which is what a start is told.
  /// One with no editor has nowhere to put it: its start stops and waits.
  bool get attended => _host != null;

  /// Runs [start], opening each terminal the environment of [key] waits on
  /// while it runs.
  ///
  /// Someone who has moved to another space gets no tab: it would land in the
  /// wrong space, with nobody there to answer. The environment keeps the way
  /// back for when they return.
  Future<void> follow(
    EnvironmentSpaceKey key,
    Future<void> Function() start,
  ) async {
    final host = _host;
    if (host == null) {
      return start();
    }
    final opened = <String>{};
    final subscription = _watch(key).listen(
      (environments) {
        for (final environment in environments) {
          final sessionId = environment.interactiveComponent?.sessionId;
          if (sessionId != null &&
              host.showsSpace(key.spaceId) &&
              opened.add(sessionId)) {
            host.openStartTerminal(
              spaceId: key.spaceId,
              sessionId: sessionId,
              label: _label,
            );
          }
        }
      },
      // The environment still says a terminal waits, with a way to it.
      onError: (Object _) {},
    );
    try {
      await start();
    } finally {
      await subscription.cancel();
    }
  }
}
