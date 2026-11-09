import 'package:control_center/features/messaging/presentation/ide/ide_conversation_tabs.dart';
import 'package:control_center/features/messaging/presentation/ide/ide_terminal_sessions.dart';
import 'package:control_center/shared/editor/editor_layout_controller.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// What the messaging IDE's helpers (`IdeTabActions`, `IdeTabOpeners`) read
/// from the IDE they act for. Every getter is read at call time: the layout
/// is swapped on every space switch.
abstract interface class IdeHost {
  /// A context under the IDE, for dialogs, toasts and localizations.
  BuildContext get context;

  /// Whether the IDE is still mounted; most actions are async or deferred.
  bool get mounted;

  /// The IDE's provider access.
  WidgetRef get ref;

  /// The workspace the IDE was opened on (the sidebar's data scope).
  String get hostWorkspaceId;

  /// The active workspace, or null before it resolves.
  String? get activeWorkspaceId;

  /// The conversation (space) the IDE shows, or null.
  String? get selectedSpaceId;

  /// The open space's conversations as the chat tabs show them.
  IdeConversationView get conversations;

  /// The terminal sessions the tabs claim.
  IdeTerminalSessions get terminals;

  /// The IDE's current layout.
  EditorLayoutController get layout;
}
