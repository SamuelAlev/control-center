// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format width=80

// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_import, prefer_relative_imports, directives_ordering, unused_element, strict_raw_type

part of 'cc_empty_state.stories.dart';

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
typedef _PlaygroundArgs = CcEmptyStatePlaygroundArgs;
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
    $Compact..$generatedName = 'Compact',
    $MessageOnly..$generatedName = 'MessageOnly',
    $WithAction..$generatedName = 'WithAction',
    $WithDescription..$generatedName = 'WithDescription',
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
    Scenario<Showcase, CcEmptyStatePlaygroundArgs>;
typedef ShowcasePlaygroundDefaults =
    Defaults<Showcase, CcEmptyStatePlaygroundArgs>;

class ShowcasePlaygroundStory
    extends Story<Showcase, CcEmptyStatePlaygroundArgs> {
  ShowcasePlaygroundStory({
    super.name,
    super.designLink,
    super.setup,
    super.modes,
    CcEmptyStatePlaygroundArgs? args,
    required super.builder,
    super.scenarios,
    super.excludeFromTests,
  }) : super(args: args ?? CcEmptyStatePlaygroundArgs());
}

class CcEmptyStatePlaygroundArgs extends StoryArgs<Showcase> {
  CcEmptyStatePlaygroundArgs({
    Arg<String>? message,
    Arg<String>? description,
    Arg<bool>? withDescription,
    Arg<bool>? withAction,
    Arg<CcEmptyStateSize>? size,
    Arg<double>? iconSize,
    Arg<double>? maxWidth,
  }) : this.messageArg = $initArg('message', message, StringArg(''))!,
       this.descriptionArg = $initArg(
         'description',
         description,
         StringArg(''),
       )!,
       this.withDescriptionArg = $initArg(
         'withDescription',
         withDescription,
         BoolArg(false),
       )!,
       this.withActionArg = $initArg('withAction', withAction, BoolArg(false))!,
       this.sizeArg = $initArg(
         'size',
         size,
         EnumArg<CcEmptyStateSize>(
           CcEmptyStateSize.md,
           values: CcEmptyStateSize.values,
         ),
       )!,
       this.iconSizeArg = $initArg('iconSize', iconSize, DoubleArg(0.0))!,
       this.maxWidthArg = $initArg('maxWidth', maxWidth, DoubleArg(0.0))!;

  CcEmptyStatePlaygroundArgs.fixed({
    String message = '',
    String description = '',
    bool withDescription = false,
    bool withAction = false,
    CcEmptyStateSize size = CcEmptyStateSize.md,
    double iconSize = 0.0,
    double maxWidth = 0.0,
  }) : this.messageArg = $initArg('message', Arg.fixed(message), null)!,
       this.descriptionArg = $initArg(
         'description',
         Arg.fixed(description),
         null,
       )!,
       this.withDescriptionArg = $initArg(
         'withDescription',
         Arg.fixed(withDescription),
         null,
       )!,
       this.withActionArg = $initArg(
         'withAction',
         Arg.fixed(withAction),
         null,
       )!,
       this.sizeArg = $initArg('size', Arg.fixed(size), null)!,
       this.iconSizeArg = $initArg('iconSize', Arg.fixed(iconSize), null)!,
       this.maxWidthArg = $initArg('maxWidth', Arg.fixed(maxWidth), null)!;

  final Arg<String> messageArg;

  final Arg<String> descriptionArg;

  final Arg<bool> withDescriptionArg;

  final Arg<bool> withActionArg;

  final Arg<CcEmptyStateSize> sizeArg;

  final Arg<double> iconSizeArg;

  final Arg<double> maxWidthArg;

  String get message => messageArg.value;

  String get description => descriptionArg.value;

  bool get withDescription => withDescriptionArg.value;

  bool get withAction => withActionArg.value;

  CcEmptyStateSize get size => sizeArg.value;

  double get iconSize => iconSizeArg.value;

  double get maxWidth => maxWidthArg.value;

  @override
  List<Arg?> get list => [
    messageArg,
    descriptionArg,
    withDescriptionArg,
    withActionArg,
    sizeArg,
    iconSizeArg,
    maxWidthArg,
  ];
}
