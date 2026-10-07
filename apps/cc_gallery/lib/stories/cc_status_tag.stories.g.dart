// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format width=80

// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_import, prefer_relative_imports, directives_ordering, unused_element, strict_raw_type

part of 'cc_status_tag.stories.dart';

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
typedef _PlaygroundArgs = CcStatusTagPlaygroundArgs;
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
    $Dots..$generatedName = 'Dots',
    $Tones..$generatedName = 'Tones',
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
    Scenario<Showcase, CcStatusTagPlaygroundArgs>;
typedef ShowcasePlaygroundDefaults =
    Defaults<Showcase, CcStatusTagPlaygroundArgs>;

class ShowcasePlaygroundStory
    extends Story<Showcase, CcStatusTagPlaygroundArgs> {
  ShowcasePlaygroundStory({
    super.name,
    super.designLink,
    super.setup,
    super.modes,
    CcStatusTagPlaygroundArgs? args,
    required super.builder,
    super.scenarios,
    super.excludeFromTests,
  }) : super(args: args ?? CcStatusTagPlaygroundArgs());
}

class CcStatusTagPlaygroundArgs extends StoryArgs<Showcase> {
  CcStatusTagPlaygroundArgs({
    Arg<String>? label,
    Arg<bool>? dot,
    Arg<CcStatusTone>? tone,
  }) : this.labelArg = $initArg('label', label, StringArg(''))!,
       this.dotArg = $initArg('dot', dot, BoolArg(false))!,
       this.toneArg = $initArg(
         'tone',
         tone,
         EnumArg<CcStatusTone>(
           CcStatusTone.positive,
           values: CcStatusTone.values,
         ),
       )!;

  CcStatusTagPlaygroundArgs.fixed({
    String label = '',
    bool dot = false,
    CcStatusTone tone = CcStatusTone.positive,
  }) : this.labelArg = $initArg('label', Arg.fixed(label), null)!,
       this.dotArg = $initArg('dot', Arg.fixed(dot), null)!,
       this.toneArg = $initArg('tone', Arg.fixed(tone), null)!;

  final Arg<String> labelArg;

  final Arg<bool> dotArg;

  final Arg<CcStatusTone> toneArg;

  String get label => labelArg.value;

  bool get dot => dotArg.value;

  CcStatusTone get tone => toneArg.value;

  @override
  List<Arg?> get list => [labelArg, dotArg, toneArg];
}
