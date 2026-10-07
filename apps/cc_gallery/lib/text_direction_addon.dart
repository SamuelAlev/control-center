import 'package:flutter/widgets.dart';
import 'package:widgetbook/widgetbook.dart';

/// An [Addon] that wraps every story in a [Directionality], so each component
/// can be previewed under RTL as well as LTR.
///
/// Widgetbook ships no direction addon of its own, so this follows the shape
/// of its built-in `AlignmentAddon`: one dropdown field, the selection applied
/// by wrapping the preview.
class TextDirectionAddon extends Addon<TextDirection> with SingleFieldOnly {
  /// Creates the addon, previewing in [initialDirection] first.
  TextDirectionAddon([TextDirection initialDirection = TextDirection.ltr])
    : super(name: 'Text direction', initialValue: initialDirection);

  static const _labels = {TextDirection.ltr: 'LTR', TextDirection.rtl: 'RTL'};

  @override
  Field<TextDirection> get field {
    return ObjectDropdownField<TextDirection>(
      name: 'direction',
      initialValue: initialValue,
      values: _labels.keys.toList(),
      labelBuilder: (value) => _labels[value]!,
    );
  }

  @override
  Widget apply(BuildContext context, Widget child, TextDirection setting) {
    return Directionality(textDirection: setting, child: child);
  }
}
