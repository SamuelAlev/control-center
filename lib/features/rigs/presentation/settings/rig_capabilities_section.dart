import 'package:cc_data/cc_data.dart' show RigBackendView;
import 'package:cc_ui/cc_ui.dart';
import 'package:control_center/features/rigs/providers/rig_providers.dart';
import 'package:control_center/features/settings/presentation/widgets/kit/settings_kit.dart';
import 'package:control_center/l10n/app_localizations.dart';
import 'package:control_center/shared/icons/app_icons.dart';
import 'package:control_center/shared/widgets/section_card.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// What this host can boot, and what would make it able to.
///
/// Every backend is listed in every state, including "nothing installed" — a
/// backend that disappears when it is missing is indistinguishable from one we
/// do not support, which leaves the operator with a greyed-out tab and nowhere
/// to find out what it needs. So an unavailable backend keeps its row and gains
/// the exact command that would fix it.
class CapabilitiesSection extends ConsumerWidget {
  /// Creates a [CapabilitiesSection].
  const CapabilitiesSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final t = context.designSystem ?? DesignSystemTokens.light();
    final capabilities = ref.watch(rigCapabilitiesProvider);

    return SectionCard(
      label: l10n.rigsCapabilitiesTitle,
      padding: const EdgeInsets.fromLTRB(0, 14, 0, 0),
      headerPadding: const EdgeInsets.fromLTRB(
        AppSpacing.lg,
        0,
        AppSpacing.lg,
        AppSpacing.md,
      ),
      child: capabilities.when(
        loading: () => const Padding(
          padding: EdgeInsets.symmetric(vertical: AppSpacing.xl),
          child: Center(child: CcSpinner()),
        ),
        error: (e, _) => Padding(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.lg,
            0,
            AppSpacing.lg,
            AppSpacing.lg,
          ),
          child: CcAlert(
            title: l10n.failedWithError('$e'),
            variant: CcAlertVariant.danger,
          ),
        ),
        data: (backends) {
          if (backends.isEmpty) {
            return Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.lg,
                0,
                AppSpacing.lg,
                AppSpacing.lg,
              ),
              child: Text(
                l10n.rigsUnsupportedServer,
                style: CcTypography.caption.copyWith(color: t.textTertiary),
              ),
            );
          }
          final available = backends.where((b) => b.available).length;
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
                child: SettingsSummary(
                  facts: [
                    SettingsFact(
                      label: l10n.rigBackendAvailable,
                      value: l10n.settingsCountOfTotal(
                        available,
                        backends.length,
                      ),
                      tone: available > 0
                          ? CcStatusTone.positive
                          : CcStatusTone.caution,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              for (final backend in backends) ...[
                const CcDivider(),
                BackendRow(backend: backend),
              ],
              const SizedBox(height: AppSpacing.sm),
            ],
          );
        },
      ),
    );
  }
}

/// One backend: whether it can boot, what it can host, and what would
/// make it able to.
class BackendRow extends StatelessWidget {
  /// Creates a [BackendRow].
  const BackendRow({super.key, required this.backend});

  /// The backend this row describes.
  final RigBackendView backend;

  @override
  Widget build(BuildContext context) {
    final t = context.designSystem ?? DesignSystemTokens.light();
    final l10n = AppLocalizations.of(context);
    final needsDetail = backend.installHint != null || !backend.enforcedEgress;

    return SettingsEntityRow(
      title: backend.label,
      icon: backend.available ? AppIcons.circleCheck : AppIcons.monitor,
      tone: backend.available ? CcStatusTone.positive : CcStatusTone.neutral,
      statusLabel: backend.available
          ? l10n.rigBackendAvailable
          : l10n.rigBackendUnavailable,
      subtitle: backend.note,
      meta: [
        if (backend.version != null) SettingsMetaFact(value: backend.version!),
        for (final surface in backend.surfaces) CcChip(label: surface),
        if (!backend.enforcedEgress)
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(AppIcons.circleAlert, size: 12, color: t.warn),
              const SizedBox(width: AppSpacing.xs),
              Text(
                l10n.rigEgressNotEnforced,
                style: CcTypography.caption.copyWith(
                  color: t.textWarningPrimary,
                ),
              ),
            ],
          ),
      ],
      // The install command, verbatim and copyable — a hint that paraphrases
      // the command is a hint you have to translate, and retyping a path off a
      // screenshot is how typos get made. Not behind a disclosure: for an
      // unavailable backend it is the only actionable thing on the row.
      detail: needsDetail && backend.installHint != null
          ? SettingsField(
              label: l10n.rigsInstallHintLabel,
              layout: SettingsFieldLayout.stacked,
              child: SettingsCopyField(value: backend.installHint),
            )
          : null,
    );
  }
}
