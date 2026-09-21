import 'package:control_center/features/auth/presentation/screens/onboarding_chrome.dart';
import 'package:control_center/features/auth/presentation/widgets/onboarding_step_layout.dart';
import 'package:control_center/features/forge/presentation/widgets/forge_connections_card.dart';
import 'package:control_center/l10n/app_localizations.dart';
import 'package:flutter/widgets.dart';

/// Shown when an operator who HAS completed onboarding no longer has a working forge
/// credential — a token expired, was revoked, or the app's authorization was withdrawn.
/// This exists because the alternative was routing them back through five-step first-run
/// onboarding, which asks for a workspace they already have and a sandbox and model they
/// already chose.
/// It borrows onboarding's chrome on purpose — the moment is adjacent, and a
/// differently-styled full-screen gate would read as a different application.
class SignedOutScreen extends StatelessWidget {
  /// Creates the [SignedOutScreen].
  const SignedOutScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return OnboardingScaffold(
      child: OnboardingStepHero(
        copy: OnboardingStepCopy(
          title: l10n.signedOutTitle,
          subtitle: l10n.signedOutSubtitle,
        ),
        // The same card Settings → Integrations and onboarding render, so the
        // sign-in offered here cannot drift from the one offered anywhere else
        // — and an operator whose server cannot run a browser sign-in still
        // gets the paste-a-token path without a second implementation.
        body: const OnboardingStepLayout(content: ForgeConnectionsCard()),
      ),
    );
  }
}
