import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// A draft belongs to one workspace, input surface and destination.
///
/// Use a record for multi-part destinations instead of concatenating IDs.
typedef TextDraftKey = ({
  String workspaceId,
  String surface,
  Object destination,
});

/// Session-owned input state, independent of routes, tabs and flyouts.
///
/// Widgets may attach listeners but must not dispose this controller. Clear it
/// after a successful submission, not when its input leaves the widget tree.
/// The backend session's provider container owns its lifetime.
final textDraftControllerProvider =
    Provider.family<TextEditingController, TextDraftKey>((ref, key) {
      final controller = TextEditingController();
      ref.onDispose(controller.dispose);
      return controller;
    });
