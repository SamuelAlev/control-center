// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format width=80

// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_import, prefer_relative_imports, directives_ordering, unused_element, strict_raw_type

part of 'cc_toaster.stories.dart';

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
typedef _PlaygroundArgs = CcToastScopePlaygroundArgs;
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
    $Alignments..$generatedName = 'Alignments',
    $Variants..$generatedName = 'Variants',
    $WithTitle..$generatedName = 'WithTitle',
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
    Scenario<Showcase, CcToastScopePlaygroundArgs>;
typedef ShowcasePlaygroundDefaults =
    Defaults<Showcase, CcToastScopePlaygroundArgs>;

class ShowcasePlaygroundStory
    extends Story<Showcase, CcToastScopePlaygroundArgs> {
  ShowcasePlaygroundStory({
    super.name,
    super.designLink,
    super.setup,
    super.modes,
    required super.args,
    required super.builder,
    super.scenarios,
    super.excludeFromTests,
  });
}

class CcToastScopePlaygroundArgs extends StoryArgs<Showcase> {
  CcToastScopePlaygroundArgs({
    Arg<CcToastVariant>? variant,
    required Arg<Alignment> alignment,
    Arg<String?>? title,
    Arg<String>? message,
    Arg<double>? seconds,
  }) : this.variantArg = $initArg(
         'variant',
         variant,
         EnumArg<CcToastVariant>(
           CcToastVariant.neutral,
           values: CcToastVariant.values,
         ),
       )!,
       this.alignmentArg = $initArg('alignment', alignment, null)!,
       this.titleArg = $initArg('title', title, NullableStringArg(null))!,
       this.messageArg = $initArg('message', message, StringArg(''))!,
       this.secondsArg = $initArg('seconds', seconds, DoubleArg(0.0))!;

  CcToastScopePlaygroundArgs.fixed({
    CcToastVariant variant = CcToastVariant.neutral,
    required Alignment alignment,
    String? title = null,
    String message = '',
    double seconds = 0.0,
  }) : this.variantArg = $initArg('variant', Arg.fixed(variant), null)!,
       this.alignmentArg = $initArg('alignment', Arg.fixed(alignment), null)!,
       this.titleArg = $initArg(
         'title',
         title == null ? null : Arg.fixed(title),
         null,
       ),
       this.messageArg = $initArg('message', Arg.fixed(message), null)!,
       this.secondsArg = $initArg('seconds', Arg.fixed(seconds), null)!;

  final Arg<CcToastVariant> variantArg;

  final Arg<Alignment> alignmentArg;

  final Arg<String?>? titleArg;

  final Arg<String> messageArg;

  final Arg<double> secondsArg;

  CcToastVariant get variant => variantArg.value;

  Alignment get alignment => alignmentArg.value;

  String? get title => titleArg?.value;

  String get message => messageArg.value;

  double get seconds => secondsArg.value;

  @override
  List<Arg?> get list => [
    variantArg,
    alignmentArg,
    titleArg,
    messageArg,
    secondsArg,
  ];
}
