// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format width=80

// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_import, prefer_relative_imports, directives_ordering, unused_element, strict_raw_type

part of 'cc_menu.stories.dart';

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
typedef _PlaygroundArgs = CcMenuPlaygroundArgs;
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
    $ContextMenuRightClick..$generatedName = 'ContextMenuRightClick',
    $GroupedAndSearchable..$generatedName = 'GroupedAndSearchable',
    $PlainAndDisabled..$generatedName = 'PlainAndDisabled',
    $SingleSelect..$generatedName = 'SingleSelect',
    $WorkspaceActions..$generatedName = 'WorkspaceActions',
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

typedef ShowcasePlaygroundScenario = Scenario<Showcase, CcMenuPlaygroundArgs>;
typedef ShowcasePlaygroundDefaults = Defaults<Showcase, CcMenuPlaygroundArgs>;

class ShowcasePlaygroundStory extends Story<Showcase, CcMenuPlaygroundArgs> {
  ShowcasePlaygroundStory({
    super.name,
    super.designLink,
    super.setup,
    super.modes,
    CcMenuPlaygroundArgs? args,
    required super.builder,
    super.scenarios,
    super.excludeFromTests,
  }) : super(args: args ?? CcMenuPlaygroundArgs());
}

class CcMenuPlaygroundArgs extends StoryArgs<Showcase> {
  CcMenuPlaygroundArgs({
    Arg<String>? triggerLabel,
    Arg<CcButtonVariant>? variant,
    Arg<double>? minWidth,
    Arg<bool>? withIcons,
    Arg<bool>? destructiveLast,
    Arg<bool>? disableLast,
  }) : this.triggerLabelArg = $initArg(
         'triggerLabel',
         triggerLabel,
         StringArg(''),
       )!,
       this.variantArg = $initArg(
         'variant',
         variant,
         EnumArg<CcButtonVariant>(
           CcButtonVariant.primary,
           values: CcButtonVariant.values,
         ),
       )!,
       this.minWidthArg = $initArg('minWidth', minWidth, DoubleArg(0.0))!,
       this.withIconsArg = $initArg('withIcons', withIcons, BoolArg(false))!,
       this.destructiveLastArg = $initArg(
         'destructiveLast',
         destructiveLast,
         BoolArg(false),
       )!,
       this.disableLastArg = $initArg(
         'disableLast',
         disableLast,
         BoolArg(false),
       )!;

  CcMenuPlaygroundArgs.fixed({
    String triggerLabel = '',
    CcButtonVariant variant = CcButtonVariant.primary,
    double minWidth = 0.0,
    bool withIcons = false,
    bool destructiveLast = false,
    bool disableLast = false,
  }) : this.triggerLabelArg = $initArg(
         'triggerLabel',
         Arg.fixed(triggerLabel),
         null,
       )!,
       this.variantArg = $initArg('variant', Arg.fixed(variant), null)!,
       this.minWidthArg = $initArg('minWidth', Arg.fixed(minWidth), null)!,
       this.withIconsArg = $initArg('withIcons', Arg.fixed(withIcons), null)!,
       this.destructiveLastArg = $initArg(
         'destructiveLast',
         Arg.fixed(destructiveLast),
         null,
       )!,
       this.disableLastArg = $initArg(
         'disableLast',
         Arg.fixed(disableLast),
         null,
       )!;

  final Arg<String> triggerLabelArg;

  final Arg<CcButtonVariant> variantArg;

  final Arg<double> minWidthArg;

  final Arg<bool> withIconsArg;

  final Arg<bool> destructiveLastArg;

  final Arg<bool> disableLastArg;

  String get triggerLabel => triggerLabelArg.value;

  CcButtonVariant get variant => variantArg.value;

  double get minWidth => minWidthArg.value;

  bool get withIcons => withIconsArg.value;

  bool get destructiveLast => destructiveLastArg.value;

  bool get disableLast => disableLastArg.value;

  @override
  List<Arg?> get list => [
    triggerLabelArg,
    variantArg,
    minWidthArg,
    withIconsArg,
    destructiveLastArg,
    disableLastArg,
  ];
}
