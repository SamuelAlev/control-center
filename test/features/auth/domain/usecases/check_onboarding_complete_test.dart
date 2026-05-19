import 'package:control_center/core/domain/entities/workspace.dart';
import 'package:control_center/features/auth/domain/usecases/check_onboarding_complete.dart';
import 'package:flutter_test/flutter_test.dart';

Workspace _workspace(String id) {
  return Workspace(
    id: id,
    name: 'Workspace $id',
    createdAt: DateTime.now(),
    updatedAt: DateTime.now(),
  );
}

void main() {
  group('CheckOnboardingCompleteUseCase', () {
    late CheckOnboardingCompleteUseCase useCase;

    setUp(() {
      useCase = const CheckOnboardingCompleteUseCase();
    });

    test('returns complete when GitHub auth and workspace present', () {
      final status = useCase.execute(
        isGitHubAuthenticated: true,
        workspaces: [_workspace('ws-1')],
      );

      expect(status.isComplete, isTrue);
      expect(status.hasGitHubAuth, isTrue);
      expect(status.hasWorkspace, isTrue);
      expect(status.workspaceCount, 1);
    });

    test('returns incomplete when GitHub not authenticated', () {
      final status = useCase.execute(
        isGitHubAuthenticated: false,
        workspaces: [_workspace('ws-1')],
      );

      expect(status.isComplete, isFalse);
      expect(status.hasGitHubAuth, isFalse);
      expect(status.hasWorkspace, isTrue);
    });

    test('returns incomplete when no workspaces exist', () {
      final status = useCase.execute(
        isGitHubAuthenticated: true,
        workspaces: [],
      );

      expect(status.isComplete, isFalse);
      expect(status.hasGitHubAuth, isTrue);
      expect(status.hasWorkspace, isFalse);
      expect(status.workspaceCount, 0);
    });

    test('returns incomplete when both conditions fail', () {
      final status = useCase.execute(
        isGitHubAuthenticated: false,
        workspaces: [],
      );

      expect(status.isComplete, isFalse);
      expect(status.hasGitHubAuth, isFalse);
      expect(status.hasWorkspace, isFalse);
      expect(status.workspaceCount, 0);
    });

    test('counts multiple workspaces correctly', () {
      final status = useCase.execute(
        isGitHubAuthenticated: true,
        workspaces: [
          _workspace('ws-1'),
          _workspace('ws-2'),
          _workspace('ws-3'),
        ],
      );

      expect(status.workspaceCount, 3);
      expect(status.hasWorkspace, isTrue);
      expect(status.isComplete, isTrue);
    });
  });

  group('OnboardingStatus', () {
    test('constructs with all fields', () {
      const status = OnboardingStatus(
        isComplete: true,
        hasGitHubAuth: true,
        hasWorkspace: true,
        workspaceCount: 5,
      );

      expect(status.isComplete, isTrue);
      expect(status.hasGitHubAuth, isTrue);
      expect(status.hasWorkspace, isTrue);
      expect(status.workspaceCount, 5);
    });

    test('constructs with isComplete false', () {
      const status = OnboardingStatus(
        isComplete: false,
        hasGitHubAuth: false,
        hasWorkspace: false,
        workspaceCount: 0,
      );

      expect(status.isComplete, isFalse);
      expect(status.hasGitHubAuth, isFalse);
      expect(status.hasWorkspace, isFalse);
      expect(status.workspaceCount, 0);
    });

    test('can be partially complete', () {
      const status = OnboardingStatus(
        isComplete: false,
        hasGitHubAuth: true,
        hasWorkspace: false,
        workspaceCount: 0,
      );

      expect(status.isComplete, isFalse);
      expect(status.hasGitHubAuth, isTrue);
      expect(status.hasWorkspace, isFalse);
    });
  });

  group('CheckOnboardingCompleteUseCase edge cases', () {
    test('const constructor works', () {
      const useCase = CheckOnboardingCompleteUseCase();
      expect(useCase, isA<CheckOnboardingCompleteUseCase>());
    });

    test('isComplete is true only when both conditions met', () {
      const useCase = CheckOnboardingCompleteUseCase();

      final complete = useCase.execute(
        isGitHubAuthenticated: true,
        workspaces: [_workspace('ws-1')],
      );
      expect(complete.isComplete, isTrue);

      final noAuth = useCase.execute(
        isGitHubAuthenticated: false,
        workspaces: [_workspace('ws-1')],
      );
      expect(noAuth.isComplete, isFalse);

      final noWs = useCase.execute(
        isGitHubAuthenticated: true,
        workspaces: [],
      );
      expect(noWs.isComplete, isFalse);

      final neither = useCase.execute(
        isGitHubAuthenticated: false,
        workspaces: [],
      );
      expect(neither.isComplete, isFalse);
    });
  });
}
