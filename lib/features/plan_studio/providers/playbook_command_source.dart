import 'package:cc_ui/cc_ui.dart';
import 'package:control_center/features/plan_studio/presentation/widgets/playbook_run_dialog.dart';
import 'package:control_center/features/plan_studio/providers/plan_studio_providers.dart';
import 'package:control_center/features/workspaces/providers/workspace_providers.dart';
import 'package:control_center/l10n/app_localizations.dart';
import 'package:control_center/router/routes.dart';
import 'package:control_center/shared/icons/app_icons.dart';
import 'package:control_center/shared/widgets/command_palette.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Contributes each workspace Playbook (PRD 17) to the ⌘K omnibox so the
/// operator can run one straight from the keyboard (PRD 19 §1 acceptance:
/// "run a Playbook").
class _PlaybookCommandSource implements CommandSource {
  @override
  String get id => 'playbooks';
  @override
  String get category => 'Playbooks';
  @override
  bool get isDynamic => true;

  @override
  List<CommandItem> buildItems(BuildContext context, WidgetRef ref) {
    final workspaceId = ref.read(activeWorkspaceIdProvider);
    if (workspaceId == null) {
      return const [];
    }
    // Uses whatever the warm playbooks stream already holds — no round-trip on
    // open (the palette keeps this provider warm).
    final playbooks = ref.watch(playbooksProvider).value ?? const [];
    final l10n = AppLocalizations.of(context);
    return [
      for (final p in playbooks)
        CommandItem(
          id: 'playbook:${p.id}',
          label: '${l10n.runPlaybookLabel}: ${p.name}',
          description: p.description.isEmpty ? null : p.description,
          icon: AppIcons.play,
          category: l10n.playbooksLabel,
          onExecute: () {
            final ctx = rootNavigatorKey.currentContext;
            if (ctx == null) {
              return;
            }
            showCcDialog<void>(
              context: ctx,
              builder: (_) =>
                  PlaybookRunDialog(playbook: p, workspaceId: workspaceId),
            );
          },
        ),
    ];
  }
}

/// Provider for the playbook command source.
final playbookCommandSourceProvider = Provider<CommandSource>(
  (_) => _PlaybookCommandSource(),
);
