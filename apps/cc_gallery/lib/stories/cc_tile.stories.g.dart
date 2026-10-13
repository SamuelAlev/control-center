// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format width=80

// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_import, prefer_relative_imports, directives_ordering, unused_element, strict_raw_type

part of 'cc_tile.stories.dart';

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
typedef _PlaygroundArgs = CcTilePlaygroundArgs;
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
    $Anatomy..$generatedName = 'Anatomy',
    $NavigationList..$generatedName = 'NavigationList',
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

typedef ShowcasePlaygroundScenario = Scenario<Showcase, CcTilePlaygroundArgs>;
typedef ShowcasePlaygroundDefaults = Defaults<Showcase, CcTilePlaygroundArgs>;

class ShowcasePlaygroundStory extends Story<Showcase, CcTilePlaygroundArgs> {
  ShowcasePlaygroundStory({
    super.name,
    super.designLink,
    super.setup,
    super.modes,
    CcTilePlaygroundArgs? args,
    required super.builder,
    super.scenarios,
    super.excludeFromTests,
  }) : super(args: args ?? CcTilePlaygroundArgs());
}

class CcTilePlaygroundArgs extends StoryArgs<Showcase> {
  CcTilePlaygroundArgs({
    Arg<String>? title,
    Arg<String>? subtitle,
    Arg<bool>? withIcon,
    Arg<bool>? withTrailing,
    Arg<bool>? selected,
    Arg<bool>? interactive,
  }) : this.titleArg = $initArg('title', title, StringArg(''))!,
       this.subtitleArg = $initArg('subtitle', subtitle, StringArg(''))!,
       this.withIconArg = $initArg('withIcon', withIcon, BoolArg(false))!,
       this.withTrailingArg = $initArg(
         'withTrailing',
         withTrailing,
         BoolArg(false),
       )!,
       this.selectedArg = $initArg('selected', selected, BoolArg(false))!,
       this.interactiveArg = $initArg(
         'interactive',
         interactive,
         BoolArg(false),
       )!;

  CcTilePlaygroundArgs.fixed({
    String title = '',
    String subtitle = '',
    bool withIcon = false,
    bool withTrailing = false,
    bool selected = false,
    bool interactive = false,
  }) : this.titleArg = $initArg('title', Arg.fixed(title), null)!,
       this.subtitleArg = $initArg('subtitle', Arg.fixed(subtitle), null)!,
       this.withIconArg = $initArg('withIcon', Arg.fixed(withIcon), null)!,
       this.withTrailingArg = $initArg(
         'withTrailing',
         Arg.fixed(withTrailing),
         null,
       )!,
       this.selectedArg = $initArg('selected', Arg.fixed(selected), null)!,
       this.interactiveArg = $initArg(
         'interactive',
         Arg.fixed(interactive),
         null,
       )!;

  final Arg<String> titleArg;

  final Arg<String> subtitleArg;

  final Arg<bool> withIconArg;

  final Arg<bool> withTrailingArg;

  final Arg<bool> selectedArg;

  final Arg<bool> interactiveArg;

  String get title => titleArg.value;

  String get subtitle => subtitleArg.value;

  bool get withIcon => withIconArg.value;

  bool get withTrailing => withTrailingArg.value;

  bool get selected => selectedArg.value;

  bool get interactive => interactiveArg.value;

  @override
  List<Arg?> get list => [
    titleArg,
    subtitleArg,
    withIconArg,
    withTrailingArg,
    selectedArg,
    interactiveArg,
  ];
}
