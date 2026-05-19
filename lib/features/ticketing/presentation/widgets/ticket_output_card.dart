import 'dart:convert';

import 'package:control_center/core/theme/design_system_tokens.dart';
import 'package:control_center/features/ticketing/domain/entities/ticket.dart';
import 'package:control_center/l10n/app_localizations.dart';
import 'package:flutter/material.dart';

/// Renders a completed ticket's structured `outputJson`, ordered and labeled by
/// its `expectedOutputSchema` when present. Missing required fields are flagged
/// (render-only — enforcement lives at the `complete_ticket` boundary).
class TicketOutputCard extends StatelessWidget {
  /// Creates a [TicketOutputCard].
  const TicketOutputCard({super.key, required this.ticket});

  /// The ticket whose output is shown.
  final Ticket ticket;

  @override
  Widget build(BuildContext context) {
    final output = ticket.outputJson;
    if (output == null) {
      return const SizedBox.shrink();
    }
    final t = context.designSystem ?? DesignSystemTokens.light();
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context);

    final schema = ticket.expectedOutputSchema;
    final props = (schema?['properties'] as Map?)?.cast<String, dynamic>();
    final required =
        (schema?['required'] as List?)?.whereType<String>().toSet() ?? const {};

    // Order keys by schema property order, then any extra keys the agent added.
    final orderedKeys = <String>[
      if (props != null) ...props.keys,
      ...output.keys.where((k) => props == null || !props.containsKey(k)),
    ];

    return Container(
      margin: const EdgeInsets.only(top: 20),
      decoration: BoxDecoration(
        color: t.bgPrimary,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: t.borderSecondary),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: BoxDecoration(
              color: t.bgSecondary,
              border: Border(bottom: BorderSide(color: t.borderSecondary)),
            ),
            child: Row(
              children: [
                Icon(Icons.task_alt, size: 14, color: t.fgBrandPrimary),
                const SizedBox(width: 8),
                Text(
                  l10n.ticketOutput,
                  style: theme.textTheme.labelMedium?.copyWith(
                    color: t.textPrimary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 10, 14, 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                for (final key in orderedKeys)
                  _OutputField(
                    label: key,
                    value: output[key],
                    tokens: t,
                    theme: theme,
                  ),
                for (final key in required)
                  if (!output.containsKey(key) || output[key] == null)
                    Padding(
                      padding: const EdgeInsets.only(top: 6),
                      child: Text(
                        l10n.missingRequiredField(key),
                        style: theme.textTheme.bodySmall
                            ?.copyWith(color: t.textErrorPrimary),
                      ),
                    ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _OutputField extends StatelessWidget {
  const _OutputField({
    required this.label,
    required this.value,
    required this.tokens,
    required this.theme,
  });

  final String label;
  final Object? value;
  final DesignSystemTokens tokens;
  final ThemeData theme;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: theme.textTheme.labelSmall?.copyWith(
              color: tokens.textTertiary,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 2),
          _renderValue(value),
        ],
      ),
    );
  }

  Widget _renderValue(Object? v) {
    if (v is String) {
      return SelectableText(
        v,
        style: theme.textTheme.bodyMedium?.copyWith(color: tokens.textPrimary),
      );
    }
    if (v is List) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          for (final item in v)
            Padding(
              padding: const EdgeInsets.only(top: 2),
              child: Text(
                '• ${item is String ? item : jsonEncode(item)}',
                style: theme.textTheme.bodyMedium
                    ?.copyWith(color: tokens.textPrimary),
              ),
            ),
        ],
      );
    }
    if (v == null) {
      return Text(
        '—',
        style:
            theme.textTheme.bodyMedium?.copyWith(color: tokens.textQuaternary),
      );
    }
    // Numbers, bools, nested maps.
    final text = v is Map
        ? const JsonEncoder.withIndent('  ').convert(v)
        : '$v';
    return SelectableText(
      text,
      style: theme.textTheme.bodySmall?.copyWith(
        color: tokens.textSecondary,
        fontFamily: 'monospace',
      ),
    );
  }
}
