import 'package:cc_domain/cc_domain.dart' show UserDto;
import 'package:cc_domain/core/domain/entities/server_audit_entry.dart';
import 'package:cc_domain/core/domain/value_objects/audit_log_page.dart'
    show AuditLogEntryDto;
import 'package:cc_ui/cc_ui.dart';
import 'package:control_center/features/settings/presentation/widgets/sections/audit/audit_formatting.dart';
import 'package:control_center/features/settings/presentation/widgets/sections/audit/audit_ledger_row.dart';
import 'package:control_center/l10n/app_localizations.dart';
import 'package:flutter/widgets.dart';

/// One audit log record on the ledger: who, the op, a prose read of it, where
/// it ran (the workspace, or the server) when the log spans more than one
/// trail, how it ended when it did not succeed, the argument names a server
/// op carried, and the network origin as filter toggles.
class AuditLogEntryRow extends StatelessWidget {
  /// Creates a row for [entry].
  const AuditLogEntryRow({
    super.key,
    required this.entry,
    required this.user,
    required this.sourceLabel,
    required this.onIpTap,
    required this.onCountryTap,
  });

  /// The record.
  final AuditLogEntryDto entry;

  /// Its actor, when this session can see them.
  final UserDto? user;

  /// Where it ran, or null when the log reads a single trail.
  final String? sourceLabel;

  /// Toggles the IP filter to this record's address.
  final ValueChanged<String> onIpTap;

  /// Toggles the country filter to this record's country label.
  final ValueChanged<String> onCountryTap;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final t = context.designSystem ?? DesignSystemTokens.light();
    final name = user?.displayName.isNotEmpty ?? false
        ? user!.displayName
        : l10n.unknownUserLabel;
    final caption = CcTypography.caption.copyWith(color: t.textTertiary);
    final meta = CcFonts.code(
      textStyle: CcTypography.monoNum.copyWith(
        fontSize: 11,
        color: t.textTertiary,
      ),
    );
    final ip = entry.ip;
    final country = activityCountryLabel(l10n, entry);
    final dot = Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: Text('·', style: caption),
    );
    return ActivityLedgerRow(
      name: name,
      user: user,
      action: entry.action,
      createdAt: entry.createdAt,
      detail: Row(
        crossAxisAlignment: CrossAxisAlignment.baseline,
        textBaseline: TextBaseline.alphabetic,
        children: [
          if (entry.outcome != AuditOutcome.ok) ...[
            ActivityCodeToken(
              label: auditOutcomeLabel(l10n, entry.outcome),
              color: entry.outcome == AuditOutcome.denied
                  ? t.textWarningPrimary
                  : t.textErrorPrimary,
            ),
            const SizedBox(width: AppSpacing.sm),
          ],
          if (sourceLabel case final source?) ...[
            Text(
              source,
              maxLines: 1,
              style: CcTypography.caption.copyWith(color: t.textSecondary),
            ),
            dot,
          ],
          Flexible(
            child: Text(
              describeActivity(l10n, entry),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: caption,
            ),
          ),
          if (entry.argNames.isNotEmpty) ...[
            const SizedBox(width: AppSpacing.sm),
            Flexible(
              child: Text(
                entry.argNames.join(', '),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                // RTL carve-out: argument names are machine strings.
                textDirection: TextDirection.ltr,
                style: meta,
              ),
            ),
          ],
          if (ip != null && ip.isNotEmpty) ...[
            const SizedBox(width: AppSpacing.sm),
            if (country != null) ...[
              _MetaChip(label: country, onPressed: () => onCountryTap(country)),
              dot,
            ],
            _MetaChip(label: ip, onPressed: () => onIpTap(ip)),
          ],
        ],
      ),
    );
  }
}

/// The localized name of [outcome].
String auditOutcomeLabel(AppLocalizations l10n, AuditOutcome outcome) =>
    switch (outcome) {
      AuditOutcome.ok => l10n.auditLogOutcomeOk,
      AuditOutcome.denied => l10n.auditLogOutcomeDenied,
      AuditOutcome.failed => l10n.auditLogOutcomeFailed,
    };

/// A small mono network token (an IP or a country) in the row meta line.
/// Tertiary at rest, underlined on hover/press: it is a filter toggle.
class _MetaChip extends StatelessWidget {
  const _MetaChip({required this.label, required this.onPressed});

  final String label;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final t = context.designSystem ?? DesignSystemTokens.light();
    return CcTappable(
      onPressed: onPressed,
      semanticLabel: label,
      semanticButton: false,
      showFocusRing: false,
      builder: (context, states) {
        final highlighted =
            states.contains(WidgetState.hovered) ||
            states.contains(WidgetState.pressed) ||
            states.contains(WidgetState.focused);
        return Text(
          label,
          // RTL carve-out: an address or country code reads left to right.
          textDirection: TextDirection.ltr,
          style: CcFonts.code(
            textStyle: CcTypography.monoNum.copyWith(
              fontSize: 11,
              color: highlighted ? t.textSecondary : t.textTertiary,
              decoration: highlighted ? TextDecoration.underline : null,
              decorationColor: t.textTertiary,
            ),
          ),
        );
      },
    );
  }
}
