import 'package:cc_domain/features/code_mode/domain/entities/script_outline.dart';
import 'package:cc_domain/features/code_mode/domain/services/script_identifiers.dart';
import 'package:collection/collection.dart';

/// One call a script made, as [buildScriptRunView] takes it.
final class ScriptRunCall<T> {
  /// Creates a call.
  const ScriptRunCall({
    required this.payload,
    required this.toolName,
    required this.line,
    required this.column,
    required this.running,
    required this.failed,
    required this.startMs,
    required this.endMs,
  });

  /// What the caller shows for the call (its own row object).
  final T payload;

  /// The tool the call was made to, raw or in the script's identifier form,
  /// or null when unknown. It breaks ties when the site lies in more than one
  /// call: the runner reports the last token evaluated before the call, which
  /// can sit inside a call in its arguments.
  final String? toolName;

  /// The 1-based line of the script the call was made from, or null when
  /// the runner did not say.
  final int? line;

  /// The 1-based column on [line], or null.
  final int? column;

  /// Whether the call is still running.
  final bool running;

  /// Whether the call ended in an error the script received (it failed, was
  /// denied or was cancelled), so code waiting on it did not go on.
  final bool failed;

  /// When the call started, in milliseconds on a clock shared by the
  /// script's calls, or null when not known.
  final int? startMs;

  /// When the call ended on the same clock, or null while it runs or when
  /// not known.
  final int? endMs;
}

/// Where one row or group of a [ScriptRunView] stands.
enum ScriptStepState {
  /// Not reached yet; the script is still running and may get here.
  queued,

  /// A call is running.
  running,

  /// Calls were made and none is running now. For a group this says
  /// nothing about whether more will come.
  done,

  /// Not reached, and it will not be: another arm was taken, code after it
  /// already ran, or the script has ended.
  skipped,

  /// A call node with no call of its own whose call, if made, could not be
  /// told from another's: it shares the position the runner reported for
  /// calls of the same tool (or of a computed one) nested in each other's
  /// arguments, or it holds such a node with calls. It is neither queued
  /// nor skipped.
  unknown,
}

/// How many rows under a node are in each [ScriptStepState].
final class ScriptRunCounts {
  /// Creates counts.
  const ScriptRunCounts({
    this.queued = 0,
    this.running = 0,
    this.done = 0,
    this.skipped = 0,
    this.unknown = 0,
  });

  /// No rows.
  static const ScriptRunCounts zero = ScriptRunCounts();

  /// Rows not reached yet.
  final int queued;

  /// Calls running.
  final int running;

  /// Calls made and finished. How each ended (completed, failed, denied) is
  /// in the payload, which this type does not read.
  final int done;

  /// Rows that will not be reached.
  final int skipped;

  /// Rows whose call may or may not have been made
  /// ([ScriptStepState.unknown]).
  final int unknown;

  /// Calls made: [running] and [done].
  int get made => running + done;

  /// Every row.
  int get total => queued + running + done + skipped + unknown;

  /// The sum of two counts.
  ScriptRunCounts operator +(ScriptRunCounts other) => ScriptRunCounts(
    queued: queued + other.queued,
    running: running + other.running,
    done: done + other.done,
    skipped: skipped + other.skipped,
    unknown: unknown + other.unknown,
  );

  ScriptRunCounts _plus(ScriptStepState state) => switch (state) {
    ScriptStepState.queued => this + const ScriptRunCounts(queued: 1),
    ScriptStepState.running => this + const ScriptRunCounts(running: 1),
    ScriptStepState.done => this + const ScriptRunCounts(done: 1),
    ScriptStepState.skipped => this + const ScriptRunCounts(skipped: 1),
    ScriptStepState.unknown => this + const ScriptRunCounts(unknown: 1),
  };

  @override
  bool operator ==(Object other) =>
      other is ScriptRunCounts &&
      other.queued == queued &&
      other.running == running &&
      other.done == done &&
      other.skipped == skipped &&
      other.unknown == unknown;

  @override
  int get hashCode => Object.hash(queued, running, done, skipped, unknown);

  @override
  String toString() =>
      'ScriptRunCounts(queued: $queued, running: $running, done: $done, '
      'skipped: $skipped, unknown: $unknown)';
}

/// A row or a group of a [ScriptRunView].
sealed class ScriptRunNode<T> {
  const ScriptRunNode({required this.key, required this.state});

  /// Stable while calls arrive, unique in the view: `n<id>` for a group, a
  /// queued or skipped row, and the first call made at a call node (`<id>`
  /// being the outline node's id); `c<index>` for any other call (`<index>`
  /// being its position in the calls passed in).
  final String key;

  /// Where it stands.
  final ScriptStepState state;
}

/// One row: a call that was made, or a call node not reached.
final class ScriptRunRow<T> extends ScriptRunNode<T> {
  /// Creates a row.
  const ScriptRunRow({
    required super.key,
    required super.state,
    required this.callIndex,
    required this.payload,
    required this.site,
    this.arm,
    this.startsIteration = false,
  });

  /// The call's position in the calls passed to [buildScriptRunView], or
  /// null for a row no call has reached ([ScriptStepState.queued] or
  /// [ScriptStepState.skipped]).
  final int? callIndex;

  /// The call's payload; null when [callIndex] is.
  final T? payload;

  /// The call node the call was made from, or the node this row stands for.
  /// Null for a call that could not be placed in the outline. Its
  /// [ScriptCallNode.toolName] and [ScriptCallNode.argumentText] caption a
  /// queued row.
  final ScriptCallNode? site;

  /// For a call made inside a repeating group: the innermost branch arm the
  /// call sits in, under that group. Null otherwise.
  final ScriptArmNode? arm;

  /// Whether this call is known to start a new iteration of the group it is
  /// listed under ([ScriptRunGroup.marksIterations]). False also when that
  /// cannot be told: rows between two marks are not known to share an
  /// iteration.
  final bool startsIteration;

  /// Whether a call was made: the row has a payload.
  bool get made => callIndex != null;

  @override
  bool operator ==(Object other) =>
      other is ScriptRunRow<T> &&
      other.key == key &&
      other.state == state &&
      other.callIndex == callIndex &&
      other.payload == payload &&
      other.site == site &&
      other.arm == arm &&
      other.startsIteration == startsIteration;

  @override
  int get hashCode => Object.hash(
    key,
    state,
    callIndex,
    payload,
    site?.id,
    arm?.id,
    startsIteration,
  );
}

/// A header with rows and groups under it: a loop, an each, a parallel
/// combinator, a function, a branch or one of its arms.
final class ScriptRunGroup<T> extends ScriptRunNode<T> {
  /// Creates a group.
  ScriptRunGroup({
    required super.key,
    required super.state,
    required this.node,
    required List<ScriptRunNode<T>> children,
    required this.counts,
    this.marksIterations = false,
    this.iterations = 0,
  }) : children = List.unmodifiable(children);

  /// The outline node: its kind, label and condition head the group.
  final ScriptOutlineNode node;

  /// What is under the header. Under a repeating node before any of its
  /// calls was made, its static contents (queued or skipped rows and nested
  /// groups); from its first call on, its calls in the order made.
  final List<ScriptRunNode<T>> children;

  /// The rows under this group, all levels down, by state.
  final ScriptRunCounts counts;

  /// Whether some rows say where an iteration starts. A loop's calls get
  /// marks unless the loop is under a `Promise` combinator; an each's only
  /// when its function is not `async` and it is not under a combinator; a
  /// function's never. Only calls in the group's own body are marked (not
  /// those in a nested loop, each or function, nor in a loop's header). False
  /// means iterations cannot be told apart, not that there was one.
  final bool marksIterations;

  /// The iterations told apart so far: at least this many ran. Zero when not
  /// [marksIterations].
  final int iterations;

  /// The payloads of the calls made under this group, all levels down, in
  /// tree order.
  List<T> get payloads {
    final out = <T>[];
    void collect(List<ScriptRunNode<T>> nodes) {
      for (final node in nodes) {
        switch (node) {
          case ScriptRunRow<T>(made: true):
            out.add(node.payload as T);
          case ScriptRunRow<T>():
            break;
          case ScriptRunGroup<T>():
            collect(node.children);
        }
      }
    }

    collect(children);
    return out;
  }

  @override
  bool operator ==(Object other) =>
      other is ScriptRunGroup<T> &&
      other.key == key &&
      other.state == state &&
      other.node == node &&
      other.counts == counts &&
      other.marksIterations == marksIterations &&
      other.iterations == iterations &&
      ListEquality<ScriptRunNode<T>>().equals(other.children, children);

  @override
  int get hashCode => Object.hash(
    key,
    state,
    node.id,
    counts,
    marksIterations,
    iterations,
    ListEquality<ScriptRunNode<T>>().hash(children),
  );
}

/// A script's outline with what has happened so far: data a widget renders
/// without reading the outline again.
final class ScriptRunView<T> {
  /// Creates a view.
  ScriptRunView({
    required this.parsed,
    required List<ScriptRunNode<T>> nodes,
    required List<ScriptRunRow<T>> unattached,
    required this.counts,
  }) : nodes = List.unmodifiable(nodes),
       unattached = List.unmodifiable(unattached);

  /// Whether the script's outline was parsed. When not, [nodes] is empty and
  /// every call is in [unattached].
  final bool parsed;

  /// The tree, top level in source order.
  final List<ScriptRunNode<T>> nodes;

  /// The calls that could not be placed in the tree, in the order made,
  /// listed after it.
  final List<ScriptRunRow<T>> unattached;

  /// Every row, by state.
  final ScriptRunCounts counts;

  @override
  bool operator ==(Object other) =>
      other is ScriptRunView<T> &&
      other.parsed == parsed &&
      other.counts == counts &&
      ListEquality<ScriptRunNode<T>>().equals(other.nodes, nodes) &&
      ListEquality<ScriptRunRow<T>>().equals(other.unattached, unattached);

  @override
  int get hashCode => Object.hash(
    parsed,
    counts,
    ListEquality<ScriptRunNode<T>>().hash(nodes),
    ListEquality<ScriptRunRow<T>>().hash(unattached),
  );
}

/// Lays [calls] over [outline].
///
/// A call is placed at a call node whose span contains its site; otherwise
/// at the only call node that starts on its line; otherwise at the call node
/// on its line whose start column is nearest; otherwise nowhere, and it is
/// listed in [ScriptRunView.unattached]. At each step, nodes whose static
/// name is the call's [ScriptRunCall.toolName] are preferred, then nodes
/// with a computed name, then any: the runner reports the last token
/// evaluated before a call, which can lie inside a call in its arguments.
/// Columns are never matched exactly: the runner's column unit can differ
/// from UTF-16 on a line with non-ASCII text.
///
/// Several nodes containing one site that are named the call's tool or
/// have a computed name form a chain of calls nested in each other's
/// arguments (`tools.a({ v: await tools.a({ q: x }) })`), for which the
/// runner reports one site, inner call first. [calls] are in the order the
/// script made them, and the calls at a chain go to its nodes from the
/// inside out in that order: a call goes to the innermost, or to the node
/// around the one the previous call there went to. It goes back to the
/// innermost after the previous call failed before this one started (an
/// outer call is not made when a call it waits on fails), or when there is
/// no node further out. Whether a call is running does not move it. Any of
/// the nodes of such a chain could own a call made there, so a node of it
/// left with no call is [ScriptStepState.unknown], never queued or skipped,
/// and so is a node left with no call that holds a node of its tool with
/// calls. Nodes with different static names never form a chain.
///
/// Outside repeating nodes (loops, eaches, functions), a call node shows its
/// calls, or one row that is queued until code after it in source order has
/// run (it was passed over) or the script has ended. A repeating node shows
/// its static contents until its first call, then its calls in the order
/// made. A branch shows a group per arm; once one arm of an exclusive branch
/// ran, the others are skipped. After the script has [ended], nothing is
/// queued.
ScriptRunView<T> buildScriptRunView<T>({
  required ScriptOutline outline,
  required List<ScriptRunCall<T>> calls,
  required bool ended,
}) => _ViewBuilder<T>(outline, calls, ended).build();

final class _ViewBuilder<T> {
  _ViewBuilder(this.outline, this.calls, this.ended)
    : _parent = List<ScriptOutlineNode?>.filled(outline.nodeCount, null),
      _owner = List<ScriptOutlineNode?>.filled(outline.nodeCount, null),
      _inFunction = List<bool>.filled(outline.nodeCount, false),
      _madeUnder = List<int>.filled(outline.nodeCount, 0);

  final ScriptOutline outline;
  final List<ScriptRunCall<T>> calls;
  final bool ended;

  final List<ScriptOutlineNode?> _parent;
  // For each node: its outermost repeating ancestor (or itself when it is
  // one and has none).
  final List<ScriptOutlineNode?> _owner;
  final List<bool> _inFunction;
  final List<int> _madeUnder;

  final List<ScriptCallNode?> _siteOf = [];
  final Map<int, List<int>> _madeAt = {};
  final Map<int, List<int>> _madeByOwner = {};
  // The latest source offset at which a call was made outside any function:
  // code before it that has not run was passed over.
  int _reached = -1;

  ScriptRunView<T> build() {
    if (outline.unparsed) {
      final rows = [for (var i = 0; i < calls.length; i++) _madeRow(i, null)];
      return ScriptRunView(
        parsed: false,
        nodes: const [],
        unattached: rows,
        counts: _sum(rows),
      );
    }
    _index();
    _attach();
    final nodes = _level(outline.nodes, skip: false, inParallel: false);
    final unattached = [
      for (var i = 0; i < calls.length; i++)
        if (_siteOf[i] == null) _madeRow(i, null),
    ];
    return ScriptRunView(
      parsed: true,
      nodes: nodes,
      unattached: unattached,
      counts: _sum(nodes) + _sum(unattached),
    );
  }

  void _index() {
    void visit(
      ScriptOutlineNode node,
      ScriptOutlineNode? parent,
      ScriptOutlineNode? owner,
      bool inFunction,
    ) {
      final ownerHere = owner ?? (node.repeats ? node : null);
      final functionHere = inFunction || node is ScriptFunctionNode;
      _parent[node.id] = parent;
      _owner[node.id] = ownerHere;
      _inFunction[node.id] = functionHere;
      for (final child in node.children) {
        visit(child, node, ownerHere, functionHere);
      }
    }

    for (final node in outline.nodes) {
      visit(node, null, null, false);
    }
  }

  void _attach() {
    final callNodes = outline.calls;
    final byLine = <int, List<ScriptCallNode>>{};
    for (final node in callNodes) {
      (byLine[node.span.start.line] ??= []).add(node);
    }
    final covering = _covering(callNodes);
    // Per site and tool: the nodes it can go to, innermost first, and the
    // calls made there so far with the depth each went to.
    final chains = <(int, int, String?), List<ScriptCallNode>>{};
    final lastAt = <(int, int, String?), (int, int)>{};

    // The nodes named [name] if any, else those with a computed name, else
    // all of [nodes].
    List<ScriptCallNode> preferNamed(List<ScriptCallNode> nodes, String? name) {
      if (name == null || nodes.length < 2) {
        return nodes;
      }
      final id = ScriptIdentifierMap.baseIdentifier(name);
      final named = [
        for (final node in nodes)
          if (node.toolName == name || node.toolName == id) node,
      ];
      if (named.isNotEmpty) {
        return named;
      }
      final computed = [
        for (final node in nodes)
          if (node.toolName == null) node,
      ];
      return computed.isNotEmpty ? computed : nodes;
    }

    // The nodes of [nodes] that could own a call of [name]: those named it
    // and those with a computed name; null when there are none.
    List<ScriptCallNode>? owners(List<ScriptCallNode> nodes, String? name) {
      if (name == null) {
        return nodes;
      }
      final id = ScriptIdentifierMap.baseIdentifier(name);
      final out = [
        for (final node in nodes)
          if (node.toolName == null ||
              node.toolName == name ||
              node.toolName == id)
            node,
      ];
      return out.isEmpty ? null : out;
    }

    List<ScriptCallNode> chain(int line, int column, String? name) {
      final containing = [
        for (final node in covering[line] ?? const <ScriptCallNode>[])
          if (node.span.contains(line, column)) node,
      ];
      if (containing.isNotEmpty) {
        final owning = owners(containing, name);
        // Nested in each other: the later a node starts, the deeper it is.
        final nodes = (owning ?? preferNamed(containing, name)).toList()
          ..sort((a, b) => b.span.start.offset.compareTo(a.span.start.offset));
        if (owning != null && nodes.length > 1) {
          _ambiguous.addAll([for (final node in nodes) node.id]);
        }
        return nodes;
      }
      final onLine = byLine[line];
      if (onLine == null) {
        return const [];
      }
      final candidates = preferNamed(onLine, name);
      if (candidates.length == 1) {
        return [candidates.single];
      }
      ScriptCallNode? best;
      for (final node in candidates) {
        if (best == null ||
            (node.span.start.column - column).abs() <
                (best.span.start.column - column).abs()) {
          best = node;
        }
      }
      return [?best];
    }

    for (var i = 0; i < calls.length; i++) {
      final call = calls[i];
      final line = call.line;
      ScriptCallNode? site;
      if (line != null) {
        final key = (line, call.column ?? 0, call.toolName);
        final nodes = chains.putIfAbsent(
          key,
          () => chain(line, call.column ?? 0, call.toolName),
        );
        if (nodes.isNotEmpty) {
          var depth = 0;
          if (lastAt[key] case (final previous, final previousDepth)
              when previousDepth + 1 < nodes.length &&
                  !_failedBefore(calls[previous], call)) {
            depth = previousDepth + 1;
          }
          lastAt[key] = (i, depth);
          site = nodes[depth];
        }
      }
      _siteOf.add(site);
      if (site == null) {
        continue;
      }
      (_madeAt[site.id] ??= []).add(i);
      final owner = _owner[site.id];
      if (owner != null) {
        (_madeByOwner[owner.id] ??= []).add(i);
      }
      if (!_inFunction[site.id] && site.span.start.offset > _reached) {
        _reached = site.span.start.offset;
      }
      for (ScriptOutlineNode? n = site; n != null; n = _parent[n.id]) {
        _madeUnder[n.id]++;
      }
    }
    _madeSites = [
      for (final node in callNodes)
        if (_madeAt.containsKey(node.id)) node,
    ]..sort((a, b) => a.span.start.offset.compareTo(b.span.start.offset));
  }

  /// For each line some call was made from, the call nodes whose span
  /// covers it. Calls nest only as deep as brackets do, so each line is
  /// covered by few nodes and this stays near the size of the outline.
  Map<int, List<ScriptCallNode>> _covering(List<ScriptCallNode> callNodes) {
    final lines = <int>{for (final call in calls) ?call.line}.toList()..sort();
    final out = <int, List<ScriptCallNode>>{};
    if (lines.isEmpty) {
      return out;
    }
    for (final node in callNodes) {
      final first = node.span.start.line;
      final last = node.span.end.line;
      var lo = 0;
      var hi = lines.length;
      while (lo < hi) {
        final mid = (lo + hi) >> 1;
        if (lines[mid] < first) {
          lo = mid + 1;
        } else {
          hi = mid;
        }
      }
      for (var k = lo; k < lines.length && lines[k] <= last; k++) {
        (out[lines[k]] ??= []).add(node);
      }
    }
    return out;
  }

  // Call nodes with calls, by start offset.
  List<ScriptCallNode> _madeSites = const [];

  // Ids of the call nodes of chains of more than one node that could own a
  // call made there.
  final Set<int> _ambiguous = {};

  /// Whether [previous] failed before [call] started, as far as the records
  /// tell: a call that started while [previous] ran was made before it
  /// failed.
  bool _failedBefore(ScriptRunCall<T> previous, ScriptRunCall<T> call) {
    if (!previous.failed) {
      return false;
    }
    final start = call.startMs;
    final end = previous.endMs;
    return start == null || end == null || start >= end;
  }

  /// Whether a call node of the same tool inside [node]'s arguments had
  /// calls made at it.
  bool _holdsMadeSameTool(ScriptCallNode node) {
    final start = node.span.start.offset;
    final end = node.span.end.offset;
    var lo = 0;
    var hi = _madeSites.length;
    while (lo < hi) {
      final mid = (lo + hi) >> 1;
      if (_madeSites[mid].span.start.offset <= start) {
        lo = mid + 1;
      } else {
        hi = mid;
      }
    }
    for (var k = lo; k < _madeSites.length; k++) {
      final inner = _madeSites[k];
      if (inner.span.start.offset >= end) {
        break;
      }
      if (inner.span.end.offset <= end &&
          (inner.toolName == node.toolName ||
              inner.toolName == null ||
              node.toolName == null)) {
        return true;
      }
    }
    return false;
  }

  /// The state of something not reached.
  ScriptStepState _pending(ScriptOutlineNode node, {required bool skip}) {
    if (ended || skip) {
      return ScriptStepState.skipped;
    }
    // A function can be called at any time, from anywhere.
    if (_inFunction[node.id]) {
      return ScriptStepState.queued;
    }
    return _reached >= node.span.end.offset
        ? ScriptStepState.skipped
        : ScriptStepState.queued;
  }

  List<ScriptRunNode<T>> _level(
    List<ScriptOutlineNode> nodes, {
    required bool skip,
    required bool inParallel,
  }) {
    final out = <ScriptRunNode<T>>[];
    for (final node in nodes) {
      switch (node) {
        case ScriptCallNode():
          final made = _madeAt[node.id];
          if (made == null) {
            final state = _pending(node, skip: skip);
            out.add(
              _pendingRow(
                node,
                _ambiguous.contains(node.id) ||
                        (state == ScriptStepState.skipped &&
                            _holdsMadeSameTool(node))
                    ? ScriptStepState.unknown
                    : state,
              ),
            );
          } else {
            for (final i in made) {
              out.add(_madeRow(i, node));
            }
          }
        case ScriptLoopNode() || ScriptEachNode() || ScriptFunctionNode():
          out.add(_repeating(node, skip: skip, inParallel: inParallel));
        case ScriptParallelNode():
          final children = _level(node.children, skip: skip, inParallel: true);
          out.add(_group(node, children, _pending(node, skip: skip)));
        case ScriptBranchNode():
          out.add(_branch(node, skip: skip, inParallel: inParallel));
        case ScriptArmNode():
          final children = _level(
            node.children,
            skip: skip,
            inParallel: inParallel,
          );
          out.add(_group(node, children, _pending(node, skip: skip)));
      }
    }
    return out;
  }

  ScriptRunGroup<T> _branch(
    ScriptBranchNode node, {
    required bool skip,
    required bool inParallel,
  }) {
    final taken =
        node.kind.exclusive && node.arms.any((arm) => _madeUnder[arm.id] > 0);
    final arms = <ScriptRunNode<T>>[
      for (final arm in node.arms)
        () {
          final skipArm = skip || (taken && _madeUnder[arm.id] == 0);
          final children = _level(
            arm.children,
            skip: skipArm,
            inParallel: inParallel,
          );
          return _group(arm, children, _pending(arm, skip: skipArm));
        }(),
    ];
    return _group(node, arms, _pending(node, skip: skip));
  }

  ScriptRunGroup<T> _repeating(
    ScriptOutlineNode node, {
    required bool skip,
    required bool inParallel,
  }) {
    final made = _madeByOwner[node.id];
    if (made == null) {
      final state = _pending(node, skip: skip);
      return _group(node, _static(node.children, state), state);
    }
    final marks =
        !inParallel &&
        (node is ScriptLoopNode || (node is ScriptEachNode && !node.isAsync));
    final rows = <ScriptRunNode<T>>[];
    var iterations = 0;
    ScriptCallNode? previous;
    for (final i in made) {
      final site = _siteOf[i]!;
      var starts = false;
      if (marks && _inOwnBody(site, node)) {
        if (previous == null || _startsAgain(site, previous)) {
          iterations++;
          starts = true;
        }
        previous = site;
      }
      rows.add(
        _madeRow(i, site, arm: _armBelow(site, node), startsIteration: starts),
      );
    }
    return _group(
      node,
      rows,
      _pending(node, skip: skip),
      marksIterations: iterations > 0,
      iterations: iterations,
    );
  }

  /// Whether [site] is in [owner]'s own body: not in a repeating node under
  /// it, and for a loop not in its header.
  bool _inOwnBody(ScriptCallNode site, ScriptOutlineNode owner) {
    for (var n = _parent[site.id]; n != null && n != owner; n = _parent[n.id]) {
      if (n.repeats) {
        return false;
      }
    }
    return owner is! ScriptLoopNode || owner.bodySpan.containsSpan(site.span);
  }

  /// Whether a call at [site] after one at [previous], both in one loop's
  /// own body, must be in a new iteration: within one pass through the body
  /// its calls are made in source order, except that a call in another
  /// call's arguments is made before that call.
  bool _startsAgain(ScriptCallNode site, ScriptCallNode previous) {
    // The same call again, or one in the previous call's arguments, which
    // ran before that call in this pass.
    if (previous.span.containsSpan(site.span)) {
      return true;
    }
    if (site.span.containsSpan(previous.span)) {
      return false;
    }
    return site.span.start.offset <= previous.span.start.offset;
  }

  ScriptArmNode? _armBelow(ScriptCallNode site, ScriptOutlineNode owner) {
    for (var n = _parent[site.id]; n != null && n != owner; n = _parent[n.id]) {
      if (n is ScriptArmNode) {
        return n;
      }
    }
    return null;
  }

  /// [nodes] as they stand before anything under them ran: rows and groups
  /// all in [state].
  List<ScriptRunNode<T>> _static(
    List<ScriptOutlineNode> nodes,
    ScriptStepState state,
  ) => [
    for (final node in nodes)
      if (node is ScriptCallNode)
        _pendingRow(node, state)
      else
        _group(node, _static(node.children, state), state),
  ];

  ScriptRunRow<T> _pendingRow(ScriptCallNode node, ScriptStepState state) =>
      ScriptRunRow<T>(
        key: 'n${node.id}',
        state: state,
        callIndex: null,
        payload: null,
        site: node,
      );

  ScriptRunRow<T> _madeRow(
    int i,
    ScriptCallNode? site, {
    ScriptArmNode? arm,
    bool startsIteration = false,
  }) {
    final first = site != null && _madeAt[site.id]!.first == i;
    return ScriptRunRow<T>(
      key: first ? 'n${site.id}' : 'c$i',
      state: calls[i].running ? ScriptStepState.running : ScriptStepState.done,
      callIndex: i,
      payload: calls[i].payload,
      site: site,
      arm: arm,
      startsIteration: startsIteration,
    );
  }

  ScriptRunGroup<T> _group(
    ScriptOutlineNode node,
    List<ScriptRunNode<T>> children,
    ScriptStepState whenEmpty, {
    bool marksIterations = false,
    int iterations = 0,
  }) {
    final counts = _sum(children);
    final state = counts.running > 0
        ? ScriptStepState.running
        : counts.done > 0
        ? ScriptStepState.done
        : counts.queued > 0
        ? ScriptStepState.queued
        : counts.skipped > 0
        ? ScriptStepState.skipped
        : counts.unknown > 0
        ? ScriptStepState.unknown
        : whenEmpty;
    return ScriptRunGroup<T>(
      key: 'n${node.id}',
      state: state,
      node: node,
      children: children,
      counts: counts,
      marksIterations: marksIterations,
      iterations: iterations,
    );
  }

  ScriptRunCounts _sum(List<ScriptRunNode<T>> nodes) {
    var counts = ScriptRunCounts.zero;
    for (final node in nodes) {
      counts = switch (node) {
        ScriptRunRow<T>() => counts._plus(node.state),
        ScriptRunGroup<T>() => counts + node.counts,
      };
    }
    return counts;
  }
}
