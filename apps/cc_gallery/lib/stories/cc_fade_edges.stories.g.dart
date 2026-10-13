// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format width=80

// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_import, prefer_relative_imports, directives_ordering, unused_element, strict_raw_type

part of 'cc_fade_edges.stories.dart';

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
typedef _PlaygroundArgs = CcFadeEdgesPlaygroundArgs;
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
    $Axes..$generatedName = 'Axes',
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
    Scenario<Showcase, CcFadeEdgesPlaygroundArgs>;
typedef ShowcasePlaygroundDefaults =
    Defaults<Showcase, CcFadeEdgesPlaygroundArgs>;

class ShowcasePlaygroundStory
    extends Story<Showcase, CcFadeEdgesPlaygroundArgs> {
  ShowcasePlaygroundStory({
    super.name,
    super.designLink,
    super.setup,
    super.modes,
    CcFadeEdgesPlaygroundArgs? args,
    required super.builder,
    super.scenarios,
    super.excludeFromTests,
  }) : super(args: args ?? CcFadeEdgesPlaygroundArgs());
}

class CcFadeEdgesPlaygroundArgs extends StoryArgs<Showcase> {
  CcFadeEdgesPlaygroundArgs({
    Arg<bool>? horizontal,
    Arg<bool>? start,
    Arg<bool>? end,
    Arg<double>? extent,
  }) : this.horizontalArg = $initArg('horizontal', horizontal, BoolArg(false))!,
       this.startArg = $initArg('start', start, BoolArg(false))!,
       this.endArg = $initArg('end', end, BoolArg(false))!,
       this.extentArg = $initArg('extent', extent, DoubleArg(0.0))!;

  CcFadeEdgesPlaygroundArgs.fixed({
    bool horizontal = false,
    bool start = false,
    bool end = false,
    double extent = 0.0,
  }) : this.horizontalArg = $initArg(
         'horizontal',
         Arg.fixed(horizontal),
         null,
       )!,
       this.startArg = $initArg('start', Arg.fixed(start), null)!,
       this.endArg = $initArg('end', Arg.fixed(end), null)!,
       this.extentArg = $initArg('extent', Arg.fixed(extent), null)!;

  final Arg<bool> horizontalArg;

  final Arg<bool> startArg;

  final Arg<bool> endArg;

  final Arg<double> extentArg;

  bool get horizontal => horizontalArg.value;

  bool get start => startArg.value;

  bool get end => endArg.value;

  double get extent => extentArg.value;

  @override
  List<Arg?> get list => [horizontalArg, startArg, endArg, extentArg];
}
