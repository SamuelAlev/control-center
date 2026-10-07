import 'package:cc_gallery/showcase.dart';
import 'package:cc_ui/cc_ui.dart';
import 'package:flutter/widgets.dart';
import 'package:widgetbook/widgetbook.dart';

part 'cc_text_field.stories.g.dart';

/// Stories for [CcTextField] — the design system's flat, single-line input.
///
/// The stories below are listed under `Components → Inputs → CcTextField` (the
/// `ComponentMeta` name and bracketed `path` segments). The builders return the
/// component directly — the gallery's theme addon supplies the [CcTheme] +
/// canvas.

const _path = '[Components]/Inputs';

const component = ComponentMeta(name: 'CcTextField', path: _path);

const meta = Meta(Showcase.new);
const playgroundMeta = Meta(
  Showcase.playground,
  argsType: CcTextFieldPlayground.new,
);

final $Playground = _PlaygroundStory(
  args: _PlaygroundArgs(
    size: EnumArg<CcTextFieldSize>(
      CcTextFieldSize.values.first,
      name: 'Size',
      values: CcTextFieldSize.values,
    ),
    hintText: StringArg('Search pull requests…', name: 'Hint'),
    initialText: StringArg('', name: 'Initial text'),
    enabled: BoolArg(true, name: 'Enabled'),
    obscureText: BoolArg(false, name: 'Obscure text'),
    withPrefix: BoolArg(true, name: 'Search prefix'),
    hasError: BoolArg(false, name: 'Error state'),
  ),
  builder: (context, args) => Showcase.playground(
    (context) => ccTextFieldPlaygroundStory(context, args),
  ),
);

final $PrefixAndSuffix = _Story(
  name: 'Prefix and suffix',
  args: _Args.fixed(preview: ccTextFieldAffordancesStory),
);

final $Sizes = _Story(args: _Args.fixed(preview: ccTextFieldSizesStory));

final $States = _Story(args: _Args.fixed(preview: ccTextFieldStatesStory));

/// The controls of the interactive story, as constructor parameters
/// widgetbook turns into typed args.
class CcTextFieldPlayground {
  CcTextFieldPlayground({
    required this.size,
    required this.hintText,
    required this.initialText,
    required this.enabled,
    required this.obscureText,
    required this.withPrefix,
    required this.hasError,
  });

  final CcTextFieldSize size;
  final String hintText;
  final String initialText;
  final bool enabled;
  final bool obscureText;
  final bool withPrefix;
  final bool hasError;
}

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
    this.clearable = false,
    this.enabled = true,
    this.obscureText = false,
    this.errorText,
    this.size = CcTextFieldSize.md,
  });

  final String? hintText;
  final String? initialText;
  final Widget? prefix;
  final Widget? suffix;
  final bool clearable;
  final bool enabled;
  final bool obscureText;
  final String? errorText;
  final CcTextFieldSize size;

  @override
  State<_TextFieldDemo> createState() => _TextFieldDemoState();
}

class _TextFieldDemoState extends State<_TextFieldDemo> {
  late final TextEditingController _controller = TextEditingController(
    text: widget.initialText,
  );

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => SizedBox(
    width: 320,
    child: widget.clearable
        ? ValueListenableBuilder<TextEditingValue>(
            valueListenable: _controller,
            builder: (context, value, _) => _buildField(
              value.text.isEmpty
                  ? null
                  : CcIconButton(
                      icon: CcIcons.x,
                      size: CcButtonSize.sm,
                      tooltip: 'Clear',
                      onPressed: _controller.clear,
                    ),
            ),
          )
        : _buildField(widget.suffix),
  );

  Widget _buildField(Widget? suffix) => CcTextField(
    controller: _controller,
    hintText: widget.hintText,
    prefix: widget.prefix,
    suffix: suffix,
    enabled: widget.enabled,
    obscureText: widget.obscureText,
    errorText: widget.errorText,
    size: widget.size,
  );
}

/// Resting, focused-on-tap, filled and disabled treatments side by side.
Widget ccTextFieldStatesStory(BuildContext context) {
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
        _TextFieldDemo(initialText: 'control-center', enabled: false),
      ],
    ),
  );
}

/// Leading and trailing affordances, including a clear button that appears
/// while typing.
Widget ccTextFieldAffordancesStory(BuildContext context) {
  return const Center(
    child: Wrap(
      spacing: 20,
      runSpacing: 20,
      children: [
        _TextFieldDemo(
          hintText: 'Filter agents…',
          prefix: Icon(CcIcons.search, size: 16),
        ),
        _TextFieldDemo(
          hintText: 'Search articles',
          prefix: Icon(CcIcons.search, size: 16),
          clearable: true,
        ),
        _TextFieldDemo(
          hintText: 'GitHub token',
          obscureText: true,
          suffix: Icon(CcIcons.eyeOff, size: 16),
        ),
      ],
    ),
  );
}

/// The vertical density scale — comfortable rows vs compact toolbar inputs.
Widget ccTextFieldSizesStory(BuildContext context) {
  return Center(
    child: Wrap(
      spacing: 20,
      runSpacing: 20,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        for (final size in CcTextFieldSize.values)
          _TextFieldDemo(
            hintText: 'Search (${size.name})',
            prefix: const Icon(CcIcons.search, size: 16),
            size: size,
          ),
      ],
    ),
  );
}

/// Interactive playground — drive every arg to see the full state space.
Widget ccTextFieldPlaygroundStory(
  BuildContext context,
  CcTextFieldPlaygroundArgs args,
) {
  final size = args.size;
  final hintText = args.hintText;
  final initialText = args.initialText;
  final enabled = args.enabled;
  final obscureText = args.obscureText;
  final withPrefix = args.withPrefix;
  final hasError = args.hasError;
  return Center(
    child: _TextFieldDemo(
      key: ValueKey(
        '$size$enabled$obscureText$withPrefix$hasError$initialText',
      ),
      hintText: hintText.isEmpty ? null : hintText,
      initialText: initialText.isEmpty ? null : initialText,
      prefix: withPrefix ? const Icon(CcIcons.search, size: 16) : null,
      enabled: enabled,
      obscureText: obscureText,
      errorText: hasError ? 'Required field' : null,
      size: size,
    ),
  );
}
