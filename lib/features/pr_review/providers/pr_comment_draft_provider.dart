import 'package:control_center/core/providers/text_draft_provider.dart';
import 'package:control_center/shared/widgets/composer/composer_text_controller.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// The session-owned draft behind a PR comment field, painting its Markdown as
/// it will read, the way the composer does.
///
/// Same lifetime rules as [textDraftControllerProvider], and a separate family
/// because that one also backs plain-text surfaces such as commit messages. A
/// surface must use one family throughout: the same key in the other family is
/// a different, empty draft.
final prCommentDraftControllerProvider =
    Provider.family<ComposerTextController, TextDraftKey>((ref, key) {
      final controller = ComposerTextController.markdownOnly();
      ref.onDispose(controller.dispose);
      return controller;
    });
