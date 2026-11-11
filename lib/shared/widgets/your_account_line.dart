import 'package:cc_domain/core/domain/value_objects/forge_connection.dart'
    show ForgeConnectionStatus;
import 'package:cc_ui/cc_ui.dart';
import 'package:control_center/l10n/app_localizations.dart';
import 'package:control_center/router/routes.dart';
import 'package:control_center/shared/icons/app_icons.dart';
import 'package:flutter/widgets.dart';
import 'package:go_router/go_router.dart';

/// What one of the reader's own accounts says in a [YourAccountLine]: the
/// account while it works, otherwise the state it is stuck in.
String yourAccountEntry(
  AppLocalizations l10n, {
  required String provider,
  required ForgeConnectionStatus status,
  String account = '',
}) => l10n.yourAccountEntry(provider, switch (status) {
  ForgeConnectionStatus.connected =>
    account.isEmpty ? l10n.connectedLabel : account,
  ForgeConnectionStatus.needsSignIn => l10n.linkedAccountStatusNeedsSignIn,
  ForgeConnectionStatus.paused => l10n.linkedAccountStatusPaused,
  ForgeConnectionStatus.unreachable => l10n.linkedAccountStatusUnreachable,
  ForgeConnectionStatus.notConnected => l10n.notConnected,
});

/// The reader's own account for one provider group on Workspace →
/// Integrations, in one line that leads to the connected accounts on their
/// profile (You → Profile).
///
/// The workspace page holds what the workspace decides; a person's sign-ins
/// are theirs and are managed on their profile. This line is the bridge:
/// it answers "am I connected here?" where the workspace setup sits, without
/// putting the controls back on a page whose changes affect everyone.
///
/// The whole line is the link. It says so with its hover wash and cursor,
/// not a chevron, like every settings row that opens elsewhere.
class YourAccountLine extends StatelessWidget {
  /// Creates a [YourAccountLine].
  const YourAccountLine({
    super.key,
    required this.workspaceId,
    required this.status,
    this.attention = false,
  });

  /// The workspace settings were opened from, which the destination keeps.
  final String workspaceId;

  /// The reader's account(s) for this group, already localized: entries
  /// built with [yourAccountEntry], or a sentence saying there are none.
  final String status;

  /// Whether the reader has something to fix (nothing connected, or a grant
  /// that stopped working). Tints the glyph; [status] says what in words.
  final bool attention;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final t = context.designSystem ?? DesignSystemTokens.light();
    final caption = CcTypography.caption.copyWith(color: t.textTertiary);
    return CcTappable(
      onPressed: () => context.go(settingsAccountsRoute(workspaceId)),
      semanticLabel: l10n.yourAccountLineSemantics(status),
      mouseCursor: SystemMouseCursors.click,
      builder: (context, states) => AnimatedContainer(
        duration: CcMotion.fast,
        padding: const EdgeInsetsDirectional.symmetric(
          horizontal: AppSpacing.lg,
          vertical: AppSpacing.sm + AppSpacing.xxs,
        ),
        decoration: BoxDecoration(
          color: states.contains(WidgetState.hovered)
              ? t.hover
              : const Color(0x00000000),
          border: Border.all(color: t.borderSecondary),
        ),
        // The semantic label says all of it once; the parts would repeat it.
        child: ExcludeSemantics(
          child: Row(
            children: [
              Icon(
                AppIcons.userRound,
                size: 14,
                color: attention ? t.fgWarningPrimary : t.fgTertiary,
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Text.rich(
                  TextSpan(
                    children: [
                      TextSpan(text: l10n.yourAccountLabel, style: caption),
                      const TextSpan(text: '  '),
                      TextSpan(
                        text: status,
                        style: CcTypography.bodySm.copyWith(
                          color: t.textPrimary,
                        ),
                      ),
                    ],
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              CcLinkText(
                l10n.linkedAccountsTitle,
                style: CcTypography.caption.copyWith(color: t.textSecondary),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
