import 'package:cc_domain/features/settings/domain/entities/adapter.dart';
import 'package:cc_ui/cc_ui.dart';
import 'package:control_center/features/settings/presentation/widgets/kit/settings_kit.dart';
import 'package:control_center/l10n/app_localizations.dart';
import 'package:control_center/shared/icons/app_icons.dart';
import 'package:flutter/widgets.dart';

/// The left rail of the detected-runners master-detail: every runner in the
/// catalog, the ones found on this machine first, each with a detection-status
/// dot. The catalog is fixed — runners are CLIs the host may or may not have,
/// not things the user adds — so there is deliberately no "add" row.
class AdapterRail extends StatelessWidget {
  /// Creates an [AdapterRail].
  const AdapterRail({
    super.key,
    required this.detected,
    required this.query,
    required this.onQueryChanged,
    required this.selectedId,
    required this.onSelected,
  });

  /// Every catalog runner with its detection state, unsorted.
  final List<DetectedAdapter> detected;

  /// The live rail search text.
  final String query;

  /// Fired on every keystroke.
  final ValueChanged<String> onQueryChanged;

  /// The selected adapter id.
  final String? selectedId;

  /// Fired when a runner row is activated.
  final ValueChanged<String> onSelected;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final tokens = context.designSystem ?? DesignSystemTokens.light();
    final q = query.trim().toLowerCase();
    bool matches(DetectedAdapter d) =>
        q.isEmpty ||
        d.adapter.name.toLowerCase().contains(q) ||
        d.adapter.cliName.toLowerCase().contains(q);

    // Found first, then still-checking, then missing — "what can I run right
    // now" is the question the rail answers. Catalog order holds inside each
    // group (the catalog already ranks the runners by relevance).
    final visible = detected.where(matches).toList()
      ..sort((a, b) => _rank(a.status).compareTo(_rank(b.status)));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        CcTextField(
          hintText: l10n.adaptersFilterHint,
          size: CcTextFieldSize.sm,
          prefix: Icon(AppIcons.search, size: 15, color: tokens.fgQuaternary),
          onChanged: onQueryChanged,
        ),
        const SizedBox(height: AppSpacing.sm),
        if (visible.isEmpty)
          SettingsRailEmptyNote(message: l10n.providersNoneMatch)
        else
          for (final d in visible)
            SettingsRailItem(
              label: d.adapter.name,
              tone: _tone(d.status),
              statusLabel: _statusLabel(l10n, d.status),
              selected: selectedId == d.adapter.id,
              onPressed: () => onSelected(d.adapter.id),
            ),
      ],
    );
  }

  static int _rank(DetectionStatus status) => switch (status) {
    DetectionStatus.found => 0,
    DetectionStatus.checking => 1,
    DetectionStatus.notFound => 2,
  };

  static CcStatusTone _tone(DetectionStatus status) => switch (status) {
    DetectionStatus.found => CcStatusTone.positive,
    DetectionStatus.checking => CcStatusTone.neutral,
    DetectionStatus.notFound => CcStatusTone.neutral,
  };

  static String _statusLabel(AppLocalizations l10n, DetectionStatus status) =>
      switch (status) {
        DetectionStatus.found => l10n.available,
        DetectionStatus.checking => l10n.checking,
        DetectionStatus.notFound => l10n.unavailable,
      };
}
