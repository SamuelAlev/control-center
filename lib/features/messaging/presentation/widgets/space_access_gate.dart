import 'package:cc_ui/cc_ui.dart';
import 'package:control_center/features/forge/presentation/widgets/repo_code_failure_view.dart';
import 'package:control_center/features/messaging/presentation/space_access_refusal.dart';
import 'package:control_center/features/messaging/providers/space_access_provider.dart';
import 'package:control_center/l10n/app_localizations.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Shows [child] (the space) only once the person may open [spaceId], and
/// otherwise says why, in place of the whole space.
///
/// A space id can arrive from anywhere (the URL, a notification tap, the
/// last space opened, a restored layout) and still name a space the server
/// now leaves out of the person's list: it is readable only with a read
/// grant and forge read on every repository it uses. Such a space is asked
/// once; a refusal shows its reason (with the sign-in that fixes it) instead
/// of a spinner that never ends, and nothing inside the space subscribes.
class SpaceAccessGate extends ConsumerWidget {
  /// Creates the gate for [spaceId] in [workspaceId].
  const SpaceAccessGate({
    super.key,
    required this.workspaceId,
    required this.spaceId,
    required this.child,
  });

  /// The workspace the space belongs to.
  final String workspaceId;

  /// The space the route names.
  final String spaceId;

  /// The space itself.
  final Widget child;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final key = (workspaceId: workspaceId, spaceId: spaceId);
    // Listed (or the list not in yet): the space opens as it always did.
    if (ref.watch(spaceListedProvider(key)) ?? true) {
      return child;
    }
    final probe = ref.watch(spaceAccessRefusalProvider(key));
    final refusal = probe.value;
    if (probe.isLoading && refusal == null) {
      return const Center(child: CcSpinner());
    }
    if (refusal == null) {
      return child;
    }
    return RepoCodeFailureView(
      error: refusal,
      fallback: AppLocalizations.of(context).spaceAccessFailed,
      workspaceId: workspaceId,
      describe: spaceAccessFailureOf,
      onRetry: () => ref.invalidate(spaceAccessRefusalProvider(key)),
    );
  }
}
