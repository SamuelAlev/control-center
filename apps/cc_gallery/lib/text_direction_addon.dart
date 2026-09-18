import 'package:flutter/widgets.dart';
import 'package:widgetbook/widgetbook.dart';

/// A [WidgetbookAddon] that wraps every use-case in a [Directionality], so
/// each component can be previewed under RTL as well as LTR.
///
/// Widgetbook ships no direction addon of its own, so this follows the shape
/// of its built-in `AlignmentAddon`: one dropdown field, the selection applied
/// by wrapping the preview.
class TextDirectionAddon extends WidgetbookAddon<TextDirection> {
  /// Creates the addon, previewing in [initialDirection] first.
  TextDirectionAddon({this.initialDirection = TextDirection.ltr})
    : super(name: 'Text direction');

  /// The direction selected when the addon first loads.
  final TextDirection initialDirection;

  static const _labels = {TextDirection.ltr: 'LTR', TextDirection.rtl: 'RTL'};

  @override
  List<Field<TextDirection>> get fields {
    return [
      ObjectDropdownField<TextDirection>(
        name: 'direction',
        initialValue: initialDirection,
        values: _labels.keys.toList(),
        labelBuilder: (value) => _labels[value]!,
      ),
    ];
  }

  @override
  TextDirection valueFromQueryGroup(Map<String, String> group) {
    return valueOf<TextDirection>('direction', group)!;
  }

  @override
  Widget buildUseCase(
    BuildContext context,
    Widget child,
    TextDirection setting,
  ) {
    return Directionality(textDirection: setting, child: child);
  }
}
