// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format width=80

// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_import, prefer_relative_imports, directives_ordering, unused_element, strict_raw_type

part of 'cc_banner.stories.dart';

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
typedef _PlaygroundArgs = CcBannerPlaygroundArgs;
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
    $Variants..$generatedName = 'Variants',
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

typedef ShowcasePlaygroundScenario = Scenario<Showcase, CcBannerPlaygroundArgs>;
typedef ShowcasePlaygroundDefaults = Defaults<Showcase, CcBannerPlaygroundArgs>;

class ShowcasePlaygroundStory extends Story<Showcase, CcBannerPlaygroundArgs> {
  ShowcasePlaygroundStory({
    super.name,
    super.designLink,
    super.setup,
    super.modes,
    CcBannerPlaygroundArgs? args,
    required super.builder,
    super.scenarios,
    super.excludeFromTests,
  }) : super(args: args ?? CcBannerPlaygroundArgs());
}

class CcBannerPlaygroundArgs extends StoryArgs<Showcase> {
  CcBannerPlaygroundArgs({
    Arg<CcBannerVariant>? variant,
    Arg<String>? title,
    Arg<String>? body,
    Arg<bool>? withPrimary,
    Arg<bool>? withSecondary,
    Arg<bool>? dismissible,
  }) : this.variantArg = $initArg(
         'variant',
         variant,
         EnumArg<CcBannerVariant>(
           CcBannerVariant.info,
           values: CcBannerVariant.values,
         ),
       )!,
       this.titleArg = $initArg('title', title, StringArg(''))!,
       this.bodyArg = $initArg('body', body, StringArg(''))!,
       this.withPrimaryArg = $initArg(
         'withPrimary',
         withPrimary,
         BoolArg(false),
       )!,
       this.withSecondaryArg = $initArg(
         'withSecondary',
         withSecondary,
         BoolArg(false),
       )!,
       this.dismissibleArg = $initArg(
         'dismissible',
         dismissible,
         BoolArg(false),
       )!;

  CcBannerPlaygroundArgs.fixed({
    CcBannerVariant variant = CcBannerVariant.info,
    String title = '',
    String body = '',
    bool withPrimary = false,
    bool withSecondary = false,
    bool dismissible = false,
  }) : this.variantArg = $initArg('variant', Arg.fixed(variant), null)!,
       this.titleArg = $initArg('title', Arg.fixed(title), null)!,
       this.bodyArg = $initArg('body', Arg.fixed(body), null)!,
       this.withPrimaryArg = $initArg(
         'withPrimary',
         Arg.fixed(withPrimary),
         null,
       )!,
       this.withSecondaryArg = $initArg(
         'withSecondary',
         Arg.fixed(withSecondary),
         null,
       )!,
       this.dismissibleArg = $initArg(
         'dismissible',
         Arg.fixed(dismissible),
         null,
       )!;

  final Arg<CcBannerVariant> variantArg;

  final Arg<String> titleArg;

  final Arg<String> bodyArg;

  final Arg<bool> withPrimaryArg;

  final Arg<bool> withSecondaryArg;

  final Arg<bool> dismissibleArg;

  CcBannerVariant get variant => variantArg.value;

  String get title => titleArg.value;

  String get body => bodyArg.value;

  bool get withPrimary => withPrimaryArg.value;

  bool get withSecondary => withSecondaryArg.value;

  bool get dismissible => dismissibleArg.value;

  @override
  List<Arg?> get list => [
    variantArg,
    titleArg,
    bodyArg,
    withPrimaryArg,
    withSecondaryArg,
    dismissibleArg,
  ];
}
