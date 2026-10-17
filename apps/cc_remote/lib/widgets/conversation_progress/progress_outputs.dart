import 'package:cc_domain/cc_domain.dart';
import 'package:cc_domain/core/domain/value_objects/message_attachment.dart';
import 'package:cc_remote/conversation_progress_providers.dart';
import 'package:cc_remote/l10n/app_localizations.dart';
import 'package:cc_remote/widgets/conversation_progress/progress_output_row.dart';
import 'package:cc_remote/widgets/conversation_progress/progress_shared.dart';
import 'package:cc_ui/cc_ui.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class ProgressOutputs extends ConsumerStatefulWidget {
  const ProgressOutputs({required this.scope, required this.runs, super.key});

  final ProgressScope scope;
  final List<AgentRunLogDto> runs;

  @override
  ConsumerState<ProgressOutputs> createState() => _ProgressOutputsState();
}

class _ProgressOutputsState extends ConsumerState<ProgressOutputs> {
  String? _openedArtifactId;

  @override
  Widget build(BuildContext context) {
    final scope = widget.scope;
    final l = AppLocalizations.of(context);
    final t = context.designSystem ?? DesignSystemTokens.light();
    final recent = ref.watch(progressRecentMessagesProvider(scope));
    if (recent.hasError) {
      return progressError(
        l,
        recent.error!,
        () => ref.invalidate(progressRecentMessagesProvider(scope)),
      );
    }
    if (recent.isLoading) return const CcSpinner(size: 18);
    final messages = recent.value?.messages ?? const <MessageDto>[];
    final outputs = <MessageDto>[];
    for (final message in messages.reversed) {
      final metadata = message.metadata;
      final meta = metadata is Map ? metadata.cast<String, dynamic>() : null;
      if (message.senderType == 'agent' &&
          (message.content.trim().isNotEmpty ||
              meta?['workProductId'] is String ||
              meta?['planId'] is String ||
              meta?['entityRefs'] is List ||
              MessageAttachment.attachmentsFromMetadata(meta).isNotEmpty)) {
        outputs.add(message);
      }
    }
    if (outputs.isEmpty) {
      return Text(
        widget.runs.any((run) => run.outputJson != null)
            ? l.progressStructuredOutputsAbove
            : l.progressNoOutputs,
        style: CcTypography.bodySm.copyWith(color: t.textSecondary),
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (final message in outputs.take(8))
          ProgressOutputRow(
            scope: scope,
            message: message,
            openedArtifactId: _openedArtifactId,
            onToggleArtifact: (id) => setState(
              () => _openedArtifactId = _openedArtifactId == id ? null : id,
            ),
          ),
        if (recent.value?.hasMore == true)
          Text(
            l.progressRecentOutputsOnly,
            style: CcTypography.caption.copyWith(color: t.textSecondary),
          ),
      ],
    );
  }
}
