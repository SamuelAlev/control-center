import 'package:cc_domain/features/environments/domain/value_objects/environment_definition.dart';
import 'package:cc_ui/cc_ui.dart';
import 'package:flutter/widgets.dart';

/// The blank value for [option], for a form with no default to show.
Object? emptyEnvironmentOptionValue(EnvironmentOption option) =>
    switch (option.type) {
      'bool' => false,
      'multi' => const <String>[],
      'enum' => option.values.isEmpty ? null : option.values.first,
      _ => '',
    };

/// One option on the Start form.
class EnvironmentOptionField extends StatelessWidget {
  /// Creates an [EnvironmentOptionField].
  const EnvironmentOptionField({
    super.key,
    required this.option,
    required this.value,
    required this.onChanged,
  });

  /// What to ask.
  final EnvironmentOption option;

  /// The current value.
  final Object? value;

  /// Fired with the new value.
  final ValueChanged<Object?> onChanged;

  @override
  Widget build(BuildContext context) {
    final t = context.designSystem ?? DesignSystemTokens.light();
    final label = option.label ?? option.key;
    final caption = CcTypography.bodySm.copyWith(color: t.textPrimary);
    switch (option.type) {
      case 'bool':
        return Row(
          children: [
            Expanded(child: Text(label, style: caption)),
            CcSwitch(
              value: value == true,
              semanticLabel: label,
              onChanged: onChanged,
            ),
          ],
        );
      case 'enum':
        return CcSelect<String>(
          label: label,
          value: value as String?,
          options: [
            for (final choice in option.values)
              CcSelectOption(value: choice, label: choice),
          ],
          onChanged: onChanged,
        );
      case 'multi':
        final chosen = {...?(value as List?)?.map((item) => '$item')};
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(label, style: caption),
            const SizedBox(height: AppSpacing.xs),
            for (final choice in option.values)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: AppSpacing.xxs),
                child: CcCheckbox(
                  value: chosen.contains(choice),
                  label: Text(choice),
                  onChanged: (selected) => onChanged([
                    for (final item in option.values)
                      if (item == choice
                          ? selected == true
                          : chosen.contains(item))
                        item,
                  ]),
                ),
              ),
          ],
        );
      default:
        return CcTextField(
          key: ValueKey(option.key),
          label: label,
          initialValue: value as String? ?? '',
          onChanged: onChanged,
        );
    }
  }
}
