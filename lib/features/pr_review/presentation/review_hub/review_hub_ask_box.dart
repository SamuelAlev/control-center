import 'package:cc_domain/core/domain/entities/channel_message.dart';
import 'package:cc_ui/cc_ui.dart';
import 'package:control_center/features/messaging/providers/messaging_providers.dart';
import 'package:control_center/features/pr_review/providers/review_studio_providers.dart';
import 'package:control_center/l10n/app_localizations.dart';
import 'package:control_center/shared/icons/app_icons.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Asks one question about one review area, and lists the questions already
/// asked about it.
///
/// The answer deliberately arrives as an ordinary message in the PR channel
/// rather than in a side panel: the sentence that finally explains why an area
/// works the way it does belongs in the transcript with the findings it is
/// about, where it is still there next week. A private chat would lose it.
class ReviewHubAskBox extends ConsumerStatefulWidget {
  /// Creates a [ReviewHubAskBox].
  const ReviewHubAskBox({
    super.key,
    required this.target,
    required this.cohortKey,
    this.channelId,
  });

  /// The PR target.
  final ReviewStudioTarget target;

  /// The area being asked about.
  final String cohortKey;

  /// The PR channel, when one exists — used to list prior questions.
  final String? channelId;

  @override
  ConsumerState<ReviewHubAskBox> createState() => _ReviewHubAskBoxState();
}

class _ReviewHubAskBoxState extends ConsumerState<ReviewHubAskBox> {
  final _controller = TextEditingController();
  bool _open = false;
  bool _sending = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final question = _controller.text.trim();
    if (question.isEmpty || _sending) {
      return;
    }
    setState(() => _sending = true);
    final l10n = AppLocalizations.of(context);
    try {
      final result = await ref
          .read(reviewStudioRepositoryProvider)
          .askArea(
            owner: widget.target.owner,
            repo: widget.target.repo,
            prNumber: widget.target.prNumber,
            cohortKey: widget.cohortKey,
            question: question,
          );
      if (!mounted) {
        return;
      }
      final noAgent = result['status'] == 'no_agent';
      CcToastScope.of(context).show(
        noAgent ? l10n.reviewHubAskNoAgent : l10n.reviewHubAskSent,
        variant: noAgent ? CcToastVariant.warning : CcToastVariant.success,
      );
      _controller.clear();
      setState(() => _open = false);
    } on Object catch (e) {
      if (!mounted) {
        return;
      }
      CcToastScope.of(context).show('$e', variant: CcToastVariant.danger);
    } finally {
      if (mounted) {
        setState(() => _sending = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final ds = context.designSystem!;
    final l10n = AppLocalizations.of(context);
    final asked = _questionsForArea(ref);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (!_open)
          CcTappable(
            onPressed: () => setState(() => _open = true),
            borderRadius: BorderRadius.circular(6),
            builder: (context, states) => Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    AppIcons.messageCircleQuestion,
                    size: 13,
                    color: ds.textSecondary,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    l10n.reviewHubAskArea,
                    style: TextStyle(color: ds.textSecondary, fontSize: 12),
                  ),
                ],
              ),
            ),
          )
        else ...[
          CcTextField(
            controller: _controller,
            hintText: l10n.reviewHubAskPlaceholder,
            autofocus: true,
            onSubmitted: (_) => _submit(),
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              CcButton(
                onPressed: _sending ? null : _submit,
                size: CcButtonSize.sm,
                loading: _sending,
                child: Text(l10n.reviewHubAskSubmit),
              ),
              const SizedBox(width: 6),
              CcTappable(
                onPressed: () => setState(() {
                  _open = false;
                  _controller.clear();
                }),
                borderRadius: BorderRadius.circular(6),
                builder: (context, states) => Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 6,
                  ),
                  child: Text(
                    l10n.cancel,
                    style: TextStyle(color: ds.textTertiary, fontSize: 12),
                  ),
                ),
              ),
            ],
          ),
        ],
        if (asked.isNotEmpty) ...[
          const SizedBox(height: 10),
          Text(
            l10n.reviewHubQuestions,
            style: TextStyle(
              color: ds.textTertiary,
              fontSize: 11,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 4),
          for (final message in asked.take(5))
            Padding(
              padding: const EdgeInsets.only(bottom: 3),
              child: Text(
                message.content.trim(),
                style: TextStyle(color: ds.textSecondary, fontSize: 11),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
        ],
      ],
    );
  }

  /// The questions already asked about THIS area, newest first.
  List<ChannelMessage> _questionsForArea(WidgetRef ref) {
    final channelId = widget.channelId;
    if (channelId == null) {
      return const [];
    }
    final messages = ref
        .watch(channelMessagesProvider(channelId))
        .asData
        ?.value;
    if (messages == null) {
      return const [];
    }
    final out = <ChannelMessage>[];
    for (final m in messages) {
      final ask = m.metadata?['reviewAsk'];
      if (ask is Map && ask['cohortKey'] == widget.cohortKey) {
        out.add(m);
      }
    }
    return out.reversed.toList();
  }
}
