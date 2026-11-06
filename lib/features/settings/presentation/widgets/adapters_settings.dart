import 'package:cc_domain/features/settings/domain/entities/adapter.dart';
import 'package:cc_ui/cc_ui.dart';
import 'package:collection/collection.dart';
import 'package:control_center/features/settings/presentation/widgets/adapters/adapter_detail_pane.dart';
import 'package:control_center/features/settings/presentation/widgets/adapters/adapter_rail.dart';
import 'package:control_center/features/settings/presentation/widgets/kit/settings_kit.dart';
import 'package:control_center/features/settings/presentation/widgets/providers_models_section.dart';
import 'package:control_center/features/settings/providers/claude_account_providers.dart';
import 'package:control_center/features/settings/providers/settings_providers.dart';
import 'package:control_center/features/settings/settings_shortcuts.dart';
import 'package:control_center/l10n/app_localizations.dart';
import 'package:control_center/shared/icons/app_icons.dart';
import 'package:control_center/shared/widgets/page_wrapper.dart';
import 'package:control_center/shared/widgets/section_card.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Auto-detection panel for installed agent runner CLIs. Which runner and model
/// an agent uses is set on the agent itself; there is no workspace default.
/// Every runner in the catalogue used to render its whole configuration inline: the
/// enforcement matrix, an environment-variable button and an extra-argv field, for the
/// installed ones and the missing ones alike.
class AdaptersSettings extends ConsumerStatefulWidget {
  /// Creates a new [AdaptersSettings].
  ///
  /// [initialAdapterId] pins the rail to that runner on the first frame
  /// (the credential gate arrives with `claude-code`). Null keeps the
  /// auto choice: first found, else first in the catalog.
  const AdaptersSettings({this.initialAdapterId, super.key});

  /// Runner to select on arrival, when the route named one.
  final String? initialAdapterId;

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
  void initState() {
    super.initState();
    final initial = widget.initialAdapterId;
    if (initial != null && initial.isNotEmpty) {
      _selectedId = initial;
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final detected = ref.watch(detectedAdaptersProvider);

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
        // One box, rather than a lazy sliver per section. These sections have
        // radically different heights (the selected provider can expose
        // hundreds of model rows). A heterogeneous SliverList estimates its
        // max extent from whichever sections are currently laid out, so the
        // desktop scrollbar thumb changes length while scrolling. Laying out
        // the page column gives the ScrollPosition its exact extent up front.
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _detectedCard(context, l10n, detected),
              const SizedBox(height: AppSpacing.xl),
              // Model catalog & provider governance (PRD 05).
              const ProvidersModelsSection(),
            ],
          ),
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
    final claudeSignInExpired =
        detected.any(
          (d) => d.isFound && d.adapter.transport == AdapterTransport.claudeCli,
        ) &&
        (ref
                .watch(claudeAccountsProvider)
                .value
                ?.any((view) => view.account.isCredentialExpired()) ??
            false);

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
      padding: const EdgeInsets.only(top: AppSpacing.md),
      headerPadding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
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
                    claudeSignInExpired: claudeSignInExpired,
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
                          signInExpired:
                              selected.adapter.transport ==
                                  AdapterTransport.claudeCli &&
                              claudeSignInExpired,
                        ),
                ),
              ],
            ),
    );
  }
}
