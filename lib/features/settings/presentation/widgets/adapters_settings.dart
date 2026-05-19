import 'package:cc_domain/features/settings/domain/entities/adapter.dart';
import 'package:cc_ui/cc_ui.dart';
import 'package:collection/collection.dart';
import 'package:control_center/features/settings/presentation/widgets/adapters/adapter_detail_pane.dart';
import 'package:control_center/features/settings/presentation/widgets/adapters/adapter_rail.dart';
import 'package:control_center/features/settings/presentation/widgets/adapters/default_runner_row.dart';
import 'package:control_center/features/settings/presentation/widgets/kit/settings_kit.dart';
import 'package:control_center/features/settings/presentation/widgets/providers_models_section.dart';
import 'package:control_center/features/settings/presentation/widgets/usage_summary_card.dart';
import 'package:control_center/features/settings/providers/adapter_preferences_providers.dart';
import 'package:control_center/features/settings/providers/settings_providers.dart';
import 'package:control_center/features/settings/settings_shortcuts.dart';
import 'package:control_center/l10n/app_localizations.dart';
import 'package:control_center/shared/icons/app_icons.dart';
import 'package:control_center/shared/widgets/page_wrapper.dart';
import 'package:control_center/shared/widgets/section_card.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Auto-detection panel for installed agent runner CLIs, plus default
/// adapter+model configuration for chat and short-task agents.
///
/// ## Why it looks like this
///
/// Every runner in the catalogue used to render its whole configuration inline:
/// the enforcement matrix, an environment-variable button and an extra-argv
/// field, for the installed ones and the missing ones alike. Nine runners
/// produced a page you scrolled for half a minute to learn one fact — which
/// CLIs are actually on this machine. The accordion that replaced it still hid
/// the answer a disclosure deep per row.
///
/// So the page now reads like the providers surface below it: the ready count
/// comes first, a rail keeps every runner visible with its detection dot
/// (installed sort to the top), and the detail pane owns one runner at a
/// time — what its transport enforces, its launch configuration, and (for
/// Claude Code) which logins runs may spend. The catalog is fixed (runners
/// are CLIs the host may or may not have), so there is no add row.
class AdaptersSettings extends ConsumerStatefulWidget {
  /// Creates a new [AdaptersSettings].
  const AdaptersSettings({super.key});

  @override
  ConsumerState<AdaptersSettings> createState() => _AdaptersSettingsState();
}

class _AdaptersSettingsState extends ConsumerState<AdaptersSettings> {
  String _query = '';

  /// The selected runner id; null means "auto" (first found, else first in
  /// the catalog). Auto follows a detection refresh without pinning a stale
  /// id.
  String? _selectedId;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final detected = ref.watch(detectedAdaptersProvider);
    // The rail above deliberately shows every catalogued runner (finding out
    // what is missing is the point of this page); the default-runner pickers
    // below must only offer what is installed.
    final available = ref.watch(availableAdaptersProvider);

    return SettingsShortcuts(
      extraBindings: {
        'settings.adapters-refresh': () =>
            ref.read(detectedAdaptersProvider.notifier).refresh(),
      },
      child: PageWrapper(
        title: l10n.adapters,
        subtitle: l10n.adaptersAutoDetected,
        actions: [
          CcButton(
            variant: CcButtonVariant.secondary,
            size: CcButtonSize.sm,
            onPressed: () =>
                ref.read(detectedAdaptersProvider.notifier).refresh(),
            icon: AppIcons.refreshCw,
            child: Text(l10n.refresh),
          ),
        ],
        child: ListView(
          padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
          children: [
            _detectedCard(context, l10n, detected),
            const SizedBox(height: AppSpacing.xl),
            _defaultsCard(context, l10n, available),
            const SizedBox(height: AppSpacing.xl),
            // Model catalog & provider governance (PRD 05).
            const ProvidersModelsSection(),
            const SizedBox(height: AppSpacing.xl),
            // Usage & cost summary (PRD 05).
            const UsageSummaryCard(),
          ],
        ),
      ),
    );
  }

  Widget _detectedCard(
    BuildContext context,
    AppLocalizations l10n,
    List<DetectedAdapter> detected,
  ) {
    const insets = EdgeInsets.symmetric(horizontal: AppSpacing.lg);
    final readyCount = detected.where((d) => d.isFound).length;

    // Selection: the pinned id when it still exists, else the first found
    // runner, else the first catalog entry.
    final selected = detected.isEmpty
        ? null
        : detected.where((d) => d.adapter.id == _selectedId).firstOrNull ??
              detected.where((d) => d.isFound).firstOrNull ??
              detected.first;

    return SectionCard(
      label: l10n.detectedRunners,
      count: detected.length,
      padding: const EdgeInsets.fromLTRB(0, 14, 0, 0),
      headerPadding: const EdgeInsets.fromLTRB(
        AppSpacing.lg,
        0,
        AppSpacing.lg,
        AppSpacing.md,
      ),
      child: detected.isEmpty
          ? Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.lg,
                0,
                AppSpacing.lg,
                AppSpacing.lg,
              ),
              child: CcEmptyState(
                icon: AppIcons.searchX,
                message: l10n.noRunnersDetected,
              ),
            )
          : Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // "N of M ready" is a dot on every rail row already. What the
                // rail cannot say is what it means for none of them to be, so
                // that sentence is the only thing kept above the hairline.
                if (readyCount == 0) ...[
                  Padding(
                    padding: insets,
                    child: Text(
                      l10n.adaptersNoneReadyNote,
                      style: CcTypography.caption.copyWith(
                        color:
                            (context.designSystem ?? DesignSystemTokens.light())
                                .textTertiary,
                        height: 1.5,
                      ),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.lg),
                ],
                const CcDivider(),
                SettingsMasterDetail(
                  rail: AdapterRail(
                    detected: detected,
                    query: _query,
                    onQueryChanged: (q) => setState(() => _query = q),
                    selectedId: selected?.adapter.id,
                    onSelected: (id) => setState(() => _selectedId = id),
                  ),
                  detail: selected == null
                      ? const SizedBox.shrink()
                      : AdapterDetailPane(
                          key: ValueKey(selected.adapter.id),
                          detected: selected,
                        ),
                ),
              ],
            ),
    );
  }

  Widget _defaultsCard(
    BuildContext context,
    AppLocalizations l10n,
    List<Adapter> available,
  ) {
    return SectionCard(
      label: l10n.defaultRunners,
      subtitle: Text(l10n.configureDefaultRunners),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          DefaultRunnerRow(
            label: l10n.defaultChat,
            description: l10n.defaultChatDescription,
            adapterIdProvider: defaultChatAdapterProvider,
            modelIdProvider: defaultChatModelProvider,
            available: available,
          ),
          const SizedBox(height: AppSpacing.lg),
          const CcDivider(),
          const SizedBox(height: AppSpacing.lg),
          DefaultRunnerRow(
            label: l10n.shortTask,
            description: l10n.shortTaskDescription,
            adapterIdProvider: shortTaskAdapterProvider,
            modelIdProvider: shortTaskModelProvider,
            available: available,
          ),
        ],
      ),
    );
  }
}
