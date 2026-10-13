// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format width=80

// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_import, prefer_relative_imports, directives_ordering, unused_element, strict_raw_type

part of 'cc_alert.stories.dart';

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
typedef _PlaygroundArgs = CcAlertPlaygroundArgs;
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
    $ActionPlacement..$generatedName = 'ActionPlacement',
    $TitleAndDescription..$generatedName = 'TitleAndDescription',
    $Variants..$generatedName = 'Variants',
    $WithAndWithoutIcon..$generatedName = 'WithAndWithoutIcon',
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

typedef ShowcasePlaygroundScenario = Scenario<Showcase, CcAlertPlaygroundArgs>;
typedef ShowcasePlaygroundDefaults = Defaults<Showcase, CcAlertPlaygroundArgs>;

class ShowcasePlaygroundStory extends Story<Showcase, CcAlertPlaygroundArgs> {
  ShowcasePlaygroundStory({
    super.name,
    super.designLink,
    super.setup,
    super.modes,
    CcAlertPlaygroundArgs? args,
    required super.builder,
    super.scenarios,
    super.excludeFromTests,
  }) : super(args: args ?? CcAlertPlaygroundArgs());
}

class CcAlertPlaygroundArgs extends StoryArgs<Showcase> {
  CcAlertPlaygroundArgs({
    Arg<CcAlertVariant>? variant,
    Arg<String>? title,
    Arg<String>? description,
    Arg<bool>? withIcon,
  }) : this.variantArg = $initArg(
         'variant',
         variant,
         EnumArg<CcAlertVariant>(
           CcAlertVariant.info,
           values: CcAlertVariant.values,
         ),
       )!,
       this.titleArg = $initArg('title', title, StringArg(''))!,
       this.descriptionArg = $initArg(
         'description',
         description,
         StringArg(''),
       )!,
       this.withIconArg = $initArg('withIcon', withIcon, BoolArg(false))!;

  CcAlertPlaygroundArgs.fixed({
    CcAlertVariant variant = CcAlertVariant.info,
    String title = '',
    String description = '',
    bool withIcon = false,
  }) : this.variantArg = $initArg('variant', Arg.fixed(variant), null)!,
       this.titleArg = $initArg('title', Arg.fixed(title), null)!,
       this.descriptionArg = $initArg(
         'description',
         Arg.fixed(description),
         null,
       )!,
       this.withIconArg = $initArg('withIcon', Arg.fixed(withIcon), null)!;

  final Arg<CcAlertVariant> variantArg;

  final Arg<String> titleArg;

  final Arg<String> descriptionArg;

  final Arg<bool> withIconArg;

  CcAlertVariant get variant => variantArg.value;

  String get title => titleArg.value;

  String get description => descriptionArg.value;

  bool get withIcon => withIconArg.value;

  @override
  List<Arg?> get list => [variantArg, titleArg, descriptionArg, withIconArg];
}
