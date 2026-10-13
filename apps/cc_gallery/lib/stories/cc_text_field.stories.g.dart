// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format width=80

// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_import, prefer_relative_imports, directives_ordering, unused_element, strict_raw_type

part of 'cc_text_field.stories.dart';

// **************************************************************************
// StoryGenerator
// **************************************************************************

typedef _Component = Component<Showcase, StoryArgs<Showcase>>;
typedef _Scenario = ShowcaseScenario;
typedef _Defaults = ShowcaseDefaults;
typedef _Story = ShowcaseStory;
typedef _Args = ShowcaseArgs;
typedef _PlaygroundScenario = ShowcasePlaygroundScenario;
typedef _PlaygroundDefaults = ShowcasePlaygroundDefaults;
typedef _PlaygroundStory = ShowcasePlaygroundStory;
typedef _PlaygroundArgs = CcTextFieldPlaygroundArgs;
final ShowcaseComponent = Component<Showcase, StoryArgs<Showcase>>(
  name: component.name ?? 'Showcase',
  path: component.path ?? 'stories',
  docsBuilder: component.docsBuilder,
  docComment:
      r'''The widget every gallery story renders: whatever [preview] builds.

Widgetbook 4 generates a story's args and builder from one widget
constructor (`Meta(Widget.new)`), and that builder must return exactly that
widget type. Most gallery stories are compositions rather than a single
instance (variant grids, state matrices, token tables, the docs pages), so
every stories file targets [Showcase] and names its navigation entry with a
`ComponentMeta` instead.''',
  stories: [
    $Playground..$generatedName = 'Playground',
    $PrefixAndSuffix..$generatedName = 'PrefixAndSuffix',
    $Sizes..$generatedName = 'Sizes',
    $States..$generatedName = 'States',
  ],
);
typedef ShowcaseScenario = Scenario<Showcase, ShowcaseArgs>;
typedef ShowcaseDefaults = Defaults<Showcase, ShowcaseArgs>;

class ShowcaseStory extends Story<Showcase, ShowcaseArgs> {
  ShowcaseStory({
    super.name,
    super.designLink,
    super.setup,
    super.modes,
    required super.args,
    StoryWidgetBuilder<Showcase, ShowcaseArgs>? builder,
    super.scenarios,
    super.excludeFromTests,
  }) : super(
         builder:
             builder ??
             (context, args) => Showcase(args.preview, key: args.key),
       );
}

class ShowcaseArgs extends StoryArgs<Showcase> {
  ShowcaseArgs({
    required Arg<Widget Function(BuildContext)> preview,
    Arg<Key?>? key,
  }) : this.previewArg = $initArg('preview', preview, null)!,
       this.keyArg = $initArg('key', key, null);

  ShowcaseArgs.fixed({required Widget Function(BuildContext) preview, Key? key})
    : this.previewArg = $initArg('preview', Arg.fixed(preview), null)!,
      this.keyArg = $initArg('key', key == null ? null : Arg.fixed(key), null);

  final Arg<Widget Function(BuildContext)> previewArg;

  final Arg<Key?>? keyArg;

  Widget Function(BuildContext) get preview => previewArg.value;

  Key? get key => keyArg?.value;

  @override
  List<Arg?> get list => [previewArg, keyArg];
}

typedef ShowcasePlaygroundScenario =
    Scenario<Showcase, CcTextFieldPlaygroundArgs>;
typedef ShowcasePlaygroundDefaults =
    Defaults<Showcase, CcTextFieldPlaygroundArgs>;

class ShowcasePlaygroundStory
    extends Story<Showcase, CcTextFieldPlaygroundArgs> {
  ShowcasePlaygroundStory({
    super.name,
    super.designLink,
    super.setup,
    super.modes,
    CcTextFieldPlaygroundArgs? args,
    required super.builder,
    super.scenarios,
    super.excludeFromTests,
  }) : super(args: args ?? CcTextFieldPlaygroundArgs());
}

class CcTextFieldPlaygroundArgs extends StoryArgs<Showcase> {
  CcTextFieldPlaygroundArgs({
    Arg<CcTextFieldSize>? size,
    Arg<String>? hintText,
    Arg<String>? initialText,
    Arg<bool>? enabled,
    Arg<bool>? obscureText,
    Arg<bool>? withPrefix,
    Arg<bool>? hasError,
  }) : this.sizeArg = $initArg(
         'size',
         size,
         EnumArg<CcTextFieldSize>(
           CcTextFieldSize.md,
           values: CcTextFieldSize.values,
         ),
       )!,
       this.hintTextArg = $initArg('hintText', hintText, StringArg(''))!,
       this.initialTextArg = $initArg(
         'initialText',
         initialText,
         StringArg(''),
       )!,
       this.enabledArg = $initArg('enabled', enabled, BoolArg(false))!,
       this.obscureTextArg = $initArg(
         'obscureText',
         obscureText,
         BoolArg(false),
       )!,
       this.withPrefixArg = $initArg('withPrefix', withPrefix, BoolArg(false))!,
       this.hasErrorArg = $initArg('hasError', hasError, BoolArg(false))!;

  CcTextFieldPlaygroundArgs.fixed({
    CcTextFieldSize size = CcTextFieldSize.md,
    String hintText = '',
    String initialText = '',
    bool enabled = false,
    bool obscureText = false,
    bool withPrefix = false,
    bool hasError = false,
  }) : this.sizeArg = $initArg('size', Arg.fixed(size), null)!,
       this.hintTextArg = $initArg('hintText', Arg.fixed(hintText), null)!,
       this.initialTextArg = $initArg(
         'initialText',
         Arg.fixed(initialText),
         null,
       )!,
       this.enabledArg = $initArg('enabled', Arg.fixed(enabled), null)!,
       this.obscureTextArg = $initArg(
         'obscureText',
         Arg.fixed(obscureText),
         null,
       )!,
       this.withPrefixArg = $initArg(
         'withPrefix',
         Arg.fixed(withPrefix),
         null,
       )!,
       this.hasErrorArg = $initArg('hasError', Arg.fixed(hasError), null)!;

  final Arg<CcTextFieldSize> sizeArg;

  final Arg<String> hintTextArg;

  final Arg<String> initialTextArg;

  final Arg<bool> enabledArg;

  final Arg<bool> obscureTextArg;

  final Arg<bool> withPrefixArg;

  final Arg<bool> hasErrorArg;

  CcTextFieldSize get size => sizeArg.value;

  String get hintText => hintTextArg.value;

  String get initialText => initialTextArg.value;

  bool get enabled => enabledArg.value;

  bool get obscureText => obscureTextArg.value;

  bool get withPrefix => withPrefixArg.value;

  bool get hasError => hasErrorArg.value;

  @override
  List<Arg?> get list => [
    sizeArg,
    hintTextArg,
    initialTextArg,
    enabledArg,
    obscureTextArg,
    withPrefixArg,
    hasErrorArg,
  ];
}
