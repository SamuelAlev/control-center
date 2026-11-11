import 'package:control_center/features/sandboxing/presentation/terminal_panel.dart';
import 'package:control_center/features/sandboxing/presentation/terminal_session_controller.dart';
import 'package:control_center/features/sandboxing/providers/terminal_registry_provider.dart';
import 'package:control_center/features/sandboxing/providers/terminal_sessions_provider.dart';
import 'package:control_center/l10n/app_localizations.dart';
import 'package:control_center/shared/editor/editor_tab.dart';
import 'package:control_center/shared/editor/host/editor_layout_codec.dart';
import 'package:flutter/foundation.dart';

/// The terminal sessions the messaging IDE's ACTIVE layout hosts.
///
/// The controllers themselves live in the app-level [terminalRegistryProvider]
/// and SURVIVE layout swaps (space switches): this object only holds the
/// CLAIMS live tabs have on them. Dropping a claim detaches the view callbacks
/// but keeps the shell, its buffer and its subscriptions alive; a controller
/// dies only on tab close, shell exit, or the registry's LRU eviction.
///
/// Everything here is keyed by tab identity ([EditorTab] has no value
/// equality) and pruned by [reconcile] against the tabs still in the tree.
/// Notifies when what a terminal tab renders changes — a claim landing, a
/// live title, a deferred start — so the host can rebuild and republish the
/// sidebar's TERMINALS mirror ([mirrorsFor]).
class IdeTerminalSessions extends ChangeNotifier {
  /// Creates the sessions over the app's terminal registry.
  IdeTerminalSessions({required this._registry, required this._registryState});

  final TerminalRegistryNotifier Function() _registry;
  final TerminalRegistryState Function() _registryState;

  /// Terminal controllers claimed by live tabs of the active layout.
  final Map<EditorTab, TerminalSessionController> _claims = {};

  /// Tabs whose claim was begun ([beginClaim]) and has not landed yet.
  final Set<EditorTab> _claiming = {};

  /// Terminal tabs whose shell the user chose to KEEP when closing them (the
  /// prompt only appears while a command is running). Read — and cleared — by
  /// the [reconcile] that follows the close, which then detaches the session
  /// instead of killing it.
  final Set<EditorTab> _kept = Set<EditorTab>.identity();

  /// Restored enclosed-VM terminal tabs the user has since pressed Start on.
  ///
  /// Session-lived on purpose: the deferral is a property of the RESTORE, so
  /// the next launch must defer again rather than remember a press from
  /// yesterday.
  final Set<EditorTab> _startedDeferred = {};

  /// Live shell titles per terminal tab (OSC 0/2 from the PTY). Absent (or
  /// cleared on shell restart) falls back to the tab's own label.
  final Map<EditorTab, String> _titles = {};

  bool _disposed = false;

  /// The controller [tab] has claimed, or null while it has none.
  TerminalSessionController? controllerFor(EditorTab tab) => _claims[tab];

  /// The session ids live tabs claim — the registry's eviction-protected set.
  Set<String> get claimedSessionIds => {
    for (final c in _claims.values) c.session.sessionId,
  };

  /// Whether [tab] is a RESTORED enclosed terminal still waiting for a press.
  ///
  /// Such a tab boots a VM the moment it attaches, so it waits — the same
  /// rule the rig tabs follow. The flag rides the persisted layout
  /// ([EditorLayoutCodec.deferStartArg]); the press is remembered only for
  /// this session.
  bool awaitsStart(EditorTab tab) =>
      tab.args[EditorLayoutCodec.deferStartArg] == true &&
      !_startedDeferred.contains(tab);

  /// Records the Start press on a deferred [tab].
  void start(EditorTab tab) {
    if (_startedDeferred.add(tab)) {
      _notify();
    }
  }

  /// Begins claiming a session for [tab]: true exactly once per unclaimed,
  /// startable tab that names its session, so the caller schedules one
  /// [completeClaim].
  bool beginClaim(EditorTab tab) =>
      tab.args['termSessionId'] is String &&
      !_claims.containsKey(tab) &&
      !awaitsStart(tab) &&
      _claiming.add(tab);

  /// Lands the claim [beginClaim] started for [tab] in [spaceId].
  ///
  /// The tab carries its session id in args (minted at tab creation and
  /// round-tripped through the persisted layout), so a tab restored after a
  /// space switch re-claims its kept session — shell, buffer and
  /// subscriptions intact.
  ///
  /// [stillOpen] false (the tab closed while the claim was deferred) kills
  /// the session instead. [onShellExit] is told when the claimed shell exits.
  /// Returns the claimed controller, or null when nothing was claimed.
  TerminalSessionController? completeClaim(
    EditorTab tab, {
    required String spaceId,
    required String workspaceId,
    required bool stillOpen,
    required void Function(String sessionId) onShellExit,
  }) {
    final sessionId = tab.args['termSessionId']! as String;
    // The terminal opens at the conversation root (`conversations/<spaceId>`),
    // resolved from the space id by the view/server. The session id stays
    // unique per tab so each terminal gets its own sandbox session.
    final session = TerminalSession(
      sessionId: sessionId,
      spaceId: spaceId,
      workspaceId: workspaceId,
      backend: tab.args['backend'] as String?,
      attachSessionId: tab.args['attachSessionId'] as String?,
    );
    final registry = _registry();
    final controller = registry.obtain(session);
    final initialInput = tab.args['initialInput'] as String?;
    if (initialInput != null) {
      controller.typeOnceReady(initialInput);
    }
    if (!stillOpen) {
      registry.kill(session.sessionId);
      _claiming.remove(tab);
      return null;
    }
    controller
      ..onTitleChange = ((title) => setTitle(tab, title))
      ..onShellExit = (() => onShellExit(session.sessionId));
    _claims[tab] = controller;
    _claiming.remove(tab);
    // Restore the label for a re-claimed kept session.
    _applyTitle(tab, controller.title);
    _notify();
    return controller;
  }

  /// Records [tab]'s live shell [title] (empty clears it).
  void setTitle(EditorTab tab, String title) {
    if (!_disposed && _applyTitle(tab, title)) {
      _notify();
    }
  }

  bool _applyTitle(EditorTab tab, String title) {
    final next = title.trim();
    final prev = _titles[tab];
    if (next.isEmpty ? prev == null : prev == next) {
      return false;
    }
    if (next.isEmpty) {
      _titles.remove(tab);
    } else {
      _titles[tab] = next;
    }
    return true;
  }

  /// Keeps [tab]'s shell running once the tab closes (the close prompt's
  /// "keep running" answer).
  void keepShell(EditorTab tab) => _kept.add(tab);

  /// Drops pending keep decisions: on a layout swap the tabs leave the tree
  /// with the layout, which is not a close, so nothing will read them.
  void forgetKeptShells() => _kept.clear();

  /// Prunes every claim and per-tab state for tabs no longer in [live].
  ///
  /// [killOrphaned] says WHY a tab left the tree: `true` (a change within the
  /// live layout — the user closed the tab) kills its shell, unless the user
  /// chose to keep it; `false` (a seed/switch/restore layout swap) detaches the
  /// view callbacks and KEEPS the session alive in the registry so switching
  /// back re-claims it with scrollback intact. A shell that exits while
  /// detached is killed — there is no tab to close.
  void reconcile(Set<EditorTab> live, {required bool killOrphaned}) {
    final registry = _registry();
    _claims.removeWhere((tab, controller) {
      if (live.contains(tab)) {
        return false;
      }
      if (killOrphaned && !_kept.remove(tab)) {
        registry.kill(controller.session.sessionId);
      } else {
        controller
          ..onTitleChange = null
          ..onShellExit = () => _registry().kill(controller.session.sessionId);
      }
      return true;
    });
    _titles.removeWhere((tab, _) => !live.contains(tab));
    _claiming.removeWhere((tab) => !live.contains(tab));
    _startedDeferred.removeWhere((tab) => !live.contains(tab));
  }

  /// The TERMINALS mirror for [spaceId]: the claimed shells, then this
  /// space's shells with NO tab — the ones kept running when their tab was
  /// closed. That row is the only way back to them.
  List<TerminalMirror> mirrorsFor(String spaceId) {
    final claimed = claimedSessionIds;
    return [
      for (final c in _claims.values)
        if (c.session.spaceId == spaceId)
          TerminalMirror(session: c.session, title: c.title),
      for (final c in _registryState().controllers.values)
        if (c.session.spaceId == spaceId &&
            !claimed.contains(c.session.sessionId))
          TerminalMirror(session: c.session, title: c.title),
    ];
  }

  /// The tab whose claim shows session [sessionId], if any.
  EditorTab? tabShowing(String sessionId) {
    for (final entry in _claims.entries) {
      if (entry.value.session.sessionId == sessionId) {
        return entry.key;
      }
    }
    return null;
  }

  /// The kept (registry-held) session [sessionId], if it is still alive.
  TerminalSession? keptSession(String sessionId) =>
      _registryState().controllers[sessionId]?.session;

  /// Ends the shell [sessionId] — a TERMINALS row's trash. A shell with a tab
  /// is returned for the caller to close (the [reconcile] then kills it, as
  /// the tab's own × would after "End shell"); a shell with no tab is killed
  /// in the registry directly.
  EditorTab? end(String sessionId) {
    final tab = tabShowing(sessionId);
    if (tab != null) {
      _kept.remove(tab);
      return tab;
    }
    _registry().kill(sessionId);
    return null;
  }

  /// A claimed shell exited: returns its tab for the caller to close, or —
  /// when no tab claims it (its space is hidden) — kills it in the registry.
  EditorTab? shellExited(String sessionId) {
    final tab = tabShowing(sessionId);
    if (tab == null) {
      _registry().kill(sessionId);
    }
    return tab;
  }

  /// The display label for a terminal [tab]. A CLAIMED tab reads its live
  /// title; an UNCLAIMED tab — a restored layout whose body hasn't built yet —
  /// falls back to the kept controller's last title in the registry, so the
  /// custom name survives navigation even before the tab is opened again.
  String label(EditorTab tab, AppLocalizations l10n) {
    final live = _titles[tab];
    if (live != null) {
      return live;
    }
    final sessionId = tab.args['termSessionId'] as String?;
    final kept = sessionId == null
        ? null
        : _registryState().controllers[sessionId]?.title;
    if ((kept == null || kept.isEmpty) && tab.args['attachSessionId'] != null) {
      // An environment process keeps its name until it titles itself.
      return tab.label;
    }
    // A constant default (NOT tab.label): the persisted label is a
    // placeholder, never the shell's name.
    return (kept == null || kept.isEmpty) ? l10n.terminal : kept;
  }

  void _notify() {
    if (!_disposed) {
      notifyListeners();
    }
  }

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }
}
