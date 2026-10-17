import 'package:cc_data/cc_data.dart';
import 'package:cc_domain/cc_domain.dart';
import 'package:cc_remote/app_icons.dart';
import 'package:cc_remote/format.dart';
import 'package:cc_remote/l10n/app_localizations.dart';
import 'package:cc_remote/operation_scope.dart';
import 'package:cc_remote/providers.dart';
import 'package:cc_remote/widgets/phone_markdown.dart';
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

  Future<void> _respond({required bool approved, bool remember = false}) async {
    final l10n = AppLocalizations.of(context);
    final client = ref.read(rpcClientProvider).value;
    if (client == null ||
        _acting ||
        (widget.request.workspaceId != null &&
            widget.request.workspaceId !=
                ref.read(activeWorkspaceIdProvider).value)) {
      setState(() => _error = l10n.requestUnavailable);
      return;
    }
    setState(() {
      _acting = true;
      _error = null;
    });
    try {
      final ok = await RemoteConfirmationRepository(client).respond(
        widget.request.id,
        approved: approved,
        rememberForSeconds: remember ? 8 * 60 * 60 : null,
      );
      if (!ok) {
        throw StateError(l10n.requestAlreadyResolved);
      }
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
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                destructive ? AppIcons.triangleAlert : AppIcons.bot,
                size: 16,
                color: destructive ? t.textErrorPrimary : t.textWarningPrimary,
              ),
              if (since != null) ...[
                const SizedBox(width: 8),
                Text(
                  AppLocalizations.of(
                    context,
                  ).waitingAgo(shortAgo(context, since)),
                  style: TextStyle(fontSize: 11, color: t.textTertiary),
                ),
              ],
            ],
          ),
          const SizedBox(height: 8),
          ConstrainedBox(
            constraints: BoxConstraints(
              maxHeight: (MediaQuery.sizeOf(context).height * 0.36)
                  .clamp(0.0, 320.0)
                  .toDouble(),
            ),
            child: CcScrollbar(
              thumbVisibility: true,
              child: SingleChildScrollView(
                padding: const EdgeInsetsDirectional.only(end: AppSpacing.sm),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      request.title.isEmpty
                          ? AppLocalizations.of(context).agentApprovalRequired
                          : request.title,
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: t.textPrimary,
                      ),
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
                      PhoneApprovalCodeBlock(source: request.command!),
                    ],
                  ],
                ),
              ),
            ),
          ),
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
                  size: CcButtonSize.lg,
                  variant: CcButtonVariant.secondary,
                  onPressed: _acting ? null : () => _respond(approved: false),
                  child: Text(AppLocalizations.of(context).deny),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: CcButton(
                  size: CcButtonSize.lg,
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
          if (request.isRememberable) ...[
            const SizedBox(height: 8),
            CcButton(
              fullWidth: true,
              size: CcButtonSize.lg,
              variant: CcButtonVariant.secondary,
              onPressed: _acting
                  ? null
                  : () => _respond(approved: true, remember: true),
              child: Text(AppLocalizations.of(context).approveAndRemember),
            ),
          ],
          if (request.spaceId.isNotEmpty) ...[
            const SizedBox(height: 6),
            CcButton(
              fullWidth: true,
              variant: CcButtonVariant.ghost,
              size: CcButtonSize.lg,
              icon: AppIcons.messageCircle,
              onPressed: () {
                final workspaceId =
                    request.workspaceId ??
                    ref.read(activeWorkspaceIdProvider).value;
                if (workspaceId == null) return;
                context.push(
                  remoteSpaceLocation(
                    workspaceId: workspaceId,
                    spaceId: request.spaceId,
                  ),
                );
              },
              child: Text(AppLocalizations.of(context).openConversation),
            ),
          ],
        ],
      ),
    );
  }
}
