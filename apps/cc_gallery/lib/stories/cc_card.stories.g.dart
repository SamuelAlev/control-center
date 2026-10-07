// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format width=80

// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_import, prefer_relative_imports, directives_ordering, unused_element, strict_raw_type

part of 'cc_card.stories.dart';

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
typedef _PlaygroundArgs = CcCardPlaygroundArgs;
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
    $Interactive..$generatedName = 'Interactive',
    $Padding..$generatedName = 'Padding',
    $Surfaces..$generatedName = 'Surfaces',
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

typedef ShowcasePlaygroundScenario = Scenario<Showcase, CcCardPlaygroundArgs>;
typedef ShowcasePlaygroundDefaults = Defaults<Showcase, CcCardPlaygroundArgs>;

class ShowcasePlaygroundStory extends Story<Showcase, CcCardPlaygroundArgs> {
  ShowcasePlaygroundStory({
    super.name,
    super.designLink,
    super.setup,
    super.modes,
    CcCardPlaygroundArgs? args,
    required super.builder,
    super.scenarios,
    super.excludeFromTests,
  }) : super(args: args ?? CcCardPlaygroundArgs());
}

class CcCardPlaygroundArgs extends StoryArgs<Showcase> {
  CcCardPlaygroundArgs({
    Arg<bool>? useSurface,
    Arg<bool>? interactive,
    Arg<double>? padding,
    Arg<String>? body,
  }) : this.useSurfaceArg = $initArg('useSurface', useSurface, BoolArg(false))!,
       this.interactiveArg = $initArg(
         'interactive',
         interactive,
         BoolArg(false),
       )!,
       this.paddingArg = $initArg('padding', padding, DoubleArg(0.0))!,
       this.bodyArg = $initArg('body', body, StringArg(''))!;

  CcCardPlaygroundArgs.fixed({
    bool useSurface = false,
    bool interactive = false,
    double padding = 0.0,
    String body = '',
  }) : this.useSurfaceArg = $initArg(
         'useSurface',
         Arg.fixed(useSurface),
         null,
       )!,
       this.interactiveArg = $initArg(
         'interactive',
         Arg.fixed(interactive),
         null,
       )!,
       this.paddingArg = $initArg('padding', Arg.fixed(padding), null)!,
       this.bodyArg = $initArg('body', Arg.fixed(body), null)!;

  final Arg<bool> useSurfaceArg;

  final Arg<bool> interactiveArg;

  final Arg<double> paddingArg;

  final Arg<String> bodyArg;

  bool get useSurface => useSurfaceArg.value;

  bool get interactive => interactiveArg.value;

  double get padding => paddingArg.value;

  String get body => bodyArg.value;

  @override
  List<Arg?> get list => [useSurfaceArg, interactiveArg, paddingArg, bodyArg];
}
