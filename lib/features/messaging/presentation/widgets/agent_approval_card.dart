import 'package:cc_domain/cc_domain.dart' show ConfirmationRequestDto;
import 'package:cc_ui/cc_ui.dart';
import 'package:control_center/features/messaging/presentation/widgets/script_origin_line.dart';
import 'package:control_center/l10n/app_localizations.dart';
import 'package:control_center/shared/icons/app_icons.dart';
import 'package:control_center/shared/widgets/markdown/markdown_style.dart';
import 'package:flutter/widgets.dart';

/// One queued request behind the answerable card: a card-shaped edge, drawn
/// without its content because only a few pixels of its top ever show.
class ApprovalDeckLayer extends StatelessWidget {
  /// Creates an [ApprovalDeckLayer].
  const ApprovalDeckLayer({super.key});

  @override
  Widget build(BuildContext context) {
    final t = context.designSystem ?? DesignSystemTokens.light();
    return DecoratedBox(
      decoration: BoxDecoration(
        color: t.bgPrimary,
        borderRadius: BorderRadius.circular(AppRadii.lg),
        border: Border.all(color: t.borderPrimary),
        boxShadow: CcElevation.raised,
      ),
    );
  }
}

/// The answerable card at the front of the approval deck: what the agent is
/// about to do, and the ways to answer it.
class ApprovalCard extends StatelessWidget {
  /// Creates an [ApprovalCard].
  const ApprovalCard({
    super.key,
    required this.request,
    required this.busy,
    required this.onApprove,
    required this.onApproveAndRemember,
    required this.onDeny,
    this.onShowScript,
    this.onOpenConversation,
    this.rememberLeads = false,
    this.onRememberLeadsChanged,
  });

  /// The request this card answers.
  final ConfirmationRequestDto request;

  /// Whether a response is already in flight (buttons disable).
  final bool busy;

  /// Approve once.
  final VoidCallback onApprove;

  /// Approve, and stop asking for the same shape of action for a while.
  final VoidCallback onApproveAndRemember;

  /// Refuse.
  final VoidCallback onDeny;

  /// Opens the conversation at the script that raised the request; null
  /// when no script did, or there is nowhere to show it.
  final VoidCallback? onShowScript;

  /// Opens the conversation whose run is waiting on this request; null when
  /// the request names none, or there is nowhere to show it.
  final VoidCallback? onOpenConversation;

  /// Whether "approve for a while" is the button and the one-time approve
  /// sits behind its caret, instead of the other way round. Only a
  /// rememberable request has both.
  final bool rememberLeads;

  /// Told which choice the person took from behind the caret, so it leads
  /// the next card.
  final ValueChanged<bool>? onRememberLeadsChanged;

  bool get _destructive => request.severity == 'destructive';

  /// The approve control. A request the server will remember carries both
  /// ways to approve in one split button: one leads, the other waits behind
  /// the caret, and taking that one makes it lead from then on. The standing
  /// approval is narrow and expires on its own, which the tooltip says.
  Widget _approve(AppLocalizations l10n) {
    final variant = _destructive
        ? CcButtonVariant.destructive
        : CcButtonVariant.primary;
    if (!request.isRememberable) {
      return CcButton(
        variant: variant,
        size: CcButtonSize.sm,
        loading: busy,
        onPressed: busy ? null : onApprove,
        child: Text(l10n.approve),
      );
    }
    final split = CcSplitButton(
      variant: variant,
      size: CcButtonSize.sm,
      loading: busy,
      onPressed: busy
          ? null
          : (rememberLeads ? onApproveAndRemember : onApprove),
      menuSemanticLabel: l10n.prMoreActions,
      items: [
        CcMenuItem(
          label: rememberLeads ? l10n.approve : l10n.approveAndRemember,
          onSelected: () {
            onRememberLeadsChanged?.call(!rememberLeads);
            (rememberLeads ? onApprove : onApproveAndRemember)();
          },
        ),
      ],
      child: Text(rememberLeads ? l10n.approveAndRemember : l10n.approve),
    );
    return rememberLeads
        ? CcTooltip(message: l10n.approveAndRememberTooltip, child: split)
        : split;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final t = context.designSystem ?? DesignSystemTokens.light();
    final accent = switch (request.severity) {
      'destructive' => t.fgErrorPrimary,
      'warning' => t.fgWarningPrimary,
      _ => t.fgBrandPrimary,
    };

    return DefaultTextStyle(
      style: CcFonts.ui(
        textStyle: CcTypography.body.copyWith(
          color: t.textPrimary,
          decoration: TextDecoration.none,
        ),
      ),
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: t.bgPrimary,
          borderRadius: BorderRadius.circular(AppRadii.lg),
          border: Border.all(color: t.borderPrimary),
          // The design system's float. This used to be a hand-rolled shadow
          // colored `bgOverlay` — the OPAQUE full-screen scrim token — which
          // painted a hard black band under the card instead of a shadow.
          boxShadow: CcElevation.floating,
        ),
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Icon(
                    _destructive ? AppIcons.shieldAlert : AppIcons.shield,
                    size: 16,
                    color: accent,
                  ),
                  const SizedBox(width: AppSpacing.xs),
                  Expanded(
                    child: Text(
                      l10n.agentApprovalRequired,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: t.textPrimary,
                        decoration: TextDecoration.none,
                      ),
                    ),
                  ),
                ],
              ),
              if (request.origin != null) ...[
                const SizedBox(height: AppSpacing.xxs),
                ScriptOriginLine(
                  onShow: onShowScript,
                  origin: request.origin,
                  workspaceId: request.workspaceId,
                ),
              ],
              // Keep the decision visible while the full intent and script scroll.
              Flexible(
                child: CcScrollbar(
                  thumbVisibility: true,
                  child: SingleChildScrollView(
                    padding: const EdgeInsetsDirectional.only(
                      end: AppSpacing.sm,
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        if (request.title.isNotEmpty) ...[
                          const SizedBox(height: AppSpacing.sm),
                          Text(
                            request.title,
                            style: CcTypography.body.copyWith(
                              color: t.textPrimary,
                              fontWeight: FontWeight.w600,
                              decoration: TextDecoration.none,
                            ),
                          ),
                        ],
                        if (request.detail.isNotEmpty) ...[
                          const SizedBox(height: AppSpacing.xs),
                          Text(
                            request.detail,
                            style: TextStyle(
                              fontSize: 12,
                              color: t.textSecondary,
                              decoration: TextDecoration.none,
                            ),
                          ),
                        ],
                        if (request.command != null &&
                            request.command!.isNotEmpty) ...[
                          const SizedBox(height: AppSpacing.sm),
                          buildSharedCodeBlock(
                            context,
                            request.command!,
                            'bash',
                            showFullSource: true,
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              Wrap(
                alignment: WrapAlignment.end,
                spacing: AppSpacing.sm,
                runSpacing: AppSpacing.sm,
                children: [
                  // The card floats over some other screen: the way to the
                  // run that is asking, where the request also sits inline.
                  if (onOpenConversation case final open?)
                    CcButton(
                      variant: CcButtonVariant.ghost,
                      size: CcButtonSize.sm,
                      onPressed: open,
                      child: Text(l10n.codeExecutionOpenConversation),
                    ),
                  CcButton(
                    variant: CcButtonVariant.secondary,
                    size: CcButtonSize.sm,
                    onPressed: busy ? null : onDeny,
                    child: Text(l10n.deny),
                  ),
                  _approve(l10n),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
