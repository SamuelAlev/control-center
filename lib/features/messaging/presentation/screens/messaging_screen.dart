import 'package:cc_ui/cc_ui.dart';
import 'package:control_center/features/messaging/presentation/ide/messaging_ide_layout.dart';
import 'package:control_center/features/messaging/presentation/widgets/conversations_sidebar_section.dart';
import 'package:control_center/features/messaging/providers/messaging_providers.dart';
import 'package:control_center/features/workspaces/providers/workspace_providers.dart';
import 'package:control_center/router/routes.dart';
import 'package:control_center/shared/widgets/scoped_shortcuts.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

/// Messaging screen rendered as an IDE-like surface: a fixed activity sidebar
/// (General / Explorer / Source control / Notes / Artifacts) plus one or more
/// tabbed editor groups (Chat / Terminal / Browser). The selected conversation comes from the
/// URL (`/spaces/:spaceId`) and is mirrored into [selectedSpaceIdProvider]
/// so the breadcrumbs, read-cursor effect and IDE layout read one source.
class MessagingScreen extends ConsumerStatefulWidget {
  /// Creates a new [MessagingScreen].
  const MessagingScreen({
    super.key,
    this.selectedSpaceId,
    this.pendingMessageId,
    this.focusedTabKey,
  });

  /// The space id from the route, or null on the bare `/spaces` location.
  final String? selectedSpaceId;

  /// A message id deep-linked via `?m=<id>` (a permalink target), or null.
  final String? pendingMessageId;

  /// The focused editor tab's key, deep-linked via `?tab=<key>`, or null when
  /// the URL names no tab (the IDE then keeps its seeded/restored selection).
  final String? focusedTabKey;

  @override
  ConsumerState<MessagingScreen> createState() => _MessagingScreenState();
}

class _MessagingScreenState extends ConsumerState<MessagingScreen> {
  /// IDE editor action sink — owned by this state so the keyboard shortcuts
  /// (⌘T/⌘W/⌘B) can drive the layout without coupling to its private state.
  ///
  /// MUST be a state field, never rebuilt in [build]: [MessagingIdeLayout]
  /// wires its callbacks onto this instance in its `initState`, so a fresh sink
  /// per build would hand the dispatcher an unwired object (every callback
  /// null) on the first rebuild — the shortcut then matches, consumes the key,
  /// and silently does nothing.
  ///
  /// Note: on web ⌘T (new tab) and ⌘W (close tab) are browser accelerators the
  /// page never receives, so those two fire on desktop only; ⌘B still works.
  final MessagingIdeActions _ideActions = MessagingIdeActions();

  @override
  void initState() {
    super.initState();
    _syncSelectionFromRoute();
  }

  @override
  void didUpdateWidget(MessagingScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.selectedSpaceId != widget.selectedSpaceId ||
        oldWidget.pendingMessageId != widget.pendingMessageId) {
      _syncSelectionFromRoute();
    }
  }

  /// Mirrors the URL's space id into [selectedSpaceIdProvider] and forwards
  /// a `?m=<id>` deep link into [pendingFocusMessageProvider] for the space
  /// feed to consume. Deferred a frame so we never mutate a provider mid-build
  /// of the route's page.
  void _syncSelectionFromRoute() {
    final id = widget.selectedSpaceId;
    final messageId = widget.pendingMessageId;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) {
        return;
      }
      if (ref.read(selectedSpaceIdProvider) != id) {
        ref.read(selectedSpaceIdProvider.notifier).select(id);
      }
      if (id != null && messageId != null && messageId.isNotEmpty) {
        ref.read(pendingFocusMessageProvider.notifier).set((
          spaceId: id,
          messageId: messageId,
        ));
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final selectedId = ref.watch(selectedSpaceIdProvider);
    final workspaceId = ref.watch(activeWorkspaceIdProvider);
    final spaces = workspaceId != null
        ? ref.watch(workspaceSpacesProvider(workspaceId)).value ?? const []
        : ref.watch(spacesProvider).value ?? const [];

    void cycleSpace({required int delta}) {
      if (spaces.isEmpty || workspaceId == null) {
        return;
      }
      final currentIndex = spaces.indexWhere((c) => c.id == selectedId);
      final base = currentIndex < 0 ? 0 : currentIndex;
      final raw = (base + delta) % spaces.length;
      final next = raw < 0 ? raw + spaces.length : raw;
      // The URL is the source of truth: navigate and the screen mirrors it
      // into [selectedSpaceIdProvider].
      GoRouter.of(context).go(spaceRoute(workspaceId, spaces[next].id));
    }

    return ScopedShortcuts(
      scope: '/spaces',
      bindings: {
        'msg.new-space': () => showNewSpaceDialog(context, ref),
        'msg.next-space': () => cycleSpace(delta: 1),
        'msg.prev-space': () => cycleSpace(delta: -1),
        'msg.ide-new-tab': () => _ideActions.openEditor?.call(),
        'msg.ide-close-tab': () => _ideActions.closeActiveTab?.call(),
        'msg.ide-toggle-sidebar': () => _ideActions.toggleSidebar?.call(),
      },
      child: workspaceId == null
          ? const Center(child: CcSpinner())
          : MessagingIdeLayout(
              workspaceId: workspaceId,
              selectedSpaceId: selectedId,
              focusedTabKey: widget.focusedTabKey,
              actions: _ideActions,
            ),
    );
  }
}
