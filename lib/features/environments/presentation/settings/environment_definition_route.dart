import 'package:cc_domain/features/environments/domain/entities/environment_definition_record.dart';
import 'package:cc_ui/cc_ui.dart';
import 'package:collection/collection.dart';
import 'package:control_center/features/environments/presentation/settings/environment_definition_editor.dart';
import 'package:control_center/features/environments/presentation/settings/environment_editor_state.dart';
import 'package:control_center/l10n/app_localizations.dart';
import 'package:control_center/router/routes.dart';
import 'package:control_center/shared/widgets/mouse_navigation_handler.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// The definition a Settings → Environments URL names, in the editor.
///
/// The URL says which definition; the selection holds its editing session. A
/// session starts from the seed the opener handed over, or, for a URL reached
/// through history or a link, from what the server holds.
class EnvironmentDefinitionRoute extends ConsumerWidget {
  /// Creates an [EnvironmentDefinitionRoute].
  const EnvironmentDefinitionRoute({
    super.key,
    required this.workspaceId,
    required this.definitionId,
    required this.definitions,
  });

  /// The owning workspace.
  final String workspaceId;

  /// The id in the URL, or [settingsNewEnvironmentId].
  final String definitionId;

  /// What the server holds.
  final AsyncValue<List<EnvironmentDefinitionRecord>> definitions;

  bool get _unsaved => definitionId == settingsNewEnvironmentId;

  bool _opens(EnvironmentEditorSeed seed) =>
      seed.workspaceId == workspaceId &&
      (_unsaved || seed.record?.id == definitionId);

  void _afterFrame(BuildContext context, VoidCallback action) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (context.mounted) {
        action();
      }
    });
  }

  void _start(BuildContext context, WidgetRef ref, EnvironmentEditorSeed seed) {
    _afterFrame(context, () {
      ref.read(environmentEditorRequestProvider.notifier).request(null);
      ref.read(environmentEditorSelectionProvider.notifier).open(seed);
    });
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Watched first: the selection auto-disposes, so starting a session needs
    // this already listening.
    final seed = ref.watch(environmentEditorSelectionProvider);
    final request = ref.watch(environmentEditorRequestProvider);
    if (request != null && _opens(request)) {
      _start(context, ref, request);
    } else if (seed != null && _opens(seed)) {
      final saved = seed.record;
      if (_unsaved && saved != null) {
        // Its first save gave it an id. In place of `/new`, or Back would land
        // there and come straight back here.
        _afterFrame(
          context,
          () => ref
              .read(navigationHistoryProvider.notifier)
              .replace(settingsEnvironmentRoute(workspaceId, saved.id)),
        );
      }
      return EnvironmentDefinitionEditor(seed: seed);
    } else if (_unsaved) {
      final name = AppLocalizations.of(context).environmentsNewDefinitionName;
      _start(
        context,
        ref,
        EnvironmentEditorSeed.blank(workspaceId, name: name),
      );
    } else if (definitions.hasValue && !definitions.isLoading) {
      final record = definitions.requireValue.firstWhereOrNull(
        (record) => record.id == definitionId,
      );
      if (record == null) {
        // Deleted since, or never in this workspace.
        _afterFrame(
          context,
          () => ref
              .read(navigationHistoryProvider.notifier)
              .backOr(settingsEnvironmentsRoute(workspaceId)),
        );
      } else {
        _start(context, ref, EnvironmentEditorSeed.record(record));
      }
    }
    return const Center(child: CcSpinner());
  }
}
