// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format width=80

// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_import, prefer_relative_imports, directives_ordering, unused_element, strict_raw_type

part of 'cc_slider.stories.dart';

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
typedef _PlaygroundArgs = CcSliderPlaygroundArgs;
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
    $ContinuousAndStepped..$generatedName = 'ContinuousAndStepped',
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

typedef ShowcasePlaygroundScenario = Scenario<Showcase, CcSliderPlaygroundArgs>;
typedef ShowcasePlaygroundDefaults = Defaults<Showcase, CcSliderPlaygroundArgs>;

class ShowcasePlaygroundStory extends Story<Showcase, CcSliderPlaygroundArgs> {
  ShowcasePlaygroundStory({
    super.name,
    super.designLink,
    super.setup,
    super.modes,
    CcSliderPlaygroundArgs? args,
    required super.builder,
    super.scenarios,
    super.excludeFromTests,
  }) : super(args: args ?? CcSliderPlaygroundArgs());
}

class CcSliderPlaygroundArgs extends StoryArgs<Showcase> {
  CcSliderPlaygroundArgs({
    Arg<int>? divisions,
    Arg<bool>? enabled,
    Arg<bool>? showValue,
    Arg<bool>? showSteps,
    Arg<bool>? labelled,
  }) : this.divisionsArg = $initArg('divisions', divisions, IntArg(0))!,
       this.enabledArg = $initArg('enabled', enabled, BoolArg(false))!,
       this.showValueArg = $initArg('showValue', showValue, BoolArg(false))!,
       this.showStepsArg = $initArg('showSteps', showSteps, BoolArg(false))!,
       this.labelledArg = $initArg('labelled', labelled, BoolArg(false))!;

  CcSliderPlaygroundArgs.fixed({
    int divisions = 0,
    bool enabled = false,
    bool showValue = false,
    bool showSteps = false,
    bool labelled = false,
  }) : this.divisionsArg = $initArg('divisions', Arg.fixed(divisions), null)!,
       this.enabledArg = $initArg('enabled', Arg.fixed(enabled), null)!,
       this.showValueArg = $initArg('showValue', Arg.fixed(showValue), null)!,
       this.showStepsArg = $initArg('showSteps', Arg.fixed(showSteps), null)!,
       this.labelledArg = $initArg('labelled', Arg.fixed(labelled), null)!;

  final Arg<int> divisionsArg;

  final Arg<bool> enabledArg;

  final Arg<bool> showValueArg;

  final Arg<bool> showStepsArg;

  final Arg<bool> labelledArg;

  int get divisions => divisionsArg.value;

  bool get enabled => enabledArg.value;

  bool get showValue => showValueArg.value;

  bool get showSteps => showStepsArg.value;

  bool get labelled => labelledArg.value;

  @override
  List<Arg?> get list => [
    divisionsArg,
    enabledArg,
    showValueArg,
    showStepsArg,
    labelledArg,
  ];
}
