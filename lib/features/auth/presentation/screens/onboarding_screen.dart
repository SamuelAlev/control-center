import 'dart:async';

import 'package:cc_domain/features/telemetry/telemetry.dart';
import 'package:control_center/core/providers/analytics_providers.dart';
import 'package:control_center/features/auth/presentation/screens/onboarding_chrome.dart';
import 'package:control_center/features/auth/presentation/screens/onboarding_model_steps.dart';
import 'package:control_center/features/auth/presentation/widgets/onboarding_adapter_step.dart';
import 'package:control_center/features/auth/presentation/widgets/onboarding_connection_steps.dart';
import 'package:control_center/features/auth/presentation/widgets/onboarding_flow_view.dart';
import 'package:control_center/features/auth/providers/onboarding_providers.dart';
import 'package:control_center/features/forge/providers/forge_providers.dart';
import 'package:control_center/features/identity/providers/identity_providers.dart';
import 'package:control_center/features/sandboxing/presentation/onboarding_step_sandbox.dart';
import 'package:control_center/features/workspaces/providers/workspace_providers.dart';
import 'package:control_center/l10n/app_localizations.dart';
import 'package:control_center/router/routes.dart';
import 'package:flutter/widgets.dart';
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

  /// When the flow opened, for `onboarding_completed.duration_s`.
  final _startedAt = DateTime.now();

  @override
  void initState() {
    super.initState();
    _trackStep();
  }

  void _trackStep() => ref.track(
    AnalyticsEvents.onboardingStepViewed(
      step: _steps[_step].name,
      stepIndex: _step,
    ),
  );

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

  void _goTo(int step) {
    setState(() => _step = step);
    _trackStep();
  }

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
    ref.track(
      AnalyticsEvents.onboardingCompleted(
        durationS: DateTime.now().difference(_startedAt).inSeconds,
        stepCount: _steps.length,
        workspaceId: wsId,
      ),
    );
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
        return OnboardingConnectStep(
          isAuthed: ref.watch(hasAnyForgeConnectedProvider),
          onContinue: next,
        );
      case _StepId.workspace:
        return OnboardingWorkspaceStep(
          onBack: index == 0 ? null : back,
          onContinue: next,
        );
      case _StepId.sandbox:
        return OnboardingStepSandbox(onBack: back, onContinue: next);
      case _StepId.adapter:
        return OnboardingAdapterStep(onBack: back, onContinue: next);
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

    return OnboardingFlowView(
      copy: copy,
      body: _bodyFor(_step),
      labels: _stepLabels(l10n),
      currentStep: _step,
      canManageModels: ref.watch(isServerOwnerProvider),
      hideVoiceActivity: _steps[_step] == _StepId.voice,
    );
  }
}
