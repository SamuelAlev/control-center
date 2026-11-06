import 'package:cc_data/cc_data.dart' show RigView;
import 'package:cc_domain/features/rigs/domain/value_objects/rig_browser_engine.dart';
import 'package:cc_ui/cc_ui.dart';
import 'package:control_center/features/environments/presentation/widgets/environment_feedback.dart';
import 'package:control_center/features/environments/presentation/widgets/environment_host.dart';
import 'package:control_center/features/environments/providers/environment_providers.dart';
import 'package:control_center/features/rigs/presentation/rig_tab_surfaces.dart';
import 'package:control_center/features/rigs/providers/rig_providers.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// How long a Browser (VM) gets to boot before the navigation is abandoned.
const Duration _bootBudget = Duration(minutes: 3);

/// Shows [url] in the space's Browser (VM): the path that works from any
/// client, because the VM reaches the server's names and a remote client can't.
///
/// The press is the intent, so this boots the machine when there is none. Rigs
/// have no open-at-URL op, so it opens the tab, waits for the machine and then
/// navigates it.
Future<void> openEndpointInBrowserVm(
  BuildContext context,
  WidgetRef ref, {
  required EnvironmentSpaceKey spaceKey,
  required String url,
  required EnvironmentHost host,
}) async {
  final toasts = CcToastScope.maybeOf(context);
  final repository = ref.read(rigRepositoryProvider);
  final workspaceId = spaceKey.workspaceId;
  host.openBrowserVm(spaceId: spaceKey.spaceId);
  try {
    var rig = await repository.open(
      workspaceId: workspaceId,
      surface: RigTabSurfaces.browser,
      conversationId: spaceKey.spaceId,
      engine: RigBrowserEngine.chromium.wire,
    );
    if (!rig.isLive) {
      final id = rig.id;
      rig = await repository
          .watch(workspaceId)
          .expand<RigView>((rigs) => rigs)
          .firstWhere((row) => row.id == id && (row.isLive || row.isTerminal))
          .timeout(_bootBudget);
    }
    if (!rig.isHumanControlled) {
      rig = await repository.takeControl(workspaceId, rig.id);
    }
    final result = await repository.act(
      workspaceId: workspaceId,
      rigId: rig.id,
      action: {'action': 'navigate', 'url': url},
    );
    if (result.isError) {
      toasts?.show(result.text, variant: CcToastVariant.danger);
    }
  } on Object catch (error) {
    toasts?.show(
      environmentFailureMessage(error),
      variant: CcToastVariant.danger,
    );
  }
}
