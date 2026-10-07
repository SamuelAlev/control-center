// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format width=80

// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_import, prefer_relative_imports, directives_ordering, unused_element, strict_raw_type

part of 'cc_text_area.stories.dart';

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
typedef _PlaygroundArgs = CcTextAreaPlaygroundArgs;
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
    $EmptyAndFilled..$generatedName = 'EmptyAndFilled',
    $ErrorAndDisabled..$generatedName = 'ErrorAndDisabled',
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
    Scenario<Showcase, CcTextAreaPlaygroundArgs>;
typedef ShowcasePlaygroundDefaults =
    Defaults<Showcase, CcTextAreaPlaygroundArgs>;

class ShowcasePlaygroundStory
    extends Story<Showcase, CcTextAreaPlaygroundArgs> {
  ShowcasePlaygroundStory({
    super.name,
    super.designLink,
    super.setup,
    super.modes,
    CcTextAreaPlaygroundArgs? args,
    required super.builder,
    super.scenarios,
    super.excludeFromTests,
  }) : super(args: args ?? CcTextAreaPlaygroundArgs());
}

class CcTextAreaPlaygroundArgs extends StoryArgs<Showcase> {
  CcTextAreaPlaygroundArgs({
    Arg<String>? hintText,
    Arg<String>? errorText,
    Arg<bool>? enabled,
    Arg<int>? minLines,
    Arg<int>? maxLength,
  }) : this.hintTextArg = $initArg('hintText', hintText, StringArg(''))!,
       this.errorTextArg = $initArg('errorText', errorText, StringArg(''))!,
       this.enabledArg = $initArg('enabled', enabled, BoolArg(false))!,
       this.minLinesArg = $initArg('minLines', minLines, IntArg(0))!,
       this.maxLengthArg = $initArg('maxLength', maxLength, IntArg(0))!;

  CcTextAreaPlaygroundArgs.fixed({
    String hintText = '',
    String errorText = '',
    bool enabled = false,
    int minLines = 0,
    int maxLength = 0,
  }) : this.hintTextArg = $initArg('hintText', Arg.fixed(hintText), null)!,
       this.errorTextArg = $initArg('errorText', Arg.fixed(errorText), null)!,
       this.enabledArg = $initArg('enabled', Arg.fixed(enabled), null)!,
       this.minLinesArg = $initArg('minLines', Arg.fixed(minLines), null)!,
       this.maxLengthArg = $initArg('maxLength', Arg.fixed(maxLength), null)!;

  final Arg<String> hintTextArg;

  final Arg<String> errorTextArg;

  final Arg<bool> enabledArg;

  final Arg<int> minLinesArg;

  final Arg<int> maxLengthArg;

  String get hintText => hintTextArg.value;

  String get errorText => errorTextArg.value;

  bool get enabled => enabledArg.value;

  int get minLines => minLinesArg.value;

  int get maxLength => maxLengthArg.value;

  @override
  List<Arg?> get list => [
    hintTextArg,
    errorTextArg,
    enabledArg,
    minLinesArg,
    maxLengthArg,
  ];
}
