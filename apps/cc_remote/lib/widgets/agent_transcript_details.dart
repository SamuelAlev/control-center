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

/// A run the server refused before it started because it has no sandbox:
/// guidance worded by the segment's code, not a red log line.
Widget _sandboxUnavailable(BuildContext context) {
  final l10n = AppLocalizations.of(context);
  return CcAlert(
    variant: CcAlertVariant.info,
    icon: CcIcons.lock,
    title: l10n.runSandboxUnavailableTitle,
    description: Text(l10n.runSandboxUnavailable),
  );
}

Widget? _reasoning(DesignSystemTokens t, ReasoningSegment s) {
  if (s.text.trim().isEmpty) {
    return null;
  }
  // A faint leading rail sets the agent's thinking apart from its answer now
  // that both interleave in one column (the answer is upright primary text).
  return DecoratedBox(
    decoration: BoxDecoration(
      border: BorderDirectional(
        start: BorderSide(color: t.borderSecondary, width: 2),
      ),
    ),
    child: Padding(
      padding: const EdgeInsetsDirectional.only(start: 8),
      child: Text(
        s.text,
        style: TextStyle(
          fontSize: 13,
          height: 1.4,
          fontStyle: FontStyle.italic,
          color: t.textTertiary,
        ),
      ),
    ),
  );
}

Widget _mono(DesignSystemTokens t, String text, Color bg, Color fg) {
  return DecoratedBox(
    decoration: BoxDecoration(
      color: bg,
      borderRadius: const BorderRadius.all(Radius.circular(8)),
    ),
    child: Padding(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      // RTL carve-out: error/violation payloads are log output — LTR in
      // every locale.
      child: Directionality(
        textDirection: TextDirection.ltr,
        child: Text(
          text,
          style: CcFonts.code(
            textStyle: TextStyle(fontSize: 12, height: 1.4, color: fg),
          ),
        ),
      ),
    ),
  );
}
