import 'package:flutter/widgets.dart';
import 'package:widgetbook/widgetbook.dart';

/// The widget every gallery story renders: whatever [preview] builds.
///
/// Widgetbook 4 generates a story's args and builder from one widget
/// constructor (`Meta(Widget.new)`), and that builder must return exactly that
/// widget type. Most gallery stories are compositions rather than a single
/// instance (variant grids, state matrices, token tables, the docs pages), so
/// every stories file targets [Showcase] and names its navigation entry with a
/// `ComponentMeta` instead.
class Showcase extends StatelessWidget {
  /// A static story; its stories pass [preview] as a fixed arg.
  const Showcase(this.preview, {super.key});

  /// An interactive story. Its own constructor so a stories file can declare
  /// a second `Meta` for it, whose `argsType` lists the story's controls,
  /// while the file's static stories keep the plain [Showcase.new] args.
  const Showcase.playground(this.preview, {super.key});

  /// Builds the preview.
  final WidgetBuilder preview;

  @override
  Widget build(BuildContext context) => preview(context);
}

/// A `ComponentMeta.docsBuilder` for entries that are pages in their own right
/// (the Docs category): no generated component docs node next to them.
List<DocBlock> noDocs(List<DocBlock> blocks) => const [];
