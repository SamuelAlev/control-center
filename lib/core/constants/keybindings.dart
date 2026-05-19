import 'package:control_center/core/keybindings/key_stroke.dart';
import 'package:control_center/l10n/app_localizations.dart';
import 'package:flutter/services.dart';

/// Categories used to group shortcuts in the keybindings settings page.
enum KeybindingCategory {
  /// Navigate between pages and sections.
  navigation,

  /// System-level actions (command palette, settings, theme).
  system,

  /// Create new entities (agents, repos, spaces).
  creation,

  /// Edit or modify entities.
  editing,

  /// View, inspect, or refresh data.
  view,
}

/// A single keyboard shortcut definition.
///
/// A binding maps a [chord] (one or more [KeyStroke]s) to a command [id]. The
/// optional [when] clause — a VS Code-style boolean expression over context
/// keys such as `route` and `textInputFocus` — gates when the binding is live.
/// [scope] is `'global'` or a route path (e.g. `/inbox`); it drives the
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
  }) => Keybinding(
    id: id,
    category: category,
    scope: scope,
    chord: KeyChord([
      KeyStroke(key, cmd: cmd, ctrl: ctrl, shift: shift, alt: alt),
    ]),
    when: when,
  );

  /// Unique stable identifier, e.g. `nav.inbox`.
  final String id;

  /// Grouping category for the settings page.
  final KeybindingCategory category;

  /// `'global'` or a route path (e.g. `/inbox`).
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

  /// Non-cancelable browser accelerators that reach the OS/browser chrome
  /// before the page, so a web build can never observe (or `preventDefault`)
  /// them — unlike ⌘S/⌘F/⌘P, which the page *can* intercept. Keyed by the
  /// trigger of the first stroke; the primary command modifier (⌘ on macOS,
  /// Ctrl on Windows/Linux) makes them browser shortcuts on every platform:
  /// new tab (T), close tab (W), new window (N) and jump-to-tab-N (1‑9).
  static final Set<LogicalKeyboardKey> _browserReservedTriggers = {
    LogicalKeyboardKey.keyT,
    LogicalKeyboardKey.keyW,
    LogicalKeyboardKey.keyN,
    LogicalKeyboardKey.digit1,
    LogicalKeyboardKey.digit2,
    LogicalKeyboardKey.digit3,
    LogicalKeyboardKey.digit4,
    LogicalKeyboardKey.digit5,
    LogicalKeyboardKey.digit6,
    LogicalKeyboardKey.digit7,
    LogicalKeyboardKey.digit8,
    LogicalKeyboardKey.digit9,
  };

  /// True when this binding can never fire in a browser tab because the browser
  /// consumes the combination itself (see [_browserReservedTriggers]). Only the
  /// command-modified ([meta]) variants are reserved; it works fine on desktop,
  /// so callers should gate on `kIsWeb` before surfacing it.
  bool get isReservedInBrowser =>
      meta &&
      chord.strokes.length == 1 &&
      _browserReservedTriggers.contains(key);
}

/// Central registry of all keyboard shortcuts.
///
/// The `KeybindingDispatcher` reads [all] and keeps its active-stroke set in
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
  static const String _userProfile =
      r'route =~ /^\/users\// && !textInputFocus';

  /// System-wide shortcuts (command palette, theme, settings, workspace
  /// switching).
  static final List<Keybinding> system = [
    Keybinding.key(
      id: 'sys.command-palette',
      category: KeybindingCategory.system,
      scope: globalScope,
      key: LogicalKeyboardKey.keyK,
      cmd: true,
    ),
    // `?` (Shift+/) opens the keyboard cheat-sheet (PRD 19 §2). The
    // `!textInputFocus` guard lets `?` be typed into fields normally.
    Keybinding.key(
      id: 'sys.cheat-sheet',
      category: KeybindingCategory.system,
      scope: globalScope,
      key: LogicalKeyboardKey.slash,
      shift: true,
      when: _notTyping,
    ),
    // Universal undo/redo (PRD 19 §4). The `!textInputFocus` guard keeps a
    // focused field's own ⌘Z/⌘⇧Z (text editing) intact — the ActionJournal
    // only takes over when no field is being edited. While a field IS focused
    // those strokes are delivered to the field's UndoHistory by the
    // dispatcher's text-undo bridge (`_bridgeTextUndoRedo`), because the
    // focus-tree path (`DefaultTextEditingShortcuts`) does not fire under the
    // native-windowing runtime.
    Keybinding.key(
      id: 'sys.undo',
      category: KeybindingCategory.editing,
      scope: globalScope,
      key: LogicalKeyboardKey.keyZ,
      cmd: true,
      when: _notTyping,
    ),
    Keybinding.key(
      id: 'sys.redo',
      category: KeybindingCategory.editing,
      scope: globalScope,
      key: LogicalKeyboardKey.keyZ,
      cmd: true,
      shift: true,
      when: _notTyping,
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

  /// Pull request list and detail screen shortcuts.
  static final List<Keybinding> pullRequests = [
    Keybinding.key(
      id: 'pr.list-refresh',
      category: KeybindingCategory.view,
      scope: '/pull-requests',
      key: LogicalKeyboardKey.keyR,
      when: _prList,
    ),
    Keybinding.key(
      id: 'pr.list-open',
      category: KeybindingCategory.navigation,
      scope: '/pull-requests',
      key: LogicalKeyboardKey.enter,
      when: _prList,
    ),
    // Focus the queue search field. Two keys reach the same field: `/` (a
    // single tap, GitHub-style) and ⌘F/Ctrl+F. Ids are unique per binding here,
    // so the alternate gets its own id; the screen wires both to one handler.
    // The `!textInputFocus` guard (in `_prList`) lets `/` be typed into the
    // field once it already has focus.
    Keybinding.key(
      id: 'pr.list-open-filter',
      category: KeybindingCategory.view,
      scope: '/pull-requests',
      key: LogicalKeyboardKey.keyF,
      when: _prList,
    ),
    // Inbox: the same F-opens-the-filter-menu affordance as the PR list (the
    // two surfaces share one filter menu).
    Keybinding.key(
      id: 'inbox.open-filter',
      category: KeybindingCategory.view,
      scope: '/inbox',
      key: LogicalKeyboardKey.keyF,
      when: "route == '/inbox' && !textInputFocus",
    ),
    // Detail-screen bindings. The PR-detail page is the only one mounted on a
    // `/pull-requests/<n>` route, so handler-presence already scopes these;
    // they only need the text-input guard. Search/viewed/collapse are owned by
    // the diff view's own hardware-keyboard handler and listed here for the
    // settings reference only (no handler is registered, so the dispatcher
    // leaves them to the diff view).
    Keybinding.key(
      id: 'pr.detail-refresh',
      category: KeybindingCategory.view,
      scope: '/pull-requests/',
      key: LogicalKeyboardKey.keyR,
      when: _notTyping,
    ),
    // ⌘W closes the active editor tab — parity with the messaging IDE's
    // `msg.ide-close-tab`. No `!textInputFocus` guard (a ⌘-modified stroke is
    // never plain text), so it closes the tab even from the diff search /
    // comment composer, matching VS Code. The route regex scopes it to the
    // detail page (the bare `/pull-requests` list never matches). Browser-
    // reserved on web, so it fires on desktop only.
    Keybinding.key(
      id: 'pr.detail-close-tab',
      category: KeybindingCategory.view,
      scope: '/pull-requests/',
      key: LogicalKeyboardKey.keyW,
      cmd: true,
      when: r'route =~ /^\/pull-requests\//',
    ),
  ];

  // ── User profile ─────────────────────────────────────────────────────────

  /// The browse-only PR queue on a `/users/<login>` profile page: move / open /
  /// search / refresh. No select or merge — profiles are read-only.
  static final List<Keybinding> userProfile = [
    Keybinding.key(
      id: 'pr.user-refresh',
      category: KeybindingCategory.view,
      scope: '/users/',
      key: LogicalKeyboardKey.keyR,
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

  /// Space screen shortcuts (new space, navigation, send). The `when`
  /// clauses use a regex so they fire on both the space list (`/spaces`)
  /// and a selected space (`/spaces/<id>`).
  static final List<Keybinding> messaging = [
    Keybinding.key(
      id: 'msg.new-space',
      category: KeybindingCategory.creation,
      scope: '/spaces',
      key: LogicalKeyboardKey.keyN,
      cmd: true,
      when: r'route =~ /^\/spaces/',
    ),
    Keybinding.key(
      id: 'msg.prev-space',
      category: KeybindingCategory.navigation,
      scope: '/spaces',
      key: LogicalKeyboardKey.keyK,
      when: r'route =~ /^\/spaces/ && !textInputFocus',
    ),
    Keybinding.key(
      id: 'msg.next-space',
      category: KeybindingCategory.navigation,
      scope: '/spaces',
      key: LogicalKeyboardKey.keyJ,
      when: r'route =~ /^\/spaces/ && !textInputFocus',
    ),
    // Enter-to-send is owned by the composer text field; listed for reference.
    Keybinding.key(
      id: 'msg.send',
      category: KeybindingCategory.editing,
      scope: '/spaces',
      key: LogicalKeyboardKey.enter,
    ),
    // Push-to-talk voice dictation (PRD 25 §2). Owned by the composer's mic
    // button (its own hardware-keyboard handler observes hold/release and
    // `preventDefault`s on web), so NO central dispatcher handler is registered
    // and it is listed here for the settings reference only. ⌘⇧D / Ctrl+Shift+D
    // — non-browser-reserved (unlike ⌘T/⌘W/⌘N/⌘1-9) and not ⌘K (the macOS
    // meta-keyup repeat bug) — and works while typing in the composer.
    Keybinding.key(
      id: 'dictation.pushToTalk',
      category: KeybindingCategory.editing,
      scope: '/spaces',
      key: LogicalKeyboardKey.keyD,
      cmd: true,
      shift: true,
    ),
    // IDE editor shortcuts. ⌘T opens (or focuses) the conversation's code-server
    // editor on its worktree — the single place where files are created/saved.
    // ⌘W closes the active tab. ⌘B toggles the sidebar. All use the cmd
    // modifier (⌘ on macos, Ctrl on linux/windows/web) so they don't clash with
    // plain-text typing.
    Keybinding.key(
      id: 'msg.ide-new-tab',
      category: KeybindingCategory.view,
      scope: '/spaces',
      key: LogicalKeyboardKey.keyT,
      cmd: true,
      when: r'route =~ /^\/spaces/',
    ),
    Keybinding.key(
      id: 'msg.ide-close-tab',
      category: KeybindingCategory.view,
      scope: '/spaces',
      key: LogicalKeyboardKey.keyW,
      cmd: true,
      when: r'route =~ /^\/spaces/',
    ),
    Keybinding.key(
      id: 'msg.ide-toggle-sidebar',
      category: KeybindingCategory.view,
      scope: '/spaces',
      key: LogicalKeyboardKey.keyB,
      cmd: true,
      when: r'route =~ /^\/spaces/',
    ),
  ];

  /// Workspace management shortcuts.
  static final List<Keybinding> workspaces = [
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
  ];

  /// Settings navigation and entity management shortcuts.
  static final List<Keybinding> settings = [
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

  /// Newsfeed navigation shortcuts.
  static final List<Keybinding> newsfeed = [
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

  // ── Aggregates ─────────────────────────────────────────────────────────

  /// All keybindings aggregated from every category.
  static List<Keybinding> get all => [
    ...system,
    ...pullRequests,
    ...userProfile,
    ...messaging,
    ...workspaces,
    ...settings,
    ...newsfeed,
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
  /// Returns the localized human-readable label for this binding.
  String resolvedLabel(AppLocalizations l10n) {
    return switch (id) {
      'sys.command-palette' => l10n.keybindingCommandPalette,
      'sys.cheat-sheet' => l10n.keybindingCheatSheet,
      'sys.undo' => l10n.keybindingUndo,
      'sys.redo' => l10n.keybindingRedo,
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
      'pr.list-refresh' => l10n.keybindingRefresh,
      'pr.list-open' => l10n.keybindingOpenPr,
      'pr.list-open-filter' => l10n.keybindingOpenFilterMenu,
      'inbox.open-filter' => l10n.keybindingOpenFilterMenu,
      'pr.user-refresh' => l10n.keybindingRefresh,
      'pr.user-focus-search' ||
      'pr.user-focus-search-alt' => l10n.keybindingFocusSearch,
      'pr.detail-close-tab' => l10n.ideCloseTab,
      'msg.new-space' => l10n.keybindingNewSpace,
      'msg.prev-space' => l10n.keybindingPreviousSpace,
      'msg.next-space' => l10n.keybindingNextSpace,
      'msg.send' => l10n.keybindingSendMessage,
      'dictation.pushToTalk' => l10n.keybindingPushToTalk,
      'msg.ide-new-tab' => l10n.ideNewTab,
      'msg.ide-close-tab' => l10n.ideCloseTab,
      'msg.ide-toggle-sidebar' => l10n.ideToggleSidebar,
      'ws.new' => l10n.keybindingNewWorkspace,
      'ws.open' => l10n.keybindingOpenWorkspace,
      'settings.next' => 'Next settings page',
      'settings.prev' => 'Previous settings page',
      'settings.agents-new' => l10n.keybindingNewAgent,
      'settings.repos-add' => l10n.keybindingAddRepository,
      'settings.adapters-refresh' => l10n.keybindingRefresh,
      'newsfeed.refresh' => l10n.keybindingRefresh,
      'newsfeed.next' => l10n.keybindingNextArticle,
      'newsfeed.prev' => l10n.keybindingPreviousArticle,
      'newsfeed.open' => l10n.keybindingOpenArticle,
      'newsfeed.save' => l10n.keybindingToggleBookmark,
      _ => id,
    };
  }

  /// Returns the localized human-readable description for this binding.
  String resolvedDescription(AppLocalizations l10n) {
    return switch (id) {
      'sys.command-palette' => l10n.keybindingOpenTheCommandPaletteDescription,
      'sys.cheat-sheet' => l10n.keybindingShowKeyboardShortcutsDescription,
      'sys.undo' => l10n.keybindingUndoLastActionDescription,
      'sys.redo' => l10n.keybindingRedoLastActionDescription,
      'sys.toggle-theme' =>
        l10n.keybindingSwitchBetweenLightAndDarkModeDescription,
      'sys.settings' => l10n.keybindingOpenTheApplicationSettingsDescription,
      'sys.focus-mode' =>
        'Activate or deactivate Focus Mode to silence non-urgent notifications',
      'sys.workspace-switcher' =>
        l10n.keybindingOpenOrCloseTheWorkspaceSwitcherPopupInTheSidebarDescription,
      'sys.workspace-next' =>
        l10n.keybindingSwitchToTheNextWorkspaceDescription,
      'sys.workspace-prev' =>
        l10n.keybindingSwitchToThePreviousWorkspaceDescription,
      'sys.workspace-1' => l10n.keybindingSwitchToTheFirstWorkspaceDescription,
      'sys.workspace-2' => l10n.keybindingSwitchToTheSecondWorkspaceDescription,
      'sys.workspace-3' => l10n.keybindingSwitchToTheThirdWorkspaceDescription,
      'sys.workspace-4' => l10n.keybindingSwitchToTheFourthWorkspaceDescription,
      'sys.workspace-5' => l10n.keybindingSwitchToTheFifthWorkspaceDescription,
      'sys.workspace-6' => l10n.keybindingSwitchToTheSixthWorkspaceDescription,
      'sys.workspace-7' =>
        l10n.keybindingSwitchToTheSeventhWorkspaceDescription,
      'sys.workspace-8' => l10n.keybindingSwitchToTheEighthWorkspaceDescription,
      'sys.workspace-9' => l10n.keybindingSwitchToTheNinthWorkspaceDescription,
      'pr.list-refresh' => l10n.keybindingRefreshThePullRequestListDescription,
      'pr.list-open' => l10n.keybindingOpenTheSelectedPullRequestDescription,
      'pr.list-open-filter' =>
        l10n.keybindingOpenThePullRequestFilterMenuDescription,
      'inbox.open-filter' =>
        l10n.keybindingOpenThePullRequestFilterMenuDescription,
      'pr.user-refresh' => l10n.keybindingRefreshThePullRequestListDescription,
      'pr.user-focus-search' || 'pr.user-focus-search-alt' =>
        l10n.keybindingFocusThePullRequestSearchFieldDescription,
      'pr.detail-close-tab' => l10n.ideCloseTab,
      'msg.new-space' => l10n.keybindingCreateANewSpaceDescription,
      'msg.prev-space' => l10n.keybindingSelectThePreviousSpaceDescription,
      'msg.next-space' => l10n.keybindingSelectTheNextSpaceDescription,
      'msg.send' => l10n.keybindingSendTheCurrentMessageDescription,
      'dictation.pushToTalk' => l10n.keybindingPushToTalkDescription,
      'msg.ide-new-tab' => l10n.ideNewTab,
      'msg.ide-close-tab' => l10n.ideCloseTab,
      'msg.ide-toggle-sidebar' => l10n.ideToggleSidebar,
      'ws.new' => l10n.keybindingCreateANewWorkspaceDescription,
      'ws.open' => l10n.keybindingOpenTheSelectedWorkspaceDescription,
      'settings.next' => 'Navigate to the next item in the settings sidebar',
      'settings.prev' =>
        'Navigate to the previous item in the settings sidebar',
      'settings.agents-new' => l10n.keybindingCreateANewAgentDescription,
      'settings.repos-add' => l10n.keybindingAddARepositoryDescription,
      'settings.adapters-refresh' =>
        l10n.keybindingRescanForAdaptersDescription,
      'newsfeed.refresh' => l10n.keybindingRefreshAllFeedsDescription,
      'newsfeed.next' => l10n.keybindingSelectTheNextArticleDescription,
      'newsfeed.prev' => l10n.keybindingSelectThePreviousArticleDescription,
      'newsfeed.open' => l10n.keybindingOpenTheSelectedArticleDescription,
      'newsfeed.save' =>
        l10n.keybindingBookmarkOrUnbookmarkTheSelectedArticleDescription,
      _ => id,
    };
  }
}
