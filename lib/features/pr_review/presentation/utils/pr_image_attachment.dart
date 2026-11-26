import 'dart:convert';

import 'package:cc_domain/features/pr_review/domain/repositories/pr_review_repository.dart';
import 'package:cc_ui/cc_ui.dart';
import 'package:control_center/l10n/app_localizations.dart';
import 'package:file_selector/file_selector.dart';
import 'package:flutter/widgets.dart';

/// Opens an image picker, uploads selected files to [repoName] via [repo], and
/// inserts Markdown image links at [controller]'s current selection.
Future<void> attachPrImagesToController({
  required BuildContext context,
  required TextEditingController controller,
  required PrReviewRepository? repo,
  required String owner,
  required String repoName,
}) async {
  final l10n = AppLocalizations.of(context);
  final toaster = CcToastScope.of(context);
  if (owner.isEmpty || repoName.isEmpty) {
    toaster.show(l10n.noActiveWorkspaceGithub, variant: CcToastVariant.danger);
    return;
  }
  final files = await openFiles(
    acceptedTypeGroups: [
      XTypeGroup(
        label: l10n.images,
        extensions: ['png', 'jpg', 'jpeg', 'gif', 'webp', 'bmp'],
      ),
    ],
  );
  for (final file in files) {
    try {
      final bytes = await file.readAsBytes();
      final base64 = base64Encode(bytes);
      final uniqueId = DateTime.now().millisecondsSinceEpoch;
      final path = '.github/pr-assets/${uniqueId}_${file.name}';
      if (repo == null) {
        return;
      }
      final url = await repo.uploadContent(
        path,
        base64,
        'Upload image for PR comment',
      );
      _insertAtCursor(controller, '![${file.name}]($url)\n');
    } on Exception catch (e) {
      if (!context.mounted) {
        return;
      }
      toaster.show(
        l10n.failedToUpload(file.name, '$e'),
        variant: CcToastVariant.danger,
      );
    }
  }
}

void _insertAtCursor(TextEditingController controller, String text) {
  final selection = controller.selection;
  final old = controller.text;
  if (selection.isValid && selection.start >= 0) {
    final start = selection.start;
    final end = selection.end;
    controller.text = old.substring(0, start) + text + old.substring(end);
    controller.selection = TextSelection.collapsed(offset: start + text.length);
  } else {
    controller.text = old + text;
    controller.selection = TextSelection.collapsed(
      offset: controller.text.length,
    );
  }
}
