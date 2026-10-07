// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format width=80

// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_import, prefer_relative_imports, directives_ordering, unused_element, strict_raw_type

part of 'cc_segmented_toggle.stories.dart';

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
typedef _PlaygroundArgs = CcSegmentedTogglePlaygroundArgs;
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
    $FullWidth..$generatedName = 'FullWidth',
    $SizesAndDisabled..$generatedName = 'SizesAndDisabled',
    $WithIcons..$generatedName = 'WithIcons',
    $WritePreview..$generatedName = 'WritePreview',
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
    Scenario<Showcase, CcSegmentedTogglePlaygroundArgs>;
typedef ShowcasePlaygroundDefaults =
    Defaults<Showcase, CcSegmentedTogglePlaygroundArgs>;

class ShowcasePlaygroundStory
    extends Story<Showcase, CcSegmentedTogglePlaygroundArgs> {
  ShowcasePlaygroundStory({
    super.name,
    super.designLink,
    super.setup,
    super.modes,
    CcSegmentedTogglePlaygroundArgs? args,
    required super.builder,
    super.scenarios,
    super.excludeFromTests,
  }) : super(args: args ?? CcSegmentedTogglePlaygroundArgs());
}

class CcSegmentedTogglePlaygroundArgs extends StoryArgs<Showcase> {
  CcSegmentedTogglePlaygroundArgs({
    Arg<bool>? enabled,
    Arg<bool>? fullWidth,
    Arg<bool>? large,
    Arg<bool>? withIcons,
    Arg<int>? count,
  }) : this.enabledArg = $initArg('enabled', enabled, BoolArg(false))!,
       this.fullWidthArg = $initArg('fullWidth', fullWidth, BoolArg(false))!,
       this.largeArg = $initArg('large', large, BoolArg(false))!,
       this.withIconsArg = $initArg('withIcons', withIcons, BoolArg(false))!,
       this.countArg = $initArg('count', count, IntArg(0))!;

  CcSegmentedTogglePlaygroundArgs.fixed({
    bool enabled = false,
    bool fullWidth = false,
    bool large = false,
    bool withIcons = false,
    int count = 0,
  }) : this.enabledArg = $initArg('enabled', Arg.fixed(enabled), null)!,
       this.fullWidthArg = $initArg('fullWidth', Arg.fixed(fullWidth), null)!,
       this.largeArg = $initArg('large', Arg.fixed(large), null)!,
       this.withIconsArg = $initArg('withIcons', Arg.fixed(withIcons), null)!,
       this.countArg = $initArg('count', Arg.fixed(count), null)!;

  final Arg<bool> enabledArg;

  final Arg<bool> fullWidthArg;

  final Arg<bool> largeArg;

  final Arg<bool> withIconsArg;

  final Arg<int> countArg;

  bool get enabled => enabledArg.value;

  bool get fullWidth => fullWidthArg.value;

  bool get large => largeArg.value;

  bool get withIcons => withIconsArg.value;

  int get count => countArg.value;

  @override
  List<Arg?> get list => [
    enabledArg,
    fullWidthArg,
    largeArg,
    withIconsArg,
    countArg,
  ];
}
