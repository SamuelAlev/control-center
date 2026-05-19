import 'dart:math' as math;

import 'package:cc_ui/cc_ui.dart';
import 'package:control_center/features/messaging/presentation/widgets/agent_approval_card.dart';
import 'package:control_center/features/messaging/providers/pending_confirmations_provider.dart';
import 'package:control_center/l10n/app_localizations.dart';
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
                          child: ApprovalDeckLayer(
                            key: ValueKey('approvalDeckLayer$depth'),
                          ),
                        ),
                      ApprovalCard(
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
