import 'package:control_center/di/providers.dart';
import 'package:control_center/features/settings/providers/adapter_preferences_providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Persists the runner picked on onboarding's adapter step: the default chat
/// pair, the workspace's short-task pair, and every seeded agent still missing
/// one.
Future<void> saveOnboardingRunnerChoice(
  WidgetRef ref, {
  required String adapterId,
  required String modelId,
}) async {
  await ref.read(defaultChatAdapterProvider.notifier).set(adapterId);
  await ref.read(defaultChatModelProvider.notifier).set(modelId);
  // The short-task runner is workspace state (titles every member reads),
  // written through the admin-gated lane. An invited member is refused there;
  // that must not block finishing onboarding.
  try {
    await ref.read(shortTaskAdapterProvider.notifier).set(adapterId);
    await ref.read(shortTaskModelProvider.notifier).set(modelId);
  } catch (_) {
    // Non-critical — the workspace admin picks it in Settings → Adapters.
  }
  // Back-patch every agent seeded before the adapter prefs existed
  // (onboarding step 2 creates the workspace, which seeds the CEO *and* the
  // four specialists; the adapter is only picked here, in step 3). The CEO was
  // the only one patched, which left the specialists with no runner at all —
  // the workspace looked configured and four of its five agents could not run.
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
