import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

/// The `onEditingComplete` a single-line cc_ui field hands its
/// [EditableText].
///
/// Without one, Enter (a `done`-style action) unfocuses the field, and on
/// desktop and web nothing then holds focus: the next Tab starts over from
/// the top of the page. A field there keeps focus and only finishes any
/// composing text; `onSubmitted` still runs. Touch platforms keep their own
/// behaviour (returning null), where Done also closes the keyboard, and so
/// do `next` / `previous`, which move focus on purpose.
VoidCallback? ccSubmitKeepsFocus(
  TextEditingController controller,
  TextInputAction? action,
) {
  if (action == TextInputAction.next || action == TextInputAction.previous) {
    return null;
  }
  if (!kIsWeb) {
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
      case TargetPlatform.iOS:
      case TargetPlatform.fuchsia:
        return null;
      case TargetPlatform.macOS:
      case TargetPlatform.windows:
      case TargetPlatform.linux:
        break;
    }
  }
  return controller.clearComposing;
}
