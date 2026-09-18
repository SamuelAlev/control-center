import 'package:cc_remote/l10n/app_localizations.dart';
import 'package:cc_remote/screens/session_utils.dart';
import 'package:cc_ui/cc_ui.dart';
import 'package:flutter/widgets.dart';

/// Status badge shared between the ticket list and the detail screen.
class TicketStatusBadge extends StatelessWidget {
  /// Creates a [TicketStatusBadge].
  const TicketStatusBadge({super.key, required this.status});

  /// Ticket status wire value (`todo`, `inProgress`, `inReview`, `done`, …).
  final String status;

  @override
  Widget build(BuildContext context) {
    final variant = switch (status) {
      'done' => CcBadgeVariant.success,
      'blocked' => CcBadgeVariant.danger,
      'inReview' => CcBadgeVariant.info,
      'inProgress' => CcBadgeVariant.brand,
      _ => CcBadgeVariant.neutral,
    };
    return CcBadge(
      label: ticketStatusLabel(AppLocalizations.of(context), status),
      variant: variant,
    );
  }
}
