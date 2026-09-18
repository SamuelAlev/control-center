import 'package:cc_ui/cc_ui.dart';
import 'package:control_center/features/rigs/providers/rig_clipboard_permissions.dart';
import 'package:control_center/l10n/app_localizations.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// A choice made when clipboard content is about to cross an enclosure.
enum RigClipboardPermissionDecision {
  /// Allow this direction for this rig for ten minutes.
  tenMinutes,

  /// Persist the direction as allowed for this user.
  always,
}

/// Returns whether clipboard content may cross [direction] for [rigId].
///
/// Durable user preferences win first, then a rig-and-direction-scoped
/// temporary grant. Only when neither applies does this present the consent
/// dialog. The clipboard itself is not read until this returns true.
Future<bool> ensureRigClipboardPermission({
  required BuildContext context,
  required WidgetRef ref,
  required String rigId,
  required RigClipboardDirection direction,
}) async {
  final preferences = ref.read(rigClipboardPreferencesProvider);
  if (preferences.allows(direction)) {
    return true;
  }
  final grants = ref.read(rigClipboardSessionGrantsProvider);
  if (grants.allows(rigId, direction)) {
    return true;
  }
  final decision = await showRigClipboardPermissionDialog(
    context: context,
    direction: direction,
  );
  if (!context.mounted || decision == null) {
    return false;
  }
  switch (decision) {
    case RigClipboardPermissionDecision.tenMinutes:
      grants.allowForTenMinutes(rigId, direction);
    case RigClipboardPermissionDecision.always:
      await ref
          .read(rigClipboardPreferencesProvider.notifier)
          .setAlwaysAllowed(direction, allowed: true);
  }
  return context.mounted;
}

/// Requests permission before clipboard content crosses the enclosure boundary.
Future<RigClipboardPermissionDecision?> showRigClipboardPermissionDialog({
  required BuildContext context,
  required RigClipboardDirection direction,
}) {
  final l10n = AppLocalizations.of(context);
  final title = switch (direction) {
    RigClipboardDirection.hostToRig =>
      l10n.rigClipboardPermissionHostToRigTitle,
    RigClipboardDirection.rigToHost =>
      l10n.rigClipboardPermissionRigToHostTitle,
  };
  final body = switch (direction) {
    RigClipboardDirection.hostToRig => l10n.rigClipboardPermissionHostToRigBody,
    RigClipboardDirection.rigToHost => l10n.rigClipboardPermissionRigToHostBody,
  };

  return showCcDialog<RigClipboardPermissionDecision>(
    context: context,
    builder: (dialogContext) => CcDialog(
      title: title,
      content: Text(body),
      actions: [
        CcButton(
          variant: CcButtonVariant.secondary,
          onPressed: () => Navigator.pop(dialogContext),
          child: Text(l10n.cancel),
        ),
        CcButton(
          variant: CcButtonVariant.secondary,
          onPressed: () => Navigator.pop(
            dialogContext,
            RigClipboardPermissionDecision.tenMinutes,
          ),
          child: Text(l10n.rigClipboardAllowTenMinutes),
        ),
        CcButton(
          onPressed: () => Navigator.pop(
            dialogContext,
            RigClipboardPermissionDecision.always,
          ),
          child: Text(l10n.rigClipboardAlwaysAllow),
        ),
      ],
    ),
  );
}
