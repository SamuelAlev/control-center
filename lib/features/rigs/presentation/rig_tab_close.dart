// The close prompt for a rig tab whose machine is still up.
//
// The tab is a VIEWER: closing it used to silently leave the guest running,
// or (earlier) destroy it without asking. Both are decisions only the person
// closing the tab can make, so this asks. Shared by the messaging IDE and the
// PR workbench — the PR page's interceptor used to only prompt for dirty
// files, which is why closing a browser-rig tab there skipped the question.
library;

import 'package:cc_ui/cc_ui.dart';
import 'package:control_center/features/rigs/presentation/rig_tab_surfaces.dart';
import 'package:control_center/features/rigs/providers/rig_providers.dart';
import 'package:control_center/l10n/app_localizations.dart';
import 'package:control_center/shared/editor/editor_live_close.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Asks whether to keep the machine behind a rig tab running or shut it down.
/// Returns whether the tab may close.
///
/// Nothing booted → nothing to ask about. A failed boot is dismissed quietly
/// (keeping the dump would resurrect it on the next open). A boot still in
/// flight counts: that machine already exists, and abandoning it halfway is
/// the most expensive thing to leave behind.
Future<bool> confirmCloseLiveRigTab({
  required BuildContext context,
  required WidgetRef ref,
  required String title,
  required String? workspaceId,
  required String? conversationId,
  required Map<String, Object?> args,
}) async {
  if (workspaceId == null || conversationId == null) {
    return true;
  }
  final key = (
    workspaceId: workspaceId,
    conversationId: conversationId,
    surface: args['surface'] as String? ?? RigTabSurfaces.computer,
    engine: RigTabSurfaces.browserEngineOf(args),
    slotId: RigTabSurfaces.slotFromArgs(args),
  );
  final rig =
      ref.read(conversationRigProvider(key)) ??
      ref.read(conversationPendingRigProvider(key));
  if (rig == null) {
    return true;
  }
  if (rig.isFailed) {
    await _destroyRig(ref, workspaceId, rig.id, context: context);
    return true;
  }
  final l10n = AppLocalizations.of(context);
  final choice = await confirmCloseLiveTab(
    context: context,
    title: title,
    body: l10n.ideCloseKeepBodyMachine,
    shutDownLabel: l10n.ideCloseShutDownMachine,
  );
  switch (choice) {
    case LiveTabCloseChoice.cancel:
      return false;
    case LiveTabCloseChoice.keepRunning:
      return true;
    case LiveTabCloseChoice.shutDown:
      await _destroyRig(
        ref,
        workspaceId,
        rig.id,
        context: context.mounted ? context : null,
      );
      return true;
  }
}

Future<void> _destroyRig(
  WidgetRef ref,
  String workspaceId,
  String rigId, {
  BuildContext? context,
}) async {
  try {
    await ref.read(rigRepositoryProvider).destroy(workspaceId, rigId);
  } on Object catch (e) {
    if (context != null && context.mounted) {
      CcToastScope.of(context).show('$e', variant: CcToastVariant.danger);
    }
  }
}
