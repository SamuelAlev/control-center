import 'dart:async';

import 'package:cc_domain/features/settings/domain/entities/adapter.dart';
import 'package:cc_ui/cc_ui.dart';
import 'package:control_center/di/providers.dart';
import 'package:control_center/features/auth/presentation/screens/onboarding_chrome.dart';
import 'package:control_center/features/auth/presentation/screens/onboarding_model_steps.dart';
import 'package:control_center/features/auth/presentation/widgets/api_keys_panel.dart';
import 'package:control_center/features/auth/presentation/widgets/onboarding_step_layout.dart';
import 'package:control_center/features/auth/providers/onboarding_providers.dart';
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
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

/// One first-run step. The flow is a LIST of these rather than a fixed count,
/// because the workspace step does not apply to everyone — an invited member
/// already has one.
enum _StepId {
  /// Connect a code-hosting forge (and optionally a ticketing vendor).
  connect,

  /// Name the first workspace.
  workspace,

  /// Turn on sandboxed agent execution.
  sandbox,

  /// Pick the default adapter + model.
  adapter,

  /// Install the on-device speech model for dictation.
  voice,
}

/// First-run onboarding: configure API access, add a workspace, set up agent
/// sandboxing, choose a default adapter + model, then optionally fetch the
/// local voice transcription model. The embedding and diarization models have
/// no step — the server force-installs both at boot.
///
/// The workspace step is skipped for someone who already belongs to one, which
/// is how an INVITED member arrives: they were added to somebody else's
/// workspace, so asking them to name their first one both misdescribes what
/// happened and leaves them with a stray second workspace. Everything else —
/// signing in, sandboxing, the model, dictation — is per-person setup they
/// still need.
class OnboardingScreen extends ConsumerStatefulWidget {
  /// Creates the [OnboardingScreen].
  const OnboardingScreen({super.key});

  /// Creates the mutable state for this widget.
  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen> {
  /// The steps this particular operator will walk, fixed for the whole flow.
  late final List<_StepId> _steps = _planSteps();

  int _step = 0;

  /// Chooses the steps ONCE, at flow start.
  ///
  /// Snapshotting is the whole discipline here. An earlier version derived
  /// skips from async auth probes on every build, which made the flow depend on
  /// frame timing — a step could vanish underneath the person walking it. The
  /// gate only routes here after the workspace list has settled, so a single
  /// read is both correct and stable.
  ///
  /// Only the workspace step is conditional. The connect step is always shown
  /// even when a forge is already connected (it simply renders the connected
  /// state): it is the one thing the gate requires, so it stays visible rather
  /// than silently absent.
  List<_StepId> _planSteps() {
    final hasWorkspace =
        ref.read(workspacesProvider).value?.isNotEmpty ?? false;
    return [
      _StepId.connect,
      if (!hasWorkspace) _StepId.workspace,
      _StepId.sandbox,
      _StepId.adapter,
      _StepId.voice,
    ];
  }

  void _goTo(int step) => setState(() => _step = step);

  /// The progress-bar labels, one per step. Every step is named, not just the
  /// current one — the bar has to read as a map of the whole flow.
  List<String> _stepLabels(AppLocalizations l10n) => [
    for (final step in _steps)
      switch (step) {
        _StepId.connect => l10n.onboardingStepConnect,
        _StepId.workspace => l10n.onboardingStepWorkspace,
        _StepId.sandbox => l10n.onboardingStepSandbox,
        _StepId.adapter => l10n.onboardingStepAdapter,
        _StepId.voice => l10n.onboardingStepVoice,
      },
  ];

  OnboardingStepCopy _copyFor(_StepId step, AppLocalizations l10n) {
    switch (step) {
      case _StepId.connect:
        return OnboardingStepCopy(
          title: l10n.letsPluginTools,
          subtitle: l10n.connectGitHubAndTicketing,
        );
      case _StepId.workspace:
        return OnboardingStepCopy(
          title: l10n.giveYourWorkAHome,
          subtitle:
              'Name your first workspace — a project, team, or initiative. '
              'You can add a logo now or link repositories later from '
              'Settings → Repositories.',
        );
      case _StepId.sandbox:
        return OnboardingStepCopy(
          title: l10n.isolateAgentExecution,
          subtitle:
              'Agents will run inside disposable containers so they can\'t '
              'touch the rest of your machine. You can fine-tune token '
              'access per conversation later — or skip this for now and '
              're-enable it from Settings → Security.',
        );
      case _StepId.adapter:
        return OnboardingStepCopy(
          title: l10n.chooseRunner,
          subtitle:
              'Select the default adapter and model for agent conversations. '
              'You can change this later in Settings → Adapters.',
        );
      case _StepId.voice:
        return OnboardingStepCopy(
          title: l10n.talkToControlCenter,
          subtitle:
              'Pick a speech model and install it to dictate messages '
              'straight into the composer. Parakeet TDT v3 is the '
              'recommended default — fast and multilingual. Runs fully '
              'on-device — or skip and turn it on later in Settings.',
        );
    }
  }

  Future<void> _finishOnboarding() async {
    // Recorded before navigating, and for everyone who reaches the end —
    // including an invited member who never created a workspace. It is what
    // tells a later credential lapse to ask for a sign-in instead of running
    // this flow again.
    await markOnboardingFinishedFromWidget(ref);
    if (!mounted) {
      return;
    }
    // The workspace created during onboarding is the active one; an invited
    // member's resolves to the workspace they were added to. The picker is a
    // safety net if none resolved.
    final wsId = ref.read(activeWorkspaceIdProvider);
    context.go(wsId == null ? workspaceListRoute : inboxRoute(wsId));
  }

  Widget _bodyFor(int index) {
    // Every step moves by ±1 through `_steps` rather than to a hardcoded
    // index, so a skipped step cannot strand its neighbours.
    final isLast = index == _steps.length - 1;
    void back() => _goTo(index - 1);
    void next() => isLast ? unawaited(_finishOnboarding()) : _goTo(index + 1);

    switch (_steps[index]) {
      case _StepId.connect:
        return _StepOne(
          isAuthed: ref.watch(hasAnyForgeConnectedProvider),
          onContinue: next,
        );
      case _StepId.workspace:
        return _StepTwo(onBack: index == 0 ? null : back, onContinue: next);
      case _StepId.sandbox:
        return OnboardingStepSandbox(onBack: back, onContinue: next);
      case _StepId.adapter:
        return _StepAdapter(onBack: back, onContinue: next);
      case _StepId.voice:
        return OnboardingVoiceStep(
          onBack: back,
          onFinish: () => unawaited(_finishOnboarding()),
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final copy = _copyFor(_steps[_step], l10n);

    // Pinned chrome, scrolling content: the step indicator, each step's
    // title/subtitle and its action row never move — only the fields between
    // them scroll — so the scrollbar hugs the card instead of spanning the
    // full window.
    return OnboardingScaffold(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          OnboardingStepIndicator(
            currentStep: _step,
            total: _steps.length,
            labels: _stepLabels(l10n),
          ),
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
                  child: SlideTransition(position: offset, child: child),
                );
              },
              child: KeyedSubtree(
                key: ValueKey<int>(_step),
                child: OnboardingStepHero(copy: copy, body: _bodyFor(_step)),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _StepOne extends StatelessWidget {
  const _StepOne({required this.isAuthed, required this.onContinue});

  final bool isAuthed;
  final VoidCallback onContinue;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return OnboardingStepLayout(
      content: const ApiKeysPanel(),
      footer: Align(
        alignment: Alignment.centerRight,
        child: CcButton(
          onPressed: isAuthed ? onContinue : null,
          child: Text(l10n.continueLabel),
        ),
      ),
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
      // The form owns its submit state, so it keeps building its own actions —
      // onboarding only re-composes where they sit: pinned under the scroll.
      layout: (fields, actions) =>
          OnboardingStepLayout(content: fields, footer: actions),
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
          if (anyChecking) ...[
            const Center(child: CcSpinner()),
            const SizedBox(height: 8),
            Center(
              child: Text(
                'Checking for installed runners...',
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
                    // Back-patch every agent seeded before the adapter prefs
                    // existed (onboarding step 2 creates the workspace, which
                    // seeds the CEO *and* the four specialists; the adapter is
                    // only picked here, in step 3). The CEO was the only one
                    // patched, which left the specialists with no runner at
                    // all — the workspace looked configured and four of its
                    // five agents could not run.
                    //
                    // Only agents missing the pair are touched, and the pair is
                    // written together: a model id belongs to the adapter that
                    // serves it, so filling one from an unrelated selection
                    // would produce a combination nothing can honour.
                    try {
                      final repo = ref.read(agentRepositoryProvider);
                      final agents = await repo.watchAll().first;
                      for (final a in agents) {
                        if (a.adapterId == null || a.modelId == null) {
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
