import 'package:cc_domain/cc_domain.dart';
import 'package:cc_domain/features/plan_studio/domain/entities/playbook.dart';
import 'package:cc_remote/app_icons.dart';
import 'package:cc_remote/providers.dart';
import 'package:cc_rpc/cc_rpc.dart';
import 'package:cc_ui/cc_ui.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

/// Playbooks tab: live playbooks (`playbook.watchForWorkspace`) — saved,
/// parameterized plans (PRD 17 §10). Tapping one pushes the run screen.
class PlaybooksScreen extends ConsumerWidget {
  /// Creates a [PlaybooksScreen].
  const PlaybooksScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = context.designSystem ?? DesignSystemTokens.light();
    final async = ref.watch(playbooksProvider);

    return ColoredBox(
      color: t.canvas,
      child: async.when(
        loading: () => const Center(child: CcSpinner(size: 24)),
        error: (e, _) => CcEmptyState(
          icon: AppIcons.triangleAlert,
          message: "Couldn't load playbooks",
          description: e.toString(),
        ),
        data: (playbooks) {
          if (playbooks.isEmpty) {
            return const CcEmptyState(
              icon: AppIcons.layers,
              message: 'No playbooks',
              description:
                  'Playbooks saved from the desktop Plan Studio appear here.',
            );
          }
          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: playbooks.length,
            separatorBuilder: (_, _) => const SizedBox(height: 8),
            itemBuilder: (context, i) =>
                _playbookCard(context, t, playbooks[i]),
          );
        },
      ),
    );
  }

  Widget _playbookCard(
    BuildContext context,
    DesignSystemTokens t,
    PlaybookDto playbook,
  ) {
    return CcCard(
      interactive: true,
      semanticLabel: playbook.name,
      onPressed: () => context.push('/playbook/${playbook.id}'),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(AppIcons.layers, size: 18, color: t.fgSecondary),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  playbook.name,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w500,
                    color: t.textPrimary,
                  ),
                ),
                if (playbook.description.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    playbook.description,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(fontSize: 13, color: t.textTertiary),
                  ),
                ],
                const SizedBox(height: 8),
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: [
                    CcBadge(label: 'v${playbook.version}'),
                    CcBadge(
                      label: playbook.params.isEmpty
                          ? 'No parameters'
                          : '${playbook.params.length} '
                                '${playbook.params.length == 1 ? 'parameter' : 'parameters'}',
                      variant: CcBadgeVariant.brand,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// `/playbook/:id` — the run screen: a parameter form (typed per
/// [PlaybookParamType]) plus an anchor-ticket picker, ending in a `Run` action
/// that calls `playbook.run`.
///
/// Running only PROPOSES a plan — the operator still approves it from the
/// desktop/web Plan Studio before anything executes or spends. That is what
/// makes this safe to trigger from the phone tier (PRD 17 §10).
class PlaybookRunScreen extends ConsumerStatefulWidget {
  /// Creates a [PlaybookRunScreen].
  const PlaybookRunScreen({required this.playbookId, super.key});

  /// The playbook id from the route.
  final String playbookId;

  @override
  ConsumerState<PlaybookRunScreen> createState() => _PlaybookRunScreenState();
}

class _PlaybookRunScreenState extends ConsumerState<PlaybookRunScreen> {
  final Map<String, TextEditingController> _controllers = {};
  final Map<String, String> _enumSelections = {};
  String? _ticketId;
  bool _choosingTicket = false;
  bool _running = false;
  String? _error;
  Map<String, dynamic>? _result;

  @override
  void dispose() {
    for (final c in _controllers.values) {
      c.dispose();
    }
    super.dispose();
  }

  TextEditingController _controllerFor(PlaybookParam p) => _controllers
      .putIfAbsent(p.name, () => TextEditingController(text: p.defaultValue));

  String _valueFor(PlaybookParam p) {
    if (p.type == PlaybookParamType.enumeration) {
      return _enumSelections[p.name] ?? p.defaultValue ?? '';
    }
    return _controllerFor(p).text;
  }

  Future<void> _run(PlaybookDto playbook) async {
    final ticketId = _ticketId;
    final client = ref.read(rpcClientProvider).value;
    if (ticketId == null || client == null) {
      return;
    }
    setState(() {
      _running = true;
      _error = null;
    });
    final args = <String, String>{
      for (final p in playbook.params) p.name: _valueFor(p).trim(),
    };
    try {
      final data = await client.call('playbook.run', {
        'playbook_id': playbook.id,
        'ticket_id': ticketId,
        'args': args,
      });
      if (!mounted) {
        return;
      }
      setState(() {
        _result = data;
        _running = false;
      });
    } on RemoteRpcException catch (e) {
      if (!mounted) {
        return;
      }
      // Verbatim: the host's message already lists exactly which parameters
      // are missing/invalid (or the underlying propose validation failure).
      setState(() {
        _error = e.message;
        _running = false;
      });
    } catch (e) {
      if (!mounted) {
        return;
      }
      setState(() {
        _error = e.toString();
        _running = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = context.designSystem ?? DesignSystemTokens.light();
    final playbook = ref
        .watch(playbooksProvider)
        .value
        ?.where((p) => p.id == widget.playbookId)
        .firstOrNull;

    return SafeArea(
      child: ColoredBox(
        color: t.canvas,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _PlaybookHeader(title: playbook?.name ?? 'Playbook'),
            if (playbook == null)
              const Expanded(child: Center(child: CcSpinner(size: 24)))
            else if (_result != null)
              Expanded(child: _successBody(t, _result!))
            else if (_choosingTicket)
              Expanded(
                child: _TicketChooser(
                  onPick: (ticket) => setState(() {
                    _ticketId = ticket.id;
                    _choosingTicket = false;
                  }),
                  onCancel: () => setState(() => _choosingTicket = false),
                ),
              )
            else
              Expanded(child: _form(t, playbook)),
          ],
        ),
      ),
    );
  }

  Widget _form(DesignSystemTokens t, PlaybookDto playbook) {
    final tickets = ref.watch(ticketsProvider).value ?? const <TicketDto>[];
    final selectedTicket = tickets
        .where((tk) => tk.id == _ticketId)
        .firstOrNull;

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        if (playbook.description.isNotEmpty) ...[
          Text(
            playbook.description,
            style: TextStyle(fontSize: 14, height: 1.5, color: t.textSecondary),
          ),
          const SizedBox(height: 12),
        ],
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            CcBadge(label: 'v${playbook.version}'),
            CcBadge(
              label: playbook.params.isEmpty
                  ? 'No parameters'
                  : '${playbook.params.length} '
                        '${playbook.params.length == 1 ? 'parameter' : 'parameters'}',
              variant: CcBadgeVariant.brand,
            ),
          ],
        ),
        const SizedBox(height: 20),
        if (_error != null) ...[
          _errorBanner(t, _error!),
          const SizedBox(height: 16),
        ],
        if (playbook.params.isNotEmpty) ...[
          _sectionLabel(t, 'Parameters'),
          const SizedBox(height: 12),
          for (final p in playbook.params) _paramField(t, p),
          const SizedBox(height: 4),
        ],
        _sectionLabel(t, 'Anchor ticket'),
        const SizedBox(height: 4),
        Text(
          'The proposed plan is parked under this ticket for the operator to '
          'review.',
          style: TextStyle(fontSize: 12, color: t.textTertiary),
        ),
        const SizedBox(height: 10),
        _anchorTicketCard(t, selectedTicket),
        const SizedBox(height: 24),
        CcButton(
          fullWidth: true,
          icon: AppIcons.sparkles,
          loading: _running,
          onPressed: (_ticketId == null || _running)
              ? null
              : () => _run(playbook),
          child: const Text('Propose plan'),
        ),
      ],
    );
  }

  Widget _sectionLabel(DesignSystemTokens t, String text) {
    return Text(
      text,
      style: TextStyle(
        fontSize: 13,
        fontWeight: FontWeight.w600,
        color: t.textTertiary,
      ),
    );
  }

  Widget _paramField(DesignSystemTokens t, PlaybookParam p) {
    final requiredSuffix = p.required ? ' (required)' : ' (optional)';
    if (p.type == PlaybookParamType.enumeration) {
      final selected = _enumSelections.putIfAbsent(
        p.name,
        () => p.defaultValue ?? '',
      );
      return Padding(
        padding: const EdgeInsets.only(bottom: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '${p.name}$requiredSuffix',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: t.textSecondary,
              ),
            ),
            if (p.description.isNotEmpty) ...[
              const SizedBox(height: 2),
              Text(
                p.description,
                style: TextStyle(fontSize: 12, color: t.textTertiary),
              ),
            ],
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final choice in p.choices)
                  CcChip(
                    label: choice,
                    selected: selected == choice,
                    onTap: () =>
                        setState(() => _enumSelections[p.name] = choice),
                  ),
              ],
            ),
          ],
        ),
      );
    }

    final hint = switch (p.type) {
      PlaybookParamType.repoRef => 'Repo id',
      PlaybookParamType.agentRef => 'Agent id',
      _ => null,
    };
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: CcTextField(
        controller: _controllerFor(p),
        label: '${p.name}$requiredSuffix',
        hintText: hint,
        helperText: p.description.isNotEmpty ? p.description : null,
      ),
    );
  }

  Widget _errorBanner(DesignSystemTokens t, String message) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: t.dangerSoft,
        borderRadius: const BorderRadius.all(Radius.circular(12)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(AppIcons.triangleAlert, size: 16, color: t.textErrorPrimary),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                message,
                style: TextStyle(fontSize: 13, color: t.textPrimary),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _anchorTicketCard(DesignSystemTokens t, TicketDto? ticket) {
    if (ticket == null) {
      return CcCard(
        interactive: true,
        semanticLabel: 'Choose an anchor ticket',
        onPressed: () => setState(() => _choosingTicket = true),
        child: Row(
          children: [
            Icon(AppIcons.ticket, size: 18, color: t.fgSecondary),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                'Choose an open ticket',
                style: TextStyle(fontSize: 14, color: t.textSecondary),
              ),
            ),
            Icon(AppIcons.chevronRight, size: 16, color: t.fgTertiary),
          ],
        ),
      );
    }
    return CcCard(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(AppIcons.ticket, size: 18, color: t.fgSecondary),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (ticket.key.isNotEmpty)
                  Text(
                    ticket.key,
                    style: TextStyle(fontSize: 12, color: t.textTertiary),
                  ),
                Text(
                  ticket.title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: t.textPrimary,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          CcButton(
            variant: CcButtonVariant.secondary,
            size: CcButtonSize.sm,
            onPressed: _running
                ? null
                : () => setState(() => _choosingTicket = true),
            child: const Text('Change'),
          ),
        ],
      ),
    );
  }

  Widget _successBody(DesignSystemTokens t, Map<String, dynamic> result) {
    final orchestrationId = result['orchestration_id']?.toString() ?? '';
    final revision = result['revision'];
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        const SizedBox(height: 24),
        Center(child: Icon(AppIcons.circleCheck, size: 40, color: t.success)),
        const SizedBox(height: 16),
        Text(
          'Plan proposed',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: t.textPrimary,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Approve it from the desktop or web Plan Studio — nothing runs or '
          'spends until then.',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 14, height: 1.5, color: t.textSecondary),
        ),
        if (orchestrationId.isNotEmpty) ...[
          const SizedBox(height: 20),
          Center(
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: t.bgSecondary,
                borderRadius: const BorderRadius.all(Radius.circular(8)),
              ),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 6,
                ),
                child: Text(
                  revision != null
                      ? 'Orchestration $orchestrationId · rev $revision'
                      : 'Orchestration $orchestrationId',
                  style: CcFonts.code(
                    textStyle: TextStyle(fontSize: 12, color: t.textSecondary),
                  ),
                ),
              ),
            ),
          ),
        ],
        const SizedBox(height: 28),
        CcButton(
          fullWidth: true,
          variant: CcButtonVariant.secondary,
          onPressed: () => context.pop(),
          child: const Text('Done'),
        ),
      ],
    );
  }
}

class _PlaybookHeader extends StatelessWidget {
  const _PlaybookHeader({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    final t = context.designSystem ?? DesignSystemTokens.light();
    return DecoratedBox(
      decoration: BoxDecoration(
        color: t.topbar,
        border: Border(bottom: BorderSide(color: t.borderSoft)),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
        child: Row(
          children: [
            CcTappable(
              onPressed: () => context.pop(),
              semanticLabel: 'Back',
              builder: (context, _) => Padding(
                padding: const EdgeInsets.all(8),
                child: Icon(AppIcons.arrowLeft, color: t.fgSecondary),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: t.textPrimary,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Inline anchor-ticket picker: open tickets in the active workspace (not
/// `done`), reusing the same live [ticketsProvider] the Tickets tab shows.
class _TicketChooser extends ConsumerWidget {
  const _TicketChooser({required this.onPick, required this.onCancel});

  final ValueChanged<TicketDto> onPick;
  final VoidCallback onCancel;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = context.designSystem ?? DesignSystemTokens.light();
    final tickets = (ref.watch(ticketsProvider).value ?? const <TicketDto>[])
        .where((tk) => tk.status != 'done')
        .toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Expanded(
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              if (tickets.isEmpty)
                const CcEmptyState(
                  icon: AppIcons.ticket,
                  message: 'No open tickets',
                  description:
                      'Open a ticket first, then anchor this plan to it.',
                ),
              for (final tk in tickets)
                Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: CcCard(
                    interactive: true,
                    semanticLabel: tk.title,
                    onPressed: () => onPick(tk),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(AppIcons.ticket, size: 18, color: t.fgSecondary),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              if (tk.key.isNotEmpty)
                                Text(
                                  tk.key,
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: t.textTertiary,
                                  ),
                                ),
                              Text(
                                tk.title,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w500,
                                  color: t.textPrimary,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          child: CcButton(
            fullWidth: true,
            variant: CcButtonVariant.secondary,
            onPressed: onCancel,
            child: const Text('Cancel'),
          ),
        ),
      ],
    );
  }
}
