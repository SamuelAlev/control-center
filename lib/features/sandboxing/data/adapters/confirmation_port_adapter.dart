import 'dart:async';

import 'package:cc_ui/cc_ui.dart';
import 'package:control_center/core/domain/ports/confirmation_port.dart';
import 'package:control_center/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// {@template confirmation_port_adapter}
/// Adapter that implements [ConfirmationPort] by showing Flutter dialogs.
/// {@endtemplate}
class ConfirmationPortAdapter implements ConfirmationPort {

  /// Creates a [ConfirmationPortAdapter] holding the widget tree reference.
  ConfirmationPortAdapter(this._ref);
  final WidgetRef _ref;

  @override
  Future<bool> requestApproval(ConfirmationRequest request) async {
    final context = _ref.read(navigatorKeyProvider).currentContext;
    if (context == null) {
      return false;
    }

    final result = await showCcDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => _ConfirmationDialog(request: request),
    );
    return result ?? false;
  }
}
class _ConfirmationDialog extends StatelessWidget {
  const _ConfirmationDialog({required this.request});

  final ConfirmationRequest request;

  ColorSeverity _severityColor(BuildContext context) {
    return switch (request.severity) {
      ConfirmationSeverity.info => (
        color: Theme.of(context).colorScheme.primary,
        icon: Icons.info_outline,
      ),
      ConfirmationSeverity.warning => (
        color: Theme.of(context).colorScheme.error,
        icon: Icons.warning_amber_outlined,
      ),
      ConfirmationSeverity.destructive => (
        color: Theme.of(context).colorScheme.error,
        icon: Icons.dangerous_outlined,
      ),
    };
  }

  @override
  Widget build(BuildContext context) {
    final sev = _severityColor(context);
    return CcDialog(
      title: request.title,
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(sev.icon, color: sev.color, size: 28),
          const SizedBox(height: 12),
          Text(request.detail),
          if (request.command != null) ...[
            const SizedBox(height: 12),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surfaceContainerHighest,
                borderRadius: AppRadii.brSm,
              ),
              child: SelectableText(
                request.command!,
                style: TextStyle(
                  fontFamily: 'JetBrainsMono',
                  fontSize: 12,
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
            ),
          ],
        ],
      ),
      actions: [
        CcButton(
          onPressed: () => Navigator.of(context).pop(false),
          variant: CcButtonVariant.secondary,
          child: Text(AppLocalizations.of(context).deny),
        ),
        CcButton(
          onPressed: () => Navigator.of(context).pop(true),
          variant: request.severity == ConfirmationSeverity.destructive
              ? CcButtonVariant.destructive
              : CcButtonVariant.primary,
          child: Text(AppLocalizations.of(context).allow),
        ),
      ],
    );
  }
}

/// Record type pairing a severity color with its icon.
typedef ColorSeverity = ({Color color, IconData icon});

/// Provides a global [NavigatorState] key used to show confirmation dialogs
/// from outside the widget tree (e.g., from MCP tool handlers).
final navigatorKeyProvider = Provider<GlobalKey<NavigatorState>>((ref) {
  return GlobalKey<NavigatorState>();
});

/// Provider for [ConfirmationPort].
///
/// Must be overridden in the widget tree with a ref-aware implementation.
final confirmationPortProvider = Provider<ConfirmationPort>((ref) {
  throw UnimplementedError(
    'confirmationPortProvider must be overridden in the widget tree '
    'with a ref-aware implementation.',
  );
});
