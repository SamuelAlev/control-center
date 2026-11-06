import 'package:cc_domain/core/domain/entities/memory_fact.dart';
import 'package:cc_ui/cc_ui.dart';
import 'package:control_center/features/memory/presentation/widgets/memory_actions.dart';
import 'package:control_center/features/memory/presentation/widgets/memory_fact_row.dart';
import 'package:control_center/features/settings/presentation/widgets/kit/settings_kit.dart';
import 'package:control_center/l10n/app_localizations.dart';
import 'package:control_center/shared/widgets/section_card.dart';
import 'package:flutter/widgets.dart';

/// Other facts this record leads to, each one a way into it.
class MemoryFactLinks extends StatelessWidget {
  /// Creates a [MemoryFactLinks].
  const MemoryFactLinks({super.key, required this.label, required this.facts});

  /// How they relate to this record.
  final String label;

  /// The facts.
  final List<MemoryFact> facts;

  @override
  Widget build(BuildContext context) {
    return SectionCard(
      label: label,
      count: facts.length,
      padding: EdgeInsets.zero,
      headerPadding: const EdgeInsetsDirectional.fromSTEB(
        AppSpacing.lg,
        14,
        AppSpacing.lg,
        0,
      ),
      child: SettingsGroup(
        separator: SettingsGroupSeparator.rule,
        children: [
          for (final fact in facts) MemoryFactRow(fact: fact, deletable: false),
        ],
      ),
    );
  }
}

/// Says a fact has been replaced, and by what when that fact still exists.
class MemoryReplacedNotice extends StatelessWidget {
  /// Creates a [MemoryReplacedNotice].
  const MemoryReplacedNotice({super.key, required this.replacement});

  /// The newer fact.
  final MemoryFact? replacement;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final newer = replacement;
    return CcAlert(
      variant: CcAlertVariant.warning,
      title: l10n.supersededTooltip,
      action: newer == null
          ? null
          : CcButton(
              variant: CcButtonVariant.secondary,
              size: CcButtonSize.sm,
              onPressed: () => openMemoryFact(context, newer),
              child: Text(l10n.openLabel),
            ),
    );
  }
}
