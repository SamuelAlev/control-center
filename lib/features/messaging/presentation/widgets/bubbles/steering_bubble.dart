import 'package:cc_domain/core/domain/entities/message.dart';
import 'package:cc_ui/cc_ui.dart';
import 'package:control_center/features/messaging/presentation/widgets/bubbles/user_bubble.dart';
import 'package:control_center/l10n/app_localizations.dart';
import 'package:flutter/widgets.dart';

/// An injected steering message, rendered in the trail.
///
/// The user's own words as a normal user bubble — the reader should not have
/// to learn a second bubble grammar for a nudge they typed — with a quiet
/// "Steered" caption beneath saying what kind of turn it was: this text was
/// injected into a run that was already working, not sent as a new one.
/// Presence over decoration (design principle 1): the badge reports a real
/// state change in the run, which is why it earns its pixels.
class SteeringBubble extends StatelessWidget {
  /// Creates a [SteeringBubble].
  const SteeringBubble({
    super.key,
    required this.message,
    required this.codeFont,
    this.collapseHeader = false,
  });

  /// The injected steering message (never a queued one — those render in the
  /// queue strip; see the feed's item builder).
  final Message message;

  /// Font family for code blocks.
  final String codeFont;

  /// Whether to collapse the sender header.
  final bool collapseHeader;

  @override
  Widget build(BuildContext context) {
    final ds = context.ds;
    final l10n = AppLocalizations.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        UserBubble(
          message: message,
          codeFont: codeFont,
          collapseHeader: collapseHeader,
        ),
        Padding(
          padding: const EdgeInsets.only(right: 8, top: 1),
          child: Text(
            l10n.steeringBadge,
            style: TextStyle(
              fontSize: 11,
              color: ds.textQuaternary,
              fontFeatures: const [FontFeature.tabularFigures()],
            ),
          ),
        ),
      ],
    );
  }
}
