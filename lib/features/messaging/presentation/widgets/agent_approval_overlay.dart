import 'dart:math' as math;

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
///
/// Several pending requests render as a DECK, not a scrolling list: one card is
/// answerable and the rest peek out behind it, three deep at most. So a host
/// with twenty blocked agents occupies exactly as much screen as one with four
/// — the overlay floats over whatever the user is actually doing, and an
/// approval queue that grows to fill the window is worse than one that stays a
/// fixed corner. The count above the deck carries what the cap cannot show.
class AgentApprovalOverlay extends ConsumerStatefulWidget {
  /// Creates an [AgentApprovalOverlay].
  const AgentApprovalOverlay({super.key});

  @override
  ConsumerState<AgentApprovalOverlay> createState() =>
      _AgentApprovalOverlayState();
}

class _AgentApprovalOverlayState extends ConsumerState<AgentApprovalOverlay> {
  /// How many queued requests peek out behind the answerable one. A fifth
  /// request lands exactly on the fourth rather than adding another step, so
  /// the deck's footprint is bounded however long the queue gets.
  static const int _maxPeeks = 3;

  /// How far each layer behind the front card rises above it.
  static const double _peekRise = 7;

  /// How much narrower each layer behind the front card is, per side.
  static const double _peekInset = 9;

  /// Ids with an in-flight `respond` call, so the buttons disable and we never
  /// double-submit while the server round-trips.
  final Set<String> _responding = {};

  /// How long "approve for a while" lasts. Deliberately a fixed, short window
  /// rather than a picker: the point is to stop a burst of identical prompts,
  /// not to let someone quietly grant a long-lived exemption from a dialog.
  /// The server clamps it regardless, and narrows the scope to what the
  /// responder's role may write.
  static const int _rememberSeconds = 8 * 60 * 60;

  Future<void> _respond(
    String id, {
    required bool approved,
    bool remember = false,
  }) async {
    if (_responding.contains(id)) {
      return;
    }
    setState(() => _responding.add(id));
    try {
      await ref
          .read(confirmationRepositoryProvider)
          .respond(
            id,
            approved: approved,
            rememberForSeconds: remember ? _rememberSeconds : null,
          );
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
    final l10n = AppLocalizations.of(context);
    final t = context.designSystem ?? DesignSystemTokens.light();

    // The queue is FIFO (the registry hands back insertion order), and the
    // OLDEST request holds the front of the deck: a request that arrives while
    // the user is reading must not swap the buttons out from under the pointer.
    final front = pending.first;
    final waiting = pending.length - 1;
    final peeks = math.min(waiting, _maxPeeks);

    return Align(
      alignment: Alignment.bottomRight,
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 420, maxHeight: 520),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // The peek is capped, so past three the deck stops reporting how
              // deep the queue is. Say it in words instead.
              if (waiting > 0) ...[
                Text(
                  l10n.agentApprovalsMoreWaiting(waiting),
                  textAlign: TextAlign.right,
                  style: TextStyle(
                    fontSize: 11,
                    color: t.textTertiary,
                    decoration: TextDecoration.none,
                  ),
                ),
                const SizedBox(height: AppSpacing.xs),
              ],
              Flexible(
                child: Padding(
                  // Reserve the rise the layers behind claim, so the deck stays
                  // inside the overlay's bounds instead of overflowing upward.
                  padding: EdgeInsets.only(top: peeks * _peekRise),
                  child: Stack(
                    clipBehavior: Clip.none,
                    alignment: Alignment.bottomCenter,
                    children: [
                      // Deepest layer first; each one is only ever visible as
                      // the strip of card edge above the layer in front of it.
                      for (var depth = peeks; depth >= 1; depth--)
                        Positioned(
                          left: depth * _peekInset,
                          right: depth * _peekInset,
                          top: -(depth * _peekRise),
                          bottom: 0,
                          child: _DeckLayer(
                            key: ValueKey('approvalDeckLayer$depth'),
                          ),
                        ),
                      _ApprovalCard(
                        request: front,
                        busy: _responding.contains(front.id),
                        onApprove: () => _respond(front.id, approved: true),
                        onApproveAndRemember: () =>
                            _respond(front.id, approved: true, remember: true),
                        onDeny: () => _respond(front.id, approved: false),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// One queued request behind the answerable card: a card-shaped edge, drawn
/// without its content because only a few pixels of its top ever show.
class _DeckLayer extends StatelessWidget {
  const _DeckLayer({super.key});

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

class _ApprovalCard extends StatelessWidget {
  const _ApprovalCard({
    required this.request,
    required this.busy,
    required this.onApprove,
    required this.onApproveAndRemember,
    required this.onDeny,
  });

  final ConfirmationRequestDto request;
  final bool busy;
  final VoidCallback onApprove;

  /// Approve, and stop asking for the same shape of action for a while.
  final VoidCallback onApproveAndRemember;
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
            // The body scrolls, the header and the decision stay put: the deck
            // replaced the overlay's outer scroll view, so a long explanation
            // would otherwise push the buttons off the bottom of the card.
            Flexible(
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
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
                  ],
                ),
              ),
            ),
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
                // Offered only when the server says this request is
                // rememberable — never on a destructive one, where "stop
                // asking me" is the wrong affordance in front of something
                // irreversible.
                if (request.isRememberable) ...[
                  CcTooltip(
                    message: l10n.approveAndRememberTooltip,
                    child: CcButton(
                      variant: CcButtonVariant.secondary,
                      size: CcButtonSize.sm,
                      onPressed: busy ? null : onApproveAndRemember,
                      child: Text(l10n.approveAndRemember),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                ],
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
