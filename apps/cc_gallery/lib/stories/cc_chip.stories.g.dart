// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format width=80

// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_import, prefer_relative_imports, directives_ordering, unused_element, strict_raw_type

part of 'cc_chip.stories.dart';

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
typedef _PlaygroundArgs = CcChipPlaygroundArgs;
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
    $Deletable..$generatedName = 'Deletable',
    $States..$generatedName = 'States',
    $WithIcon..$generatedName = 'WithIcon',
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

typedef ShowcasePlaygroundScenario = Scenario<Showcase, CcChipPlaygroundArgs>;
typedef ShowcasePlaygroundDefaults = Defaults<Showcase, CcChipPlaygroundArgs>;

class ShowcasePlaygroundStory extends Story<Showcase, CcChipPlaygroundArgs> {
  ShowcasePlaygroundStory({
    super.name,
    super.designLink,
    super.setup,
    super.modes,
    CcChipPlaygroundArgs? args,
    required super.builder,
    super.scenarios,
    super.excludeFromTests,
  }) : super(args: args ?? CcChipPlaygroundArgs());
}

class CcChipPlaygroundArgs extends StoryArgs<Showcase> {
  CcChipPlaygroundArgs({
    Arg<String>? label,
    Arg<bool>? selected,
    Arg<bool>? withIcon,
    Arg<bool>? tappable,
    Arg<bool>? deletable,
  }) : this.labelArg = $initArg('label', label, StringArg(''))!,
       this.selectedArg = $initArg('selected', selected, BoolArg(false))!,
       this.withIconArg = $initArg('withIcon', withIcon, BoolArg(false))!,
       this.tappableArg = $initArg('tappable', tappable, BoolArg(false))!,
       this.deletableArg = $initArg('deletable', deletable, BoolArg(false))!;

  CcChipPlaygroundArgs.fixed({
    String label = '',
    bool selected = false,
    bool withIcon = false,
    bool tappable = false,
    bool deletable = false,
  }) : this.labelArg = $initArg('label', Arg.fixed(label), null)!,
       this.selectedArg = $initArg('selected', Arg.fixed(selected), null)!,
       this.withIconArg = $initArg('withIcon', Arg.fixed(withIcon), null)!,
       this.tappableArg = $initArg('tappable', Arg.fixed(tappable), null)!,
       this.deletableArg = $initArg('deletable', Arg.fixed(deletable), null)!;

  final Arg<String> labelArg;

  final Arg<bool> selectedArg;

  final Arg<bool> withIconArg;

  final Arg<bool> tappableArg;

  final Arg<bool> deletableArg;

  String get label => labelArg.value;

  bool get selected => selectedArg.value;

  bool get withIcon => withIconArg.value;

  bool get tappable => tappableArg.value;

  bool get deletable => deletableArg.value;

  @override
  List<Arg?> get list => [
    labelArg,
    selectedArg,
    withIconArg,
    tappableArg,
    deletableArg,
  ];
}
