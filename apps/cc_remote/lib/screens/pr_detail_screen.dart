import 'package:cc_domain/features/pr_review/domain/entities/check_run.dart';
import 'package:cc_domain/features/pr_review/domain/entities/pr_file.dart';
import 'package:cc_domain/features/pr_review/domain/entities/pr_review_submission.dart';
import 'package:cc_domain/features/pr_review/domain/entities/pr_user.dart';
import 'package:cc_domain/features/pr_review/domain/entities/pull_request.dart';
import 'package:cc_markdown/cc_markdown.dart';
import 'package:cc_remote/app_icons.dart';
import 'package:cc_remote/external_link.dart';
import 'package:cc_remote/l10n/app_localizations.dart';
import 'package:cc_remote/pr_providers.dart';
import 'package:cc_remote/widgets/pr_detail/check_row.dart';
import 'package:cc_remote/widgets/pr_detail/file_diff_tile.dart';
import 'package:cc_remote/widgets/pr_detail/pr_action_bar.dart';
import 'package:cc_remote/widgets/pr_detail/pr_conversation.dart';
import 'package:cc_remote/widgets/pr_detail/pr_summary.dart';
import 'package:cc_remote/widgets/touch_target.dart';
import 'package:cc_ui/cc_ui.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

part 'pr_detail_body.dart';

enum _PrTab { conversation, files, checks }

/// `/pr/:repoId/:number` — one pull request.
class PrDetailScreen extends ConsumerStatefulWidget {
  /// Creates a [PrDetailScreen].
  const PrDetailScreen({super.key, required this.repoId, required this.number});

  final String repoId;
  final int number;

  @override
  ConsumerState<PrDetailScreen> createState() => _PrDetailScreenState();
}

class _PrDetailScreenState extends ConsumerState<PrDetailScreen> {
  final TextEditingController _comment = TextEditingController();
  _PrTab _tab = _PrTab.conversation;
  bool _acting = false;
  String? _error;
  String? _optimisticPrBody;
  final Map<int, String> _optimisticComments = {};

  void _set(VoidCallback fn) => setState(fn);
  String? _notice;

  PrCoords get _coords => (repoId: widget.repoId, number: widget.number);

  @override
  void dispose() {
    _comment.dispose();
    super.dispose();
  }

  Future<void> _run(String success, Future<void> Function() action) async {
    setState(() {
      _acting = true;
      _error = null;
      _notice = null;
    });
    try {
      await action();
      if (mounted) setState(() => _notice = success);
    } catch (e) {
      if (mounted) setState(() => _error = '$e');
    } finally {
      if (mounted) setState(() => _acting = false);
    }
  }

  Future<void> _submitReview(String event, String success) async {
    final repository = ref.read(prReviewRepositoryProvider(_coords));
    if (repository == null) return;
    final body = _comment.text.trim();
    if (event == 'REQUEST_CHANGES' && body.isEmpty) {
      setState(
        () => _error = AppLocalizations.of(context).requestChangesNeedsComment,
      );
      return;
    }
    await _run(success, () async {
      await repository.submitReview(
        prNumber: widget.number,
        event: event,
        body: body.isEmpty ? null : body,
      );
      _comment.clear();
    });
  }

  Future<void> _merge(PullRequest pr) async {
    final repository = ref.read(prReviewRepositoryProvider(_coords));
    if (repository == null) return;
    await _run(AppLocalizations.of(context).merged, () async {
      await repository.mergePullRequest(
        prNumber: widget.number,
        mergeMethod: 'squash',
        idempotencyKey: 'phone-merge:${widget.repoId}:${widget.number}',
      );
    });
  }

  bool _hasWriteAccess() {
    final perm = ref.read(prRepoPermissionProvider(_coords)).value;
    return perm == 'admin' || perm == 'write';
  }

  String _viewerLogin() {
    final repo = ref.read(prRepoProvider(_coords));
    final logins = ref.read(viewerLoginsProvider).value ?? const {};
    if (repo == null) {
      return '';
    }
    return logins[repo.forge] ?? '';
  }

  bool _canEditPrBody(PullRequest pr) {
    final login = _viewerLogin();
    final isAuthor =
        login.isNotEmpty && pr.author?.login.toLowerCase() == login;
    return isAuthor || _hasWriteAccess();
  }

  bool _canEditComment(PrUser? author) {
    final login = _viewerLogin();
    final isAuthor =
        login.isNotEmpty && author?.login.toLowerCase() == login;
    return isAuthor || _hasWriteAccess();
  }

  Future<void> _togglePrBodyCheckbox(PullRequest pr, int index) async {
    if (_acting) {
      return;
    }
    final repository = ref.read(prReviewRepositoryProvider(_coords));
    if (repository == null) {
      return;
    }
    final source = _optimisticPrBody ?? pr.body;
    final next = toggleMarkdownTaskListItem(source, index);
    if (next == null || next == source) {
      return;
    }
    setState(() => _optimisticPrBody = next);
    try {
      await repository.updatePullRequest(prNumber: widget.number, body: next);
    } catch (e) {
      if (mounted) {
        setState(() {
          _optimisticPrBody = null;
          _error = '$e';
        });
      }
    }
  }

  Future<void> _toggleCommentCheckbox({
    required int commentId,
    required String currentBody,
    required int index,
  }) async {
    if (_acting) {
      return;
    }
    final repository = ref.read(prReviewRepositoryProvider(_coords));
    if (repository == null) {
      return;
    }
    final source = _optimisticComments[commentId] ?? currentBody;
    final next = toggleMarkdownTaskListItem(source, index);
    if (next == null || next == source) {
      return;
    }
    setState(() => _optimisticComments[commentId] = next);
    try {
      await repository.updateIssueComment(
        prNumber: widget.number,
        commentId: commentId,
        body: next,
      );
    } catch (e) {
      if (mounted) {
        setState(() {
          _optimisticComments.remove(commentId);
          _error = '$e';
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = context.designSystem ?? DesignSystemTokens.light();
    final async = ref.watch(prDetailProvider(_coords));
    final repo = ref.watch(prRepoProvider(_coords));
    final pr = async.value;

    return SafeArea(
      child: ColoredBox(
        color: t.canvas,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _header(
              t,
              repo?.fullName ?? AppLocalizations.of(context).pullRequest,
              pr,
            ),
            if (pr == null)
              Expanded(
                child: async.hasError
                    ? CcEmptyState(
                        icon: AppIcons.triangleAlert,
                        message: AppLocalizations.of(context).prLoadFailed,
                        description: '${async.error}',
                      )
                    : const Center(child: CcSpinner(size: 24)),
              )
            else ...[
              Expanded(child: _body(t, pr)),
              PrActionBar(
                pr: pr,
                acting: _acting,
                error: _error,
                notice: _notice,
                commentController: _comment,
                onSubmitReview: _submitReview,
                onMerge: () => _merge(pr),
              ),
            ],
          ],
        ),
      ),
    );
  }

}
