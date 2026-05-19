import 'package:cc_ui/cc_ui.dart';
import 'package:flutter/widgets.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:widgetbook/widgetbook.dart';
import 'package:widgetbook_annotation/widgetbook_annotation.dart' as widgetbook;

/// Use-cases for [CcTextFormField] — a [CcTextField] wired into a [Form].
///
/// Each builder is annotated with `@widgetbook.UseCase`; widgetbook_generator
/// groups them under `Components → Inputs → CcTextFormField`. The builders
/// return the component directly — the gallery's theme addon supplies the
/// [CcTheme] + canvas.

const _path = '[Components]/Inputs';

String? _required(String? v) =>
    (v == null || v.trim().isEmpty) ? 'Workspace name is required' : null;

/// Empty placeholder, a pre-filled value, and the disabled treatment.
@widgetbook.UseCase(name: 'States', type: CcTextFormField, path: _path)
Widget ccTextFormFieldStatesUseCase(BuildContext context) {
  return const Center(
    child: SizedBox(
      width: 360,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          CcTextFormField(hintText: 'Search pull requests…'),
          SizedBox(height: 16),
          CcTextFormField(initialValue: 'control-center'),
          SizedBox(height: 16),
          CcTextFormField(
            initialValue: 'claude-opus-4',
            enabled: false,
          ),
        ],
      ),
    ),
  );
}

/// Validation: an always-on validator flips the field into its error treatment
/// and renders the message beneath it.
@widgetbook.UseCase(name: 'Validation', type: CcTextFormField, path: _path)
Widget ccTextFormFieldValidationUseCase(BuildContext context) {
  return const Center(
    child: SizedBox(
      width: 360,
      child: CcTextFormField(
        hintText: 'name@example.com',
        autovalidateMode: AutovalidateMode.always,
        validator: _required,
      ),
    ),
  );
}

/// Affordances: a leading icon and an obscured secret field, the way the
/// onboarding token form presents them.
@widgetbook.UseCase(name: 'With affordances', type: CcTextFormField, path: _path)
Widget ccTextFormFieldAffordancesUseCase(BuildContext context) {
  final t = context.designSystem!;
  return Center(
    child: SizedBox(
      width: 360,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          CcTextFormField(
            hintText: 'Search repositories',
            prefix: Icon(LucideIcons.search, size: 16, color: t.textTertiary),
          ),
          const SizedBox(height: 16),
          CcTextFormField(
            hintText: 'GitHub personal access token',
            obscureText: true,
            prefix: Icon(LucideIcons.keyRound, size: 16, color: t.textTertiary),
          ),
        ],
      ),
    ),
  );
}

/// Interactive playground — drive every knob to see the full state space, with
/// a submit button that runs the enclosing form's validation.
@widgetbook.UseCase(name: 'Playground', type: CcTextFormField, path: _path)
Widget ccTextFormFieldPlaygroundUseCase(BuildContext context) {
  final hintText = context.knobs.string(
    label: 'Hint text',
    initialValue: 'Name this workspace',
  );
  final obscure = context.knobs.boolean(label: 'Obscure text');
  final enabled = context.knobs.boolean(label: 'Enabled', initialValue: true);
  final withPrefix = context.knobs.boolean(label: 'Leading icon');
  final required = context.knobs.boolean(
    label: 'Required validator',
    initialValue: true,
  );
  return _TextFormFieldPlayground(
    hintText: hintText,
    obscureText: obscure,
    enabled: enabled,
    withPrefix: withPrefix,
    required: required,
  );
}

class _TextFormFieldPlayground extends StatefulWidget {
  const _TextFormFieldPlayground({
    required this.hintText,
    required this.obscureText,
    required this.enabled,
    required this.withPrefix,
    required this.required,
  });

  final String hintText;
  final bool obscureText;
  final bool enabled;
  final bool withPrefix;
  final bool required;

  @override
  State<_TextFormFieldPlayground> createState() =>
      _TextFormFieldPlaygroundState();
}

class _TextFormFieldPlaygroundState extends State<_TextFormFieldPlayground> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final t = context.designSystem!;
    return Center(
      child: SizedBox(
        width: 360,
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              CcTextFormField(
                controller: _controller,
                hintText: widget.hintText,
                obscureText: widget.obscureText,
                enabled: widget.enabled,
                prefix: widget.withPrefix
                    ? Icon(LucideIcons.folder, size: 16, color: t.textTertiary)
                    : null,
                validator: widget.required ? _required : null,
              ),
              const SizedBox(height: 16),
              CcButton(
                onPressed: widget.enabled
                    ? () => _formKey.currentState?.validate()
                    : null,
                child: const Text('Create workspace'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
