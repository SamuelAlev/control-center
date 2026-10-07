import 'package:cc_gallery/showcase.dart';
import 'package:cc_ui/cc_ui.dart';
import 'package:flutter/widgets.dart';
import 'package:widgetbook/widgetbook.dart';

part 'cc_text_form_field.stories.g.dart';

/// Stories for [CcTextFormField] — a [CcTextField] wired into a [Form].
///
/// The stories below are listed under `Components → Inputs → CcTextFormField`
/// (the `ComponentMeta` name and bracketed `path` segments). The builders
/// return the component directly — the gallery's theme addon supplies the
/// [CcTheme] + canvas.

const _path = '[Components]/Inputs';

const component = ComponentMeta(name: 'CcTextFormField', path: _path);

const meta = Meta(Showcase.new);
const playgroundMeta = Meta(
  Showcase.playground,
  argsType: CcTextFormFieldPlayground.new,
);

final $Playground = _PlaygroundStory(
  args: _PlaygroundArgs(
    hintText: StringArg('Name this workspace', name: 'Hint text'),
    obscure: BoolArg(false, name: 'Obscure text'),
    enabled: BoolArg(true, name: 'Enabled'),
    withPrefix: BoolArg(false, name: 'Leading icon'),
    required: BoolArg(true, name: 'Required validator'),
  ),
  builder: (context, args) => Showcase.playground(
    (context) => ccTextFormFieldPlaygroundStory(context, args),
  ),
);

final $States = _Story(args: _Args.fixed(preview: ccTextFormFieldStatesStory));

final $Validation = _Story(
  args: _Args.fixed(preview: ccTextFormFieldValidationStory),
);

final $WithAffordances = _Story(
  name: 'With affordances',
  args: _Args.fixed(preview: ccTextFormFieldAffordancesStory),
);

/// The controls of the interactive story, as constructor parameters
/// widgetbook turns into typed args.
class CcTextFormFieldPlayground {
  CcTextFormFieldPlayground({
    required this.hintText,
    required this.obscure,
    required this.enabled,
    required this.withPrefix,
    required this.required,
  });

  final String hintText;
  final bool obscure;
  final bool enabled;
  final bool withPrefix;
  final bool required;
}

String? _required(String? v) =>
    (v == null || v.trim().isEmpty) ? 'Workspace name is required' : null;

/// Empty placeholder, a pre-filled value and the disabled treatment.
Widget ccTextFormFieldStatesStory(BuildContext context) {
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
          CcTextFormField(initialValue: 'claude-opus-4', enabled: false),
        ],
      ),
    ),
  );
}

/// Validation: an always-on validator flips the field into its error treatment
/// and renders the message beneath it.
Widget ccTextFormFieldValidationStory(BuildContext context) {
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
Widget ccTextFormFieldAffordancesStory(BuildContext context) {
  final t = context.designSystem!;
  return Center(
    child: SizedBox(
      width: 360,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          CcTextFormField(
            hintText: 'Search repositories',
            prefix: Icon(CcIcons.search, size: 16, color: t.textTertiary),
          ),
          const SizedBox(height: 16),
          CcTextFormField(
            hintText: 'GitHub personal access token',
            obscureText: true,
            prefix: Icon(CcIcons.keyRound, size: 16, color: t.textTertiary),
          ),
        ],
      ),
    ),
  );
}

/// Interactive playground — drive every arg to see the full state space, with
/// a submit button that runs the enclosing form's validation.
Widget ccTextFormFieldPlaygroundStory(
  BuildContext context,
  CcTextFormFieldPlaygroundArgs args,
) {
  final hintText = args.hintText;
  final obscure = args.obscure;
  final enabled = args.enabled;
  final withPrefix = args.withPrefix;
  final required = args.required;
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
                    ? Icon(CcIcons.folder, size: 16, color: t.textTertiary)
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
