import 'package:cc_domain/cc_domain.dart';
import 'package:cc_remote/app_icons.dart';
import 'package:cc_remote/providers.dart';
import 'package:cc_ui/cc_ui.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

/// The header control that shows the ACTIVE workspace (resolved reactively from
/// the persisted id + the live workspace list) and, on tap, opens the full-screen
/// [WorkspaceSwitcherScreen].
///
/// Because the session auto-selects + persists a workspace (falling back to the
/// first), this shows the workspace NAME as soon as one resolves — never a stale
/// "Choose workspace" while a workspace is in fact active.
class WorkspaceSwitcherButton extends ConsumerWidget {
  /// Creates a [WorkspaceSwitcherButton].
  const WorkspaceSwitcherButton({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = context.designSystem ?? DesignSystemTokens.light();
    final activeId = ref.watch(activeWorkspaceIdProvider).value;
    final workspaces = ref.watch(workspacesProvider).value ?? const [];
    final name = _resolveName(activeId, workspaces);

    return CcTappable(
      onPressed: () => context.push('/workspaces'),
      borderRadius: const BorderRadius.all(Radius.circular(8)),
      builder: (context, states) {
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(AppIcons.layers, size: 16, color: t.fgSecondary),
              const SizedBox(width: 6),
              Text(
                name ?? 'Choose workspace',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: name == null ? t.fgTertiary : t.textPrimary,
                ),
              ),
              const SizedBox(width: 4),
              Icon(AppIcons.chevronDown, size: 14, color: t.fgTertiary),
            ],
          ),
        );
      },
    );
  }

  String? _resolveName(String? activeId, List<WorkspaceDto> workspaces) {
    if (activeId == null) {
      return workspaces.isEmpty ? null : 'Choose workspace';
    }
    for (final w in workspaces) {
      if (w.id == activeId) {
        return w.name;
      }
    }
    return null;
  }
}

/// Full-screen workspace picker: lists the live workspaces and points the
/// session's active workspace at the chosen one (persisted; the stateless server
/// has no binding to set).
class WorkspaceSwitcherScreen extends ConsumerWidget {
  /// Creates a [WorkspaceSwitcherScreen].
  const WorkspaceSwitcherScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = context.designSystem ?? DesignSystemTokens.light();
    final activeId = ref.watch(activeWorkspaceIdProvider).value;
    final async = ref.watch(workspacesProvider);

    return SafeArea(
      child: ColoredBox(
        color: t.canvas,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _header(context, t),
            Expanded(child: _body(context, ref, t, async, activeId)),
          ],
        ),
      ),
    );
  }

  Widget _header(BuildContext context, DesignSystemTokens t) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 8, 16, 8),
      child: Row(
        children: [
          CcTappable(
            onPressed: () => context.pop(),
            semanticLabel: 'Back',
            builder: (context, _) => Padding(
              padding: const EdgeInsets.all(8),
              child: Icon(AppIcons.arrowLeft, color: t.fgSecondary),
            ),
          ),
          const SizedBox(width: 8),
          Text(
            'Workspaces',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: t.textPrimary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _body(
    BuildContext context,
    WidgetRef ref,
    DesignSystemTokens t,
    AsyncValue<List<WorkspaceDto>> async,
    String? activeId,
  ) {
    return async.when(
      loading: () => const Center(child: CcSpinner(size: 22)),
      error: (e, _) => CcEmptyState(
        icon: AppIcons.triangleAlert,
        message: "Couldn't load workspaces",
        description: e.toString(),
      ),
      data: (workspaces) {
        if (workspaces.isEmpty) {
          return const CcEmptyState(
            icon: AppIcons.layers,
            message: 'No workspaces yet',
          );
        }
        return ListView(
          children: [
            for (final w in workspaces)
              CcCard(
                interactive: true,
                semanticLabel: 'Select ${w.name}',
                onPressed: () {
                  ref.read(remoteSessionProvider).setActiveWorkspace(w.id);
                  context.pop();
                },
                child: Row(
                  children: [
                    Icon(AppIcons.layers, size: 18, color: t.fgSecondary),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        w.name,
                        style: TextStyle(fontSize: 15, color: t.textPrimary),
                      ),
                    ),
                    if (w.id == activeId)
                      Icon(AppIcons.check, size: 18, color: t.accent),
                  ],
                ),
              ),
          ],
        );
      },
    );
  }
}
