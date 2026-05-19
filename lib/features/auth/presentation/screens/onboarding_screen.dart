import 'package:control_center/core/infrastructure/embedding/embedding_providers.dart';
import 'package:control_center/core/infrastructure/speech/voice_model_providers.dart';
import 'package:control_center/core/theme/app_radii.dart';
import 'package:control_center/core/theme/design_system_tokens.dart';
import 'package:control_center/core/theme/theme_provider.dart';
import 'package:control_center/di/providers.dart';
import 'package:control_center/features/auth/presentation/widgets/api_keys_panel.dart';
import 'package:control_center/features/auth/providers/auth_providers.dart';
import 'package:control_center/features/sandboxing/presentation/onboarding_step_sandbox.dart';
import 'package:control_center/features/settings/domain/entities/adapter.dart';
import 'package:control_center/features/settings/presentation/widgets/model_select.dart';
import 'package:control_center/features/settings/presentation/widgets/sections/voice_section.dart' show AudioInputRow;
import 'package:control_center/features/settings/providers/adapter_preferences_providers.dart';
import 'package:control_center/features/settings/providers/settings_providers.dart';
import 'package:control_center/features/workspaces/presentation/widgets/add_workspace_form.dart';
import 'package:control_center/features/workspaces/providers/workspace_providers.dart';
import 'package:control_center/l10n/app_localizations.dart';
import 'package:control_center/router/routes.dart';
import 'package:control_center/shared/widgets/shader_background.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:forui/forui.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

/// Six-step first-run onboarding: configure API access, add a workspace,
/// set up agent sandboxing, choose a default adapter + model, optionally
/// fetch the local voice transcription model, then optionally fetch the
/// semantic memory embedding model.
class OnboardingScreen extends ConsumerStatefulWidget {
  /// Creates the [OnboardingScreen].
  const OnboardingScreen({super.key});

  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen> {
  static const int _totalSteps = 6;
  int _step = 0;
  bool _skipFirstStep = false;

  @override
  void initState() {
    super.initState();
    // Jump straight to the workspace step if API access is already set up.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) {
        return;
      }

      if (ref.read(isGitHubAuthenticatedProvider)) {
        setState(() {
          _step = 1;
          _skipFirstStep = true;
        });
      }
    });
  }

  int get _visibleStepCount =>
      _skipFirstStep ? _totalSteps - 1 : _totalSteps;
  int get _visibleStepIndex => _skipFirstStep ? _step - 1 : _step;

  _StepCopy _copyFor(int step, AppLocalizations l10n) {
    final number = _visibleStepIndex + 1;
    switch (step) {
      case 0:
        return _StepCopy(
          eyebrow: l10n.stepConnect(number),
          title: l10n.letsPluginTools,
          subtitle: l10n.connectGitHubAndTicketing,
          icon: LucideIcons.plug,
        );
      case 1:
        return _StepCopy(
          eyebrow: 'Step $number · Workspace',
          title: l10n.giveYourWorkAHome,
          subtitle:
              'Name your first workspace — a project, team, or initiative. '
              'You can add a logo now or link repositories later from '
              'Settings → Repositories.',
          icon: LucideIcons.layoutGrid,
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
          icon: LucideIcons.shield,
        );
      case 3:
        return _StepCopy(
          eyebrow: 'Step $number · Adapter',
          title: l10n.chooseRunner,
          subtitle:
              'Select the default adapter and model for agent conversations. '
              'You can change this later in Settings → Adapters.',
          icon: LucideIcons.cpu,
        );
      case 4:
        return _StepCopy(
          eyebrow: 'Step $number · Voice (optional)',
          title: l10n.talkToControlCenter,
          subtitle:
              'Install the Whisper base.en model (~200 MB) to dictate '
              'messages straight into the composer. Runs fully on-device — '
              'or skip and turn it on later in Settings.',
          icon: LucideIcons.mic,
        );
      default:
        return _StepCopy(
          eyebrow: 'Step $number · Memory (optional)',
          title: l10n.giveAgentsAMemory,
          subtitle:
              'Install the all-MiniLM-L6-v2 embedding model (~22 MB) to '
              'enable semantic memory search. Runs fully on-device — or '
              'skip and turn it on later in Settings.',
          icon: LucideIcons.brain,
        );
    }
  }

  void _finishOnboarding() {
    if (!mounted) {
      return;
    }
    context.go(dashboardRoute);
  }

  Widget _bodyFor(int step) {
    switch (step) {
      case 0:
        return _StepOne(
          isAuthed: ref.watch(isGitHubAuthenticatedProvider),
          onContinue: () => setState(() => _step = 1),
        );
      case 1:
        return _StepTwo(
          onBack: _skipFirstStep ? null : () => setState(() => _step = 0),
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
      case 4:
        return _StepVoice(
          onBack: () => setState(() => _step = 3),
          onContinue: () => setState(() => _step = 5),
        );
      default:
        return _StepEmbedding(
          onBack: () => setState(() => _step = 4),
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
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(24, 32, 24, 32),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        _StepIndicator(
                          currentStep: _visibleStepIndex,
                          total: _visibleStepCount,
                        ),
                        const SizedBox(height: 32),
                        AnimatedSwitcher(
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
    return FButton.icon(
      onPress: onToggle,
      child: Icon(isLight ? LucideIcons.moon : LucideIcons.sun),
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
        : (tokens?.bgSecondary ?? const Color(0xFF1F1F1F)).withValues(alpha: 0.30);
    final borderColor = isLight
        ? (tokens?.borderSecondary ?? Colors.white).withValues(alpha: 0.65)
        : (tokens?.borderSoft ?? Colors.white).withValues(alpha: 0.10);

    final accent = isLight ? scheme.primary : (tokens?.accent ?? scheme.primary);
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
                  style: theme.textTheme.labelMedium?.copyWith(
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
            style: theme.textTheme.headlineSmall?.copyWith(
              color: tokens?.textPrimary,
              fontWeight: FontWeight.w700,
              height: 1.2,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            copy.subtitle,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: tokens?.textTertiary,
              height: 1.55,
            ),
          ),
          if (body != null) ...[
            const SizedBox(height: 24),
            body!,
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
    return Row(children: segments);
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
          child: FButton(
            onPress: isAuthed ? onContinue : null,
            mainAxisSize: MainAxisSize.min,
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
      if (!mounted) return;
      final persisted = ref.read(defaultChatAdapterProvider);
      final detected = ref.read(detectedAdaptersProvider);
      final found = detected.where((d) => d.isFound).toList();

      if (_selectedAdapterId != null) return;

      setState(() {
        _selectedAdapterId = persisted ??
            (found.isNotEmpty ? found.first.adapter.id : null);
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
    final anyChecking = detected.any((d) => d.status == DetectionStatus.checking);
    final theme = Theme.of(context);
    final tokens = context.designSystem;
    final l10n = AppLocalizations.of(context);
    final adapterItems = <String, String>{
      for (final d in found)
        d.adapter.name: d.adapter.id,
    };

    final canContinue = _selectedAdapterId != null &&
        _selectedModelId != null &&
        _selectedModelId!.isNotEmpty;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Adapter dropdown.
        Text(
          l10n.adapterLabel,
          style: theme.textTheme.bodySmall?.copyWith(
            color: tokens?.textTertiary,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 8),
        if (anyChecking) ...[
          const Center(
            child: FCircularProgress(),
          ),
          const SizedBox(height: 8),
          Center(
            child: Text(
              'Checking for installed runners...',
              style: theme.textTheme.bodySmall?.copyWith(
                color: tokens?.textTertiary,
              ),
            ),
          ),
        ] else if (found.isEmpty) ...[
          Row(
            children: [
              Icon(
                LucideIcons.alertTriangle,
                size: 16,
                color: theme.colorScheme.error,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'No adapter detected. Install Pi to continue:\n'
                  'npm install -g @anthropic/pi',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: tokens?.textTertiary,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          FButton(
            onPress: () =>
                ref.read(detectedAdaptersProvider.notifier).refresh(),
            variant: FButtonVariant.outline,
            mainAxisSize: MainAxisSize.min,
            prefix: const Icon(LucideIcons.refreshCw, size: 14),
            child: Text(l10n.refresh),
          ),
        ] else ...[
          FSelect<String>(
            items: adapterItems,
            hint: l10n.selectRunner,
            control: FSelectControl<String>.managed(
              initial: _selectedAdapterId != null
                  ? adapterItems.entries
                        .where((e) => e.value == _selectedAdapterId)
                        .firstOrNull
                        ?.value
                  : null,
              onChange: (id) {
                setState(() {
                  _selectedAdapterId = id;
                  _selectedModelId = null;
                });
              },
            ),
          ),
        ],
        const SizedBox(height: 16),

        // Model autocomplete.
        if (_selectedAdapterId != null) ...[
          Text(
            l10n.modelLabel,
            style: theme.textTheme.bodySmall?.copyWith(
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
            FButton(
              onPress: widget.onBack,
              variant: FButtonVariant.outline,
              mainAxisSize: MainAxisSize.min,
              child: Text(l10n.back),
            ),
            const Spacer(),
            FButton(
              onPress: canContinue
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
                            await repo.upsert(a.copyWith(
                              adapterId: _selectedAdapterId,
                              modelId: _selectedModelId,
                            ));
                          }
                        }
                      } catch (_) {
                        // Non-critical — adapter can be changed in Settings.
                      }
                      widget.onContinue();
                    }
                  : null,
              mainAxisSize: MainAxisSize.min,
              child: Text(l10n.continueLabel),
            ),
          ],
        ),
      ],
    );
  }
}

class _StepVoice extends ConsumerWidget {
  const _StepVoice({required this.onBack, required this.onContinue});

  final VoidCallback onBack;
  final VoidCallback onContinue;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(voiceModelStateProvider);
    final notifier = ref.read(voiceModelStateProvider.notifier);
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context);

    final isInstalled = state.status == VoiceModelStatus.installed;
    final isDownloading = state.status == VoiceModelStatus.downloading;
    final hasError = state.status == VoiceModelStatus.error;

    final tokens = context.designSystem;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Icon(
              isInstalled
                  ? LucideIcons.circleCheck
                  : (isDownloading ? LucideIcons.download : LucideIcons.mic),
              size: 18,
              color: isInstalled
                  ? theme.colorScheme.primary
                  : tokens?.textTertiary,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                isInstalled
                    ? 'Voice model installed and ready to use.'
                    : (isDownloading
                        ? (state.phase == 'extracting'
                            ? l10n.extractingModel((state.progress * 100).round())
                            : l10n.downloadingModel((state.progress * 100).round()))
                        : l10n.voiceModelNotInstalledLabel),
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: tokens?.textPrimary,
                ),
              ),
            ),
          ],
        ),
        if (isDownloading) ...[
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: state.progress > 0
                ? FDeterminateProgress(value: state.progress)
                : const FProgress(),
          ),
        ],
        if (hasError && state.error != null) ...[
          const SizedBox(height: 12),
          Text(
            state.error!,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.error,
            ),
          ),
        ],
        const SizedBox(height: 16),
        const AudioInputRow(),
        const SizedBox(height: 20),
        Row(
          children: [
            FButton(
              onPress: onBack,
              variant: FButtonVariant.outline,
              mainAxisSize: MainAxisSize.min,
              child: Text(l10n.back),
            ),
            const Spacer(),
            if (isDownloading)
              FButton(
                onPress: notifier.cancel,
                variant: FButtonVariant.outline,
                mainAxisSize: MainAxisSize.min,
                child: Text(l10n.cancel),
              )
            else if (isInstalled)
              FButton(
                onPress: onContinue,
                mainAxisSize: MainAxisSize.min,
                child: Text(l10n.continueLabel),
              )
            else ...[
              FButton(
                onPress: onContinue,
                variant: FButtonVariant.outline,
                mainAxisSize: MainAxisSize.min,
                child: Text(l10n.skipForNow),
              ),
              const SizedBox(width: 8),
              FButton(
                onPress: notifier.installIfNeeded,
                mainAxisSize: MainAxisSize.min,
                child: Text(l10n.download),
              ),
            ],
          ],
        ),
      ],
    );
  }
}

class _StepEmbedding extends ConsumerWidget {
  const _StepEmbedding({required this.onBack, required this.onFinish});

  final VoidCallback onBack;
  final VoidCallback onFinish;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(embeddingModelStateProvider);
    final notifier = ref.read(embeddingModelStateProvider.notifier);
    final theme = Theme.of(context);
    final tokens = context.designSystem;
    final l10n = AppLocalizations.of(context);

    final isInstalled = state.status == EmbeddingModelStatus.installed;
    final isDownloading = state.status == EmbeddingModelStatus.downloading;
    final hasError = state.status == EmbeddingModelStatus.error;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Icon(
              isInstalled
                  ? LucideIcons.circleCheck
                  : (isDownloading
                      ? LucideIcons.download
                      : LucideIcons.brain),
              size: 18,
              color: isInstalled
                  ? theme.colorScheme.primary
                  : tokens?.textTertiary,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                isInstalled
                    ? 'Embedding model installed and ready to use.'
                    : (isDownloading
                        ? 'Downloading… ${(state.progress * 100).toStringAsFixed(0)}%'
                        : 'Embedding model not installed.'),
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: tokens?.textPrimary,
                ),
              ),
            ),
          ],
        ),
        if (isDownloading) ...[
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: state.progress > 0
                ? FDeterminateProgress(value: state.progress)
                : const FProgress(),
          ),
        ],
        if (hasError && state.error != null) ...[
          const SizedBox(height: 12),
          Text(
            state.error!,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.error,
            ),
          ),
        ],
        const SizedBox(height: 20),
        Row(
          children: [
            FButton(
              onPress: onBack,
              variant: FButtonVariant.outline,
              mainAxisSize: MainAxisSize.min,
              child: Text(l10n.back),
            ),
            const Spacer(),
            if (isDownloading)
              FButton(
                onPress: notifier.cancel,
                variant: FButtonVariant.outline,
                mainAxisSize: MainAxisSize.min,
                child: Text(l10n.cancel),
              )
            else if (isInstalled)
              FButton(
                onPress: onFinish,
                mainAxisSize: MainAxisSize.min,
                child: Text(l10n.finish),
              )
            else ...[
              FButton(
                onPress: onFinish,
                variant: FButtonVariant.outline,
                mainAxisSize: MainAxisSize.min,
                child: Text(l10n.skipForNow),
              ),
              const SizedBox(width: 8),
              FButton(
                onPress: notifier.installIfNeeded,
                mainAxisSize: MainAxisSize.min,
                child: Text(l10n.download),
              ),
            ],
          ],
        ),
      ],
    );
  }
}
