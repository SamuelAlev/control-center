import 'dart:async';

import 'package:cc_domain/core/domain/entities/agent_shell_process.dart';
import 'package:cc_ui/cc_ui.dart';
import 'package:control_center/features/sandboxing/providers/agent_shell_providers.dart';
import 'package:control_center/features/sandboxing/providers/terminal_sessions_provider.dart';
import 'package:control_center/l10n/app_localizations.dart';
import 'package:control_center/shared/icons/app_icons.dart';
import 'package:control_center/shared/utils/relative_time.dart';
import 'package:control_center/shared/widgets/collapsible_sidebar_section.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// The TERMINALS section of the messaging IDE's General panel: the
/// conversation's shells, then the commands its agents left running — a
/// backgrounded task, or a foreground one that outlived a quick call.
///
/// Both kinds of row carry their stop on hover: a terminal's trash ends the
/// shell, an agent command's stop ends the command and everything under it.
/// That is the way out of a stuck test run or a dev server the agent forgot,
/// without hunting its pid in another terminal.
class TerminalsSection extends ConsumerWidget {
  /// Creates a [TerminalsSection].
  const TerminalsSection({
    super.key,
    required this.spaceId,
    required this.workspaceId,
    required this.onFocusTerminal,
    required this.onKillTerminal,
  });

  /// The active conversation.
  final String spaceId;

  /// The active workspace.
  final String workspaceId;

  /// Focuses (or opens) the terminal identified by its session id.
  final ValueChanged<String> onFocusTerminal;

  /// Ends the terminal identified by its session id, closing its tab.
  final ValueChanged<String> onKillTerminal;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final sessions = ref.watch(spaceTerminalsProvider(spaceId));
    final key = (workspaceId: workspaceId, spaceId: spaceId);
    final commands =
        ref.watch(spaceAgentShellsProvider(key)).asData?.value ??
        const <AgentShellProcess>[];
    final total = sessions.length + commands.length;
    return CollapsibleSidebarSection(
      icon: AppIcons.terminal,
      label: l10n.generalSectionTerminals,
      count: total == 0 ? null : '$total',
      child: total == 0
          ? SidebarEmptyRow(message: l10n.generalTerminalsEmpty)
          : Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                for (final s in sessions)
                  _TerminalRow(
                    mirror: s,
                    onTap: () => onFocusTerminal(s.sessionId),
                    onKill: () => onKillTerminal(s.sessionId),
                  ),
                for (final c in commands)
                  _AgentCommandRow(
                    // Keyed by pid so a row's "stopping" state stays with its
                    // command when the one above it exits.
                    key: ValueKey(c.pid),
                    process: c,
                    shellsKey: key,
                  ),
              ],
            ),
    );
  }
}

/// A flat hover wash instead of an ink ripple — the design system reports
/// state through color, not motion. Shared by both row kinds so a terminal
/// and an agent command read as one list.
class _RowShell extends StatelessWidget {
  const _RowShell({required this.hovered, required this.child});

  final bool hovered;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final t = context.designSystem ?? DesignSystemTokens.light();
    return ColoredBox(
      color: hovered ? t.bgSecondaryHover : const Color(0x00000000),
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.sm,
          vertical: 5,
        ),
        child: child,
      ),
    );
  }
}

/// One shell: a live dot, its title, and — on hover — the trash that ends it.
class _TerminalRow extends StatelessWidget {
  const _TerminalRow({
    required this.mirror,
    required this.onTap,
    required this.onKill,
  });

  final TerminalMirror mirror;
  final VoidCallback onTap;
  final VoidCallback onKill;

  @override
  Widget build(BuildContext context) {
    final t = context.designSystem ?? DesignSystemTokens.light();
    final l10n = AppLocalizations.of(context);
    // Prefer the shell's live title (OSC / foreground process); fall back to
    // the bound agent id, then the generic section label.
    final name = mirror.title.isNotEmpty
        ? mirror.title
        : (mirror.session.agentId.isEmpty
              ? l10n.terminal
              : mirror.session.agentId);
    return CcTappable(
      onPressed: onTap,
      semanticLabel: l10n.focusTerminal,
      builder: (context, states) {
        final hovered = states.contains(WidgetState.hovered);
        return _RowShell(
          hovered: hovered,
          child: Row(
            children: [
              const CcStatusDot(tone: CcStatusTone.positive),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Text(
                  name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(fontSize: 13, color: t.textSecondary),
                ),
              ),
              // Hover only, like the BROWSERS rows' ×: the list reads clean at
              // rest, and ending the shell is the one action a row carries.
              if (hovered)
                _RowAction(
                  icon: AppIcons.trash2,
                  label: l10n.killTerminal,
                  onPressed: onKill,
                ),
            ],
          ),
        );
      },
    );
  }
}

/// One agent command: the command as the agent wrote it (mono — it is code),
/// how long it has run, and — on hover — the stop. The full command is in the
/// tooltip; a row only has room for its start.
class _AgentCommandRow extends ConsumerStatefulWidget {
  const _AgentCommandRow({
    super.key,
    required this.process,
    required this.shellsKey,
  });

  final AgentShellProcess process;
  final AgentShellsKey shellsKey;

  @override
  ConsumerState<_AgentCommandRow> createState() => _AgentCommandRowState();
}

class _AgentCommandRowState extends ConsumerState<_AgentCommandRow> {
  /// Set from the stop until the row leaves the list: a stopped command gets
  /// a grace period to exit, and the row must not look like nothing happened.
  bool _stopping = false;

  Future<void> _stop() async {
    setState(() => _stopping = true);
    final toast = CcToastScope.maybeOf(context);
    final p = widget.process;
    try {
      await ref
          .read(agentShellProcessPortProvider)
          .kill(workspaceId: p.workspaceId, spaceId: p.spaceId, pid: p.pid);
    } on Object catch (e) {
      if (mounted) {
        setState(() => _stopping = false);
      }
      toast?.show('$e', variant: CcToastVariant.danger);
      return;
    }
    ref.invalidate(spaceAgentShellsProvider(widget.shellsKey));
  }

  @override
  Widget build(BuildContext context) {
    final t = context.designSystem ?? DesignSystemTokens.light();
    final l10n = AppLocalizations.of(context);
    final p = widget.process;
    // ps and the shell both render a multi-line script; the row shows its
    // first line, the tooltip all of it.
    final firstLine = p.command.split('\n').first;
    final elapsed = _compactElapsed(context, p.startedAt);
    final status = _stopping ? l10n.agentCommandStopping : elapsed;
    return Semantics(
      label: l10n.agentCommandSemantics(firstLine, elapsed),
      container: true,
      child: _HoverBuilder(
        builder: (hovered) => _RowShell(
          hovered: hovered,
          child: Row(
            children: [
              CcStatusDot(
                tone: _stopping ? CcStatusTone.neutral : CcStatusTone.positive,
              ),
              const SizedBox(width: AppSpacing.sm),
              Icon(AppIcons.bot, size: 14, color: t.textSecondary),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: CcTooltip(
                  message: p.command,
                  // RTL carve-out: a shell command reads left to right.
                  child: Text(
                    firstLine,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    textDirection: TextDirection.ltr,
                    style: CcFonts.code(
                      textStyle: TextStyle(
                        fontSize: 12,
                        color: t.textSecondary,
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: AppSpacing.xs),
              Text(
                status,
                maxLines: 1,
                style: CcFonts.code(
                  textStyle: TextStyle(fontSize: 11, color: t.textQuaternary),
                ),
              ),
              if (hovered && !_stopping) ...[
                const SizedBox(width: AppSpacing.xs),
                _RowAction(
                  icon: AppIcons.circleStop,
                  label: l10n.stopAgentCommand,
                  onPressed: () => unawaited(_stop()),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

/// `12s` under a minute (a running command's first minute is when it matters
/// most whether it is moving), then the sidebar's compact age.
String _compactElapsed(BuildContext context, DateTime startedAt) {
  final seconds = DateTime.now().difference(startedAt).inSeconds;
  if (seconds < 60) {
    return AppLocalizations.of(
      context,
    ).sidebarAgeSeconds(seconds < 0 ? 0 : seconds);
  }
  return formatCompactAge(context, startedAt);
}

/// Hover state for a row that is not itself a button: the agent command row
/// has nothing to open, only the stop.
class _HoverBuilder extends StatefulWidget {
  const _HoverBuilder({required this.builder});

  final Widget Function(bool hovered) builder;

  @override
  State<_HoverBuilder> createState() => _HoverBuilderState();
}

class _HoverBuilderState extends State<_HoverBuilder> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) => MouseRegion(
    onEnter: (_) => setState(() => _hovered = true),
    onExit: (_) => setState(() => _hovered = false),
    child: widget.builder(_hovered),
  );
}

/// A row's trailing action: the glyph alone, named by its tooltip. The
/// sidebar's in-row idiom (see the rig rows' power button) — a 32px
/// CcIconButton would tower over these dense rows. It paints its own hover
/// only when its own target is hovered.
class _RowAction extends StatelessWidget {
  const _RowAction({
    required this.icon,
    required this.label,
    required this.onPressed,
  });

  final IconData icon;
  final String label;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final t = context.designSystem ?? DesignSystemTokens.light();
    return Semantics(
      button: true,
      label: label,
      child: CcTooltip(
        message: label,
        child: CcTappable(
          onPressed: onPressed,
          borderRadius: AppRadii.brSm,
          builder: (context, states) => Padding(
            padding: const EdgeInsets.all(2),
            child: Icon(
              icon,
              size: 14,
              color: states.contains(WidgetState.hovered)
                  ? t.textPrimary
                  : t.textSecondary,
            ),
          ),
        ),
      ),
    );
  }
}
