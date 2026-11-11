import 'dart:async';

import 'package:cc_domain/features/telemetry/telemetry.dart';
import 'package:control_center/core/providers/analytics_providers.dart';
import 'package:control_center/features/auth/presentation/screens/onboarding_model_steps.dart';
import 'package:control_center/features/auth/presentation/screens/onboarding_steps.dart';
import 'package:control_center/features/auth/presentation/widgets/onboarding_adapter_step.dart';
import 'package:control_center/features/auth/presentation/widgets/onboarding_connect_step.dart';
import 'package:control_center/features/auth/presentation/widgets/onboarding_connection_steps.dart';
import 'package:control_center/features/auth/presentation/widgets/onboarding_flow_view.dart';
import 'package:control_center/features/auth/presentation/widgets/onboarding_you_step.dart';
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

/// First-run onboarding: confirm a username, (for the server owner) choose
/// whose provider apps sign people in, connect a forge, add a workspace, set
/// up agent sandboxing, choose a default adapter + model, then optionally
/// fetch the local voice transcription model. The embedding and diarization
/// models have no step: the server force-installs both at boot.
///
/// Every account walks it once, but only through the steps it is missing. An
/// INVITED member of a ready workspace sees just "You": they were added to
/// somebody else's workspace, so asking them to name one, or to set up the
/// sandbox and runner its agents already have, misdescribes what happened and
/// leaves them with a stray second workspace.
class OnboardingScreen extends ConsumerStatefulWidget {
  /// Creates the [OnboardingScreen].
  const OnboardingScreen({super.key});

  /// Creates the mutable state for this widget.
  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen> {
  /// The steps this particular operator will walk, fixed for the whole flow.
  late final List<OnboardingStepId> _steps = _planSteps();

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

  /// Chooses the steps ONCE, at flow start: only the ones this person is
  /// missing.
  ///
  /// Snapshotting is the whole discipline here. An earlier version derived
  /// skips from async auth probes on every build, which made the flow depend on
  /// frame timing: a step could vanish underneath the person walking it. The
  /// gate only routes here after the finished flag, the forge connections and
  /// the workspace list have settled, so a single read is both correct and
  /// stable. An input that has still not settled counts as missing: the step
  /// then shows, which costs one Continue.
  ///
  /// * "You" comes first for anyone who has not finished onboarding: the
  ///   server derived a username for them (an OS account, an invite hint, an
  ///   IdP claim) and this is where they confirm or change it.
  /// * Without a connected forge, the server owner first decides whose apps
  ///   every forge sign-in uses, then the connect step signs in.
  /// * Without a workspace, the workspace step creates one, and the sandbox,
  ///   runner and voice steps set up what its agents run with. Someone who may
  ///   not create workspaces gets none of these: they wait for an invite on
  ///   the workspace picker instead.
  List<OnboardingStepId> _planSteps() {
    final needsWorkspace =
        !(ref.read(workspacesProvider).value?.isNotEmpty ?? false) &&
        ref.read(canCreateWorkspacesProvider);
    final hasForge =
        ref.read(forgeConnectionsProvider).hasValue &&
        ref.read(hasAnyForgeConnectedProvider);
    final steps = [
      if (ref.read(onboardingFinishedProvider) != true) OnboardingStepId.you,
      if (!hasForge && ref.read(isServerOwnerProvider)) OnboardingStepId.signIn,
      if (!hasForge) OnboardingStepId.connect,
      if (needsWorkspace) ...[
        OnboardingStepId.workspace,
        OnboardingStepId.sandbox,
        OnboardingStepId.adapter,
        OnboardingStepId.voice,
      ],
    ];
    // Reached with nothing missing (the route opened directly): "You" is the
    // one step that is always safe to walk again.
    return steps.isEmpty ? const [OnboardingStepId.you] : steps;
  }

  void _goTo(int step) {
    setState(() => _step = step);
    _trackStep();
  }

  Future<void> _finishOnboarding() async {
    // Recorded before navigating, and for everyone who reaches the end,
    // including an invited member who never created a workspace. It is the
    // only write of the flag, and what lets the gate open.
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
      case OnboardingStepId.you:
        return OnboardingYouStep(onContinue: next);
      case OnboardingStepId.signIn:
        return OnboardingConnectStep(onContinue: next);
      case OnboardingStepId.connect:
        return OnboardingForgeStep(
          isAuthed: ref.watch(hasAnyForgeConnectedProvider),
          onContinue: next,
        );
      case OnboardingStepId.workspace:
        return OnboardingWorkspaceStep(
          onBack: index == 0 ? null : back,
          onContinue: next,
        );
      case OnboardingStepId.sandbox:
        return OnboardingStepSandbox(onBack: back, onContinue: next);
      case OnboardingStepId.adapter:
        return OnboardingAdapterStep(onBack: back, onContinue: next);
      case OnboardingStepId.voice:
        return OnboardingVoiceStep(
          onBack: back,
          onFinish: () => unawaited(_finishOnboarding()),
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final copy = _steps[_step].copy(l10n);

    return OnboardingFlowView(
      copy: copy,
      body: _bodyFor(_step),
      labels: [for (final step in _steps) step.label(l10n)],
      currentStep: _step,
      canManageModels: ref.watch(isServerOwnerProvider),
      hideVoiceActivity: _steps[_step] == OnboardingStepId.voice,
    );
  }
}
