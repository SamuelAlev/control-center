import 'package:cc_ui/cc_ui.dart';
import 'package:control_center/l10n/app_localizations.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

/// Outcome of reading the max-parallel-runs field.
///
/// A blank field is not an error: it is the only way to express "no cap", so
/// it parses to `(value: null, isInvalid: false)`. `isInvalid` is reserved for
/// text that was typed but is not a whole number of 1 or more — which must be
/// rejected rather than silently coerced, since coercing 0 to "unlimited"
/// would mean the opposite of what was typed.
typedef MaxParallelRunsParse = ({int? value, bool isInvalid});

/// Parses the raw text of a max-parallel-runs field. See
/// [MaxParallelRunsParse].
MaxParallelRunsParse parseMaxParallelRuns(String raw) {
  final trimmed = raw.trim();
  if (trimmed.isEmpty) {
    return (value: null, isInvalid: false);
  }
  final parsed = int.tryParse(trimmed);
  if (parsed == null || parsed < 1) {
    return (value: null, isInvalid: true);
  }
  return (value: parsed, isInvalid: false);
}

/// The "max parallel runs" form field, shared by the run-settings dialog and
/// the new-template dialog so the cap reads and validates the same in both.
class MaxParallelRunsField extends StatelessWidget {
  /// Creates a [MaxParallelRunsField] over [controller].
  const MaxParallelRunsField({
    super.key,
    required this.controller,
    this.errorText,
    this.onChanged,
  });

  /// Holds the raw text; read it back with [parseMaxParallelRuns].
  final TextEditingController controller;

  /// Validation message shown under the field, or null when it is valid.
  final String? errorText;

  /// Called on every edit — use it to clear [errorText] as the user retypes.
  final ValueChanged<String>? onChanged;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final tokens = context.designSystem ?? DesignSystemTokens.light();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          l10n.pipelineRunSettingsMaxParallel,
          style: TextStyle(
            color: tokens.textPrimary,
            fontSize: 13,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 6),
        CcTextField(
          controller: controller,
          hintText: l10n.pipelineRunSettingsMaxParallelHint,
          keyboardType: TextInputType.number,
          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
          onChanged: onChanged,
        ),
        const SizedBox(height: 4),
        Text(
          errorText ?? l10n.pipelineRunSettingsMaxParallelHelp,
          style: TextStyle(
            color: errorText == null
                ? tokens.textTertiary
                : tokens.textErrorPrimary,
            fontSize: 12,
          ),
        ),
      ],
    );
  }
}
