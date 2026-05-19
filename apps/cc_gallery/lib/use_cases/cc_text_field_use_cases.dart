import 'package:cc_ui/cc_ui.dart';
import 'package:flutter/widgets.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:widgetbook/widgetbook.dart';
import 'package:widgetbook_annotation/widgetbook_annotation.dart' as widgetbook;

/// Use-cases for [CcTextField] — the design system's flat, single-line input.
///
/// Each builder is annotated with `@widgetbook.UseCase`; widgetbook_generator
/// groups them under `Components → Inputs → CcTextField` (from [CcTextField] as
/// the `type` and the bracketed `path` segments). The builders return the
/// component directly — the gallery's theme addon supplies the [CcTheme] +
/// canvas.

const _path = '[Components]/Inputs';

/// A stateful wrapper so the field's own controller drives hint visibility.
///
/// Mirrors `_TextFieldDemo` in component_stories.dart: it owns the controller
/// and disposes it, optionally seeding initial text so a "filled" state renders.
class _TextFieldDemo extends StatefulWidget {
  const _TextFieldDemo({
    super.key,
    this.hintText,
    this.initialText,
    this.prefix,
    this.suffix,
    this.enabled = true,
    this.obscureText = false,
    this.errorText,
    this.size = CcTextFieldSize.md,
  });

  final String? hintText;
  final String? initialText;
  final Widget? prefix;
  final Widget? suffix;
  final bool enabled;
  final bool obscureText;
  final String? errorText;
  final CcTextFieldSize size;

  @override
  State<_TextFieldDemo> createState() => _TextFieldDemoState();
}

class _TextFieldDemoState extends State<_TextFieldDemo> {
  late final TextEditingController _controller =
      TextEditingController(text: widget.initialText);

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => SizedBox(
        width: 320,
        child: CcTextField(
          controller: _controller,
          hintText: widget.hintText,
          prefix: widget.prefix,
          suffix: widget.suffix,
          enabled: widget.enabled,
          obscureText: widget.obscureText,
          errorText: widget.errorText,
          size: widget.size,
        ),
      );
}

/// Resting, focused-on-tap, filled, and disabled treatments side by side.
@widgetbook.UseCase(name: 'States', type: CcTextField, path: _path)
Widget ccTextFieldStatesUseCase(BuildContext context) {
  return const Center(
    child: Wrap(
      spacing: 20,
      runSpacing: 20,
      children: [
        _TextFieldDemo(hintText: 'Search pull requests…'),
        _TextFieldDemo(initialText: 'claude-opus-4-8'),
        _TextFieldDemo(
          hintText: 'Workspace name',
          errorText: 'Workspace already exists',
        ),
        _TextFieldDemo(
          initialText: 'control-center',
          enabled: false,
        ),
      ],
    ),
  );
}

/// Leading and trailing affordances: a search prefix and a password suffix.
@widgetbook.UseCase(name: 'Prefix and suffix', type: CcTextField, path: _path)
Widget ccTextFieldAffordancesUseCase(BuildContext context) {
  return const Center(
    child: Wrap(
      spacing: 20,
      runSpacing: 20,
      children: [
        _TextFieldDemo(
          hintText: 'Filter agents…',
          prefix: Icon(LucideIcons.search, size: 16),
        ),
        _TextFieldDemo(
          hintText: 'GitHub token',
          obscureText: true,
          suffix: Icon(LucideIcons.eyeOff, size: 16),
        ),
      ],
    ),
  );
}

/// The vertical density scale — comfortable rows vs compact toolbar inputs.
@widgetbook.UseCase(name: 'Sizes', type: CcTextField, path: _path)
Widget ccTextFieldSizesUseCase(BuildContext context) {
  return Center(
    child: Wrap(
      spacing: 20,
      runSpacing: 20,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        for (final size in CcTextFieldSize.values)
          _TextFieldDemo(
            hintText: 'Search (${size.name})',
            prefix: const Icon(LucideIcons.search, size: 16),
            size: size,
          ),
      ],
    ),
  );
}

/// Interactive playground — drive every knob to see the full state space.
@widgetbook.UseCase(name: 'Playground', type: CcTextField, path: _path)
Widget ccTextFieldPlaygroundUseCase(BuildContext context) {
  final size = context.knobs.object.dropdown(
    label: 'Size',
    options: CcTextFieldSize.values,
    labelBuilder: (s) => s.name,
  );
  final hintText = context.knobs.string(
    label: 'Hint',
    initialValue: 'Search pull requests…',
  );
  final initialText = context.knobs.string(
    label: 'Initial text',
    initialValue: '',
  );
  final enabled = context.knobs.boolean(label: 'Enabled', initialValue: true);
  final obscureText = context.knobs.boolean(label: 'Obscure text');
  final withPrefix =
      context.knobs.boolean(label: 'Search prefix', initialValue: true);
  final hasError = context.knobs.boolean(label: 'Error state');
  return Center(
    child: _TextFieldDemo(
      key: ValueKey('$size$enabled$obscureText$withPrefix$hasError$initialText'),
      hintText: hintText.isEmpty ? null : hintText,
      initialText: initialText.isEmpty ? null : initialText,
      prefix: withPrefix ? const Icon(LucideIcons.search, size: 16) : null,
      enabled: enabled,
      obscureText: obscureText,
      errorText: hasError ? 'Required field' : null,
      size: size,
    ),
  );
}
