import 'package:control_center/core/theme/design_system_tokens.dart';
import 'package:control_center/di/providers.dart';
import 'package:control_center/features/pr_review/domain/entities/pr_file.dart';
import 'package:control_center/features/pr_review/presentation/widgets/pr_diff_view.dart';
import 'package:control_center/features/repos/providers/repo_providers.dart';
import 'package:control_center/features/ticketing/domain/entities/ticket.dart';
import 'package:control_center/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:forui/forui.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

/// Identifies a ticket's working-tree diff request.
typedef _ChangesArgs = ({String workspaceId, String ticketId});

/// The uncommitted working-tree diff (`git diff HEAD`) across every repo linked
/// to the ticket's workspace. Agents edit the linked repos in place — there are
/// no per-ticket worktrees — so the workspace's repos are the source of truth.
final ticketChangesProvider =
    FutureProvider.autoDispose.family<List<PrFile>, _ChangesArgs>(
  (ref, args) async {
    final repos = await ref.watch(reposForWorkspaceProvider(args.workspaceId).future);
    final git = ref.read(gitCommandPortProvider);
    final multiRepo = repos.length > 1;
    final files = <PrFile>[];
    for (final repo in repos) {
      final result = await git.run(
        const ['diff', '--no-color', '-M', 'HEAD'],
        workdir: repo.path,
      );
      if (!result.isSuccess || result.stdout.trim().isEmpty) {
        continue;
      }
      files.addAll(
        _filesFromDiff(result.stdout, repoLabel: multiRepo ? repo.name : null),
      );
    }
    return files;
  },
);

/// Splits a full `git diff` into one [PrFile] per file, deriving status and
/// line counts from each section. When [repoLabel] is set (multiple repos), the
/// filename is prefixed so files from different repos stay distinguishable.
List<PrFile> _filesFromDiff(String fullDiff, {String? repoLabel}) {
  const needle = 'diff --git ';
  final starts = <int>[];
  var i = fullDiff.indexOf(needle);
  while (i >= 0) {
    starts.add(i);
    i = fullDiff.indexOf(needle, i + needle.length);
  }

  final files = <PrFile>[];
  for (var s = 0; s < starts.length; s++) {
    final start = starts[s];
    final end = s + 1 < starts.length ? starts[s + 1] : fullDiff.length;
    final section = fullDiff.substring(start, end);

    final firstNl = section.indexOf('\n');
    final header = firstNl < 0 ? section : section.substring(0, firstNl);
    final bIdx = header.indexOf(' b/');
    if (bIdx < 0) {
      continue;
    }
    final path = header.substring(bIdx + 3).trim();

    var status = PrFileStatus.modified;
    String? previous;
    if (section.contains('\nnew file mode')) {
      status = PrFileStatus.added;
    } else if (section.contains('\ndeleted file mode')) {
      status = PrFileStatus.removed;
    } else if (section.contains('\nrename from ')) {
      status = PrFileStatus.renamed;
      final aIdx = header.indexOf(' a/');
      if (aIdx >= 0 && aIdx < bIdx) {
        previous = header.substring(aIdx + 3, bIdx).trim();
      }
    }

    final hunk = section.indexOf('\n@@');
    if (hunk < 0) {
      // Pure rename / mode change with no content hunks — nothing to render.
      continue;
    }
    final patch = section.substring(hunk + 1);

    var additions = 0;
    var deletions = 0;
    for (final line in patch.split('\n')) {
      if (line.startsWith('+') && !line.startsWith('+++')) {
        additions++;
      } else if (line.startsWith('-') && !line.startsWith('---')) {
        deletions++;
      }
    }

    final filename = repoLabel == null ? path : '$repoLabel/$path';
    files.add(
      PrFile(
        filename: filename,
        status: status,
        additions: additions,
        deletions: deletions,
        patch: patch,
        previousFilename:
            previous == null || repoLabel == null ? previous : '$repoLabel/$previous',
      ),
    );
  }
  return files;
}

/// The "Changes" tab: the live working-tree diff of the ticket's workspace,
/// rendered with the same diff viewer used in PR review.
class TicketChangesTab extends ConsumerWidget {
  /// Creates a [TicketChangesTab].
  const TicketChangesTab({super.key, required this.ticket});

  /// The ticket being viewed.
  final Ticket ticket;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final t = context.designSystem ?? DesignSystemTokens.light();
    final args = (workspaceId: ticket.workspaceId, ticketId: ticket.id);
    final changes = ref.watch(ticketChangesProvider(args));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 10, 8, 10),
          child: Row(
            children: [
              Text(
                l10n.ticketTabChanges,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: t.textSecondary,
                ),
              ),
              const Spacer(),
              FTooltip(
                tipAnchor: Alignment.topCenter,
                childAnchor: Alignment.bottomCenter,
                tipBuilder: (_, _) => Text(l10n.refresh),
                child: FButton.icon(
                  onPress: () => ref.invalidate(ticketChangesProvider(args)),
                  child: const Icon(LucideIcons.refreshCw, size: 16),
                ),
              ),
            ],
          ),
        ),
        Container(height: 1, color: t.borderSecondary),
        Expanded(
          child: changes.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, _) => Center(child: Text(l10n.failedWithError('$e'))),
            data: (files) {
              if (files.isEmpty) {
                return _Empty(message: l10n.ticketNoChanges);
              }
              return CustomScrollView(
                slivers: [
                  PrDiffView(files: files, comments: const []),
                ],
              );
            },
          ),
        ),
      ],
    );
  }
}

class _Empty extends StatelessWidget {
  const _Empty({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    final t = context.designSystem ?? DesignSystemTokens.light();
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(LucideIcons.fileDiff, size: 32, color: t.fgQuaternary),
          const SizedBox(height: 10),
          Text(message, style: TextStyle(color: t.textTertiary, fontSize: 13)),
        ],
      ),
    );
  }
}
