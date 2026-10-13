// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format width=80

// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_import, prefer_relative_imports, directives_ordering, unused_element, strict_raw_type

part of 'cc_swipe_actions.stories.dart';

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
typedef _PlaygroundArgs = CcSwipeActionsPlaygroundArgs;
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
    $NotificationRows..$generatedName = 'NotificationRows',
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
    Scenario<Showcase, CcSwipeActionsPlaygroundArgs>;
typedef ShowcasePlaygroundDefaults =
    Defaults<Showcase, CcSwipeActionsPlaygroundArgs>;

class ShowcasePlaygroundStory
    extends Story<Showcase, CcSwipeActionsPlaygroundArgs> {
  ShowcasePlaygroundStory({
    super.name,
    super.designLink,
    super.setup,
    super.modes,
    CcSwipeActionsPlaygroundArgs? args,
    required super.builder,
    super.scenarios,
    super.excludeFromTests,
  }) : super(args: args ?? CcSwipeActionsPlaygroundArgs());
}

class CcSwipeActionsPlaygroundArgs extends StoryArgs<Showcase> {
  CcSwipeActionsPlaygroundArgs({Arg<bool>? gate, Arg<int>? holdMs})
    : this.gateArg = $initArg('gate', gate, BoolArg(false))!,
      this.holdMsArg = $initArg('holdMs', holdMs, IntArg(0))!;

  CcSwipeActionsPlaygroundArgs.fixed({bool gate = false, int holdMs = 0})
    : this.gateArg = $initArg('gate', Arg.fixed(gate), null)!,
      this.holdMsArg = $initArg('holdMs', Arg.fixed(holdMs), null)!;

  final Arg<bool> gateArg;

  final Arg<int> holdMsArg;

  bool get gate => gateArg.value;

  int get holdMs => holdMsArg.value;

  @override
  List<Arg?> get list => [gateArg, holdMsArg];
}
