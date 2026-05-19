import 'package:control_center/core/theme/design_system_tokens.dart';
import 'package:control_center/features/settings/domain/entities/adapter.dart';
import 'package:control_center/features/settings/presentation/widgets/model_select.dart';
import 'package:control_center/features/settings/presentation/widgets/settings_shortcuts.dart';
import 'package:control_center/features/settings/providers/adapter_preferences_providers.dart';
import 'package:control_center/features/settings/providers/settings_providers.dart';
import 'package:control_center/l10n/app_localizations.dart';
import 'package:control_center/shared/widgets/page_wrapper.dart';
import 'package:control_center/shared/widgets/section_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:forui/forui.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

/// Auto-detection panel for installed agent runner CLIs, plus default
/// adapter+model configuration for chat and short-task agents.
class AdaptersSettings extends ConsumerWidget {
  /// Creates a new [AdaptersSettings].
  const AdaptersSettings({super.key, this.colors, this.textTheme});

  /// Forui colors override (legacy, unused).
  final FColors? colors;
  /// Material text theme override (legacy, unused).
  final TextTheme? textTheme;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
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
        FButton(
          variant: FButtonVariant.outline,
          onPress: () =>
              ref.read(detectedAdaptersProvider.notifier).refresh(),
          mainAxisSize: MainAxisSize.min,
          prefix: const Icon(LucideIcons.refreshCw, size: 14),
          child: Text(l10n.refresh),
        ),
      ],
      child: ListView(
        padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
        children: [
          // Detected runners section.
          SectionCard(
            label: l10n.detectedRunners(detected.length),
            padding: const EdgeInsets.fromLTRB(0, 14, 0, 0),
            headerPadding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
            child: detected.isEmpty
                ? Padding(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                    child: Text(
                      l10n.noRunnersDetected,
                    ),
                  )
                : ListView.separated(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: detected.length,
                    separatorBuilder: (_, _) => const FDivider(),
                    itemBuilder: (_, i) => _AdapterRow(detected: detected[i]),
                  ),
          ),
          const SizedBox(height: 24),

          // Default Runners section.
          SectionCard(
            label: l10n.defaultRunners,
            padding: const EdgeInsets.fromLTRB(0, 14, 0, 0),
            headerPadding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
            subtitle: Text(
              l10n.configureDefaultRunners,
            ),
            child: Column(
              children: [
                _DefaultRunnerRow(
                  label: l10n.defaultChat,
                  adapterIdProvider: defaultChatAdapterProvider,
                  modelIdProvider: defaultChatModelProvider,
                  detected: detected,
                ),
                const FDivider(),
                _DefaultRunnerRow(
                  label: l10n.shortTask,
                  adapterIdProvider: shortTaskAdapterProvider,
                  modelIdProvider: shortTaskModelProvider,
                  detected: detected,
                ),
              ],
            ),
          ),
        ],
      ),
      ),
    );
  }
}

/// A single row for configuring a default runner (adapter + model dropdowns).
class _DefaultRunnerRow extends ConsumerWidget {
  const _DefaultRunnerRow({
    required this.label,
    required this.adapterIdProvider,
    required this.modelIdProvider,
    required this.detected,
  });

  final String label;
  final NotifierProvider<dynamic, String?> adapterIdProvider;
  final NotifierProvider<dynamic, String?> modelIdProvider;
  final List<DetectedAdapter> detected;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final tokens = context.designSystem;
    final l10n = AppLocalizations.of(context);
    final currentAdapterId = ref.watch(adapterIdProvider);
    final currentModelId = ref.watch(modelIdProvider);

    // Build adapter dropdown items from ALL detected adapters (not just found
    // ones) so that a previously-selected adapter remains visible and
    // selectable even when it isn't currently detected on the filesystem.
    final adapterItems = <String, String>{
      for (final d in detected)
        if (d.status == DetectionStatus.checking)
          '${d.adapter.name} (${l10n.checkingEllipsis})': d.adapter.id
        else if (d.isFound)
          d.adapter.name: d.adapter.id
        else
          '${d.adapter.name} (${l10n.notDetected})': d.adapter.id,
    };

    // Ensure the currently-selected adapter is always in the dropdown, even if
    // it was removed from predefinedAdapters and never detected.
    if (currentAdapterId != null &&
        !adapterItems.containsValue(currentAdapterId)) {
      adapterItems[currentAdapterId] = currentAdapterId;
    }

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: theme.textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.w600,
              color: tokens?.textPrimary,
            ),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              // Adapter dropdown.
              Expanded(
                child: FSelect<String>(
                  items: adapterItems,
                  hint: l10n.adapterLabel,
                  control: FSelectControl<String>.managed(
                    initial: currentAdapterId != null
                        ? adapterItems.entries
                              .where((e) => e.value == currentAdapterId)
                              .firstOrNull
                              ?.value
                        : null,
                    onChange: (id) {
                      ref.read(adapterIdProvider.notifier).set(id);
                      ref.read(modelIdProvider.notifier).set(null);
                    },
                  ),
                ),
              ),
              const SizedBox(width: 12),
              // Model dropdown.
              Expanded(
                child: ModelSelect(
                  adapterId: currentAdapterId,
                  selectedModelId: currentModelId,
                  onChange: (id) {
                    ref.read(modelIdProvider.notifier).set(id);
                  },
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _AdapterRow extends StatelessWidget {
  const _AdapterRow({required this.detected});
  final DetectedAdapter detected;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final colors = FTheme.of(context).colors;
    final tokens = context.designSystem;
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 10),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: _statusTint(colors, tokens),
              borderRadius: BorderRadius.circular(8),
            ),
            child: _statusIcon(colors, tokens),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  detected.adapter.name,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: tokens?.textPrimary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  detected.isFound
                      ? l10n.installedVersion(detected.version ?? 'unknown')
                      : detected.status == DetectionStatus.checking
                          ? l10n.checkingEllipsis
                          : l10n.notFoundLabel,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: _statusColor(colors, tokens),
                    height: 1.4,
                  ),
                ),
                if (detected.isFound && detected.path != null) ...[
                  const SizedBox(height: 4),
                  Text(
                    detected.path!,
                    style: TextStyle(
                      fontSize: 12,
                      height: 1.4,
                      color: colors.mutedForeground,
                      fontFamily: 'monospace',
                    ),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(width: 12),
          _statusBadge(l10n),
        ],
      ),
    );
  }

  Color _statusColor(FColors colors, DesignSystemTokens? tokens) {
    switch (detected.status) {
      case DetectionStatus.checking:
        return colors.mutedForeground;
      case DetectionStatus.found:
        return tokens?.success ?? Colors.green;
      case DetectionStatus.notFound:
        return colors.mutedForeground;
    }
  }

  Color _statusTint(FColors colors, DesignSystemTokens? tokens) {
    return _statusColor(colors, tokens).withValues(alpha: 0.1);
  }

  Widget _statusIcon(FColors colors, DesignSystemTokens? tokens) {
    switch (detected.status) {
      case DetectionStatus.checking:
        return const Center(
          child: FCircularProgress(
            style: FCircularProgressStyleDelta.delta(
              iconStyle: IconThemeDataDelta.delta(size: 18),
            ),
          ),
        );
      case DetectionStatus.found:
        return Icon(
          LucideIcons.check,
          size: 20,
          color: tokens?.success ?? Colors.green,
        );
      case DetectionStatus.notFound:
        return Icon(LucideIcons.x, size: 20, color: colors.mutedForeground);
    }
  }

  Widget _statusBadge(AppLocalizations l10n) {
    switch (detected.status) {
      case DetectionStatus.checking:
        return FBadge(
          variant: FBadgeVariant.secondary,
          child: Text(l10n.checking),
        );
      case DetectionStatus.found:
        return FBadge(
          variant: FBadgeVariant.primary,
          child: Text(l10n.available),
        );
      case DetectionStatus.notFound:
        return FBadge(
          variant: FBadgeVariant.outline,
          child: Text(l10n.unavailable),
        );
    }
  }
}
