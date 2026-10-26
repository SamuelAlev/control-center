part of 'agent_transcript.dart';

Widget _detail(DesignSystemTokens t, String label, String body) {
  return Padding(
    padding: const EdgeInsets.only(top: 6),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.w600,
            color: t.fgTertiary,
          ),
        ),
        const SizedBox(height: 2),
        // RTL carve-out: tool inputs/outputs are code/JSON — LTR in every
        // locale.
        Directionality(
          textDirection: TextDirection.ltr,
          child: Text(
            body,
            maxLines: 8,
            overflow: TextOverflow.ellipsis,
            style: CcFonts.code(
              textStyle: TextStyle(
                fontSize: 11,
                height: 1.4,
                color: t.textSecondary,
              ),
            ),
          ),
        ),
      ],
    ),
  );
}

String _pretty(Map<String, dynamic>? json) {
  if (json == null) {
    return '';
  }
  try {
    return const JsonEncoder.withIndent('  ').convert(json);
  } catch (_) {
    return json.toString();
  }
}

/// A turn whose credential stopped authenticating: what happened and the
/// fix, rather than the CLI's sentence as a log line. The sentence stays
/// underneath as the evidence.
Widget _authFailure(
  BuildContext context,
  DesignSystemTokens t,
  ErrorSegment s,
) {
  final l10n = AppLocalizations.of(context);
  final claude = s.source == ErrorSegment.claudeCodeSource;
  final detail = s.message.replaceFirst(RegExp(r'^\[\w+\]\s*'), '').trim();
  return CcAlert(
    variant: CcAlertVariant.warning,
    icon: CcIcons.keyRound,
    title: claude
        ? l10n.transcriptClaudeSignInExpiredTitle
        : l10n.transcriptSignInExpiredTitle,
    description: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          claude
              ? l10n.transcriptClaudeSignInExpiredBody
              : l10n.transcriptSignInExpiredBody,
          style: TextStyle(fontSize: 12, color: t.textSecondary),
        ),
        if (detail.isNotEmpty) ...[
          const SizedBox(height: 4),
          Text(
            detail,
            maxLines: 3,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(fontSize: 12, color: t.textTertiary),
          ),
        ],
      ],
    ),
  );
}
