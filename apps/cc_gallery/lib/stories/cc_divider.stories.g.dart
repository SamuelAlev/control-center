// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format width=80

// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_import, prefer_relative_imports, directives_ordering, unused_element, strict_raw_type

part of 'cc_divider.stories.dart';

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
typedef _PlaygroundArgs = CcDividerPlaygroundArgs;
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
    $Horizontal..$generatedName = 'Horizontal',
    $ThicknessIndent..$generatedName = 'ThicknessIndent',
    $Vertical..$generatedName = 'Vertical',
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
    Scenario<Showcase, CcDividerPlaygroundArgs>;
typedef ShowcasePlaygroundDefaults =
    Defaults<Showcase, CcDividerPlaygroundArgs>;

class ShowcasePlaygroundStory extends Story<Showcase, CcDividerPlaygroundArgs> {
  ShowcasePlaygroundStory({
    super.name,
    super.designLink,
    super.setup,
    super.modes,
    CcDividerPlaygroundArgs? args,
    required super.builder,
    super.scenarios,
    super.excludeFromTests,
  }) : super(args: args ?? CcDividerPlaygroundArgs());
}

class CcDividerPlaygroundArgs extends StoryArgs<Showcase> {
  CcDividerPlaygroundArgs({
    Arg<Axis>? axis,
    Arg<double>? thickness,
    Arg<double>? indent,
    Arg<double>? endIndent,
  }) : this.axisArg = $initArg(
         'axis',
         axis,
         EnumArg<Axis>(Axis.horizontal, values: Axis.values),
       )!,
       this.thicknessArg = $initArg('thickness', thickness, DoubleArg(0.0))!,
       this.indentArg = $initArg('indent', indent, DoubleArg(0.0))!,
       this.endIndentArg = $initArg('endIndent', endIndent, DoubleArg(0.0))!;

  CcDividerPlaygroundArgs.fixed({
    Axis axis = Axis.horizontal,
    double thickness = 0.0,
    double indent = 0.0,
    double endIndent = 0.0,
  }) : this.axisArg = $initArg('axis', Arg.fixed(axis), null)!,
       this.thicknessArg = $initArg('thickness', Arg.fixed(thickness), null)!,
       this.indentArg = $initArg('indent', Arg.fixed(indent), null)!,
       this.endIndentArg = $initArg('endIndent', Arg.fixed(endIndent), null)!;

  final Arg<Axis> axisArg;

  final Arg<double> thicknessArg;

  final Arg<double> indentArg;

  final Arg<double> endIndentArg;

  Axis get axis => axisArg.value;

  double get thickness => thicknessArg.value;

  double get indent => indentArg.value;

  double get endIndent => endIndentArg.value;

  @override
  List<Arg?> get list => [axisArg, thicknessArg, indentArg, endIndentArg];
}
