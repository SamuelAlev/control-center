import 'package:cc_domain/features/rigs/domain/value_objects/rig_browser_engine.dart';
import 'package:cc_domain/features/rigs/domain/value_objects/rig_surface.dart';
import 'package:control_center/features/environments/presentation/widgets/environment_host.dart';
import 'package:control_center/features/pr_review/presentation/screens/pull_request_detail/pr_tab_kinds.dart';
import 'package:control_center/features/rigs/presentation/rig_tab_surfaces.dart';
import 'package:control_center/l10n/app_localizations.dart';
import 'package:control_center/shared/editor/editor_layout_controller.dart';
import 'package:control_center/shared/editor/editor_tab.dart';
import 'package:control_center/shared/editor/host/editor_tab_url_sync.dart';
import 'package:control_center/shared/icons/app_icons.dart';
import 'package:flutter/widgets.dart';

/// What the environment section can open on a PR page.
///
/// [layout] and [state] are read at call time, so the host can be built once
/// and keep its identity across rebuilds.
EnvironmentHost prEnvironmentHost({
  required String workspaceId,
  required EditorLayoutController Function() layout,
  required State state,
}) {
  AppLocalizations l10n() => AppLocalizations.of(state.context);

  void openOrFocus(EditorTab tab) {
    final key = tab.dedupKey;
    if (key == null || !layout().focusTab((t) => t.dedupKey == key)) {
      layout().openInActiveLeaf(tab);
    }
  }

  EditorTab rigTab(RigTabTarget target, String label, IconData icon) =>
      EditorTab(
        kind: PrTabKinds.rig,
        label: label,
        icon: icon,
        args: target.args,
        dedupKey: '${PrTabKinds.rig}:${target.dedupKey}',
      );

  void openTerminal(String sessionId, String label, {bool setup = false}) =>
      openOrFocus(
        EditorTab(
          kind: PrTabKinds.terminal,
          label: label,
          icon: PrTabKinds.iconFor(PrTabKinds.terminal),
          args: {
            'attachSessionId': sessionId,
            if (setup) kEnvironmentSetupTabArg: true,
          },
          dedupKey: '${PrTabKinds.terminal}:environment-$sessionId',
        ),
      );

  return EnvironmentHost(
    openUrl: ({required url, required label}) => openOrFocus(
      EditorTab(
        kind: PrTabKinds.browser,
        label: label,
        icon: PrTabKinds.iconFor(PrTabKinds.browser),
        args: {'url': url},
        dedupKey: '${PrTabKinds.browser}:$url',
      ),
    ),
    openBrowserVm: ({required spaceId}) {
      const target = RigTabTarget(
        RigTabSurfaces.browser,
        engine: RigBrowserEngine.chromium,
      );
      openOrFocus(
        rigTab(
          target,
          RigTabSurfaces.labelFor(
            l10n(),
            target.surface,
            engine: target.engine,
          ),
          RigTabSurfaces.iconFor(target.surface),
        ),
      );
    },
    openLogs: ({required spaceId, required target, required label}) =>
        openOrFocus(
          EditorTab(
            kind: PrTabKinds.environmentLogs,
            label: l10n().environmentLogsTab(label),
            icon: PrTabKinds.iconFor(PrTabKinds.environmentLogs),
            args: {
              'workspaceId': workspaceId,
              'spaceId': spaceId,
              'target': target,
            },
            dedupKey: '${PrTabKinds.environmentLogs}:$spaceId:$target',
          ),
        ),
    openProvisioningLogs: ({required spaceId}) => openOrFocus(
      EditorTab(
        kind: PrTabKinds.provisioningLogs,
        label: l10n().spaceSetupLogs,
        icon: PrTabKinds.iconFor(PrTabKinds.provisioningLogs),
        args: {'workspaceId': workspaceId, 'spaceId': spaceId},
        dedupKey: '${PrTabKinds.provisioningLogs}:$spaceId',
      ),
    ),
    openProcess: ({required spaceId, required sessionId, required label}) =>
        openTerminal(sessionId, label),
    openSetup: ({required spaceId, required sessionId, required label}) =>
        openTerminal(sessionId, label, setup: true),
    openViewer: ({required spaceId, required componentId, required label}) =>
        openOrFocus(
          rigTab(
            RigTabTarget(RigSurface.window.wire, slotId: componentId),
            label,
            AppIcons.appWindow,
          ),
        ),
    openPrefilledTerminal: ({required spaceId, required command}) =>
        layout().openInActiveLeaf(
          EditorTab(
            kind: PrTabKinds.terminal,
            label: l10n().terminal,
            icon: PrTabKinds.iconFor(PrTabKinds.terminal),
            args: {'initialInput': command},
            dedupKey: instanceTabKey(PrTabKinds.terminal),
          ),
        ),
    // A PR page has the one space, so being up is being on it.
    showsSpace: (spaceId) => state.mounted,
  );
}
