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
