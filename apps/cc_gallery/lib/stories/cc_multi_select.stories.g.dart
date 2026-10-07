// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format width=80

// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_import, prefer_relative_imports, directives_ordering, unused_element, strict_raw_type

part of 'cc_multi_select.stories.dart';

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
typedef _PlaygroundArgs = CcMultiSelectPlaygroundArgs;
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
    $ChipsSummary..$generatedName = 'ChipsSummary',
    $CountSummary..$generatedName = 'CountSummary',
    $Disabled..$generatedName = 'Disabled',
    $Filterable..$generatedName = 'Filterable',
    $SelectAll..$generatedName = 'SelectAll',
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
    Scenario<Showcase, CcMultiSelectPlaygroundArgs>;
typedef ShowcasePlaygroundDefaults =
    Defaults<Showcase, CcMultiSelectPlaygroundArgs>;

class ShowcasePlaygroundStory
    extends Story<Showcase, CcMultiSelectPlaygroundArgs> {
  ShowcasePlaygroundStory({
    super.name,
    super.designLink,
    super.setup,
    super.modes,
    CcMultiSelectPlaygroundArgs? args,
    required super.builder,
    super.scenarios,
    super.excludeFromTests,
  }) : super(args: args ?? CcMultiSelectPlaygroundArgs());
}

class CcMultiSelectPlaygroundArgs extends StoryArgs<Showcase> {
  CcMultiSelectPlaygroundArgs({
    Arg<bool>? showChips,
    Arg<bool>? enabled,
    Arg<String>? hintText,
  }) : this.showChipsArg = $initArg('showChips', showChips, BoolArg(false))!,
       this.enabledArg = $initArg('enabled', enabled, BoolArg(false))!,
       this.hintTextArg = $initArg('hintText', hintText, StringArg(''))!;

  CcMultiSelectPlaygroundArgs.fixed({
    bool showChips = false,
    bool enabled = false,
    String hintText = '',
  }) : this.showChipsArg = $initArg('showChips', Arg.fixed(showChips), null)!,
       this.enabledArg = $initArg('enabled', Arg.fixed(enabled), null)!,
       this.hintTextArg = $initArg('hintText', Arg.fixed(hintText), null)!;

  final Arg<bool> showChipsArg;

  final Arg<bool> enabledArg;

  final Arg<String> hintTextArg;

  bool get showChips => showChipsArg.value;

  bool get enabled => enabledArg.value;

  String get hintText => hintTextArg.value;

  @override
  List<Arg?> get list => [showChipsArg, enabledArg, hintTextArg];
}
