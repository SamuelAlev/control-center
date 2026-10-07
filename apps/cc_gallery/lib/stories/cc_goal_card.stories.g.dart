// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format width=80

// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_import, prefer_relative_imports, directives_ordering, unused_element, strict_raw_type

part of 'cc_goal_card.stories.dart';

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
typedef _PlaygroundArgs = CcGoalCardPlaygroundArgs;
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
    $Lifecycle..$generatedName = 'Lifecycle',
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
    Scenario<Showcase, CcGoalCardPlaygroundArgs>;
typedef ShowcasePlaygroundDefaults =
    Defaults<Showcase, CcGoalCardPlaygroundArgs>;

class ShowcasePlaygroundStory
    extends Story<Showcase, CcGoalCardPlaygroundArgs> {
  ShowcasePlaygroundStory({
    super.name,
    super.designLink,
    super.setup,
    super.modes,
    CcGoalCardPlaygroundArgs? args,
    required super.builder,
    super.scenarios,
    super.excludeFromTests,
  }) : super(args: args ?? CcGoalCardPlaygroundArgs());
}

class CcGoalCardPlaygroundArgs extends StoryArgs<Showcase> {
  CcGoalCardPlaygroundArgs({
    Arg<String>? objective,
    Arg<int>? used,
    Arg<int>? budget,
    Arg<CcGoalStatus>? status,
  }) : this.objectiveArg = $initArg('objective', objective, StringArg(''))!,
       this.usedArg = $initArg('used', used, IntArg(0))!,
       this.budgetArg = $initArg('budget', budget, IntArg(0))!,
       this.statusArg = $initArg(
         'status',
         status,
         EnumArg<CcGoalStatus>(
           CcGoalStatus.active,
           values: CcGoalStatus.values,
         ),
       )!;

  CcGoalCardPlaygroundArgs.fixed({
    String objective = '',
    int used = 0,
    int budget = 0,
    CcGoalStatus status = CcGoalStatus.active,
  }) : this.objectiveArg = $initArg('objective', Arg.fixed(objective), null)!,
       this.usedArg = $initArg('used', Arg.fixed(used), null)!,
       this.budgetArg = $initArg('budget', Arg.fixed(budget), null)!,
       this.statusArg = $initArg('status', Arg.fixed(status), null)!;

  final Arg<String> objectiveArg;

  final Arg<int> usedArg;

  final Arg<int> budgetArg;

  final Arg<CcGoalStatus> statusArg;

  String get objective => objectiveArg.value;

  int get used => usedArg.value;

  int get budget => budgetArg.value;

  CcGoalStatus get status => statusArg.value;

  @override
  List<Arg?> get list => [objectiveArg, usedArg, budgetArg, statusArg];
}
