import 'package:cc_domain/features/settings/domain/entities/adapter.dart';
import 'package:cc_ui/cc_ui.dart';
import 'package:control_center/features/auth/presentation/widgets/onboarding_step_layout.dart';
import 'package:control_center/features/auth/providers/onboarding_runner_choice.dart';
import 'package:control_center/features/settings/presentation/widgets/field_placeholder.dart';
import 'package:control_center/features/settings/presentation/widgets/harness_provider_login.dart';
import 'package:control_center/features/settings/presentation/widgets/model_picker_field.dart';
import 'package:control_center/features/settings/providers/adapter_preferences_providers.dart';
import 'package:control_center/features/settings/providers/harness_providers_providers.dart';
import 'package:control_center/features/settings/providers/settings_providers.dart';
import 'package:control_center/l10n/app_localizations.dart';
import 'package:control_center/shared/icons/app_icons.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Step 3: Default adapter + model selection.
class OnboardingAdapterStep extends ConsumerStatefulWidget {
  /// Creates the default adapter and model step.
  const OnboardingAdapterStep({
    required this.onBack,
    required this.onContinue,
    super.key,
  });

  /// Returns to the previous step.
  final VoidCallback onBack;

  /// Advances after saving the chosen runner and model.
  final VoidCallback onContinue;

  @override
  ConsumerState<OnboardingAdapterStep> createState() =>
      _OnboardingAdapterStepState();
}

class _OnboardingAdapterStepState extends ConsumerState<OnboardingAdapterStep> {
  String? _selectedAdapterId;
  String? _selectedModelId;

  /// The runner to show: an explicit pick, else a persisted one that is still
  /// installed, else the built-in loop. The built-in loop is always found
  /// (no binary), so waiting on Claude Code's `--version` must not hide it.
  String? _resolvedAdapterId(List<DetectedAdapter> found) {
    if (_selectedAdapterId != null) {
      return _selectedAdapterId;
    }
    if (found.isEmpty) {
      return null;
    }
    final ids = {for (final d in found) d.adapter.id};
    final persisted = ref.read(defaultChatAdapterProvider);
    if (persisted != null && ids.contains(persisted)) {
      return persisted;
    }
    if (ids.contains(builtInAdapter.id)) {
      return builtInAdapter.id;
    }
    return found.first.adapter.id;
  }

  @override
  Widget build(BuildContext context) {
    final detected = ref.watch(detectedAdaptersProvider);
    final found = detected.where((d) => d.isFound).toList();
    final stillChecking = detected.any(
      (d) => d.status == DetectionStatus.checking,
    );
    final adapterId = _resolvedAdapterId(found);
    final persistedAdapter = ref.read(defaultChatAdapterProvider);
    final persistedModel = ref.read(defaultChatModelProvider);
    final modelId =
        _selectedModelId ??
        (adapterId != null && adapterId == persistedAdapter
            ? persistedModel
            : null);
    final t = context.designSystem ?? DesignSystemTokens.light();
    final tokens = context.designSystem;
    final l10n = AppLocalizations.of(context);
    final adapterItems = <String, String>{
      for (final d in found) d.adapter.name: d.adapter.id,
    };

    final canContinue =
        adapterId != null && modelId != null && modelId.isNotEmpty;

    return OnboardingStepLayout(
      content: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Adapter dropdown.
          Text(
            l10n.adapterLabel,
            style: CcTypography.caption.copyWith(
              color: tokens?.textTertiary,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          if (found.isEmpty && stillChecking) ...[
            const Center(child: CcSpinner()),
            const SizedBox(height: 8),
            Center(
              child: Text(
                l10n.detectingAdapters,
                style: CcTypography.caption.copyWith(
                  color: tokens?.textTertiary,
                ),
              ),
            ),
          ] else if (found.isEmpty) ...[
            Row(
              children: [
                Icon(
                  AppIcons.alertTriangle,
                  size: 16,
                  color: t.textErrorPrimary,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    l10n.noRunnersDetected,
                    style: CcTypography.caption.copyWith(
                      color: tokens?.textTertiary,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            CcButton(
              onPressed: () =>
                  ref.read(detectedAdaptersProvider.notifier).refresh(),
              variant: CcButtonVariant.secondary,
              icon: AppIcons.refreshCw,
              child: Text(l10n.refresh),
            ),
          ] else ...[
            CcSelect<String>(
              options: [
                for (final entry in adapterItems.entries)
                  CcSelectOption(value: entry.value, label: entry.key),
              ],
              value: adapterId,
              hintText: l10n.selectRunner,
              onChanged: (id) {
                setState(() {
                  _selectedAdapterId = id;
                  _selectedModelId = null;
                });
              },
            ),
          ],
          const SizedBox(height: 16),

          // The built-in runner serves its model list live from the providers
          // the user is logged into — until one is connected the model dropdown
          // is empty, so the login flow happens right here.
          if (adapterId == builtInAdapter.id) ...[
            Text(
              l10n.providerLabel,
              style: CcTypography.caption.copyWith(
                color: tokens?.textTertiary,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            _providerLoginSelect(l10n),
            const SizedBox(height: 16),
          ],

          // Model picker (opens the model browser dialog).
          if (adapterId != null) ...[
            Text(
              l10n.modelLabel,
              style: CcTypography.caption.copyWith(
                color: tokens?.textTertiary,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            ModelPickerField(
              adapterId: adapterId,
              selectedModelId: modelId,
              onChange: (id) => setState(() => _selectedModelId = id),
            ),
          ],
        ],
      ),
      footer: Row(
        children: [
          CcButton(
            onPressed: widget.onBack,
            variant: CcButtonVariant.secondary,
            child: Text(l10n.back),
          ),
          const Spacer(),
          CcButton(
            onPressed: canContinue
                ? () async {
                    await saveOnboardingRunnerChoice(
                      ref,
                      adapterId: adapterId,
                      modelId: modelId,
                    );
                    widget.onContinue();
                  }
                : null,
            child: Text(l10n.continueLabel),
          ),
        ],
      ),
    );
  }

  /// Provider picker for the built-in runner: connected providers are marked;
  /// picking an unconnected one opens the login dialog (API key or browser
  /// OAuth). A successful login invalidates the provider/model lists, so the
  /// model dropdown below repopulates on its own.
  Widget _providerLoginSelect(AppLocalizations l10n) {
    final providersAsync = ref.watch(harnessProvidersProvider);
    return providersAsync.when(
      loading: () => FieldPlaceholder(
        text: l10n.loadingProviders,
        kind: FieldPlaceholderKind.loading,
      ),
      error: (e, _) => FieldPlaceholder(
        text: l10n.failedWithError('$e'),
        kind: FieldPlaceholderKind.error,
      ),
      data: (providers) => CcSelect<String>(
        options: [
          for (final p in providers)
            CcSelectOption(
              value: p.id,
              label: p.connected
                  ? '${p.displayName} · ${l10n.providerConnectedOauth}'
                  : p.displayName,
            ),
        ],
        value: null,
        hintText: l10n.selectProviderToLogin,
        onChanged: (id) {
          final provider = providers.where((p) => p.id == id).firstOrNull;
          if (provider == null || provider.connected) {
            return;
          }
          showHarnessProviderLoginDialog(context, provider);
        },
      ),
    );
  }
}
