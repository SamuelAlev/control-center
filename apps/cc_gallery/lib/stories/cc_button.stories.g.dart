// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format width=80

// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_import, prefer_relative_imports, directives_ordering, unused_element, strict_raw_type

part of 'cc_button.stories.dart';

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
typedef _PlaygroundArgs = CcButtonPlaygroundArgs;
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
    $Loading..$generatedName = 'Loading',
    $Sizes..$generatedName = 'Sizes',
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

typedef ShowcasePlaygroundScenario = Scenario<Showcase, CcButtonPlaygroundArgs>;
typedef ShowcasePlaygroundDefaults = Defaults<Showcase, CcButtonPlaygroundArgs>;

class ShowcasePlaygroundStory extends Story<Showcase, CcButtonPlaygroundArgs> {
  ShowcasePlaygroundStory({
    super.name,
    super.designLink,
    super.setup,
    super.modes,
    CcButtonPlaygroundArgs? args,
    required super.builder,
    super.scenarios,
    super.excludeFromTests,
  }) : super(args: args ?? CcButtonPlaygroundArgs());
}

class CcButtonPlaygroundArgs extends StoryArgs<Showcase> {
  CcButtonPlaygroundArgs({
    Arg<CcButtonVariant>? variant,
    Arg<CcButtonSize>? size,
    Arg<bool>? loading,
    Arg<bool>? withIcon,
    Arg<bool>? enabled,
    Arg<String>? label,
  }) : this.variantArg = $initArg(
         'variant',
         variant,
         EnumArg<CcButtonVariant>(
           CcButtonVariant.primary,
           values: CcButtonVariant.values,
         ),
       )!,
       this.sizeArg = $initArg(
         'size',
         size,
         EnumArg<CcButtonSize>(CcButtonSize.md, values: CcButtonSize.values),
       )!,
       this.loadingArg = $initArg('loading', loading, BoolArg(false))!,
       this.withIconArg = $initArg('withIcon', withIcon, BoolArg(false))!,
       this.enabledArg = $initArg('enabled', enabled, BoolArg(false))!,
       this.labelArg = $initArg('label', label, StringArg(''))!;

  CcButtonPlaygroundArgs.fixed({
    CcButtonVariant variant = CcButtonVariant.primary,
    CcButtonSize size = CcButtonSize.md,
    bool loading = false,
    bool withIcon = false,
    bool enabled = false,
    String label = '',
  }) : this.variantArg = $initArg('variant', Arg.fixed(variant), null)!,
       this.sizeArg = $initArg('size', Arg.fixed(size), null)!,
       this.loadingArg = $initArg('loading', Arg.fixed(loading), null)!,
       this.withIconArg = $initArg('withIcon', Arg.fixed(withIcon), null)!,
       this.enabledArg = $initArg('enabled', Arg.fixed(enabled), null)!,
       this.labelArg = $initArg('label', Arg.fixed(label), null)!;

  final Arg<CcButtonVariant> variantArg;

  final Arg<CcButtonSize> sizeArg;

  final Arg<bool> loadingArg;

  final Arg<bool> withIconArg;

  final Arg<bool> enabledArg;

  final Arg<String> labelArg;

  CcButtonVariant get variant => variantArg.value;

  CcButtonSize get size => sizeArg.value;

  bool get loading => loadingArg.value;

  bool get withIcon => withIconArg.value;

  bool get enabled => enabledArg.value;

  String get label => labelArg.value;

  @override
  List<Arg?> get list => [
    variantArg,
    sizeArg,
    loadingArg,
    withIconArg,
    enabledArg,
    labelArg,
  ];
}
