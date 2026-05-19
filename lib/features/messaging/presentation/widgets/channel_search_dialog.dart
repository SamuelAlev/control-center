import 'dart:async';

import 'package:cc_ui/cc_ui.dart';
import 'package:control_center/features/messaging/providers/channel_search_providers.dart';
import 'package:control_center/features/messaging/providers/messaging_providers.dart';
import 'package:control_center/l10n/app_localizations.dart';
import 'package:control_center/shared/icons/app_icons.dart';
import 'package:control_center/shared/utils/format_utils.dart';
import 'package:control_center/shared/widgets/app_timestamp.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// In-channel full-text search (§8.4): a debounced search field over a live
/// results list. Selecting a result sets the pending-focus message so the feed
/// scrolls/highlights it (the same jump-to mechanism used by `?m=` deep links),
/// then closes the dialog.
class ChannelSearchDialog extends ConsumerStatefulWidget {
  /// Creates the dialog for [channelId].
  const ChannelSearchDialog({super.key, required this.channelId});

  /// The channel being searched.
  final String channelId;

  @override
  ConsumerState<ChannelSearchDialog> createState() =>
      _ChannelSearchDialogState();
}

class _ChannelSearchDialogState extends ConsumerState<ChannelSearchDialog> {
  final TextEditingController _controller = TextEditingController();
  Timer? _debounce;
  String _query = '';

  void _onChanged(String value) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 300), () {
      if (mounted) {
        setState(() => _query = value.trim());
      }
    });
  }

  void _jumpTo(String messageId) {
    ref.read(pendingFocusMessageProvider.notifier).set((
      channelId: widget.channelId,
      messageId: messageId,
    ));
    Navigator.of(context).pop();
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final tokens = context.designSystem;

    return CcDialog(
      title: l10n.searchInConversation,
      content: SizedBox(
        width: 460,
        height: 380,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            CcTextField(
              controller: _controller,
              autofocus: true,
              hintText: l10n.searchMessagesHint,
              prefix: Icon(
                AppIcons.search,
                size: 16,
                color: tokens?.textTertiary,
              ),
              onChanged: _onChanged,
            ),
            const SizedBox(height: 12),
            Expanded(child: _results(l10n, tokens)),
          ],
        ),
      ),
      actions: [
        CcButton(
          variant: CcButtonVariant.secondary,
          onPressed: () => Navigator.of(context).pop(),
          child: Text(l10n.close),
        ),
      ],
    );
  }

  Widget _results(AppLocalizations l10n, DesignSystemTokens? tokens) {
    if (_query.isEmpty) {
      return Center(
        child: Text(
          l10n.searchMessagesHint,
          style: TextStyle(color: tokens?.textTertiary),
        ),
      );
    }
    final resultsAsync = ref.watch(
      channelSearchProvider((channelId: widget.channelId, query: _query)),
    );
    return resultsAsync.when(
      loading: () => const Center(child: CcSpinner()),
      error: (e, _) => Center(child: Text(l10n.failedWithError('$e'))),
      data: (messages) {
        if (messages.isEmpty) {
          return Center(
            child: Text(
              l10n.noMessagesFound,
              style: TextStyle(color: tokens?.textTertiary),
            ),
          );
        }
        return ListView.separated(
          itemCount: messages.length,
          separatorBuilder: (_, _) => const CcDivider(),
          itemBuilder: (context, i) {
            final m = messages[i];
            return _SearchResultRow(
              content: m.content,
              createdAt: m.createdAt,
              time: formatTime(m.createdAt),
              tokens: tokens,
              onTap: () => _jumpTo(m.id),
            );
          },
        );
      },
    );
  }
}

class _SearchResultRow extends StatelessWidget {
  const _SearchResultRow({
    required this.content,
    required this.createdAt,
    required this.time,
    required this.tokens,
    required this.onTap,
  });

  final String content;
  final DateTime createdAt;
  final String time;
  final DesignSystemTokens? tokens;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      type: MaterialType.transparency,
      child: InkWell(
        onTap: onTap,
        borderRadius: AppRadii.brSm,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                content,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(color: tokens?.textPrimary),
              ),
              const SizedBox(height: 2),
              AppTimestamp(
                dateTime: createdAt,
                child: Text(
                  time,
                  style: TextStyle(fontSize: 11, color: tokens?.textQuaternary),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
