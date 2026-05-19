import 'package:cc_ui/cc_ui.dart';
import 'package:control_center/core/theme/diff_colors.dart';
import 'package:control_center/features/session_review/presentation/widgets/session_review_panel.dart';
import 'package:control_center/features/session_review/providers/session_review_providers.dart';
import 'package:control_center/features/vscode_theme/providers/vscode_theme_providers.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Opens the session-review panel over a scrim, computing the changeset for
/// [request] on demand. Shows a loading state while git runs and an empty state
/// when nothing changed.
Future<void> showSessionReviewDialog({
  required BuildContext context,
  required SessionDiffRequest request,
  SessionReviewLabels labels = const SessionReviewLabels(),
}) {
  return showCcDialog<void>(
    context: context,
    builder: (_) => CcDialog(
      content: SizedBox(
        width: 880,
        height: 600,
        child: _SessionReviewDialogBody(request: request, labels: labels),
      ),
    ),
  );
}

class _SessionReviewDialogBody extends ConsumerWidget {
  const _SessionReviewDialogBody({required this.request, required this.labels});

  final SessionDiffRequest request;
  final SessionReviewLabels labels;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final changeSet = ref.watch(sessionChangeSetProvider(request));
    final vscode = ref.watch(vscodeEditorThemeProvider);
    // An imported VS Code theme overrides the diff colors so the session review
    // matches the user's IDE; otherwise the shared design-system colors apply.
    final diffColors = vscode == null ? null : DiffColors.fromVsCode(vscode);
    return changeSet.when(
      loading: () =>
          SessionReviewPanel(files: const [], labels: labels, loading: true),
      error: (_, _) => SessionReviewPanel(files: const [], labels: labels),
      data: (files) => SessionReviewPanel(
        files: files,
        labels: labels,
        diffColors: diffColors,
      ),
    );
  }
}
