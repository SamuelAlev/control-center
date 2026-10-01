import 'package:cc_domain/core/domain/ports/directory_browser_port.dart';
import 'package:cc_ui/cc_ui.dart';
import 'package:control_center/features/repos/presentation/widgets/add_repo_dialog.dart';
import 'package:control_center/features/repos/providers/repo_providers.dart';
import 'package:control_center/l10n/app_localizations.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// The add-repo entry point on every platform: shows the server-filesystem
/// browser dialog and returns the batch outcome, or null when cancelled.
///
/// The browse + register dependencies are read from [ref] HERE (under the app's
/// `ProviderScope`) and handed to the dialog, because the dialog itself is
/// mounted in the root overlay above that scope and so cannot read providers.
/// [workspaceId] names the workspace the repos are registered into — repos are
/// workspace-scoped, so it is threaded all the way to the register call rather
/// than resolved from an ambient "active workspace".
Future<RepoAddOutcome?> addRepos(
  BuildContext context,
  WidgetRef ref,
  String workspaceId,
) => showAddRepoDialog(
  context,
  browser: ref.read(directoryBrowserProvider),
  register: ref.read(addRepoFromServerPathProvider),
  workspaceId: workspaceId,
);

/// [addRepos] for a caller holding the dependencies rather than a [WidgetRef]
/// (a deep link resolved outside the widget tree), with an optional [intro]
/// replacing the generic instructions.
Future<RepoAddOutcome?> showAddRepoDialog(
  BuildContext context, {
  required DirectoryBrowserPort browser,
  required Future<String> Function(String workspaceId, String path) register,
  required String workspaceId,
  String? intro,
}) {
  final l10n = AppLocalizations.of(context);
  return showCcDialog<RepoAddOutcome?>(
    context: context,
    builder: (dialogContext) => CcDialog(
      title: l10n.addRepository,
      content: SizedBox(
        width: 460,
        child: AddRepoDialog(
          browser: browser,
          register: register,
          workspaceId: workspaceId,
          intro: intro,
          onDone: (outcome) => Navigator.pop(dialogContext, outcome),
          onCancel: () => Navigator.pop(dialogContext),
        ),
      ),
      actions: const [],
    ),
  );
}
