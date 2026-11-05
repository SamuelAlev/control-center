import 'package:control_center/di/providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Persists the runner picked on onboarding's adapter step onto every seeded
/// agent still missing one, the content synthesizer included. There is no
/// workspace default runner: a conversation runs on its agents' runners.
Future<void> saveOnboardingRunnerChoice(
  WidgetRef ref, {
  required String adapterId,
  required String modelId,
}) async {
  // Back-patch every agent seeded before the adapter prefs existed
  // (onboarding step 2 creates the workspace, which seeds the CEO *and* the
  // specialists; the adapter is only picked here, in step 3). The CEO was
  // the only one patched, which left the specialists with no runner at all —
  // the workspace looked configured and most of its agents could not run.
  //
  // Only agents missing the pair are touched, and the pair is written
  // together: a model id belongs to the adapter that serves it, so filling one
  // from an unrelated selection would produce a combination nothing can
  // honour.
  try {
    final repo = ref.read(agentRepositoryProvider);
    final agents = await repo.watchAll().first;
    for (final a in agents) {
      if (a.adapterId == null || a.modelId == null) {
        await repo.upsert(a.copyWith(adapterId: adapterId, modelId: modelId));
      }
    }
  } catch (_) {
    // Non-critical — adapter can be changed in Settings.
  }
}
