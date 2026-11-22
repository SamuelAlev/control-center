import 'package:cc_ui/cc_ui.dart';
import 'package:control_center/features/agents/providers/agent_providers.dart';
import 'package:control_center/l10n/app_localizations.dart';
import 'package:control_center/shared/icons/app_icons.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path/path.dart' as p;

/// Shows one run's recorded NDJSON events.
///
/// The log file lives in the SERVER's data directory, so its contents are
/// fetched with an RPC op. This dialog used to `File(...).readAsLines()` the
/// path directly, which rendered an empty list with no error whenever the
/// server was not the local machine.
class AgentRunViewerDialog extends ConsumerStatefulWidget {
  /// Creates the viewer for one run.
  const AgentRunViewerDialog({
    super.key,
    required this.runId,
    required this.logPath,
    required this.workspaceId,
  });

  /// The run whose log to read (the server resolves the file from this).
  final String runId;

  /// The server-side path — displayed as the dialog title only, never opened.
  final String logPath;

  /// The workspace the run belongs to (scopes the read).
  final String workspaceId;

  @override
  ConsumerState<AgentRunViewerDialog> createState() =>
      _AgentRunViewerDialogState();
}

class _AgentRunViewerDialogState extends ConsumerState<AgentRunViewerDialog> {
  late Future<List<Map<String, dynamic>>> _events;

  @override
  void initState() {
    super.initState();
    _events = _load();
  }

  Future<List<Map<String, dynamic>>> _load() async {
    final read = await ref
        .read(remoteAgentRunLogOpsProvider)
        .readEvents(widget.workspaceId, widget.runId);
    return [
      if (read.truncated)
        {'type': 'raw', 'content': '… (older lines trimmed by the server)'},
      ...read.events,
    ];
  }

  @override
  Widget build(BuildContext context) {
    final tokens = context.designSystem ?? DesignSystemTokens.light();
    final l10n = AppLocalizations.of(context);
    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 720, maxHeight: 600),
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: tokens.bgPrimary,
          borderRadius: AppRadii.brLg,
          border: Border.all(color: tokens.borderPrimary),
        ),
        child: ClipRRect(
          borderRadius: AppRadii.brLg,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(
                padding: const EdgeInsetsDirectional.fromSTEB(16, 14, 8, 8),
                child: Row(
                  children: [
                    Icon(
                      AppIcons.scrollText,
                      size: 16,
                      color: tokens.textPrimary,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        p.basename(widget.logPath),
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          fontFamily: 'monospace',
                          color: tokens.textPrimary,
                        ),
                      ),
                    ),
                    CcIconButton(
                      icon: AppIcons.x,
                      tooltip: l10n.close,
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                  ],
                ),
              ),
              const CcDivider(),
              Flexible(
                child: FutureBuilder<List<Map<String, dynamic>>>(
                  future: _events,
                  builder: (context, snap) {
                    if (snap.connectionState != ConnectionState.done) {
                      return const Center(child: CcSpinner());
                    }
                    if (snap.hasError) {
                      return Padding(
                        padding: const EdgeInsets.all(16),
                        child: Text(
                          'Failed to read log: ${snap.error}',
                          style: TextStyle(color: tokens.textErrorPrimary),
                        ),
                      );
                    }
                    final events = snap.data ?? const [];
                    return ListView.builder(
                      padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                      itemCount: events.length,
                      itemBuilder: (_, i) {
                        final e = events[i];
                        final type = (e['type'] as String?) ?? 'raw';
                        final ts = e['ts'] as String?;
                        final content =
                            (e['content'] as String?) ??
                            e['eventType']?.toString() ??
                            '';
                        Color color = tokens.textPrimary;
                        if (type == 'start') {
                          color = tokens.textPrimary;
                        }
                        if (type == 'end') {
                          color = tokens.success;
                        }
                        if (type == 'event' && e['eventType'] == 'error') {
                          color = tokens.textErrorPrimary;
                        }
                        return Padding(
                          padding: const EdgeInsets.symmetric(vertical: 2),
                          child: RichText(
                            text: TextSpan(
                              style: TextStyle(
                                fontFamily: 'monospace',
                                fontSize: 11,
                                color: tokens.textPrimary,
                              ),
                              children: [
                                if (ts != null)
                                  TextSpan(
                                    text: '${ts.substring(11, 19)}  ',
                                    style: TextStyle(
                                      color: tokens.textTertiary,
                                    ),
                                  ),
                                TextSpan(
                                  text: '$type ',
                                  style: TextStyle(
                                    color: color,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                if (type == 'event')
                                  TextSpan(
                                    text: '${e['eventType']} ',
                                    style: TextStyle(
                                      color: tokens.textTertiary,
                                    ),
                                  ),
                                TextSpan(text: content),
                                if (e['exitCode'] != null)
                                  TextSpan(
                                    text: ' exit=${e['exitCode']}',
                                    style: TextStyle(color: color),
                                  ),
                              ],
                            ),
                          ),
                        );
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
