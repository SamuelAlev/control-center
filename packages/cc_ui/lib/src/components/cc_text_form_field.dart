import 'package:cc_ui/src/components/cc_text_field.dart';
import 'package:cc_ui/src/foundation/cc_typography.dart';
import 'package:cc_ui/src/theme/cc_theme.dart';
import 'package:cc_ui/src/tokens/app_spacing.dart';
import 'package:cc_ui/src/tokens/design_system_tokens.dart';
import 'package:flutter/widgets.dart';

/// A [CcTextField] wired into a [Form] via [FormField].
///
/// Runs [validator] when the enclosing `Form` validates, flips the field into
/// its error treatment, and renders the message beneath it. All other props
/// forward to [CcTextField].
class CcTextFormField extends StatelessWidget {
  /// Creates a [CcTextFormField].
  const CcTextFormField({
    super.key,
    this.controller,
    this.initialValue,
    this.hintText,
    this.prefix,
    this.suffix,
    this.validator,
    this.onChanged,
    this.enabled = true,
    this.obscureText = false,
    this.keyboardType,
    this.maxLength,
    this.autovalidateMode,
  });

  /// External controller; its current text seeds the field's form value.
  final TextEditingController? controller;

  /// Initial value when no [controller] is supplied.
  final String? initialValue;

  /// Placeholder shown while empty.
  final String? hintText;

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

  @override
  Widget build(BuildContext context) {
    final t = context.designSystem ?? DesignSystemTokens.light();
    return FormField<String>(
      initialValue: controller?.text ?? initialValue ?? '',
      validator: validator,
      autovalidateMode: autovalidateMode ?? AutovalidateMode.disabled,
      builder: (field) {
        return Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            CcTextField(
              controller: controller,
              hintText: hintText,
              prefix: prefix,
              suffix: suffix,
              enabled: enabled,
              obscureText: obscureText,
              keyboardType: keyboardType,
              maxLength: maxLength,
              errorText: field.errorText,
              onChanged: (v) {
                field.didChange(v);
                onChanged?.call(v);
              },
            ),
            if (field.errorText != null)
              Padding(
                padding: const EdgeInsets.only(top: AppSpacing.xs, left: 2),
                child: Text(
                  field.errorText!,
                  style: CcTypography.caption.copyWith(color: t.textErrorPrimary),
                ),
              ),
          ],
        );
      },
    );
  }
}
