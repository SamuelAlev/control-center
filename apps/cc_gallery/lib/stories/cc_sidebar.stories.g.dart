// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format width=80

// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_import, prefer_relative_imports, directives_ordering, unused_element, strict_raw_type

part of 'cc_sidebar.stories.dart';

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
typedef _PlaygroundArgs = CcSidebarPlaygroundArgs;
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
    $CollapsedRail..$generatedName = 'CollapsedRail',
    $CollapsibleGroups..$generatedName = 'CollapsibleGroups',
    $Expanded..$generatedName = 'Expanded',
    $NestedBranch..$generatedName = 'NestedBranch',
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
    Scenario<Showcase, CcSidebarPlaygroundArgs>;
typedef ShowcasePlaygroundDefaults =
    Defaults<Showcase, CcSidebarPlaygroundArgs>;

class ShowcasePlaygroundStory extends Story<Showcase, CcSidebarPlaygroundArgs> {
  ShowcasePlaygroundStory({
    super.name,
    super.designLink,
    super.setup,
    super.modes,
    CcSidebarPlaygroundArgs? args,
    required super.builder,
    super.scenarios,
    super.excludeFromTests,
  }) : super(args: args ?? CcSidebarPlaygroundArgs());
}

class CcSidebarPlaygroundArgs extends StoryArgs<Showcase> {
  CcSidebarPlaygroundArgs({
    Arg<bool>? collapsed,
    Arg<bool>? withHeader,
    Arg<bool>? withFooter,
    Arg<double>? width,
  }) : this.collapsedArg = $initArg('collapsed', collapsed, BoolArg(false))!,
       this.withHeaderArg = $initArg('withHeader', withHeader, BoolArg(false))!,
       this.withFooterArg = $initArg('withFooter', withFooter, BoolArg(false))!,
       this.widthArg = $initArg('width', width, DoubleArg(0.0))!;

  CcSidebarPlaygroundArgs.fixed({
    bool collapsed = false,
    bool withHeader = false,
    bool withFooter = false,
    double width = 0.0,
  }) : this.collapsedArg = $initArg('collapsed', Arg.fixed(collapsed), null)!,
       this.withHeaderArg = $initArg(
         'withHeader',
         Arg.fixed(withHeader),
         null,
       )!,
       this.withFooterArg = $initArg(
         'withFooter',
         Arg.fixed(withFooter),
         null,
       )!,
       this.widthArg = $initArg('width', Arg.fixed(width), null)!;

  final Arg<bool> collapsedArg;

  final Arg<bool> withHeaderArg;

  final Arg<bool> withFooterArg;

  final Arg<double> widthArg;

  bool get collapsed => collapsedArg.value;

  bool get withHeader => withHeaderArg.value;

  bool get withFooter => withFooterArg.value;

  double get width => widthArg.value;

  @override
  List<Arg?> get list => [collapsedArg, withHeaderArg, withFooterArg, widthArg];
}
