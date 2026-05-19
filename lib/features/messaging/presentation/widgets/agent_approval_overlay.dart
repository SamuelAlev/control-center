import 'package:cc_domain/cc_domain.dart' show ConfirmationRequestDto;
import 'package:cc_ui/cc_ui.dart';
import 'package:control_center/features/messaging/providers/pending_confirmations_provider.dart';
import 'package:control_center/l10n/app_localizations.dart';
import 'package:control_center/shared/icons/app_icons.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// A global, always-on-top surface that lists agent actions awaiting a human
/// decision and lets the user approve or deny them inline.
///
/// The SERVER blocks an agent whenever it hits an approval-gated action
/// (a destructive command, a privileged MCP tool) and publishes the request to
/// every connected client over `confirmation.watchPending`; it stays blocked
/// until someone responds (there is no timeout). This is the desktop/web
/// responder — the counterpart to the phone's approval screen — so a user at
/// the desktop can unblock the agent without reaching for their phone.
///
/// Renders nothing when nothing is pending, so it is safe to mount permanently
/// in the app shell.
class AgentApprovalOverlay extends ConsumerStatefulWidget {
  /// Creates an [AgentApprovalOverlay].
  const AgentApprovalOverlay({super.key});

  @override
  ConsumerState<AgentApprovalOverlay> createState() =>
      _AgentApprovalOverlayState();
}

class _AgentApprovalOverlayState extends ConsumerState<AgentApprovalOverlay> {
  /// Ids with an in-flight `respond` call, so the buttons disable and we never
  /// double-submit while the server round-trips.
  final Set<String> _responding = {};

  Future<void> _respond(String id, {required bool approved}) async {
    if (_responding.contains(id)) {
      return;
    }
    setState(() => _responding.add(id));
    try {
      await ref
          .read(confirmationRepositoryProvider)
          .respond(id, approved: approved);
    } finally {
      if (mounted) {
        setState(() => _responding.remove(id));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final pending = ref.watch(pendingConfirmationsProvider).asData?.value;
    if (pending == null || pending.isEmpty) {
      return const SizedBox.shrink();
    }
    return Align(
      alignment: Alignment.bottomRight,
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 420, maxHeight: 520),
          child: SingleChildScrollView(
            reverse: true,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                for (final req in pending)
                  Padding(
                    padding: const EdgeInsets.only(top: AppSpacing.sm),
                    child: _ApprovalCard(
                      request: req,
                      busy: _responding.contains(req.id),
                      onApprove: () => _respond(req.id, approved: true),
                      onDeny: () => _respond(req.id, approved: false),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ApprovalCard extends StatelessWidget {
  const _ApprovalCard({
    required this.request,
    required this.busy,
    required this.onApprove,
    required this.onDeny,
  });

  final ConfirmationRequestDto request;
  final bool busy;
  final VoidCallback onApprove;
  final VoidCallback onDeny;

  bool get _destructive => request.severity == 'destructive';

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final t = context.designSystem ?? DesignSystemTokens.light();
    final accent = switch (request.severity) {
      'destructive' => t.fgErrorPrimary,
      'warning' => t.fgWarningPrimary,
      _ => t.fgBrandPrimary,
    };

    return DecoratedBox(
      decoration: BoxDecoration(
        color: t.bgPrimary,
        borderRadius: BorderRadius.circular(AppRadii.lg),
        border: Border.all(color: t.borderPrimary),
        boxShadow: [
          BoxShadow(
            color: t.bgOverlay,
            blurRadius: 24,
            offset: const Offset(0, 8),
          ),
        ],
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
                    request.title.isEmpty
                        ? l10n.agentApprovalRequired
                        : request.title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
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
            if (request.command != null && request.command!.isNotEmpty) ...[
              const SizedBox(height: AppSpacing.sm),
              DecoratedBox(
                decoration: BoxDecoration(
                  color: t.bgSecondary,
                  borderRadius: BorderRadius.circular(AppRadii.sm),
                  border: Border.all(color: t.borderSecondary),
                ),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.sm,
                    vertical: AppSpacing.xs,
                  ),
                  child: Text(
                    request.command!,
                    style: CcFonts.code(
                      textStyle: TextStyle(
                        fontSize: 12,
                        color: t.textPrimary,
                        decoration: TextDecoration.none,
                      ),
                    ),
                  ),
                ),
              ),
            ],
            const SizedBox(height: AppSpacing.md),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                CcButton(
                  variant: CcButtonVariant.secondary,
                  size: CcButtonSize.sm,
                  onPressed: busy ? null : onDeny,
                  child: Text(l10n.deny),
                ),
                const SizedBox(width: AppSpacing.sm),
                CcButton(
                  variant: _destructive
                      ? CcButtonVariant.destructive
                      : CcButtonVariant.primary,
                  size: CcButtonSize.sm,
                  loading: busy,
                  onPressed: busy ? null : onApprove,
                  child: Text(l10n.approve),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
