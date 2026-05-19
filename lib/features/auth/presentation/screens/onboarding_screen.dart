import 'package:cc_domain/features/settings/domain/entities/adapter.dart';
import 'package:cc_ui/cc_ui.dart';
import 'package:control_center/core/theme/theme_provider.dart';
import 'package:control_center/di/providers.dart';
import 'package:control_center/features/auth/presentation/screens/onboarding_model_steps.dart';
import 'package:control_center/features/auth/presentation/widgets/api_keys_panel.dart';
import 'package:control_center/features/forge/providers/forge_providers.dart';
import 'package:control_center/features/sandboxing/presentation/onboarding_step_sandbox.dart';
import 'package:control_center/features/settings/presentation/widgets/harness_provider_login.dart';
import 'package:control_center/features/settings/presentation/widgets/model_select.dart';
import 'package:control_center/features/settings/providers/adapter_preferences_providers.dart';
import 'package:control_center/features/settings/providers/harness_providers_providers.dart';
import 'package:control_center/features/settings/providers/settings_providers.dart';
import 'package:control_center/features/workspaces/presentation/widgets/add_workspace_form.dart';
import 'package:control_center/features/workspaces/providers/workspace_providers.dart';
import 'package:control_center/l10n/app_localizations.dart';
import 'package:control_center/router/routes.dart';
import 'package:control_center/shared/icons/app_icons.dart';
import 'package:control_center/shared/widgets/shader_background.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

/// Five-step first-run onboarding: configure API access, add a workspace,
/// set up agent sandboxing, choose a default adapter + model, then optionally
/// fetch the local voice transcription model. The embedding and diarization
/// models have no step — the server force-installs both at boot.
class OnboardingScreen extends ConsumerStatefulWidget {
  /// Creates the [OnboardingScreen].
  const OnboardingScreen({super.key});

  /// Creates the mutable state for this widget.
  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen> {
  static const int _totalSteps = 5;
  int _step = 0;

  // NO step skipping: the onboarding gate (complete / incomplete) is the only
  // decision — it routes here when incomplete and an incomplete onboarding
  // starts from step 1 every time, even when GitHub auth is already set up
  // (the step then simply shows the connected state). Deriving a skip from
  // async auth probes made the flow depend on frame timing.

  _StepCopy _copyFor(int step, AppLocalizations l10n) {
    final number = _step + 1;
    switch (step) {
      case 0:
        return _StepCopy(
          eyebrow: l10n.stepConnect(number),
          title: l10n.letsPluginTools,
          subtitle: l10n.connectGitHubAndTicketing,
          icon: AppIcons.plug,
        );
      case 1:
        return _StepCopy(
          eyebrow: 'Step $number · Workspace',
          title: l10n.giveYourWorkAHome,
          subtitle:
              'Name your first workspace — a project, team, or initiative. '
              'You can add a logo now or link repositories later from '
              'Settings → Repositories.',
          icon: AppIcons.layoutGrid,
        );
      case 2:
        return _StepCopy(
          eyebrow: 'Step $number · Sandbox',
          title: l10n.isolateAgentExecution,
          subtitle:
              'Agents will run inside disposable containers so they can\'t '
              'touch the rest of your machine. You can fine-tune token '
              'access per conversation later — or skip this for now and '
              're-enable it from Settings → Security.',
          icon: AppIcons.shield,
        );
      case 3:
        return _StepCopy(
          eyebrow: 'Step $number · Adapter',
          title: l10n.chooseRunner,
          subtitle:
              'Select the default adapter and model for agent conversations. '
              'You can change this later in Settings → Adapters.',
          icon: AppIcons.cpu,
        );
      default:
        return _StepCopy(
          eyebrow: 'Step $number · Voice (optional)',
          title: l10n.talkToControlCenter,
          subtitle:
              'Pick a speech model and install it to dictate messages '
              'straight into the composer. Parakeet TDT v3 is the '
              'recommended default — fast and multilingual. Runs fully '
              'on-device — or skip and turn it on later in Settings.',
          icon: AppIcons.mic,
        );
    }
  }

  void _finishOnboarding() {
    if (!mounted) {
      return;
    }
    // The first workspace created during onboarding is the active one; enter
    // its inbox. The picker is a safety net if none resolved.
    final wsId = ref.read(activeWorkspaceIdProvider);
    context.go(wsId == null ? workspaceListRoute : inboxRoute(wsId));
  }

  Widget _bodyFor(int step) {
    switch (step) {
      case 0:
        return _StepOne(
          isAuthed: ref.watch(hasAnyForgeConnectedProvider),
          onContinue: () => setState(() => _step = 1),
        );
      case 1:
        return _StepTwo(
          onBack: () => setState(() => _step = 0),
          onContinue: () => setState(() => _step = 2),
        );
      case 2:
        return OnboardingStepSandbox(
          onBack: () => setState(() => _step = 1),
          onContinue: () => setState(() => _step = 3),
        );
      case 3:
        return _StepAdapter(
          onBack: () => setState(() => _step = 2),
          onContinue: () => setState(() => _step = 4),
        );
      default:
        return OnboardingVoiceStep(
          onBack: () => setState(() => _step = 3),
          onFinish: _finishOnboarding,
        );
    }
  }

  void _toggleTheme() {
    final isLight = Theme.of(context).brightness == Brightness.light;
    ref
        .read(themeModeProvider.notifier)
        .setThemeMode(isLight ? ThemeMode.dark : ThemeMode.light);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final copy = _copyFor(_step, l10n);

    return ShaderBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: SafeArea(
          child: Stack(
            children: [
              Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 720),
                  // Pinned chrome, scrolling content: the step indicator and
                  // each step's title/subtitle never move — only the step body
                  // scrolls (inside _StepHero) — so the scrollbar hugs the
                  // content instead of spanning the full window.
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(24, 32, 24, 32),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        _StepIndicator(currentStep: _step, total: _totalSteps),
                        const SizedBox(height: 32),
                        Flexible(
                          child: AnimatedSwitcher(
                            duration: const Duration(milliseconds: 280),
                            switchInCurve: Curves.easeOutCubic,
                            switchOutCurve: Curves.easeInCubic,
                            transitionBuilder: (child, animation) {
                              final offset = Tween<Offset>(
                                begin: const Offset(0, 0.04),
                                end: Offset.zero,
                              ).animate(animation);
                              return FadeTransition(
                                opacity: animation,
                                child: SlideTransition(
                                  position: offset,
                                  child: child,
                                ),
                              );
                            },
                            child: KeyedSubtree(
                              key: ValueKey<int>(_step),
                              child: _StepHero(
                                copy: copy,
                                body: _bodyFor(_step),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              Positioned(
                top: 16,
                right: 16,
                child: _ThemeToggle(onToggle: _toggleTheme),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ThemeToggle extends StatelessWidget {
  const _ThemeToggle({required this.onToggle});

  final VoidCallback onToggle;

  @override
  Widget build(BuildContext context) {
    final isLight = Theme.of(context).brightness == Brightness.light;
    return CcIconButton(
      icon: isLight ? AppIcons.moon : AppIcons.sun,
      tooltip: AppLocalizations.of(context).toggleTheme,
      onPressed: onToggle,
    );
  }
}

class _StepCopy {
  const _StepCopy({
    required this.eyebrow,
    required this.title,
    required this.subtitle,
    required this.icon,
  });

  final String eyebrow;
  final String title;
  final String subtitle;
  final IconData icon;
}

class _StepHero extends StatelessWidget {
  const _StepHero({required this.copy, this.body});

  final _StepCopy copy;
  final Widget? body;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final tokens = context.designSystem;
    final isLight = theme.brightness == Brightness.light;

    final surfaceTint = isLight
        ? (tokens?.panel ?? Colors.white).withValues(alpha: 0.55)
        : (tokens?.bgSecondary ?? const Color(0xFF1F1F1F)).withValues(
            alpha: 0.30,
          );
    final borderColor = isLight
        ? (tokens?.borderSecondary ?? Colors.white).withValues(alpha: 0.65)
        : (tokens?.borderSoft ?? Colors.white).withValues(alpha: 0.10);

    final accent = isLight
        ? scheme.primary
        : (tokens?.accent ?? scheme.primary);
    final iconBg = isLight
        ? scheme.primary.withValues(alpha: 0.12)
        : (tokens?.bgTertiary ?? Colors.white).withValues(alpha: 0.14);

    return Container(
      padding: const EdgeInsets.fromLTRB(24, 22, 24, 24),
      decoration: BoxDecoration(
        color: surfaceTint,
        borderRadius: AppRadii.brLg,
        border: Border.all(color: borderColor, width: 1),
      ),
      child: Column(
        // Shrink-wraps so a short step keeps the compact centred card; the
        // outer Flexible (in OnboardingScreen) caps it at the viewport, where
        // the body below takes over scrolling.
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 44,
                height: 44,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: iconBg,
                  borderRadius: AppRadii.brSm,
                ),
                child: Icon(copy.icon, color: accent, size: 22),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  copy.eyebrow,
                  style: CcTypography.caption.copyWith(
                    color: accent,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.6,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            copy.title,
            style: CcTypography.display.copyWith(
              color: tokens?.textPrimary,
              fontWeight: FontWeight.w700,
              height: 1.2,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            copy.subtitle,
            style: CcTypography.body.copyWith(
              color: tokens?.textTertiary,
              height: 1.55,
            ),
          ),
          // Only the step body scrolls: the eyebrow, title and subtitle stay
          // pinned under the step indicator no matter how tall a step is.
          if (body != null) ...[
            const SizedBox(height: 24),
            Flexible(child: SingleChildScrollView(child: body!)),
          ],
        ],
      ),
    );
  }
}

class _StepIndicator extends StatelessWidget {
  const _StepIndicator({required this.currentStep, required this.total});

  final int currentStep;
  final int total;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final segments = <Widget>[];
    for (var i = 0; i < total; i++) {
      final active = i <= currentStep;
      segments.add(
        Expanded(
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 260),
            height: 4,
            decoration: BoxDecoration(
              color: active
                  ? scheme.primary
                  : scheme.onSurface.withValues(alpha: 0.16),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
        ),
      );
      if (i < total - 1) {
        segments.add(const SizedBox(width: 6));
      }
    }
    return Row(key: const Key('onboarding-step-indicator'), children: segments);
  }
}

class _StepOne extends StatelessWidget {
  const _StepOne({required this.isAuthed, required this.onContinue});

  final bool isAuthed;
  final VoidCallback onContinue;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const ApiKeysPanel(),
        const SizedBox(height: 24),
        Align(
          alignment: Alignment.centerRight,
          child: CcButton(
            onPressed: isAuthed ? onContinue : null,
            child: Text(l10n.continueLabel),
          ),
        ),
      ],
    );
  }
}

class _StepTwo extends ConsumerWidget {
  const _StepTwo({required this.onBack, required this.onContinue});

  final VoidCallback? onBack;
  final VoidCallback onContinue;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    return AddWorkspaceForm(
      onCreated: (_) {
        ref.invalidate(workspacesProvider);
        onContinue();
      },
      onCancel: onBack,
      submitLabel: l10n.continueLabel,
    );
  }
}

/// Step 3: Default adapter + model selection.
class _StepAdapter extends ConsumerStatefulWidget {
  const _StepAdapter({required this.onBack, required this.onContinue});

  final VoidCallback onBack;
  final VoidCallback onContinue;

  @override
  ConsumerState<_StepAdapter> createState() => _StepAdapterState();
}

class _StepAdapterState extends ConsumerState<_StepAdapter> {
  String? _selectedAdapterId;
  String? _selectedModelId;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) {
        return;
      }
      final persisted = ref.read(defaultChatAdapterProvider);
      final detected = ref.read(detectedAdaptersProvider);
      final found = detected.where((d) => d.isFound).toList();

      if (_selectedAdapterId != null) {
        return;
      }

      setState(() {
        _selectedAdapterId =
            persisted ?? (found.isNotEmpty ? found.first.adapter.id : null);
      });
      final persistedModel = ref.read(defaultChatModelProvider);
      if (persistedModel != null && _selectedModelId == null) {
        setState(() => _selectedModelId = persistedModel);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final detected = ref.watch(detectedAdaptersProvider);
    final found = detected.where((d) => d.isFound).toList();
    final anyChecking = detected.any(
      (d) => d.status == DetectionStatus.checking,
    );
    final theme = Theme.of(context);
    final tokens = context.designSystem;
    final l10n = AppLocalizations.of(context);
    final adapterItems = <String, String>{
      for (final d in found) d.adapter.name: d.adapter.id,
    };

    final canContinue =
        _selectedAdapterId != null &&
        _selectedModelId != null &&
        _selectedModelId!.isNotEmpty;

    return Column(
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
        if (anyChecking) ...[
          const Center(child: CcSpinner()),
          const SizedBox(height: 8),
          Center(
            child: Text(
              'Checking for installed runners...',
              style: CcTypography.caption.copyWith(color: tokens?.textTertiary),
            ),
          ),
        ] else if (found.isEmpty) ...[
          Row(
            children: [
              Icon(
                AppIcons.alertTriangle,
                size: 16,
                color: theme.colorScheme.error,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'No adapter detected. Install Pi to continue:\n'
                  'npm install -g @anthropic/pi',
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
            value: _selectedAdapterId,
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
        if (_selectedAdapterId == 'cc-harness') ...[
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

        // Model autocomplete.
        if (_selectedAdapterId != null) ...[
          Text(
            l10n.modelLabel,
            style: CcTypography.caption.copyWith(
              color: tokens?.textTertiary,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          ModelSelect(
            adapterId: _selectedAdapterId,
            selectedModelId: _selectedModelId,
            onChange: (id) => setState(() => _selectedModelId = id),
          ),
        ],

        const SizedBox(height: 20),
        Row(
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
                      await ref
                          .read(defaultChatAdapterProvider.notifier)
                          .set(_selectedAdapterId);
                      await ref
                          .read(defaultChatModelProvider.notifier)
                          .set(_selectedModelId);
                      await ref
                          .read(shortTaskAdapterProvider.notifier)
                          .set(_selectedAdapterId);
                      await ref
                          .read(shortTaskModelProvider.notifier)
                          .set(_selectedModelId);
                      // Back-patch CEO agents created before adapter prefs
                      // were available (onboarding Step 1 creates the
                      // workspace, CEO is seeded then; Step 3 sets adapter).
                      try {
                        final repo = ref.read(agentRepositoryProvider);
                        final agents = await repo.watchAll().first;
                        for (final a in agents) {
                          if (a.name == 'ceo' &&
                              (a.adapterId == null || a.modelId == null)) {
                            await repo.upsert(
                              a.copyWith(
                                adapterId: _selectedAdapterId,
                                modelId: _selectedModelId,
                              ),
                            );
                          }
                        }
                      } catch (_) {
                        // Non-critical — adapter can be changed in Settings.
                      }
                      widget.onContinue();
                    }
                  : null,
              child: Text(l10n.continueLabel),
            ),
          ],
        ),
      ],
    );
  }

  /// Provider picker for the built-in runner: connected providers are marked;
  /// picking an unconnected one opens the login dialog (API key or browser
  /// OAuth). A successful login invalidates the provider/model lists, so the
  /// model dropdown below repopulates on its own.
  Widget _providerLoginSelect(AppLocalizations l10n) {
    final providersAsync = ref.watch(harnessProvidersProvider);
    return providersAsync.when(
      loading: () => FieldPlaceholder(text: l10n.loadingProviders),
      error: (e, _) => FieldPlaceholder(text: l10n.failedWithError('$e')),
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
