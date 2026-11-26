import 'package:cc_ui/src/components/cc_text_field.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

/// A [CcTextField] wired into a [Form] via [FormField].
///
/// Runs [validator] when the enclosing `Form` validates, flips the field into
/// its error treatment and renders the message beneath it (delegated to
/// [CcTextField], which also supports an optional [label] and [helperText]).
/// All other props forward to [CcTextField]. Submit through
/// [validateAndFocus] so a failed check puts focus on the first field to fix.
class CcTextFormField extends StatelessWidget {
  /// Creates a [CcTextFormField].
  const CcTextFormField({
    super.key,
    this.controller,
    this.initialValue,
    this.hintText,
    this.label,
    this.helperText,
    this.prefix,
    this.suffix,
    this.validator,
    this.onChanged,
    this.enabled = true,
    this.obscureText = false,
    this.keyboardType,
    this.maxLength,
    this.autovalidateMode,
    this.onSubmitted,
    this.textInputAction,
  });

  /// External controller; its current text seeds the field's form value.
  final TextEditingController? controller;

  /// Initial value when no [controller] is supplied.
  final String? initialValue;

  /// Placeholder shown while empty.
  final String? hintText;

  /// Optional persistent label rendered above the field.
  final String? label;

  /// Optional helper text rendered beneath the field when there is no error.
  final String? helperText;

  /// Leading widget.
  final Widget? prefix;

  /// Trailing widget.
  final Widget? suffix;

  /// Validation callback, run by `Form.validate()`.
  final FormFieldValidator<String>? validator;

  /// Called as the text changes (after the form value is updated).
  final ValueChanged<String>? onChanged;

  /// Whether the field accepts input.
  final bool enabled;

  /// Whether to obscure entered characters.
  final bool obscureText;

  /// Soft-keyboard / input type hint.
  final TextInputType? keyboardType;

  /// Optional hard character limit.
  final int? maxLength;

  /// When to auto-run [validator]; defaults to [AutovalidateMode.disabled].
  final AutovalidateMode? autovalidateMode;

  /// Called when Enter submits the field.
  final ValueChanged<String>? onSubmitted;

  /// Keyboard action (e.g. [TextInputAction.next] to chain a form's fields).
  final TextInputAction? textInputAction;

  /// Validates [form] and, when a field fails, moves focus to the first one
  /// that failed, so a keyboard or screen-reader user lands on what to fix
  /// instead of hunting for the message. Returns whether the form is valid.
  static bool validateAndFocus(FormState form) {
    final invalid = form.validateGranularly();
    for (final field in invalid) {
      final node = _editableFocusIn(field.context);
      if (node != null && node.canRequestFocus) {
        node.requestFocus();
        break;
      }
    }
    return invalid.isEmpty;
  }

  static FocusNode? _editableFocusIn(BuildContext context) {
    FocusNode? found;
    void visit(Element element) {
      if (found != null) {
        return;
      }
      final widget = element.widget;
      if (widget is EditableText) {
        found = widget.focusNode;
        return;
      }
      element.visitChildren(visit);
    }

    context.visitChildElements(visit);
    return found;
  }

  @override
  Widget build(BuildContext context) {
    return FormField<String>(
      initialValue: controller?.text ?? initialValue ?? '',
      validator: validator,
      autovalidateMode: autovalidateMode ?? AutovalidateMode.disabled,
      builder: (field) {
        // CcTextField owns the label/helper/error anatomy (including the error
        // message), so this wrapper just forwards the form's errorText.
        return CcTextField(
          controller: controller,
          // Seed the visible text too, not just the FormField value — otherwise
          // an initialValue-only field renders empty.
          initialValue: initialValue,
          hintText: hintText,
          label: label,
          helperText: helperText,
          prefix: prefix,
          suffix: suffix,
          enabled: enabled,
          obscureText: obscureText,
          keyboardType: keyboardType,
          maxLength: maxLength,
          onSubmitted: onSubmitted,
          textInputAction: textInputAction,
          errorText: field.errorText,
          onChanged: (v) {
            field.didChange(v);
            onChanged?.call(v);
          },
        );
      },
    );
  }
}
