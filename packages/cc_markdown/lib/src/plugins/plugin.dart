import 'package:cc_markdown/src/ast/nodes.dart';

/// Base type of parser plugins. Subclass [CcBlockPlugin] or [CcInlinePlugin].
abstract class CcParserPlugin {
  /// Creates a [CcParserPlugin].
  const CcParserPlugin();

  /// Unique id — duplicate registration throws in [CcPluginSet].
  String get id;

  /// Higher priority runs first. Core syntaxes effectively sit below 0.
  int get priority => 0;
}

/// Result of a successful block-plugin parse.
final class CcBlockParseResult {
  /// Creates a [CcBlockParseResult].
  const CcBlockParseResult(this.node, this.linesConsumed);

  /// The produced block node (usually a [CcCustomBlock] subclass).
  final CcBlockNode node;

  /// How many source lines the plugin consumed (>= 1).
  final int linesConsumed;
}

/// A block-level parser extension. Consulted before every core block syntax.
abstract class CcBlockPlugin extends CcParserPlugin {
  /// Creates a [CcBlockPlugin].
  const CcBlockPlugin();

  /// Cheap gate: whether [line] (at [index] of [lines]) could start this
  /// block. Called for every unconsumed line, so keep it O(prefix).
  bool canParse(String line, List<String> lines, int index);

  /// Parses the block starting at [startIndex]. Returning null falls through
  /// to the next plugin / core syntax.
  CcBlockParseResult? parse(List<String> lines, int startIndex);
}

/// Result of a successful inline-plugin parse.
final class CcInlineParseResult {
  /// Creates a [CcInlineParseResult].
  const CcInlineParseResult(this.node, this.consumed);

  /// The produced inline node (usually a [CcCustomInline] subclass).
  final CcInlineNode node;

  /// How many source characters the plugin consumed (>= 1).
  final int consumed;
}

/// An inline-level parser extension, dispatched in O(1) by trigger character.
abstract class CcInlinePlugin extends CcParserPlugin {
  /// Creates a [CcInlinePlugin].
  const CcInlinePlugin();

  /// The character(s) that can start this syntax (each indexed for O(1)
  /// dispatch — the plugin is only consulted when one of them is seen).
  String get triggerCharacters;

  /// Cheap gate at [index] in [text].
  bool canParse(String text, int index);

  /// Parses starting at [startIndex]. Returning null falls through.
  CcInlineParseResult? parse(String text, int startIndex);
}

/// An immutable, identity-stable set of parser plugins.
///
/// Immutability is load-bearing: the parse cache keys on `(source, plugin-set
/// identity)`, which is only sound because a set can never gain or lose
/// plugins after construction. Keep app-side sets as process-global finals.
final class CcPluginSet {
  /// Creates a set from [plugins]. Throws [ArgumentError] on duplicate ids.
  factory CcPluginSet(Iterable<CcParserPlugin> plugins) {
    final block = <CcBlockPlugin>[];
    final inline = <CcInlinePlugin>[];
    final seen = <String>{};
    for (final p in plugins) {
      if (!seen.add(p.id)) {
        throw ArgumentError('Duplicate plugin id: ${p.id}');
      }
      switch (p) {
        case final CcBlockPlugin b:
          block.add(b);
        case final CcInlinePlugin i:
          inline.add(i);
        default:
          throw ArgumentError(
            'Plugin ${p.id} must extend CcBlockPlugin or CcInlinePlugin',
          );
      }
    }
    block.sort((a, b) => b.priority.compareTo(a.priority));
    inline.sort((a, b) => b.priority.compareTo(a.priority));
    final triggers = <int, List<CcInlinePlugin>>{};
    for (final p in inline) {
      for (final unit in p.triggerCharacters.codeUnits) {
        (triggers[unit] ??= []).add(p);
      }
    }
    return CcPluginSet._(
      List.unmodifiable(block),
      List.unmodifiable(inline),
      Map.unmodifiable(triggers),
    );
  }

  const CcPluginSet._(this.blockPlugins, this.inlinePlugins, this._triggers);

  /// The empty set (identity-stable const).
  static const CcPluginSet empty = CcPluginSet._(
    [],
    [],
    <int, List<CcInlinePlugin>>{},
  );

  /// Block plugins, priority-sorted descending.
  final List<CcBlockPlugin> blockPlugins;

  /// Inline plugins, priority-sorted descending.
  final List<CcInlinePlugin> inlinePlugins;

  final Map<int, List<CcInlinePlugin>> _triggers;

  /// Inline plugins triggered by code unit [unit], priority-sorted, or null.
  List<CcInlinePlugin>? inlinePluginsFor(int unit) => _triggers[unit];

  /// A new set with [more] added (same dedup/sort rules).
  CcPluginSet withPlugins(Iterable<CcParserPlugin> more) =>
      CcPluginSet([...blockPlugins, ...inlinePlugins, ...more]);
}
