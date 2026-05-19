import 'package:cc_domain/core/domain/entities/workspace.dart';

/// Result of evaluating whether the user has completed onboarding.
class OnboardingStatus {
  /// Creates an [OnboardingStatus].
  const OnboardingStatus({
    required this.isComplete,
    required this.hasGitHubAuth,
    required this.hasWorkspace,
    required this.workspaceCount,
  });

  /// Whether onboarding is fully complete.
  final bool isComplete;

  /// Whether GitHub authentication is configured.
  final bool hasGitHubAuth;

  /// Whether at least one workspace exists.
  final bool hasWorkspace;

  /// Total number of existing workspaces.
  final int workspaceCount;
}

/// Evaluates whether the user has finished onboarding.
class CheckOnboardingCompleteUseCase {
  /// Creates a const [CheckOnboardingCompleteUseCase].
  const CheckOnboardingCompleteUseCase();

  /// Evaluates onboarding completion from auth state and workspaces.
  OnboardingStatus execute({
    required bool isGitHubAuthenticated,
    required List<Workspace> workspaces,
  }) {
    final hasWorkspace = workspaces.isNotEmpty;
    return OnboardingStatus(
      isComplete: isGitHubAuthenticated && hasWorkspace,
      hasGitHubAuth: isGitHubAuthenticated,
      hasWorkspace: hasWorkspace,
      workspaceCount: workspaces.length,
    );
  }
}

