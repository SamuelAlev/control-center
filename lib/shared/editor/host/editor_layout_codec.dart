import 'dart:convert';

import 'package:control_center/shared/editor/editor_layout_controller.dart';
import 'package:control_center/shared/editor/editor_layout_node.dart';
import 'package:control_center/shared/editor/editor_tab.dart';
import 'package:flutter/widgets.dart' show Axis, IconData;

/// Shared JSON codec for editor split trees (structure only).
///
/// Persists shape, weights, tab order — not focus (always first tab of first
/// leaf; `?tab=` is the only load-time override), not PTYs/webviews, not node
/// ids (minted on decode). Malformed → `null`. Constructor: [restorableKinds],
/// [dropOnEncode], [requiredStringArgs], [iconFor], [aliasKind],
/// [rewriteArgsOnDecode] (e.g. stamp [deferStartArg] so enclosed VMs restore as
/// affordances), [transientArgs] (never re-encoded).
class EditorLayoutCodec {
  /// Creates a codec bound to one host's tab vocabulary.
  const EditorLayoutCodec({
    required this.restorableKinds,
    required this.iconFor,
    this.dropOnEncode = const {},
    this.requiredStringArgs = const {},
    this.aliasKind,
    this.rewriteArgsOnDecode,
    this.transientArgs = const {},
  });

  /// Schema version of the persisted payload. Bumped only on a breaking change
  /// to the JSON shape; a mismatch decodes to `null` (fresh default).
  static const int schemaVersion = 1;

  /// Arg key meaning "this tab was RESTORED — render its start affordance
  /// rather than doing the expensive thing it does when a user opens it".
  ///
  /// Stamped by [rewriteArgsOnDecode] and listed in [transientArgs] so it is
  /// a property of the restore, never of the saved layout.
  static const String deferStartArg = 'deferStart';

  /// Kinds that survive a persist/restore round-trip.
  final Set<String> restorableKinds;

  /// Icon for a restored tab of the given kind.
  final IconData? Function(String kind) iconFor;

  /// Kinds never written on encode (transient / non-serialisable args).
  final Set<String> dropOnEncode;

  /// Per-kind required String args; a decoded tab missing any is dropped.
  final Map<String, List<String>> requiredStringArgs;

  /// Optional decode-time kind rewrite, applied before the whitelist check.
  final String Function(String kind)? aliasKind;

  /// Optional decode-time arg rewrite, applied after the required-arg check.
  final Map<String, Object?> Function(String kind, Map<String, Object?> args)?
  rewriteArgsOnDecode;

  /// Arg keys stripped on encode (flags a decode adds, never saved state).
  final Set<String> transientArgs;

  /// Serialises [controller]'s tree to a JSON string for the cache.
  String encode(EditorLayoutController controller) {
    return jsonEncode({
      'v': schemaVersion,
      'root': _encodeNode(controller.root),
    });
  }

  /// Rebuilds an [EditorLayoutController] from [json], or returns null when the
  /// payload is missing, malformed, an unknown schema version, or contains no
  /// restorable tabs.
  EditorLayoutController? decode(String json) {
    try {
      final data = jsonDecode(json);
      if (data is! Map || data['v'] != schemaVersion) {
        return null;
      }
      final counter = _IdCounter();
      final root = _decodeNode(data['root'], counter);
      if (root == null || _countTabs(root) == 0) {
        return null;
      }
      // Focus is never restored: the first leaf's first tab is where a restored
      // layout opens (each leaf decodes with `selectedIndex` 0).
      return EditorLayoutController.fromTree(
        root: root,
        activeLeafId: _firstLeafId(root),
        nextId: counter.value,
      );
    } catch (_) {
      return null;
    }
  }

  Map<String, Object?> _encodeNode(EditorNode node) {
    if (node is EditorLeafNode) {
      final kept = <Map<String, Object?>>[];
      for (final tab in node.controller.tabs) {
        final encoded = _encodeTab(tab);
        if (encoded != null) {
          kept.add(encoded);
        }
      }
      // Neither the selected tab nor the active leaf is written: a restore
      // always opens on the first tab (see the class doc).
      return {'t': 'leaf', 'tabs': kept};
    }
    final split = node as EditorSplitNode;
    return {
      't': 'split',
      'axis': split.axis == Axis.horizontal ? 'h' : 'v',
      'weights': split.weights,
      'children': [for (final c in split.children) _encodeNode(c)],
    };
  }

  /// Encodes a tab, or returns null when it is not safely serialisable (a
  /// [dropOnEncode] kind, or an unexpected non-primitive arg value).
  Map<String, Object?>? _encodeTab(EditorTab tab) {
    if (dropOnEncode.contains(tab.kind)) {
      return null;
    }
    final args = <String, Object?>{};
    for (final entry in tab.args.entries) {
      if (transientArgs.contains(entry.key)) {
        continue;
      }
      final v = entry.value;
      if (v == null || v is String || v is num || v is bool) {
        args[entry.key] = v;
      } else {
        // A non-primitive arg on a kind we thought was serialisable — drop the
        // whole tab rather than persist a value we cannot restore.
        return null;
      }
    }
    return {
      'kind': tab.kind,
      'label': tab.label,
      'args': args,
      if (tab.dedupKey != null) 'dedup': tab.dedupKey,
    };
  }

  EditorNode? _decodeNode(Object? raw, _IdCounter counter) {
    if (raw is! Map) {
      return null;
    }
    final type = raw['t'];
    if (type == 'leaf') {
      final controller = EditorTabGroupController();
      final tabsRaw = raw['tabs'];
      if (tabsRaw is List) {
        for (final t in tabsRaw) {
          final tab = _decodeTab(t);
          if (tab != null) {
            controller.insert(controller.tabs.length, tab);
          }
        }
      }
      // Every leaf comes back on its first tab. The reset is explicit because
      // `insert` selects what it inserts, so a populated group would otherwise
      // sit on the LAST decoded tab.
      controller.selectedIndex = 0;
      return EditorLeafNode(
        id: 'leaf-${counter.next()}',
        controller: controller,
      );
    }
    if (type == 'split') {
      final childrenRaw = raw['children'];
      if (childrenRaw is! List || childrenRaw.isEmpty) {
        return null;
      }
      final axis = raw['axis'] == 'v' ? Axis.vertical : Axis.horizontal;
      final weightsRaw = raw['weights'];
      final children = <EditorNode>[];
      final weights = <double>[];
      for (var i = 0; i < childrenRaw.length; i++) {
        final node = _decodeNode(childrenRaw[i], counter);
        if (node == null) {
          continue;
        }
        children.add(node);
        final w =
            (weightsRaw is List &&
                i < weightsRaw.length &&
                weightsRaw[i] is num)
            ? (weightsRaw[i] as num).toDouble()
            : 1.0;
        weights.add(w <= 0 ? 0 : w);
      }
      if (children.isEmpty) {
        return null;
      }
      // A split that decoded down to one child collapses to that child.
      if (children.length == 1) {
        return children.first;
      }
      return EditorSplitNode(
        id: 'split-${counter.next()}',
        axis: axis,
        children: children,
        weights: _normalize(weights),
      );
    }
    return null;
  }

  EditorTab? _decodeTab(Object? raw) {
    if (raw is! Map) {
      return null;
    }
    final rawKind = raw['kind'];
    final label = raw['label'];
    if (rawKind is! String || label is! String) {
      return null;
    }
    final kind = aliasKind?.call(rawKind) ?? rawKind;
    // Unknown kinds (a future/foreign kind, or a non-restorable transient) are
    // skipped.
    if (!restorableKinds.contains(kind)) {
      return null;
    }
    final args = <String, Object?>{};
    final argsRaw = raw['args'];
    if (argsRaw is Map) {
      argsRaw.forEach((k, v) {
        if (k is String) {
          args[k] = v;
        }
      });
    }
    // Reject tabs whose required args are missing — they would throw on render.
    final required = requiredStringArgs[kind];
    if (required != null) {
      for (final key in required) {
        if (args[key] is! String) {
          return null;
        }
      }
    }
    final dedup = raw['dedup'];
    return EditorTab(
      kind: kind,
      label: label,
      args: rewriteArgsOnDecode?.call(kind, args) ?? args,
      icon: iconFor(kind),
      dedupKey: dedup is String ? dedup : null,
    );
  }

  int _countTabs(EditorNode node) {
    if (node is EditorLeafNode) {
      return node.controller.tabs.length;
    }
    final split = node as EditorSplitNode;
    return split.children.fold(0, (sum, c) => sum + _countTabs(c));
  }

  String _firstLeafId(EditorNode node) {
    if (node is EditorLeafNode) {
      return node.id;
    }
    return _firstLeafId((node as EditorSplitNode).children.first);
  }

  List<double> _normalize(List<double> w) {
    final sum = w.fold<double>(0, (a, b) => a + b);
    if (sum <= 0) {
      return List.filled(w.length, 1 / w.length);
    }
    return [for (final x in w) x / sum];
  }
}

/// Mints sequential numeric suffixes for fresh node ids during decode.
class _IdCounter {
  int value = 0;
  int next() => value++;
}
