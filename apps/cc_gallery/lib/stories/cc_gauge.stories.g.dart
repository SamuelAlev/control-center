// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format width=80

// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_import, prefer_relative_imports, directives_ordering, unused_element, strict_raw_type

part of 'cc_gauge.stories.dart';

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
typedef _PlaygroundArgs = CcGaugePlaygroundArgs;
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
    $FillLevels..$generatedName = 'FillLevels',
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

typedef ShowcasePlaygroundScenario = Scenario<Showcase, CcGaugePlaygroundArgs>;
typedef ShowcasePlaygroundDefaults = Defaults<Showcase, CcGaugePlaygroundArgs>;

class ShowcasePlaygroundStory extends Story<Showcase, CcGaugePlaygroundArgs> {
  ShowcasePlaygroundStory({
    super.name,
    super.designLink,
    super.setup,
    super.modes,
    CcGaugePlaygroundArgs? args,
    required super.builder,
    super.scenarios,
    super.excludeFromTests,
  }) : super(args: args ?? CcGaugePlaygroundArgs());
}

class CcGaugePlaygroundArgs extends StoryArgs<Showcase> {
  CcGaugePlaygroundArgs({
    Arg<double>? value,
    Arg<double>? size,
    Arg<double>? stroke,
  }) : this.valueArg = $initArg('value', value, DoubleArg(0.0))!,
       this.sizeArg = $initArg('size', size, DoubleArg(0.0))!,
       this.strokeArg = $initArg('stroke', stroke, DoubleArg(0.0))!;

  CcGaugePlaygroundArgs.fixed({
    double value = 0.0,
    double size = 0.0,
    double stroke = 0.0,
  }) : this.valueArg = $initArg('value', Arg.fixed(value), null)!,
       this.sizeArg = $initArg('size', Arg.fixed(size), null)!,
       this.strokeArg = $initArg('stroke', Arg.fixed(stroke), null)!;

  final Arg<double> valueArg;

  final Arg<double> sizeArg;

  final Arg<double> strokeArg;

  double get value => valueArg.value;

  double get size => sizeArg.value;

  double get stroke => strokeArg.value;

  @override
  List<Arg?> get list => [valueArg, sizeArg, strokeArg];
}
