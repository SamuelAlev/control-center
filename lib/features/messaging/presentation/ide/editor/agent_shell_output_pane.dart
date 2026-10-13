import 'dart:async';

import 'package:cc_domain/core/domain/entities/agent_shell_output.dart';
import 'package:cc_markdown/cc_markdown.dart' show CcSelectionRegion;
import 'package:cc_ui/cc_ui.dart';
import 'package:control_center/features/sandboxing/providers/agent_shell_providers.dart';
import 'package:control_center/l10n/app_localizations.dart';
import 'package:control_center/shared/icons/app_icons.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

const _pollInterval = Duration(seconds: 3);
const _followThreshold = 48.0;

/// Read-only server-captured output; closing it never stops the command.
class AgentShellOutputPane extends ConsumerStatefulWidget {
  /// Opens the captured output for an agent command.
  const AgentShellOutputPane({
    super.key,
    required this.workspaceId,
    required this.spaceId,
    required this.outputId,
    required this.command,
  });

  /// The process's workspace.
  final String workspaceId;

  /// The process's space.
  final String spaceId;

  /// The opaque server-issued output identity.
  final String outputId;

  /// The full command as displayed in the terminal sidebar.
  final String command;

  @override
  ConsumerState<AgentShellOutputPane> createState() =>
      _AgentShellOutputPaneState();
}

class _AgentShellOutputPaneState extends ConsumerState<AgentShellOutputPane> {
  final ScrollController _scroll = ScrollController();
  AgentShellOutput? _snapshot;
  Object? _error;
  Timer? _nextPoll;
  bool _reading = false;
  bool _following = true;
  int _generation = 0;

  @override
  void initState() {
    super.initState();
    _scroll.addListener(_onScroll);
    _readOutput();
  }

  @override
  void didUpdateWidget(covariant AgentShellOutputPane oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.workspaceId != oldWidget.workspaceId ||
        widget.spaceId != oldWidget.spaceId ||
        widget.outputId != oldWidget.outputId) {
      _nextPoll?.cancel();
      _generation++;
      _reading = false;
      _snapshot = null;
      _error = null;
      _following = true;
      _readOutput();
    }
  }

  @override
  void dispose() {
    _generation++;
    _nextPoll?.cancel();
    _scroll.removeListener(_onScroll);
    _scroll.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (!_scroll.hasClients) {
      return;
    }
    final nearBottom =
        _scroll.position.maxScrollExtent - _scroll.offset < _followThreshold;
    if (_following != nearBottom) {
      setState(() => _following = nearBottom);
    }
  }

  Future<void> _readOutput() async {
    if (_reading || !mounted) {
      return;
    }
    _nextPoll?.cancel();
    final generation = _generation;
    _reading = true;
    try {
      final next = await ref
          .read(agentShellProcessPortProvider)
          .readOutput(
            workspaceId: widget.workspaceId,
            spaceId: widget.spaceId,
            outputId: widget.outputId,
          );
      if (!mounted || generation != _generation) {
        return;
      }
      final changed = next.output != _snapshot?.output;
      setState(() {
        _snapshot = next;
        _error = null;
      });
      if (changed && _following) {
        _jumpAfterLayout();
      }
      if (next.state == AgentShellOutputState.running) {
        _nextPoll = Timer(_pollInterval, _readOutput);
      }
    } on Object catch (error) {
      if (!mounted || generation != _generation) {
        return;
      }
      setState(() => _error = error);
    } finally {
      if (generation == _generation) {
        _reading = false;
      }
    }
  }

  void _jumpAfterLayout() {
    final generation = _generation;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted &&
          generation == _generation &&
          _following &&
          _scroll.hasClients) {
        _scroll.jumpTo(_scroll.position.maxScrollExtent);
      }
    });
  }

  void _jumpToLatest() {
    setState(() => _following = true);
    _jumpAfterLayout();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final t = context.designSystem ?? DesignSystemTokens.light();
    final snapshot = _snapshot;
    final output = snapshot?.output ?? '';
    final state = snapshot?.state;
    final status = switch (state) {
      AgentShellOutputState.running => l10n.running,
      AgentShellOutputState.exited => l10n.runStatusCompleted,
      AgentShellOutputState.unavailable => l10n.unavailable,
      null => null,
    };
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.lg,
            vertical: AppSpacing.sm,
          ),
          child: Row(
            children: [
              Expanded(
                child: CcTooltip(
                  message: widget.command,
                  child: Text(
                    widget.command.split('\n').first,
                    // RTL carve-out: shell commands retain their source order.
                    textDirection: TextDirection.ltr,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: CcFonts.code(
                      textStyle: TextStyle(fontSize: 12, color: t.textPrimary),
                    ),
                  ),
                ),
              ),
              if (status != null) ...[
                const SizedBox(width: AppSpacing.sm),
                Text(
                  status,
                  style: TextStyle(fontSize: 12, color: t.textSecondary),
                ),
              ],
              if (output.isNotEmpty) ...[
                const SizedBox(width: AppSpacing.sm),
                CcIconButton(
                  icon: AppIcons.copy,
                  size: CcButtonSize.sm,
                  tooltip: l10n.copyLogs,
                  onPressed: () =>
                      Clipboard.setData(ClipboardData(text: output)),
                ),
              ],
            ],
          ),
        ),
        const CcDivider(),
        if (snapshot?.truncated == true)
          Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.lg,
              vertical: AppSpacing.xs,
            ),
            child: Text(
              l10n.jobLogsTruncated,
              style: TextStyle(fontSize: 12, color: t.textSecondary),
            ),
          ),
        if (_error != null && output.isNotEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    l10n.failedToLoadLogs('$_error'),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(fontSize: 12, color: t.textSecondary),
                  ),
                ),
                CcButton(
                  size: CcButtonSize.sm,
                  onPressed: _readOutput,
                  child: Text(l10n.retry),
                ),
              ],
            ),
          ),
        Expanded(
          child: output.isEmpty
              ? _emptyState(l10n, state)
              : Stack(
                  children: [
                    // RTL carve-out: command output retains terminal order.
                    Directionality(
                      textDirection: TextDirection.ltr,
                      child: CcScrollbar(
                        controller: _scroll,
                        child: SingleChildScrollView(
                          controller: _scroll,
                          padding: const EdgeInsetsDirectional.fromSTEB(
                            AppSpacing.lg,
                            AppSpacing.md,
                            AppSpacing.lg,
                            AppSpacing.xxl,
                          ),
                          child: Align(
                            alignment: AlignmentDirectional.topStart,
                            child: CcSelectionRegion(
                              child: Text(
                                output,
                                style: CcFonts.code(
                                  textStyle: TextStyle(
                                    fontSize: 12,
                                    height: 1.5,
                                    color: t.textPrimary,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                    if (!_following)
                      PositionedDirectional(
                        end: AppSpacing.md,
                        bottom: AppSpacing.md,
                        child: CcButton(
                          icon: AppIcons.arrowDown,
                          size: CcButtonSize.sm,
                          onPressed: _jumpToLatest,
                          child: Text(l10n.agentActivityJumpToLatest),
                        ),
                      ),
                  ],
                ),
        ),
      ],
    );
  }

  Widget _emptyState(AppLocalizations l10n, AgentShellOutputState? state) {
    if (_error != null) {
      return CcEmptyState(
        icon: AppIcons.triangleAlert,
        message: l10n.failedToLoadLogs('$_error'),
        action: CcButton(
          size: CcButtonSize.sm,
          onPressed: _readOutput,
          child: Text(l10n.retry),
        ),
      );
    }
    if (state == null) {
      return const Center(child: CcSpinner(size: 18, strokeWidth: 2));
    }
    return CcEmptyState(
      icon: state == AgentShellOutputState.unavailable
          ? AppIcons.triangleAlert
          : AppIcons.terminal,
      message: state == AgentShellOutputState.unavailable
          ? l10n.unavailable
          : l10n.noExecutionLogsYet,
    );
  }
}
