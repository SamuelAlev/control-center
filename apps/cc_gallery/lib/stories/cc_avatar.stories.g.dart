// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format width=80

// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_import, prefer_relative_imports, directives_ordering, unused_element, strict_raw_type

part of 'cc_avatar.stories.dart';

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
typedef _PlaygroundArgs = CcAvatarPlaygroundArgs;
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
    $CustomBackground..$generatedName = 'CustomBackground',
    $FallbackContent..$generatedName = 'FallbackContent',
    $Sizes..$generatedName = 'Sizes',
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

typedef ShowcasePlaygroundScenario = Scenario<Showcase, CcAvatarPlaygroundArgs>;
typedef ShowcasePlaygroundDefaults = Defaults<Showcase, CcAvatarPlaygroundArgs>;

class ShowcasePlaygroundStory extends Story<Showcase, CcAvatarPlaygroundArgs> {
  ShowcasePlaygroundStory({
    super.name,
    super.designLink,
    super.setup,
    super.modes,
    CcAvatarPlaygroundArgs? args,
    required super.builder,
    super.scenarios,
    super.excludeFromTests,
  }) : super(args: args ?? CcAvatarPlaygroundArgs());
}

class CcAvatarPlaygroundArgs extends StoryArgs<Showcase> {
  CcAvatarPlaygroundArgs({
    Arg<double>? size,
    Arg<String>? initials,
    Arg<bool>? useInitials,
  }) : this.sizeArg = $initArg('size', size, DoubleArg(0.0))!,
       this.initialsArg = $initArg('initials', initials, StringArg(''))!,
       this.useInitialsArg = $initArg(
         'useInitials',
         useInitials,
         BoolArg(false),
       )!;

  CcAvatarPlaygroundArgs.fixed({
    double size = 0.0,
    String initials = '',
    bool useInitials = false,
  }) : this.sizeArg = $initArg('size', Arg.fixed(size), null)!,
       this.initialsArg = $initArg('initials', Arg.fixed(initials), null)!,
       this.useInitialsArg = $initArg(
         'useInitials',
         Arg.fixed(useInitials),
         null,
       )!;

  final Arg<double> sizeArg;

  final Arg<String> initialsArg;

  final Arg<bool> useInitialsArg;

  double get size => sizeArg.value;

  String get initials => initialsArg.value;

  bool get useInitials => useInitialsArg.value;

  @override
  List<Arg?> get list => [sizeArg, initialsArg, useInitialsArg];
}
