import 'package:control_center/features/messaging/providers/visible_conversation_spaces.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Refcounts [spaceId] and [conversationId] as visible for as long as this
/// widget is mounted AND on screen, so the global approval overlay can hide
/// requests this pane already shows inline.
///
/// Editor tabs stay mounted offstage with tickers disabled; a hidden tab
/// holds nothing, so a request for it keeps floating in the overlay instead
/// of vanishing behind a tab the user is not looking at.
class VisibleConversationRegistrar extends ConsumerStatefulWidget {
  /// Creates a [VisibleConversationRegistrar].
  const VisibleConversationRegistrar({
    super.key,
    required this.spaceId,
    this.conversationId,
    required this.child,
  });

  /// The space whose conversation this subtree is showing.
  final String spaceId;

  /// The conversation this subtree is showing, once resolved.
  final String? conversationId;

  /// The pane contents.
  final Widget child;

  @override
  ConsumerState<VisibleConversationRegistrar> createState() =>
      _VisibleConversationRegistrarState();
}

class _VisibleConversationRegistrarState
    extends ConsumerState<VisibleConversationRegistrar> {
  /// Cached in [initState]: [WidgetRef.read] is unsafe once this State is
  /// deactivating, and [dispose] still has to release the refcount.
  late final VisibleConversationSpaces _spaces;
  late final VisibleConversations _conversations;

  /// What this State currently holds, so a change releases exactly that.
  String? _heldSpace;
  String? _heldConversation;

  @override
  void initState() {
    super.initState();
    _spaces = ref.read(visibleConversationSpacesProvider.notifier);
    _conversations = ref.read(visibleConversationsProvider.notifier);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _sync();
  }

  @override
  void didUpdateWidget(VisibleConversationRegistrar oldWidget) {
    super.didUpdateWidget(oldWidget);
    _sync();
  }

  @override
  void dispose() {
    _hold(space: null, conversation: null);
    super.dispose();
  }

  void _sync() {
    final onScreen = TickerMode.valuesOf(context).enabled;
    _hold(
      space: onScreen ? widget.spaceId : null,
      conversation: onScreen ? widget.conversationId : null,
    );
  }

  void _hold({required String? space, required String? conversation}) {
    if (space != _heldSpace) {
      if (_heldSpace case final held?) {
        _spaces.release(held);
      }
      if (space != null) {
        _spaces.acquire(space);
      }
      _heldSpace = space;
    }
    if (conversation != _heldConversation) {
      if (_heldConversation case final held?) {
        _conversations.release(held);
      }
      if (conversation != null) {
        _conversations.acquire(conversation);
      }
      _heldConversation = conversation;
    }
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
