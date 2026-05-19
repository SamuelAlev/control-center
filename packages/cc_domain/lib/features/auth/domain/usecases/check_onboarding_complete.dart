import 'package:cc_domain/core/domain/entities/workspace.dart';

/// Result of evaluating whether the user has completed onboarding.
class OnboardingStatus {
  /// Creates an [OnboardingStatus].
  const OnboardingStatus({
    required this.isComplete,
    required this.hasForgeConnection,
    required this.hasWorkspace,
    required this.workspaceCount,
  });

  /// Whether onboarding is fully complete.
  final bool isComplete;

  /// Whether at least one code-hosting forge is connected.
  ///
  /// Any forge counts. An operator who works only on GitLab is set up; the
  /// requirement is a place to read pull requests from, not GitHub in
  /// particular.
  final bool hasForgeConnection;

  /// Whether at least one workspace exists.
  final bool hasWorkspace;

  /// Total number of existing workspaces.
  final int workspaceCount;
}

/// Evaluates whether the user has finished onboarding.
class CheckOnboardingCompleteUseCase {
  /// Creates a const [CheckOnboardingCompleteUseCase].
  const CheckOnboardingCompleteUseCase();

  /// Evaluates onboarding completion from forge connectivity and workspaces.
  OnboardingStatus execute({
    required bool hasForgeConnection,
    required List<Workspace> workspaces,
  }) {
    final hasWorkspace = workspaces.isNotEmpty;
    return OnboardingStatus(
      isComplete: hasForgeConnection && hasWorkspace,
      hasForgeConnection: hasForgeConnection,
      hasWorkspace: hasWorkspace,
      workspaceCount: workspaces.length,
    );
  }
}
