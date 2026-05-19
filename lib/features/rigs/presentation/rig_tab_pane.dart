// A rig as an editor tab, in a channel or on a PR page.
//
// The tab IS the intent ("give me a browser"), so starting one is a single
// press — but it is a PRESS, not automatic. A persisted layout restores its
// tabs at launch, and auto-starting would boot two gigabytes of VM per rig tab
// every time the app opens, for machines nobody asked for yet.
library;

import 'dart:async';

import 'package:cc_ui/cc_ui.dart';
import 'package:control_center/features/rigs/presentation/rig_panel.dart';
import 'package:control_center/features/rigs/presentation/rig_tab_states.dart';
import 'package:control_center/features/rigs/providers/rig_providers.dart';
import 'package:control_center/features/workspaces/providers/workspace_providers.dart';
import 'package:control_center/l10n/app_localizations.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// The body of a rig tab: the live machine, or the affordance that starts one.
///
/// Scoped to [conversationId] so the tab, the agent's `browser_use` calls and
/// the Rigs screen all address ONE machine rather than three copies of it.
class RigTabPane extends ConsumerStatefulWidget {
  /// Creates a [RigTabPane].
  const RigTabPane({
    super.key,
    required this.surface,
    required this.conversationId,
    this.isVisible = true,
  });

  /// Which machine this tab shows.
  final String surface;

  /// The conversation the rig belongs to (a channel, or a PR's channel).
  final String? conversationId;

  /// Whether this tab is the one on screen. A hidden tab holds its last frame
  /// and stops streaming.
  final bool isVisible;

  @override
  ConsumerState<RigTabPane> createState() => _RigTabPaneState();
}

class _RigTabPaneState extends ConsumerState<RigTabPane> {
  bool _starting = false;
  String? _error;

  Future<void> _start(String workspaceId) async {
    final conversationId = widget.conversationId;
    if (conversationId == null || _starting) {
      return;
    }
    setState(() {
      _starting = true;
      _error = null;
    });
    try {
      await ref
          .read(rigRepositoryProvider)
          .open(
            workspaceId: workspaceId,
            surface: widget.surface,
            conversationId: conversationId,
          );
    } on Object catch (e) {
      if (mounted) {
        setState(() => _error = '$e');
      }
    } finally {
      if (mounted) {
        setState(() => _starting = false);
      }
    }
  }

  Future<void> _stop(String workspaceId, String rigId) async {
    try {
      await ref.read(rigRepositoryProvider).destroy(workspaceId, rigId);
    } on Object catch (e) {
      if (mounted) {
        CcToastScope.of(context).show('$e', variant: CcToastVariant.danger);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final workspaceId = ref.watch(activeWorkspaceIdProvider);
    final conversationId = widget.conversationId;

    // No workspace is not the empty workspace. Falling back to `''` sent an
    // unscoped RPC call that could only fail; the tab has nothing to show
    // until the shell has resolved one.
    if (workspaceId == null || workspaceId.isEmpty) {
      return const Center(child: CcSpinner());
    }
    if (conversationId == null || conversationId.isEmpty) {
      // A rig belongs to a conversation, so an unscoped tab has nothing to
      // attach to. Say that rather than opening a machine nobody can find.
      return RigNotice(text: l10n.rigTabNeedsConversation);
    }

    final rig = ref.watch(
      conversationRigProvider((
        workspaceId: workspaceId,
        conversationId: conversationId,
        surface: widget.surface,
      )),
    );
    if (rig != null) {
      return RigPanel(
        workspaceId: workspaceId,
        rig: rig,
        paused: !widget.isVisible,
        onStop: () => unawaited(_stop(workspaceId, rig.id)),
      );
    }

    // A machine takes 20–60 seconds to come up and the server reports each
    // stage as it goes. Showing only a spinner on the button meant a boot that
    // was working looked identical to one that had done nothing, for two
    // minutes, and a boot that failed just reverted to the start screen.
    final pending = ref.watch(
      conversationPendingRigProvider((
        workspaceId: workspaceId,
        conversationId: conversationId,
        surface: widget.surface,
      )),
    );
    if (pending != null && !pending.isFailed) {
      return RigProgress(surface: widget.surface, detail: pending.detail);
    }

    return RigStart(
      surface: widget.surface,
      starting: _starting,
      // A failed boot's reason outlives the call that started it: the rig row
      // carries it, so a user who navigated away and back still sees why.
      error: _error ?? (pending?.isFailed ?? false ? pending?.detail : null),
      onStart: () => unawaited(_start(workspaceId)),
    );
  }
}
