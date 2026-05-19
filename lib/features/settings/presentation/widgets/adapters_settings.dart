import 'package:cc_ui/cc_ui.dart';
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
import 'package:lucide_icons_flutter/lucide_icons.dart';

/// Auto-detection panel for installed agent runner CLIs, plus default
/// adapter+model configuration for chat and short-task agents.
class AdaptersSettings extends ConsumerWidget {
  /// Creates a new [AdaptersSettings].
  const AdaptersSettings({super.key});

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
        CcButton(
          variant: CcButtonVariant.secondary,
          onPressed: () =>
              ref.read(detectedAdaptersProvider.notifier).refresh(),
          icon: LucideIcons.refreshCw,
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
                    separatorBuilder: (_, _) => const CcDivider(),
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
                const CcDivider(),
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
                child: CcSelect<String>(
                  options: adapterItems.entries
                      .map(
                        (e) => CcSelectOption(value: e.value, label: e.key),
                      )
                      .toList(),
                  value: currentAdapterId,
                  hintText: l10n.adapterLabel,
                  onChanged: (id) {
                    // ignore: avoid_dynamic_calls
                    ref.read(adapterIdProvider.notifier).set(id);
                    // ignore: avoid_dynamic_calls
                    ref.read(modelIdProvider.notifier).set(null);
                  },
                ),
              ),
              const SizedBox(width: 12),
              // Model dropdown.
              Expanded(
                child: ModelSelect(
                  adapterId: currentAdapterId,
                  selectedModelId: currentModelId,
                  onChange: (id) {
                    // ignore: avoid_dynamic_calls
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
    final tokens = context.designSystem ?? DesignSystemTokens.light();
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 10),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: _statusTint(tokens),
              borderRadius: BorderRadius.circular(8),
            ),
            child: _statusIcon(tokens),
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
                    color: tokens.textPrimary,
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
                    color: _statusColor(tokens),
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
                      color: tokens.textTertiary,
                      fontFamily: 'monospace',
                    ),
                  ),
                ],
                if (detected.isFound && detected.capabilities != null) ...[
                  const SizedBox(height: 6),
                  Wrap(
                    spacing: 6,
                    runSpacing: 4,
                    children: [
                      _CapabilityChip(
                        label: l10n.capabilityJsonMode,
                        enabled: detected.capabilities!.supportsJsonMode,
                        tokens: tokens,
                      ),
                      _CapabilityChip(
                        label: l10n.capabilityModelSelection,
                        enabled:
                            detected.capabilities!.supportsModelSelection,
                        tokens: tokens,
                      ),
                    ],
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

  Color _statusColor(DesignSystemTokens tokens) {
    switch (detected.status) {
      case DetectionStatus.checking:
        return tokens.textTertiary;
      case DetectionStatus.found:
        return tokens.success;
      case DetectionStatus.notFound:
        return tokens.textTertiary;
    }
  }

  Color _statusTint(DesignSystemTokens tokens) {
    return _statusColor(tokens).withValues(alpha: 0.1);
  }

  Widget _statusIcon(DesignSystemTokens tokens) {
    switch (detected.status) {
      case DetectionStatus.checking:
        return const Center(
          child: CcSpinner(size: 18),
        );
      case DetectionStatus.found:
        return Icon(
          LucideIcons.check,
          size: 20,
          color: tokens.success,
        );
      case DetectionStatus.notFound:
        return Icon(LucideIcons.x, size: 20, color: tokens.textTertiary);
    }
  }

  Widget _statusBadge(AppLocalizations l10n) {
    switch (detected.status) {
      case DetectionStatus.checking:
        return CcBadge(
          variant: CcBadgeVariant.neutral,
          label: l10n.checking,
        );
      case DetectionStatus.found:
        return CcBadge(
          variant: CcBadgeVariant.success,
          label: l10n.available,
        );
      case DetectionStatus.notFound:
        return CcBadge(
          variant: CcBadgeVariant.neutral,
          label: l10n.unavailable,
        );
    }
  }
}

/// A compact on/off capability chip (✓ / ✗ + label) shown under an adapter.
class _CapabilityChip extends StatelessWidget {
  const _CapabilityChip({
    required this.label,
    required this.enabled,
    required this.tokens,
  });

  final String label;
  final bool enabled;
  final DesignSystemTokens tokens;

  @override
  Widget build(BuildContext context) {
    final color = enabled ? tokens.textPrimary : tokens.textTertiary;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(enabled ? LucideIcons.check : LucideIcons.x, size: 12, color: color),
        const SizedBox(width: 4),
        Text(label, style: TextStyle(fontSize: 11, color: color)),
      ],
    );
  }
}
