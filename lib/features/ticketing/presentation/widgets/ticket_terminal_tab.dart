import 'package:control_center/core/theme/design_system_tokens.dart';
import 'package:control_center/di/providers.dart';
import 'package:control_center/features/sandboxing/presentation/terminal_panel.dart';
import 'package:control_center/features/ticketing/domain/entities/ticket.dart';
import 'package:control_center/features/ticketing/domain/entities/ticket_collaborator.dart';
import 'package:control_center/l10n/app_localizations.dart';
import 'package:control_center/shared/utils/string_utils.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

/// The "Terminal" tab: an interactive PTY rooted in the ticket folder, reusing
/// the messaging [TerminalPanel]. The session resolves from the ticket's
/// assigned agent (its on-disk directory becomes the writable workspace, and
/// the cwd is the ticket's conversation folder). When no agent is assigned,
/// shows a hint. The parent panel keeps this tab mounted, so the shell stays
/// alive across tab switches.
class TicketTerminalTab extends ConsumerStatefulWidget {
  /// Creates a [TicketTerminalTab].
  const TicketTerminalTab({super.key, required this.ticket});

  /// The ticket being viewed.
  final Ticket ticket;

  @override
  ConsumerState<TicketTerminalTab> createState() => _TicketTerminalTabState();
}

class _TicketTerminalTabState extends ConsumerState<TicketTerminalTab> {
  TerminalSession? _session;
  bool _resolving = true;

  @override
  void initState() {
    super.initState();
    _resolve();
  }

  Future<void> _resolve() async {
    final agentId = widget.ticket.assignedAgentId;
    if (agentId == null || agentId == TicketCollaborator.userSentinel) {
      if (mounted) {
        setState(() => _resolving = false);
      }
      return;
    }
    final agent = await ref.read(agentRepositoryProvider).getById(agentId);
    if (agent == null) {
      if (mounted) {
        setState(() => _resolving = false);
      }
      return;
    }
    final fs = ref.read(workspaceFilesystemPortProvider);
    final slug = slugify(agent.name);
    final dir = await fs.agentDir(agent.workspaceId, slug);
    if (!dir.existsSync()) {
      await fs.ensureAgentDir(agent.workspaceId, slug);
    }
    if (!mounted) {
      return;
    }
    setState(() {
      _session = TerminalSession(
        sessionId: widget.ticket.channelId ?? widget.ticket.id,
        agentDirHostPath: dir.path,
        workspaceId: agent.workspaceId,
        agentId: agent.id,
      );
      _resolving = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_resolving) {
      return const Center(child: CircularProgressIndicator());
    }
    final session = _session;
    if (session == null) {
      return const _NoAgent();
    }
    return TerminalPanel(session: session);
  }
}

class _NoAgent extends StatelessWidget {
  const _NoAgent();

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final t = context.designSystem ?? DesignSystemTokens.light();
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(LucideIcons.terminal, size: 32, color: t.fgQuaternary),
          const SizedBox(height: 10),
          Text(
            l10n.ticketTerminalNoAgent,
            style: TextStyle(color: t.textTertiary, fontSize: 13),
          ),
        ],
      ),
    );
  }
}
