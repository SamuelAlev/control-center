import 'package:cc_remote/app_icons.dart';
import 'package:cc_remote/l10n/app_localizations.dart';
import 'package:cc_ui/cc_ui.dart';
import 'package:flutter/widgets.dart';

/// Distinguishes a resolved, absent ticket from an unresolved stream.
class TicketMissingState extends StatelessWidget {
  const TicketMissingState({super.key, required this.onRetry});

  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) => CcEmptyState(
    icon: AppIcons.ticket,
    message: AppLocalizations.of(context).mobileTicketNotFound,
    description: AppLocalizations.of(context).mobileTicketNotFoundDescription,
    action: CcButton(
      size: CcButtonSize.lg,
      onPressed: onRetry,
      child: Text(AppLocalizations.of(context).retry),
    ),
  );
}

/// Displays a real subscription/provider error and a scoped retry action.
class TicketLoadErrorState extends StatelessWidget {
  const TicketLoadErrorState({
    super.key,
    required this.error,
    required this.onRetry,
  });

  final Object error;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) => CcEmptyState(
    icon: AppIcons.triangleAlert,
    message: AppLocalizations.of(context).ticketLoadFailed,
    description: error.toString(),
    action: CcButton(
      size: CcButtonSize.lg,
      onPressed: onRetry,
      child: Text(AppLocalizations.of(context).retry),
    ),
  );
}
