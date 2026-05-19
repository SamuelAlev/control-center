import 'package:cc_ui/cc_ui.dart';
import 'package:flutter/widgets.dart';

/// One SSO text field that owns its controller for the widget's lifetime and
/// re-seeds it when the parent reloads the config.
///
/// External value changes win only while the user is not mid-edit, so a reload
/// that arrives during typing does not yank the cursor.
class SsoTextField extends StatefulWidget {
  /// Creates an [SsoTextField].
  const SsoTextField({
    super.key,
    required this.value,
    required this.onChanged,
    this.hint,
    this.minLines,
    this.maxLines = 1,
    this.obscure = false,
    this.enabled = true,
  });

  /// The current value from the parent's draft.
  final String value;

  /// Fired on every keystroke.
  final ValueChanged<String> onChanged;

  /// Placeholder.
  final String? hint;

  /// Minimum visible lines (for pasted blocks).
  final int? minLines;

  /// Maximum visible lines before scrolling.
  final int maxLines;

  /// Masks the input.
  final bool obscure;

  /// Whether the field accepts edits.
  final bool enabled;

  @override
  State<SsoTextField> createState() => _SsoTextFieldState();
}

class _SsoTextFieldState extends State<SsoTextField> {
  late final TextEditingController _controller = TextEditingController(
    text: widget.value,
  );

  @override
  void didUpdateWidget(covariant SsoTextField oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.value != widget.value && _controller.text != widget.value) {
      _controller.value = TextEditingValue(
        text: widget.value,
        selection: TextSelection.collapsed(offset: widget.value.length),
      );
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return CcTextField(
      controller: _controller,
      hintText: widget.hint,
      minLines: widget.minLines,
      maxLines: widget.maxLines,
      obscureText: widget.obscure,
      enabled: widget.enabled,
      onChanged: widget.onChanged,
    );
  }
}
