import 'package:cc_data/cc_data.dart';
import 'package:cc_domain/cc_domain.dart';
import 'package:cc_remote/app_icons.dart';
import 'package:cc_remote/format.dart';
import 'package:cc_remote/l10n/app_localizations.dart';
import 'package:cc_remote/providers.dart';
import 'package:cc_ui/cc_ui.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

/// One blocked agent, with the two answers that unblock it.
///
/// The verbatim command is shown, not summarised: approving a destructive
/// action you have only seen paraphrased is not approval. Both buttons are
/// full-size touch targets — this is the one control on the phone where a
/// mis-tap has a side effect on someone's repository.
class ApprovalCard extends ConsumerStatefulWidget {
  const ApprovalCard({super.key, required this.request});

  final ConfirmationRequestDto request;

  @override
  ConsumerState<ApprovalCard> createState() => _ApprovalCardState();
}

class _ApprovalCardState extends ConsumerState<ApprovalCard> {
  bool _acting = false;
  String? _error;

  Future<void> _respond({required bool approved}) async {
    final client = ref.read(rpcClientProvider).value;
    if (client == null || _acting) {
      return;
    }
    setState(() {
      _acting = true;
      _error = null;
    });
    try {
      await RemoteConfirmationRepository(
        client,
      ).respond(widget.request.id, approved: approved);
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = '$e';
          _acting = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = context.designSystem ?? DesignSystemTokens.light();
    final request = widget.request;
    final destructive = request.severity == 'destructive';
    final since = DateTime.tryParse(request.createdAt);

    return CcCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                destructive ? AppIcons.triangleAlert : AppIcons.bot,
                size: 16,
                color: destructive ? t.textErrorPrimary : t.textWarningPrimary,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  request.title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: t.textPrimary,
                  ),
                ),
              ),
              if (since != null)
                Text(
                  AppLocalizations.of(
                    context,
                  ).waitingAgo(shortAgo(context, since)),
                  style: TextStyle(fontSize: 11, color: t.textTertiary),
                ),
            ],
          ),
          if (request.detail.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              request.detail,
              style: TextStyle(
                fontSize: 13,
                height: 1.4,
                color: t.textSecondary,
              ),
            ),
          ],
          if ((request.command ?? '').isNotEmpty) ...[
            const SizedBox(height: 10),
            DecoratedBox(
              decoration: BoxDecoration(
                color: t.bgTertiary,
                borderRadius: BorderRadius.circular(6),
              ),
              child: Padding(
                padding: const EdgeInsets.all(10),
                child: Text(
                  request.command!,
                  style: CcFonts.code(
                    textStyle: TextStyle(
                      fontSize: 12,
                      height: 1.45,
                      color: t.textPrimary,
                    ),
                  ),
                ),
              ),
            ),
          ],
          if (_error != null) ...[
            const SizedBox(height: 8),
            Text(
              _error!,
              style: TextStyle(fontSize: 12, color: t.textErrorPrimary),
            ),
          ],
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: CcButton(
                  variant: CcButtonVariant.secondary,
                  onPressed: _acting ? null : () => _respond(approved: false),
                  child: Text(AppLocalizations.of(context).deny),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: CcButton(
                  variant: destructive
                      ? CcButtonVariant.destructive
                      : CcButtonVariant.primary,
                  loading: _acting,
                  onPressed: _acting ? null : () => _respond(approved: true),
                  child: Text(AppLocalizations.of(context).approve),
                ),
              ),
            ],
          ),
          if (request.spaceId.isNotEmpty) ...[
            const SizedBox(height: 6),
            CcButton(
              fullWidth: true,
              variant: CcButtonVariant.ghost,
              size: CcButtonSize.sm,
              icon: AppIcons.messageCircle,
              onPressed: () => context.push('/spaces/${request.spaceId}'),
              child: Text(AppLocalizations.of(context).openConversation),
            ),
          ],
        ],
      ),
    );
  }
}
