import 'package:cc_markdown/src/ast/nodes.dart';
import 'package:cc_markdown/src/render/render_context.dart';
import 'package:cc_markdown/src/style/style.dart';
import 'package:flutter/widgets.dart';

/// A widget builder for one AST node type, registered by [CcNode.nodeType].
///
/// Overrides have **per-node fall-through**: when [canBuild] returns false
/// for a specific node, the engine's default rendering for that node type
/// runs instead — so a builder can claim only the nodes it cares about (e.g.
/// only `control-center://` links) and leave the rest to the default.
///
/// Builders for INLINE node types return a widget that the renderer embeds
/// as a [WidgetSpan] inside the paragraph's single `Text.rich` — the span
/// run is never split.
abstract class CcNodeBuilder {
  /// Creates a [CcNodeBuilder].
  const CcNodeBuilder();

  /// Whether this builder handles [node]. False falls through to the default.
  bool canBuild(CcNode node) => true;

  /// How the renderer aligns this builder's widget within the line when the
  /// node is inline (embedded as a [WidgetSpan]).
  ///
  /// Defaults to line-box middle — right for images and badge-like widgets.
  /// Builders whose widget carries text meant to read as part of the sentence
  /// (e.g. an inline-code chip) should return [PlaceholderAlignment.baseline]
  /// so their glyphs sit on the paragraph's baseline instead of floating on
  /// the box's vertical center.
  PlaceholderAlignment get placeholderAlignment => PlaceholderAlignment.middle;

  /// Builds the widget for [node].
  Widget build(CcNode node, CcMarkdownStyle style, CcRenderContext context);
}

/// An immutable, identity-stable registry of node-type overrides.
///
/// The engine renders every core node type itself; the registry carries the
/// app's OVERRIDES plus builders for plugin-produced custom node types.
/// Identity-stability matters: the streaming widget's memo treats a registry
/// change as a full invalidation, so keep app registries process-global.
final class CcBuilderRegistry {
  /// Creates a registry from [builders] (nodeType → builder).
  CcBuilderRegistry([Map<String, CcNodeBuilder> builders = const {}])
    : _builders = Map.unmodifiable(builders);

  /// The empty registry.
  static final CcBuilderRegistry empty = CcBuilderRegistry();

  final Map<String, CcNodeBuilder> _builders;

  /// The registered builder for [nodeType], or null.
  CcNodeBuilder? builderFor(String nodeType) => _builders[nodeType];

  /// A NEW registry with [overrides] layered on top (new identity — the
  /// streaming memo invalidates, which is what you want).
  CcBuilderRegistry withOverrides(Map<String, CcNodeBuilder> overrides) =>
      CcBuilderRegistry({..._builders, ...overrides});

  /// All registered entries.
  Iterable<MapEntry<String, CcNodeBuilder>> get entries => _builders.entries;
}
