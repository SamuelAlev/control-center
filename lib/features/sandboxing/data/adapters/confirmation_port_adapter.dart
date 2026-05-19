import 'dart:async';

import 'package:control_center/core/domain/ports/confirmation_port.dart';
import 'package:control_center/core/theme/app_radii.dart';
import 'package:control_center/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:forui/forui.dart';

class ConfirmationPortAdapter implements ConfirmationPort {

  ConfirmationPortAdapter(this._ref);
  final WidgetRef _ref;

  @override
  Future<bool> requestApproval(ConfirmationRequest request) async {
    final context = _ref.read(_navigatorKeyProvider).currentContext;
    if (context == null) {
      return false;
    }

    final result = await showFDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (ctx, style, animation) => _ConfirmationDialog(request: request, style: style, animation: animation),
    );
    return result ?? false;
  }
}
class _ConfirmationDialog extends StatelessWidget {
  const _ConfirmationDialog({required this.request, required this.style, required this.animation});

  final ConfirmationRequest request;
  final FDialogStyle style;
  final Animation<double> animation;

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
    return FDialog(
      style: style,
      animation: animation,
      image: Icon(sev.icon, color: sev.color, size: 28),
      title: Text(request.title),
      body: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
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
        SizedBox(
          width: double.infinity,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              FButton(
                onPress: () => Navigator.of(context).pop(false),
                variant: FButtonVariant.outline,
                child: Text(AppLocalizations.of(context).deny),
              ),
              const SizedBox(width: 8),
              FButton(
                onPress: () => Navigator.of(context).pop(true),
                variant: request.severity == ConfirmationSeverity.destructive
                    ? FButtonVariant.destructive
                    : FButtonVariant.primary,
                child: Text(AppLocalizations.of(context).allow),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

typedef ColorSeverity = ({Color color, IconData icon});

final _navigatorKeyProvider = Provider<GlobalKey<NavigatorState>>((ref) {
  return GlobalKey<NavigatorState>();
});

final confirmationPortProvider = Provider<ConfirmationPort>((ref) {
  throw UnimplementedError(
    'confirmationPortProvider must be overridden in the widget tree '
    'with a ref-aware implementation.',
  );
});
