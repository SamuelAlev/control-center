import 'package:control_center/features/auth/presentation/screens/onboarding_chrome.dart';
import 'package:control_center/l10n/app_localizations.dart';

/// One first-run step. The flow is a LIST of these rather than a fixed count,
/// because several steps do not apply to everyone: an invited member already
/// has a workspace, and only the server owner chooses the sign-in apps.
enum OnboardingStepId {
  /// Choose a username and display name (anyone who has not finished
  /// onboarding).
  you,

  /// Choose whose provider apps sign people in (server owner only).
  signIn,

  /// Connect a code-hosting forge (and optionally a ticketing vendor).
  connect,

  /// Name the first workspace.
  workspace,

  /// Turn on sandboxed agent execution.
  sandbox,

  /// Pick the default adapter + model.
  adapter,

  /// Install the on-device speech model for dictation.
  voice;

  /// The progress-bar label. Every step is named, not just the current one:
  /// the bar has to read as a map of the whole flow.
  String label(AppLocalizations l10n) => switch (this) {
    you => l10n.onboardingStepYou,
    signIn => l10n.onboardingStepSignIn,
    connect => l10n.onboardingStepConnect,
    workspace => l10n.onboardingStepWorkspace,
    sandbox => l10n.onboardingStepSandbox,
    adapter => l10n.onboardingStepAdapter,
    voice => l10n.onboardingStepVoice,
  };

  /// The step's heading and lead.
  OnboardingStepCopy copy(AppLocalizations l10n) => switch (this) {
    you => OnboardingStepCopy(
      title: l10n.onboardingYouTitle,
      subtitle: l10n.onboardingYouSubtitle,
    ),
    signIn => OnboardingStepCopy(
      title: l10n.onboardingConnectTitle,
      subtitle: l10n.onboardingConnectSubtitle,
    ),
    connect => OnboardingStepCopy(
      title: l10n.letsPluginTools,
      subtitle: l10n.connectGitHubAndTicketing,
    ),
    workspace => OnboardingStepCopy(
      title: l10n.giveYourWorkAHome,
      subtitle:
          'Name your first workspace — a project, team, or initiative. '
          'You can add a logo now or link repositories later from '
          'Settings → Repositories.',
    ),
    sandbox => OnboardingStepCopy(
      title: l10n.isolateAgentExecution,
      subtitle:
          'Agents will run inside disposable containers so they can\'t '
          'touch the rest of your machine. You can fine-tune token '
          'access per conversation later — or skip this for now and '
          're-enable it from Settings → Security.',
    ),
    adapter => OnboardingStepCopy(
      title: l10n.chooseRunner,
      subtitle:
          'Select the default adapter and model for agent conversations. '
          'You can change this later in Settings → Adapters.',
    ),
    voice => OnboardingStepCopy(
      title: l10n.talkToControlCenter,
      subtitle:
          'Pick a speech model and install it to dictate messages '
          'straight into the composer. Parakeet TDT v3 is the '
          'recommended default — fast and multilingual. Runs fully '
          'on-device — or skip and turn it on later in Settings.',
    ),
  };
}
