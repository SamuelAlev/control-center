import 'package:control_center/core/keybindings/key_stroke.dart';
import 'package:control_center/l10n/app_localizations.dart';
import 'package:flutter/services.dart';

/// Categories used to group shortcuts in the keybindings settings page.
enum KeybindingCategory {
  navigation,
  system,
  creation,
  editing,
  deletion,
  view,
}

/// A single keyboard shortcut definition.
///
/// A binding maps a [chord] (one or more [KeyStroke]s) to a command [id]. The
/// optional [when] clause — a VS Code-style boolean expression over context
/// keys such as `route` and `textInputFocus` — gates when the binding is live.
/// [scope] is `'global'` or a route path (e.g. `/dashboard`); it drives the
/// settings-page grouping and the dispatcher's "most specific wins" priority.
class Keybinding {
  /// Creates a [Keybinding] from an explicit [chord].
  const Keybinding({
    required this.id,
    required this.category,
    required this.scope,
    required this.chord,
    this.when,
  });

  /// Creates a single-stroke [Keybinding] (the common case).
  factory Keybinding.key({
    required String id,
    required KeybindingCategory category,
    required String scope,
    required LogicalKeyboardKey key,
    bool cmd = false,
    bool ctrl = false,
    bool shift = false,
    bool alt = false,
    String? when,
  }) =>
      Keybinding(
        id: id,
        category: category,
        scope: scope,
        chord: KeyChord([
          KeyStroke(key, cmd: cmd, ctrl: ctrl, shift: shift, alt: alt),
        ]),
        when: when,
      );

  /// Unique stable identifier, e.g. `nav.dashboard`.
  final String id;

  /// Grouping category for the settings page.
  final KeybindingCategory category;

  /// `'global'` or a route path (e.g. `/dashboard`).
  final String scope;

  /// The key sequence that triggers this binding.
  final KeyChord chord;

  /// Optional VS Code-style `when` clause. `null`/empty means always-on
  /// (subject to the command having a registered handler).
  final String? when;

  /// The primary trigger key (first stroke). Convenience for display widgets.
  LogicalKeyboardKey get key => chord.first.trigger;

  /// Whether the first stroke uses the primary command modifier (⌘/Ctrl).
  bool get meta => chord.first.cmd;

  /// Whether the first stroke uses the literal Control modifier.
  bool get control => chord.first.ctrl;

  /// Whether the first stroke uses Shift.
  bool get shift => chord.first.shift;

  /// Whether the first stroke uses Option / Alt.
  bool get alt => chord.first.alt;

  /// A platform-aware label such as `⌘⇧T` or `Ctrl+Shift+T`.
  String displayLabel(TargetPlatform platform) => chord.displayLabel(platform);
}

/// Central registry of all keyboard shortcuts.
///
/// The `KeybindingDispatcher` reads [all] and keeps the live hotkey set in
/// sync with the bindings whose command has a handler and whose
/// [Keybinding.when] holds.
abstract final class KeybindingRegistry {
  KeybindingRegistry._();

  /// The scope value for application-wide shortcuts.
  static const String globalScope = 'global';

  // `when` fragments shared across screen-scoped bindings. The `route ==`
  // guard keeps a screen's bare-key shortcuts from firing while a child route
  // (which keeps the parent page mounted, e.g. PR detail over the list) is
  // active; `!textInputFocus` lets the same keys be typed into text fields.
  static const String _prList = "route == '/pull-requests' && !textInputFocus";
  static const String _notTyping = '!textInputFocus';
  // Any `/users/<login>` profile page. Regex (not `==`) because the login is
  // part of the location; `!textInputFocus` lets the same keys be typed into
  // the profile's search field.
  static const String _userProfile = r'route =~ /^\/users\// && !textInputFocus';

  // ── Navigation (global) ────────────────────────────────────────────────

  static final List<Keybinding> navigation = [
    Keybinding.key(
      id: 'nav.dashboard',
      category: KeybindingCategory.navigation,
      scope: globalScope,
      key: LogicalKeyboardKey.digit1,
      cmd: true,
    ),
    Keybinding.key(
      id: 'nav.tickets',
      category: KeybindingCategory.navigation,
      scope: globalScope,
      key: LogicalKeyboardKey.digit2,
      cmd: true,
    ),
    Keybinding.key(
      id: 'nav.pull-requests',
      category: KeybindingCategory.navigation,
      scope: globalScope,
      key: LogicalKeyboardKey.digit3,
      cmd: true,
    ),
    Keybinding.key(
      id: 'nav.pipelines',
      category: KeybindingCategory.navigation,
      scope: globalScope,
      key: LogicalKeyboardKey.digit4,
      cmd: true,
    ),
    Keybinding.key(
      id: 'nav.agents',
      category: KeybindingCategory.navigation,
      scope: globalScope,
      key: LogicalKeyboardKey.digit5,
      cmd: true,
    ),
    Keybinding.key(
      id: 'nav.analytics',
      category: KeybindingCategory.navigation,
      scope: globalScope,
      key: LogicalKeyboardKey.digit6,
      cmd: true,
    ),
    Keybinding.key(
      id: 'nav.memory',
      category: KeybindingCategory.navigation,
      scope: globalScope,
      key: LogicalKeyboardKey.digit7,
      cmd: true,
    ),
    Keybinding.key(
      id: 'nav.newsfeed',
      category: KeybindingCategory.navigation,
      scope: globalScope,
      key: LogicalKeyboardKey.digit8,
      cmd: true,
    ),
  ];

  // ── System (global) ──────────────────────────────────────────────────

  static final List<Keybinding>system = [
    Keybinding.key(
      id: 'sys.command-palette',
      category: KeybindingCategory.system,
      scope: globalScope,
      key: LogicalKeyboardKey.keyK,
      cmd: true,
    ),
    Keybinding.key(
      id: 'sys.toggle-theme',
      category: KeybindingCategory.system,
      scope: globalScope,
      key: LogicalKeyboardKey.keyT,
      cmd: true,
      shift: true,
    ),
    Keybinding.key(
      id: 'sys.settings',
      category: KeybindingCategory.system,
      scope: globalScope,
      key: LogicalKeyboardKey.comma,
      cmd: true,
    ),
    Keybinding.key(
      id: 'sys.focus-mode',
      category: KeybindingCategory.system,
      scope: globalScope,
      key: LogicalKeyboardKey.keyF,
      cmd: true,
      shift: true,
      alt: true,
    ),
    Keybinding.key(
      id: 'sys.workspace-switcher',
      category: KeybindingCategory.navigation,
      scope: globalScope,
      key: LogicalKeyboardKey.keyW,
      cmd: true,
      shift: true,
    ),
    Keybinding.key(
      id: 'sys.workspace-next',
      category: KeybindingCategory.navigation,
      scope: globalScope,
      key: LogicalKeyboardKey.bracketRight,
      cmd: true,
    ),
    Keybinding.key(
      id: 'sys.workspace-prev',
      category: KeybindingCategory.navigation,
      scope: globalScope,
      key: LogicalKeyboardKey.bracketLeft,
      cmd: true,
    ),
    Keybinding.key(
      id: 'sys.workspace-1',
      category: KeybindingCategory.navigation,
      scope: globalScope,
      key: LogicalKeyboardKey.digit1,
      cmd: true,
      alt: true,
    ),
    Keybinding.key(
      id: 'sys.workspace-2',
      category: KeybindingCategory.navigation,
      scope: globalScope,
      key: LogicalKeyboardKey.digit2,
      cmd: true,
      alt: true,
    ),
    Keybinding.key(
      id: 'sys.workspace-3',
      category: KeybindingCategory.navigation,
      scope: globalScope,
      key: LogicalKeyboardKey.digit3,
      cmd: true,
      alt: true,
    ),
    Keybinding.key(
      id: 'sys.workspace-4',
      category: KeybindingCategory.navigation,
      scope: globalScope,
      key: LogicalKeyboardKey.digit4,
      cmd: true,
      alt: true,
    ),
    Keybinding.key(
      id: 'sys.workspace-5',
      category: KeybindingCategory.navigation,
      scope: globalScope,
      key: LogicalKeyboardKey.digit5,
      cmd: true,
      alt: true,
    ),
    Keybinding.key(
      id: 'sys.workspace-6',
      category: KeybindingCategory.navigation,
      scope: globalScope,
      key: LogicalKeyboardKey.digit6,
      cmd: true,
      alt: true,
    ),
    Keybinding.key(
      id: 'sys.workspace-7',
      category: KeybindingCategory.navigation,
      scope: globalScope,
      key: LogicalKeyboardKey.digit7,
      cmd: true,
      alt: true,
    ),
    Keybinding.key(
      id: 'sys.workspace-8',
      category: KeybindingCategory.navigation,
      scope: globalScope,
      key: LogicalKeyboardKey.digit8,
      cmd: true,
      alt: true,
    ),
    Keybinding.key(
      id: 'sys.workspace-9',
      category: KeybindingCategory.navigation,
      scope: globalScope,
      key: LogicalKeyboardKey.digit9,
      cmd: true,
      alt: true,
    ),
  ];

  // ── Dashboard ──────────────────────────────────────────────────────────

  static final List<Keybinding>dashboard = [
    Keybinding.key(
      id: 'dashboard.refresh',
      category: KeybindingCategory.view,
      scope: '/dashboard',
      key: LogicalKeyboardKey.keyR,
      when: "route == '/dashboard' && !textInputFocus",
    ),
  ];

  // ── Pull Requests ──────────────────────────────────────────────────────

  static final List<Keybinding>pullRequests = [
    Keybinding.key(
      id: 'pr.list-refresh',
      category: KeybindingCategory.view,
      scope: '/pull-requests',
      key: LogicalKeyboardKey.keyR,
      when: _prList,
    ),
    Keybinding.key(
      id: 'pr.list-prev',
      category: KeybindingCategory.navigation,
      scope: '/pull-requests',
      key: LogicalKeyboardKey.keyK,
      when: _prList,
    ),
    Keybinding.key(
      id: 'pr.list-next',
      category: KeybindingCategory.navigation,
      scope: '/pull-requests',
      key: LogicalKeyboardKey.keyJ,
      when: _prList,
    ),
    Keybinding.key(
      id: 'pr.list-open',
      category: KeybindingCategory.navigation,
      scope: '/pull-requests',
      key: LogicalKeyboardKey.enter,
      when: _prList,
    ),
    Keybinding.key(
      id: 'pr.list-select',
      category: KeybindingCategory.view,
      scope: '/pull-requests',
      key: LogicalKeyboardKey.keyX,
      when: _prList,
    ),
    Keybinding.key(
      id: 'pr.list-merge',
      category: KeybindingCategory.editing,
      scope: '/pull-requests',
      key: LogicalKeyboardKey.keyE,
      when: _prList,
    ),
    Keybinding.key(
      id: 'pr.list-peek',
      category: KeybindingCategory.view,
      scope: '/pull-requests',
      key: LogicalKeyboardKey.space,
      when: _prList,
    ),
    // Focus the queue search field. Two keys reach the same field: `/` (a
    // single tap, GitHub-style) and ⌘F/Ctrl+F. Ids are unique per binding here,
    // so the alternate gets its own id; the screen wires both to one handler.
    // The `!textInputFocus` guard (in `_prList`) lets `/` be typed into the
    // field once it already has focus.
    Keybinding.key(
      id: 'pr.list-focus-search',
      category: KeybindingCategory.view,
      scope: '/pull-requests',
      key: LogicalKeyboardKey.slash,
      when: _prList,
    ),
    Keybinding.key(
      id: 'pr.list-focus-search-alt',
      category: KeybindingCategory.view,
      scope: '/pull-requests',
      key: LogicalKeyboardKey.keyF,
      cmd: true,
      when: _prList,
    ),
    // Detail-screen bindings. The PR-detail page is the only one mounted on a
    // `/pull-requests/<n>` route, so handler-presence already scopes these;
    // they only need the text-input guard. Search/viewed/collapse are owned by
    // the diff view's own hardware-keyboard handler and listed here for the
    // settings reference only (no handler is registered, so the dispatcher
    // leaves them to the diff view).
    Keybinding.key(
      id: 'pr.detail-tab-conv',
      category: KeybindingCategory.view,
      scope: '/pull-requests/',
      key: LogicalKeyboardKey.digit1,
      when: _notTyping,
    ),
    Keybinding.key(
      id: 'pr.detail-tab-files',
      category: KeybindingCategory.view,
      scope: '/pull-requests/',
      key: LogicalKeyboardKey.digit2,
      when: _notTyping,
    ),
    Keybinding.key(
      id: 'pr.detail-search',
      category: KeybindingCategory.view,
      scope: '/pull-requests/',
      key: LogicalKeyboardKey.keyF,
      cmd: true,
      when: _notTyping,
    ),
    Keybinding.key(
      id: 'pr.detail-toggle-viewed',
      category: KeybindingCategory.editing,
      scope: '/pull-requests/',
      key: LogicalKeyboardKey.keyV,
      when: _notTyping,
    ),
    Keybinding.key(
      id: 'pr.detail-toggle-collapse',
      category: KeybindingCategory.view,
      scope: '/pull-requests/',
      key: LogicalKeyboardKey.keyC,
      when: _notTyping,
    ),
  ];

  // ── User profile ─────────────────────────────────────────────────────────

  /// The browse-only PR queue on a `/users/<login>` profile page: move / open /
  /// peek / search / refresh. No select or merge — profiles are read-only.
  static final List<Keybinding> userProfile = [
    Keybinding.key(
      id: 'pr.user-refresh',
      category: KeybindingCategory.view,
      scope: '/users/',
      key: LogicalKeyboardKey.keyR,
      when: _userProfile,
    ),
    Keybinding.key(
      id: 'pr.user-prev',
      category: KeybindingCategory.navigation,
      scope: '/users/',
      key: LogicalKeyboardKey.keyK,
      when: _userProfile,
    ),
    Keybinding.key(
      id: 'pr.user-next',
      category: KeybindingCategory.navigation,
      scope: '/users/',
      key: LogicalKeyboardKey.keyJ,
      when: _userProfile,
    ),
    Keybinding.key(
      id: 'pr.user-open',
      category: KeybindingCategory.navigation,
      scope: '/users/',
      key: LogicalKeyboardKey.enter,
      when: _userProfile,
    ),
    Keybinding.key(
      id: 'pr.user-peek',
      category: KeybindingCategory.view,
      scope: '/users/',
      key: LogicalKeyboardKey.space,
      when: _userProfile,
    ),
    // Focus the profile search field: `/` (GitHub-style single tap) and
    // ⌘F/Ctrl+F. The screen wires both ids to one handler.
    Keybinding.key(
      id: 'pr.user-focus-search',
      category: KeybindingCategory.view,
      scope: '/users/',
      key: LogicalKeyboardKey.slash,
      when: _userProfile,
    ),
    Keybinding.key(
      id: 'pr.user-focus-search-alt',
      category: KeybindingCategory.view,
      scope: '/users/',
      key: LogicalKeyboardKey.keyF,
      cmd: true,
      when: _userProfile,
    ),
  ];

  // ── Messaging ──────────────────────────────────────────────────────────

  static final List<Keybinding>messaging = [
    Keybinding.key(
      id: 'msg.new-dm',
      category: KeybindingCategory.creation,
      scope: '/messaging',
      key: LogicalKeyboardKey.keyN,
      cmd: true,
      when: "route == '/messaging'",
    ),
    Keybinding.key(
      id: 'msg.new-group',
      category: KeybindingCategory.creation,
      scope: '/messaging',
      key: LogicalKeyboardKey.keyN,
      cmd: true,
      shift: true,
      when: "route == '/messaging'",
    ),
    Keybinding.key(
      id: 'msg.prev-channel',
      category: KeybindingCategory.navigation,
      scope: '/messaging',
      key: LogicalKeyboardKey.keyK,
      when: "route == '/messaging' && !textInputFocus",
    ),
    Keybinding.key(
      id: 'msg.next-channel',
      category: KeybindingCategory.navigation,
      scope: '/messaging',
      key: LogicalKeyboardKey.keyJ,
      when: "route == '/messaging' && !textInputFocus",
    ),
    Keybinding.key(
      id: 'msg.delete-channel',
      category: KeybindingCategory.deletion,
      scope: '/messaging',
      key: LogicalKeyboardKey.backspace,
      cmd: true,
      when: "route == '/messaging' && !textInputFocus",
    ),
    // Enter-to-send is owned by the composer text field; listed for reference.
    Keybinding.key(
      id: 'msg.send',
      category: KeybindingCategory.editing,
      scope: '/messaging',
      key: LogicalKeyboardKey.enter,
    ),
  ];

  // ── Workspaces ─────────────────────────────────────────────────────────

  static final List<Keybinding>workspaces = [
    Keybinding.key(
      id: 'ws.new',
      category: KeybindingCategory.creation,
      scope: '/workspaces',
      key: LogicalKeyboardKey.keyN,
      cmd: true,
      when: "route == '/workspaces'",
    ),
    Keybinding.key(
      id: 'ws.open',
      category: KeybindingCategory.navigation,
      scope: '/workspaces',
      key: LogicalKeyboardKey.enter,
      when: "route == '/workspaces' && !textInputFocus",
    ),
    Keybinding.key(
      id: 'ws.delete',
      category: KeybindingCategory.deletion,
      scope: '/workspaces',
      key: LogicalKeyboardKey.backspace,
      cmd: true,
      when: "route == '/workspaces' && !textInputFocus",
    ),
  ];

  // ── Settings ───────────────────────────────────────────────────────────

  static final List<Keybinding>settings = [
    Keybinding.key(
      id: 'settings.next',
      category: KeybindingCategory.navigation,
      scope: '/settings',
      key: LogicalKeyboardKey.keyJ,
      when: 'route =~ /^\\/settings/ && !textInputFocus',
    ),
    Keybinding.key(
      id: 'settings.prev',
      category: KeybindingCategory.navigation,
      scope: '/settings',
      key: LogicalKeyboardKey.keyK,
      when: 'route =~ /^\\/settings/ && !textInputFocus',
    ),
    Keybinding.key(
      id: 'settings.agents-new',
      category: KeybindingCategory.creation,
      scope: '/settings/agents',
      key: LogicalKeyboardKey.keyN,
      cmd: true,
    ),
    Keybinding.key(
      id: 'settings.agents-delete',
      category: KeybindingCategory.deletion,
      scope: '/settings/agents',
      key: LogicalKeyboardKey.backspace,
      cmd: true,
      when: _notTyping,
    ),
    Keybinding.key(
      id: 'settings.repos-add',
      category: KeybindingCategory.creation,
      scope: '/settings/repositories',
      key: LogicalKeyboardKey.keyN,
      cmd: true,
    ),
    Keybinding.key(
      id: 'settings.adapters-refresh',
      category: KeybindingCategory.view,
      scope: '/settings/adapters',
      key: LogicalKeyboardKey.keyR,
      when: _notTyping,
    ),
  ];

  // ── Newsfeed ─────────────────────────────────────────────────────────────

  static final List<Keybinding>newsfeed = [
    Keybinding.key(
      id: 'newsfeed.refresh',
      category: KeybindingCategory.view,
      scope: '/newsfeed',
      key: LogicalKeyboardKey.keyR,
      when: "route == '/newsfeed' && !textInputFocus",
    ),
    Keybinding.key(
      id: 'newsfeed.next',
      category: KeybindingCategory.navigation,
      scope: '/newsfeed',
      key: LogicalKeyboardKey.keyJ,
      when: "route == '/newsfeed' && !textInputFocus",
    ),
    Keybinding.key(
      id: 'newsfeed.prev',
      category: KeybindingCategory.navigation,
      scope: '/newsfeed',
      key: LogicalKeyboardKey.keyK,
      when: "route == '/newsfeed' && !textInputFocus",
    ),
    Keybinding.key(
      id: 'newsfeed.open',
      category: KeybindingCategory.navigation,
      scope: '/newsfeed',
      key: LogicalKeyboardKey.enter,
      when: "route == '/newsfeed' && !textInputFocus",
    ),
    Keybinding.key(
      id: 'newsfeed.save',
      category: KeybindingCategory.editing,
      scope: '/newsfeed',
      key: LogicalKeyboardKey.keyS,
      when: "route == '/newsfeed' && !textInputFocus",
    ),
  ];

  // ── Analytics ──────────────────────────────────────────────────────────

  static final List<Keybinding>analytics = [
    Keybinding.key(
      id: 'analytics.refresh',
      category: KeybindingCategory.view,
      scope: '/analytics',
      key: LogicalKeyboardKey.keyR,
      when: "route == '/analytics' && !textInputFocus",
    ),
  ];

  // ── Peer Review ────────────────────────────────────────────────────────

  static final List<Keybinding>peerReview = [
    Keybinding.key(
      id: 'peer.approve',
      category: KeybindingCategory.editing,
      scope: '/workspaces/',
      key: LogicalKeyboardKey.enter,
      cmd: true,
      when: _notTyping,
    ),
    Keybinding.key(
      id: 'peer.reject',
      category: KeybindingCategory.editing,
      scope: '/workspaces/',
      key: LogicalKeyboardKey.enter,
      cmd: true,
      shift: true,
      when: _notTyping,
    ),
  ];

  // ── Aggregates ─────────────────────────────────────────────────────────

  static List<Keybinding> get all => [
        ...navigation,
        ...system,
        ...dashboard,
        ...pullRequests,
        ...userProfile,
        ...messaging,
        ...workspaces,
        ...settings,
        ...newsfeed,
        ...analytics,
        ...peerReview,
      ];

  /// Returns all keybindings whose [scope] starts with the given prefix.
  static List<Keybinding> forScope(String scope) {
    return all
        .where((b) => b.scope == scope || b.scope.startsWith(scope))
        .toList();
  }

  /// Returns all keybindings for the `'global'` scope.
  static List<Keybinding> get global => forScope(globalScope);

  /// Finds a single keybinding by its [id].
  static Keybinding? find(String id) {
    for (final b in all) {
      if (b.id == id) {
        return b;
      }
    }
    return null;
  }

  /// Groups all keybindings by category.
  static Map<KeybindingCategory, List<Keybinding>> byCategory() {
    final map = <KeybindingCategory, List<Keybinding>>{};
    for (final b in all) {
      map.putIfAbsent(b.category, () => []).add(b);
    }
    return map;
  }
}

/// Resolves keybinding labels and descriptions via l10n.
extension KeybindingL10n on Keybinding {
  String resolvedLabel(AppLocalizations l10n) {
    return switch (id) {
      'nav.dashboard' => l10n.keybindingGoToDashboard,
      'nav.tickets' => l10n.keybindingGoToTickets,
      'nav.pull-requests' => l10n.keybindingGoToPullRequests,
      'nav.pipelines' => l10n.keybindingGoToPipelines,
      'nav.agents' => l10n.keybindingGoToAgents,
      'nav.analytics' => l10n.keybindingGoToAnalytics,
      'nav.memory' => l10n.keybindingGoToMemory,
      'nav.newsfeed' => l10n.keybindingGoToNewsfeed,
      'sys.command-palette' => l10n.keybindingCommandPalette,
      'sys.toggle-theme' => l10n.keybindingToggleTheme,
      'sys.settings' => l10n.keybindingOpenSettings,
      'sys.focus-mode' => 'Toggle focus mode',
      'sys.workspace-switcher' => l10n.keybindingToggleWorkspaceSwitcher,
      'sys.workspace-next' => l10n.keybindingNextWorkspace,
      'sys.workspace-prev' => l10n.keybindingPreviousWorkspace,
      'sys.workspace-1' => l10n.keybindingWorkspace1,
      'sys.workspace-2' => l10n.keybindingWorkspace2,
      'sys.workspace-3' => l10n.keybindingWorkspace3,
      'sys.workspace-4' => l10n.keybindingWorkspace4,
      'sys.workspace-5' => l10n.keybindingWorkspace5,
      'sys.workspace-6' => l10n.keybindingWorkspace6,
      'sys.workspace-7' => l10n.keybindingWorkspace7,
      'sys.workspace-8' => l10n.keybindingWorkspace8,
      'sys.workspace-9' => l10n.keybindingWorkspace9,
      'dashboard.refresh' => l10n.keybindingRefresh,
      'pr.list-refresh' => l10n.keybindingRefresh,
      'pr.list-prev' => l10n.keybindingPreviousPr,
      'pr.list-next' => l10n.keybindingNextPr,
      'pr.list-open' => l10n.keybindingOpenPr,
      'pr.list-select' => l10n.keybindingSelectPr,
      'pr.list-merge' => l10n.keybindingMergePr,
      'pr.list-peek' => l10n.keybindingPeekPr,
      'pr.list-focus-search' || 'pr.list-focus-search-alt' =>
        l10n.keybindingFocusSearch,
      'pr.user-refresh' => l10n.keybindingRefresh,
      'pr.user-prev' => l10n.keybindingPreviousPr,
      'pr.user-next' => l10n.keybindingNextPr,
      'pr.user-open' => l10n.keybindingOpenPr,
      'pr.user-peek' => l10n.keybindingPeekPr,
      'pr.user-focus-search' || 'pr.user-focus-search-alt' =>
        l10n.keybindingFocusSearch,
      'pr.detail-tab-conv' => l10n.keybindingConversationTab,
      'pr.detail-tab-files' => l10n.keybindingFilesChangedTab,
      'pr.detail-search' => l10n.keybindingSearchInDiff,
      'pr.detail-toggle-viewed' => l10n.keybindingToggleViewed,
      'pr.detail-toggle-collapse' => l10n.keybindingToggleCollapse,
      'msg.new-dm' => l10n.keybindingNewDirectMessage,
      'msg.new-group' => l10n.keybindingNewGroup,
      'msg.prev-channel' => l10n.keybindingPreviousChannel,
      'msg.next-channel' => l10n.keybindingNextChannel,
      'msg.delete-channel' => l10n.keybindingDeleteChannel,
      'msg.send' => l10n.keybindingSendMessage,
      'ws.new' => l10n.keybindingNewWorkspace,
      'ws.open' => l10n.keybindingOpenWorkspace,
      'ws.delete' => l10n.keybindingDeleteWorkspace,
      'settings.next' => 'Next settings page',
      'settings.prev' => 'Previous settings page',
      'settings.agents-new' => l10n.keybindingNewAgent,
      'settings.agents-delete' => l10n.keybindingDeleteAgent,
      'settings.repos-add' => l10n.keybindingAddRepository,
      'settings.adapters-refresh' => l10n.keybindingRefresh,
      'newsfeed.refresh' => l10n.keybindingRefresh,
      'newsfeed.next' => l10n.keybindingNextArticle,
      'newsfeed.prev' => l10n.keybindingPreviousArticle,
      'newsfeed.open' => l10n.keybindingOpenArticle,
      'newsfeed.save' => l10n.keybindingToggleBookmark,
      'analytics.refresh' => l10n.keybindingRefresh,
      'peer.approve' => l10n.keybindingApprove,
      'peer.reject' => l10n.keybindingRequestChanges,
      _ => id,
    };
  }

  String resolvedDescription(AppLocalizations l10n) {
    return switch (id) {
      'nav.dashboard' => l10n.keybindingNavigateToTheGlobalDashboardDescription,
      'nav.tickets' => l10n.keybindingNavigateToTheTicketsBoardDescription,
      'nav.pull-requests' => l10n.keybindingNavigateToThePullRequestListDescription,
      'nav.pipelines' => l10n.keybindingNavigateToThePipelinesListDescription,
      'nav.agents' => l10n.keybindingNavigateToTheAgentsRegistryDescription,
      'nav.analytics' => l10n.keybindingNavigateToTheAnalyticsDashboardDescription,
      'nav.memory' => l10n.keybindingNavigateToTheMemoryDescription,
      'nav.newsfeed' => l10n.keybindingNavigateToTheNewsfeedDescription,
      'sys.command-palette' => l10n.keybindingOpenTheCommandPaletteDescription,
      'sys.toggle-theme' => l10n.keybindingSwitchBetweenLightAndDarkModeDescription,
      'sys.settings' => l10n.keybindingOpenTheApplicationSettingsDescription,
      'sys.focus-mode' => 'Activate or deactivate Focus Mode to silence non-urgent notifications',
      'sys.workspace-switcher' => l10n.keybindingOpenOrCloseTheWorkspaceSwitcherPopupInTheSidebarDescription,
      'sys.workspace-next' => l10n.keybindingSwitchToTheNextWorkspaceDescription,
      'sys.workspace-prev' => l10n.keybindingSwitchToThePreviousWorkspaceDescription,
      'sys.workspace-1' => l10n.keybindingSwitchToTheFirstWorkspaceDescription,
      'sys.workspace-2' => l10n.keybindingSwitchToTheSecondWorkspaceDescription,
      'sys.workspace-3' => l10n.keybindingSwitchToTheThirdWorkspaceDescription,
      'sys.workspace-4' => l10n.keybindingSwitchToTheFourthWorkspaceDescription,
      'sys.workspace-5' => l10n.keybindingSwitchToTheFifthWorkspaceDescription,
      'sys.workspace-6' => l10n.keybindingSwitchToTheSixthWorkspaceDescription,
      'sys.workspace-7' => l10n.keybindingSwitchToTheSeventhWorkspaceDescription,
      'sys.workspace-8' => l10n.keybindingSwitchToTheEighthWorkspaceDescription,
      'sys.workspace-9' => l10n.keybindingSwitchToTheNinthWorkspaceDescription,
      'dashboard.refresh' => l10n.keybindingRefreshDashboardDataDescription,
      'pr.list-refresh' => l10n.keybindingRefreshThePullRequestListDescription,
      'pr.list-prev' => l10n.keybindingSelectThePreviousPullRequestDescription,
      'pr.list-next' => l10n.keybindingSelectTheNextPullRequestDescription,
      'pr.list-open' => l10n.keybindingOpenTheSelectedPullRequestDescription,
      'pr.list-select' =>
        l10n.keybindingToggleSelectionOfTheFocusedPullRequestDescription,
      'pr.list-merge' =>
        l10n.keybindingMergeTheFocusedPullRequestDescription,
      'pr.list-peek' =>
        l10n.keybindingExpandOrCollapseTheFocusedPullRequestPeekDescription,
      'pr.list-focus-search' || 'pr.list-focus-search-alt' =>
        l10n.keybindingFocusThePullRequestSearchFieldDescription,
      'pr.user-refresh' => l10n.keybindingRefreshThePullRequestListDescription,
      'pr.user-prev' => l10n.keybindingSelectThePreviousPullRequestDescription,
      'pr.user-next' => l10n.keybindingSelectTheNextPullRequestDescription,
      'pr.user-open' => l10n.keybindingOpenTheSelectedPullRequestDescription,
      'pr.user-peek' =>
        l10n.keybindingExpandOrCollapseTheFocusedPullRequestPeekDescription,
      'pr.user-focus-search' || 'pr.user-focus-search-alt' =>
        l10n.keybindingFocusThePullRequestSearchFieldDescription,
      'pr.detail-tab-conv' => l10n.keybindingSwitchToTheConversationTabDescription,
      'pr.detail-tab-files' => l10n.keybindingSwitchToTheFilesChangedTabDescription,
      'pr.detail-search' => l10n.keybindingSearchWithinTheDiffViewDescription,
      'pr.detail-toggle-viewed' =>
        l10n.keybindingMarkTheFocusedFileAsViewedOrUnviewedDescription,
      'pr.detail-toggle-collapse' =>
        l10n.keybindingCollapseOrExpandTheFocusedFileDescription,
      'msg.new-dm' => l10n.keybindingStartANewDirectMessageDescription,
      'msg.new-group' => l10n.keybindingCreateANewGroupChannelDescription,
      'msg.prev-channel' => l10n.keybindingSelectThePreviousChannelDescription,
      'msg.next-channel' => l10n.keybindingSelectTheNextChannelDescription,
      'msg.delete-channel' => l10n.keybindingDeleteTheSelectedChannelDescription,
      'msg.send' => l10n.keybindingSendTheCurrentMessageDescription,
      'ws.new' => l10n.keybindingCreateANewWorkspaceDescription,
      'ws.open' => l10n.keybindingOpenTheSelectedWorkspaceDescription,
      'ws.delete' => l10n.keybindingDeleteTheSelectedWorkspaceDescription,
      'settings.next' => 'Navigate to the next item in the settings sidebar',
      'settings.prev' => 'Navigate to the previous item in the settings sidebar',
      'settings.agents-new' => l10n.keybindingCreateANewAgentDescription,
      'settings.agents-delete' => l10n.keybindingDeleteTheSelectedAgentDescription,
      'settings.repos-add' => l10n.keybindingAddARepositoryDescription,
      'settings.adapters-refresh' => l10n.keybindingRescanForAdaptersDescription,
      'newsfeed.refresh' => l10n.keybindingRefreshAllFeedsDescription,
      'newsfeed.next' => l10n.keybindingSelectTheNextArticleDescription,
      'newsfeed.prev' => l10n.keybindingSelectThePreviousArticleDescription,
      'newsfeed.open' => l10n.keybindingOpenTheSelectedArticleDescription,
      'newsfeed.save' => l10n.keybindingBookmarkOrUnbookmarkTheSelectedArticleDescription,
      'analytics.refresh' => l10n.keybindingRefreshAnalyticsDataDescription,
      'peer.approve' => l10n.keybindingApproveThePeerReviewDescription,
      'peer.reject' => l10n.keybindingRequestChangesOnThePeerReviewDescription,
      _ => id,
    };
  }
}
