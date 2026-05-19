import 'package:control_center/features/workspaces/providers/workspace_providers.dart';
// `Override` lives in riverpod's `misc.dart`, not its main library, so a helper
// that returns one (rather than inlining it into a `ProviderScope.overrides`
// literal, where the element type is inferred) has to name it from there.
import 'package:riverpod/misc.dart' show Override;

/// The workspace id every widget/provider test runs inside unless it names its
/// own.
///
/// A workspace id selects the server-side database file, so `requireWorkspaceId`
/// throws off a `/workspaces/:workspaceId` route. Tests pump widgets with no
/// router, so they must seed the id explicitly.
const kTestWorkspaceId = 'ws-test';

/// Seeds [activeWorkspaceIdProvider] with a fixed id, bypassing the router and
/// `shared_preferences` reconciliation the real notifier performs in `build`.
class TestActiveWorkspaceId extends ActiveWorkspaceIdNotifier {
  /// Pins the active workspace to [id]; `null` reproduces a pre-context surface
  /// (splash, onboarding, the picker) where no workspace is selected.
  TestActiveWorkspaceId(this.id);

  /// The id handed to every reader for the lifetime of the test.
  final String? id;

  @override
  String? build() => id;

  @override
  Future<void> setActive(String next) async => state = next;
}

/// Override pinning the active workspace to [id] for a test's `ProviderScope`.
///
/// Prefer this over overriding `activeWorkspaceProvider`: the *id* is what
/// workspace-scoped repository calls thread, and the row is derived from it.
Override activeWorkspaceIdOverride([String? id = kTestWorkspaceId]) =>
    activeWorkspaceIdProvider.overrideWith(() => TestActiveWorkspaceId(id));
