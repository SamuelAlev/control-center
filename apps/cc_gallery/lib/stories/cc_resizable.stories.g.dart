// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format width=80

// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_import, prefer_relative_imports, directives_ordering, unused_element, strict_raw_type

part of 'cc_resizable.stories.dart';

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
typedef _PlaygroundArgs = CcResizablePlaygroundArgs;
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
    $HorizontalSplit..$generatedName = 'HorizontalSplit',
    $ThreeRegions..$generatedName = 'ThreeRegions',
    $VerticalSplit..$generatedName = 'VerticalSplit',
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
    Scenario<Showcase, CcResizablePlaygroundArgs>;
typedef ShowcasePlaygroundDefaults =
    Defaults<Showcase, CcResizablePlaygroundArgs>;

class ShowcasePlaygroundStory
    extends Story<Showcase, CcResizablePlaygroundArgs> {
  ShowcasePlaygroundStory({
    super.name,
    super.designLink,
    super.setup,
    super.modes,
    CcResizablePlaygroundArgs? args,
    required super.builder,
    super.scenarios,
    super.excludeFromTests,
  }) : super(args: args ?? CcResizablePlaygroundArgs());
}

class CcResizablePlaygroundArgs extends StoryArgs<Showcase> {
  CcResizablePlaygroundArgs({
    Arg<bool>? horizontal,
    Arg<double>? thickness,
    Arg<double>? hitSize,
    Arg<String>? firstLabel,
    Arg<String>? secondLabel,
  }) : this.horizontalArg = $initArg('horizontal', horizontal, BoolArg(false))!,
       this.thicknessArg = $initArg('thickness', thickness, DoubleArg(0.0))!,
       this.hitSizeArg = $initArg('hitSize', hitSize, DoubleArg(0.0))!,
       this.firstLabelArg = $initArg('firstLabel', firstLabel, StringArg(''))!,
       this.secondLabelArg = $initArg(
         'secondLabel',
         secondLabel,
         StringArg(''),
       )!;

  CcResizablePlaygroundArgs.fixed({
    bool horizontal = false,
    double thickness = 0.0,
    double hitSize = 0.0,
    String firstLabel = '',
    String secondLabel = '',
  }) : this.horizontalArg = $initArg(
         'horizontal',
         Arg.fixed(horizontal),
         null,
       )!,
       this.thicknessArg = $initArg('thickness', Arg.fixed(thickness), null)!,
       this.hitSizeArg = $initArg('hitSize', Arg.fixed(hitSize), null)!,
       this.firstLabelArg = $initArg(
         'firstLabel',
         Arg.fixed(firstLabel),
         null,
       )!,
       this.secondLabelArg = $initArg(
         'secondLabel',
         Arg.fixed(secondLabel),
         null,
       )!;

  final Arg<bool> horizontalArg;

  final Arg<double> thicknessArg;

  final Arg<double> hitSizeArg;

  final Arg<String> firstLabelArg;

  final Arg<String> secondLabelArg;

  bool get horizontal => horizontalArg.value;

  double get thickness => thicknessArg.value;

  double get hitSize => hitSizeArg.value;

  String get firstLabel => firstLabelArg.value;

  String get secondLabel => secondLabelArg.value;

  @override
  List<Arg?> get list => [
    horizontalArg,
    thicknessArg,
    hitSizeArg,
    firstLabelArg,
    secondLabelArg,
  ];
}
