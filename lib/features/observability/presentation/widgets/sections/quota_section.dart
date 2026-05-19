import 'package:cc_domain/features/observability/domain/quota.dart';
import 'package:cc_ui/cc_ui.dart';
import 'package:control_center/features/observability/presentation/obs_format.dart';
import 'package:control_center/features/observability/presentation/widgets/obs_widgets.dart';
import 'package:control_center/features/observability/providers/quota_providers.dart';
import 'package:control_center/l10n/app_localizations.dart';
import 'package:control_center/shared/icons/app_icons.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Provider usage-limit dashboard section (PRD 06, feature #4).
///
/// CC has no provider-usage API, so usage is computed from local run logs over
/// rolling 5h / daily / weekly windows and limits are user-configured. With a
/// limit set, a row reads as a percentage against a ceiling with a status and a
/// reset countdown; without one, raw per-window usage is still shown.
///
/// Non-scrolling: renders as a column of [ObsSection] cards; the parent tab
/// owns the scroll view.
class QuotaSection extends ConsumerWidget {
  /// Creates a [QuotaSection].
  const QuotaSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final reports = ref.watch(configuredQuotaReportsProvider);
    final windows = ref.watch(quotaUsageWindowsProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _ConfiguredLimitsSection(reports: reports),
        const SizedBox(height: AppSpacing.lg),
        _UsageWindowsSection(windows: windows),
      ],
    );
  }
}

/// Maps a [QuotaStatus] to its presentational tone.
ObsTone _toneFor(QuotaStatus status) => switch (status) {
  QuotaStatus.ok => ObsTone.success,
  QuotaStatus.warning => ObsTone.warning,
  QuotaStatus.exhausted => ObsTone.danger,
  QuotaStatus.unknown => ObsTone.neutral,
};

/// A short word for [unit] used in labels.
String _unitLabel(AppLocalizations l10n, QuotaUnit unit) => switch (unit) {
  QuotaUnit.tokens => l10n.obsQuotaUnitTokens,
  QuotaUnit.requests => l10n.obsQuotaUnitRequests,
  QuotaUnit.costCents => l10n.obsQuotaUnitCost,
};

/// A localized word for a [QuotaStatus] used in detail labels.
String _statusLabel(AppLocalizations l10n, QuotaStatus status) =>
    switch (status) {
      QuotaStatus.ok => l10n.obsQuotaStatusOk,
      QuotaStatus.warning => l10n.obsQuotaStatusWarning,
      QuotaStatus.exhausted => l10n.obsQuotaStatusExhausted,
      QuotaStatus.unknown => l10n.obsQuotaStatusUnknown,
    };

/// Formats a usage amount for [unit].
String _fmtAmount(QuotaUnit unit, int amount) => switch (unit) {
  QuotaUnit.tokens => fmtTokens(amount),
  QuotaUnit.requests => fmtCount(amount),
  QuotaUnit.costCents => fmtCents(amount),
};

/// The trailing value label for a report, e.g. `12.3k / 50k` or `$4.20`.
String _valueLabel(QuotaUsageReport report) {
  final used = _fmtAmount(report.unit, report.used);
  final limit = report.limit;
  if (limit != null && limit > 0) {
    return '$used / ${_fmtAmount(report.unit, limit)}';
  }
  return used;
}

/// The header for a report row, e.g. `anthropic · 5h`.
String _reportTitle(QuotaUsageReport report) =>
    '${report.provider} · ${report.window.label}';

class _ConfiguredLimitsSection extends ConsumerWidget {
  const _ConfiguredLimitsSection({required this.reports});

  final List<QuotaUsageReport> reports;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = context.designSystem ?? DesignSystemTokens.light();
    final l10n = AppLocalizations.of(context);

    return ObsSection(
      title: l10n.obsQuotaConfiguredLimits,
      subtitle: l10n.obsQuotaConfiguredLimitsSubtitle,
      icon: AppIcons.gauge,
      trailing: reports.isEmpty
          ? null
          : CcButton(
              variant: CcButtonVariant.secondary,
              size: CcButtonSize.sm,
              icon: AppIcons.plus,
              onPressed: () => _showAddLimitDialog(context, ref),
              child: Text(l10n.obsQuotaAddLimit),
            ),
      child: reports.isEmpty
          ? Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l10n.obsQuotaNoLimits,
                  style: CcTypography.bodySm.copyWith(color: t.textTertiary),
                ),
                const SizedBox(height: AppSpacing.md),
                CcButton(
                  variant: CcButtonVariant.secondary,
                  size: CcButtonSize.sm,
                  icon: AppIcons.plus,
                  onPressed: () => _showAddLimitDialog(context, ref),
                  child: Text(l10n.obsQuotaAddLimit),
                ),
              ],
            )
          : Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                for (final report in reports)
                  _ConfiguredLimitRow(report: report),
              ],
            ),
    );
  }
}

class _ConfiguredLimitRow extends ConsumerWidget {
  const _ConfiguredLimitRow({required this.report});

  final QuotaUsageReport report;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = context.designSystem ?? DesignSystemTokens.light();
    final l10n = AppLocalizations.of(context);
    final status = report.status;
    final tone = _toneFor(status);
    final reset = fmtDurationOf(report.resetsIn(DateTime.now()));

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: ObsBar(
            label: _reportTitle(report),
            fraction: report.fraction ?? 0,
            valueLabel: _valueLabel(report),
            tone: tone,
            detail: l10n.obsQuotaResetDetail(reset, _statusLabel(l10n, status)),
          ),
        ),
        const SizedBox(width: AppSpacing.sm),
        Padding(
          padding: const EdgeInsets.only(top: AppSpacing.sm),
          child: CcButton(
            variant: CcButtonVariant.ghost,
            size: CcButtonSize.sm,
            icon: AppIcons.trash2,
            semanticLabel: l10n.obsQuotaRemoveSemantic(_reportTitle(report)),
            onPressed: () {
              final limit = report.limit;
              if (limit == null) {
                return;
              }
              ref
                  .read(quotaLimitsProvider.notifier)
                  .remove(
                    QuotaLimit(
                      provider: report.provider,
                      window: report.window,
                      unit: report.unit,
                      limit: limit,
                    ),
                  );
            },
            child: Text(
              l10n.remove,
              style: CcTypography.caption.copyWith(color: t.textTertiary),
            ),
          ),
        ),
      ],
    );
  }
}

class _UsageWindowsSection extends StatelessWidget {
  const _UsageWindowsSection({required this.windows});

  final List<QuotaUsageReport> windows;

  @override
  Widget build(BuildContext context) {
    final t = context.designSystem ?? DesignSystemTokens.light();
    final l10n = AppLocalizations.of(context);

    return ObsSection(
      title: l10n.obsQuotaUsageWindows,
      subtitle: l10n.obsQuotaUsageWindowsSubtitle,
      icon: AppIcons.clock,
      child: windows.isEmpty
          ? Text(
              l10n.obsQuotaNoUsage,
              style: CcTypography.bodySm.copyWith(color: t.textTertiary),
            )
          : Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                for (var i = 0; i < QuotaWindow.values.length; i++) ...[
                  if (i > 0) const SizedBox(height: AppSpacing.md),
                  _UsageWindowGroup(
                    window: QuotaWindow.values[i],
                    windows: windows,
                  ),
                ],
              ],
            ),
    );
  }
}

class _UsageWindowGroup extends StatelessWidget {
  const _UsageWindowGroup({required this.window, required this.windows});

  final QuotaWindow window;
  final List<QuotaUsageReport> windows;

  @override
  Widget build(BuildContext context) {
    final t = context.designSystem ?? DesignSystemTokens.light();
    final l10n = AppLocalizations.of(context);
    final inWindow = windows.where((r) => r.window == window).toList();
    QuotaUsageReport? forUnit(QuotaUnit unit) {
      for (final r in inWindow) {
        if (r.unit == unit) {
          return r;
        }
      }
      return null;
    }

    final tokens = forUnit(QuotaUnit.tokens);
    final requests = forUnit(QuotaUnit.requests);
    final cost = forUnit(QuotaUnit.costCents);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          window.label,
          style: CcTypography.label.copyWith(
            color: t.textSecondary,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: AppSpacing.xs),
        ObsKeyValue(
          label: l10n.obsQuotaTokensUsed,
          value: tokens == null
              ? '—'
              : _fmtAmount(QuotaUnit.tokens, tokens.used),
        ),
        ObsKeyValue(
          label: l10n.obsQuotaRequests,
          value: requests == null
              ? '—'
              : _fmtAmount(QuotaUnit.requests, requests.used),
        ),
        ObsKeyValue(
          label: l10n.obsColCost,
          value: cost == null
              ? '—'
              : _fmtAmount(QuotaUnit.costCents, cost.used),
        ),
      ],
    );
  }
}

/// Opens the dialog that collects a new [QuotaLimit] and persists it.
Future<void> _showAddLimitDialog(BuildContext context, WidgetRef ref) {
  return showCcDialog<void>(
    context: context,
    builder: (context) => _AddLimitDialog(
      onSubmit: (limit) => ref.read(quotaLimitsProvider.notifier).upsert(limit),
    ),
  );
}

class _AddLimitDialog extends StatefulWidget {
  const _AddLimitDialog({required this.onSubmit});

  final ValueChanged<QuotaLimit> onSubmit;

  @override
  State<_AddLimitDialog> createState() => _AddLimitDialogState();
}

class _AddLimitDialogState extends State<_AddLimitDialog> {
  final TextEditingController _provider = TextEditingController(text: 'all');
  final TextEditingController _limit = TextEditingController();
  QuotaWindow _window = QuotaWindow.fiveHour;
  QuotaUnit _unit = QuotaUnit.tokens;

  @override
  void dispose() {
    _provider.dispose();
    _limit.dispose();
    super.dispose();
  }

  bool get _isValid {
    final value = int.tryParse(_limit.text.trim());
    return value != null && value > 0;
  }

  void _submit() {
    final value = int.tryParse(_limit.text.trim());
    if (value == null || value <= 0) {
      return;
    }
    final provider = _provider.text.trim().isEmpty
        ? 'all'
        : _provider.text.trim();
    widget.onSubmit(
      QuotaLimit(
        provider: provider,
        window: _window,
        unit: _unit,
        limit: value,
      ),
    );
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final t = context.designSystem ?? DesignSystemTokens.light();
    final l10n = AppLocalizations.of(context);

    return CcDialog(
      title: l10n.obsQuotaAddLimitTitle,
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _FieldLabel(text: l10n.obsQuotaProviderLabel),
          const SizedBox(height: AppSpacing.xs),
          CcTextField(
            controller: _provider,
            hintText: 'all',
            onChanged: (_) => setState(() {}),
          ),
          const SizedBox(height: AppSpacing.lg),
          _FieldLabel(text: l10n.obsQuotaWindowLabel),
          const SizedBox(height: AppSpacing.xs),
          Wrap(
            spacing: AppSpacing.sm,
            runSpacing: AppSpacing.sm,
            children: [
              for (final window in QuotaWindow.values)
                CcChip(
                  label: window.label,
                  selected: _window == window,
                  onTap: () => setState(() => _window = window),
                ),
            ],
          ),
          const SizedBox(height: AppSpacing.lg),
          _FieldLabel(text: l10n.obsQuotaUnitLabel),
          const SizedBox(height: AppSpacing.xs),
          Wrap(
            spacing: AppSpacing.sm,
            runSpacing: AppSpacing.sm,
            children: [
              for (final unit in QuotaUnit.values)
                CcChip(
                  label: _unitLabel(l10n, unit),
                  selected: _unit == unit,
                  onTap: () => setState(() => _unit = unit),
                ),
            ],
          ),
          const SizedBox(height: AppSpacing.lg),
          _FieldLabel(text: l10n.obsQuotaLimitLabel(_unitLabel(l10n, _unit))),
          const SizedBox(height: AppSpacing.xs),
          CcTextField(
            controller: _limit,
            hintText: _unit == QuotaUnit.costCents ? 'e.g. 500' : 'e.g. 100000',
            keyboardType: TextInputType.number,
            onChanged: (_) => setState(() {}),
            onSubmitted: (_) => _submit(),
          ),
          if (_unit == QuotaUnit.costCents) ...[
            const SizedBox(height: AppSpacing.xs),
            Text(
              l10n.obsQuotaCentsHint,
              style: CcTypography.caption.copyWith(color: t.textTertiary),
            ),
          ],
        ],
      ),
      actions: [
        CcButton(
          variant: CcButtonVariant.ghost,
          onPressed: () => Navigator.of(context).pop(),
          child: Text(l10n.cancel),
        ),
        CcButton(
          variant: CcButtonVariant.primary,
          onPressed: _isValid ? _submit : null,
          child: Text(l10n.save),
        ),
      ],
    );
  }
}

class _FieldLabel extends StatelessWidget {
  const _FieldLabel({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    final t = context.designSystem ?? DesignSystemTokens.light();
    return Text(
      text,
      style: CcTypography.label.copyWith(
        color: t.textSecondary,
        fontWeight: FontWeight.w600,
      ),
    );
  }
}
