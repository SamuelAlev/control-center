// How a rig surface says what the person may not do with it: watch only (no
// write grant on the space), or nothing at all (the space is unreadable).
library;

import 'package:cc_ui/cc_ui.dart';
import 'package:control_center/features/forge/presentation/widgets/repo_code_failure_view.dart';
import 'package:control_center/features/messaging/presentation/space_access_refusal.dart';
import 'package:control_center/l10n/app_localizations.dart';
import 'package:control_center/shared/icons/app_icons.dart';
import 'package:flutter/widgets.dart';

/// The quiet strip above a machine this person may only watch. Shown once,
/// in place, instead of a refusal on every click or keystroke.
class RigWatchOnlyNote extends StatelessWidget {
  /// Creates the note.
  const RigWatchOnlyNote({super.key, this.holderOnly = false});

  /// Whether the reason is that the machine carries somebody else's
  /// sign-ins (rather than the space's write grant).
  final bool holderOnly;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final t = context.designSystem ?? DesignSystemTokens.light();
    return Padding(
      padding: const EdgeInsetsDirectional.fromSTEB(8, 6, 8, 6),
      child: Row(
        children: [
          CcBadge(label: l10n.rigWatchOnlyBadge, icon: AppIcons.eye),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              holderOnly ? l10n.rigHolderOnlyHint : l10n.rigWatchOnlyHint,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: CcTypography.caption.copyWith(color: t.textTertiary),
            ),
          ),
        ],
      ),
    );
  }
}

/// In place of a machine the person may not even watch: the space's refusal
/// in words when the server gave one by kind, else that the machine belongs
/// to a space they cannot read (a lane's bare 403).
class RigAccessRefused extends StatelessWidget {
  /// Creates the view for [refusal].
  const RigAccessRefused({super.key, required this.refusal, this.workspaceId});

  /// The refused op's error, or null for a lane's 403.
  final Object? refusal;

  /// The workspace a sign-in starts from.
  final String? workspaceId;

  @override
  Widget build(BuildContext context) => RepoCodeFailureView(
    error: refusal,
    fallback: AppLocalizations.of(context).rigViewRefused,
    workspaceId: workspaceId,
    describe: spaceAccessFailureOf,
  );
}
