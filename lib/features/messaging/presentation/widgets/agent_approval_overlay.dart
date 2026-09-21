import 'dart:math' as math;

import 'package:cc_ui/cc_ui.dart';
import 'package:control_center/features/messaging/presentation/widgets/agent_approval_card.dart';
import 'package:control_center/features/messaging/providers/pending_confirmations_provider.dart';
import 'package:control_center/features/messaging/providers/visible_conversation_spaces.dart';
import 'package:control_center/l10n/app_localizations.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// A global, always-on-top surface that lists agent actions awaiting a human decision for
/// conversations that are not currently on screen.
/// When the conversation is open, the permission prompt renders the same request inline
/// above the composer and this overlay hides it, so the operator never answers twice.
/// This is the desktop/web responder — the counterpart to the phone's approval screen — so
/// a user at the desktop can unblock the agent without reaching for their phone.
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
            rememberForSeconds: remember ? kApprovalRememberSeconds : null,
          );
    } finally {
      if (mounted) {
        setState(() => _responding.remove(id));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final visible = ref.watch(visibleConversationSpacesProvider);
    final pending =
        (ref.watch(pendingConfirmationsProvider).asData?.value ?? const [])
            .where((r) => r.spaceId.isEmpty || !visible.contains(r.spaceId))
            .toList();
    if (pending.isEmpty) {
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
      alignment: AlignmentDirectional.bottomEnd,
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
                  textAlign: TextAlign.end,
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
