import 'dart:async';

import 'package:cc_domain/cc_domain.dart' show FileSearchHit;
import 'package:control_center/l10n/app_localizations.dart';
import 'package:control_center/shared/icons/app_icons.dart';
import 'package:control_center/shared/widgets/composer/composer_models.dart';
import 'package:control_center/shared/widgets/composer/mention/mention_source.dart';
import 'package:flutter/widgets.dart';
import 'package:path/path.dart' as p;

/// Resolves a fuzzy file query to hits, ranked best-first.
///
/// Always satisfied over RPC (`repos.searchFiles`): the search runs on
/// `cc_server`, which owns the repo checkouts and the native searcher. The
/// client never walks a filesystem and never loads `libfff_c`.
typedef FileMentionSearch = Future<List<FileSearchHit>> Function(String query);

/// Streams file/folder mentions from a server-side file search.
class FileMentionSource extends MentionSource {
  /// Creates a new [FileMentionSource] over [search].
  FileMentionSource({
    required this.search,
    this.debounce = const Duration(milliseconds: 150),
    this.limit = 12,
  });

  /// Resolves each query, server-side.
  final FileMentionSearch search;

  /// Delay before a query is sent, so a burst of keystrokes costs one round
  /// trip instead of one per character. The popup cancels the previous
  /// subscription on every re-query, which cancels the pending timer before it
  /// ever reaches the wire.
  final Duration debounce;

  /// Cap on suggestions emitted per query.
  final int limit;

  @override
  String get kind => 'file';

  @override
  Set<MentionTrigger> get triggers => {MentionTrigger.at};

  @override
  String? sectionLabel(BuildContext context) =>
      AppLocalizations.of(context).filesMentionSection;

  @override
  Stream<List<MentionSuggestion>> suggest(MentionQuery query) {
    if (query.trigger != MentionTrigger.at) {
      return const Stream.empty();
    }
    // Don't fire file search on empty query — it'd dump the entire tree.
    // Other (cheaper) sources fill that case.
    if (query.partial.isEmpty) {
      return Stream<List<MentionSuggestion>>.value(const []);
    }

    late final StreamController<List<MentionSuggestion>> controller;
    Timer? timer;
    var cancelled = false;

    Future<void> run() async {
      try {
        final hits = await search(query.partial);
        if (cancelled) {
          return;
        }
        controller.add([
          for (final hit in hits.take(limit)) _hitToSuggestion(hit),
        ]);
      } catch (e, st) {
        if (!cancelled) {
          controller.addError(e, st);
        }
      } finally {
        if (!cancelled) {
          await controller.close();
        }
      }
    }

    controller = StreamController<List<MentionSuggestion>>(
      onListen: () => timer = Timer(debounce, run),
      onCancel: () {
        cancelled = true;
        timer?.cancel();
      },
    );
    return controller.stream;
  }

  MentionSuggestion _hitToSuggestion(FileSearchHit hit) {
    final base = p.basename(hit.relativePath);
    final dir = p.dirname(hit.relativePath);
    final needsQuote = base.contains(' ');
    final replacement = needsQuote ? "@'$base' " : '@${hit.relativePath} ';
    return MentionSuggestion(
      id: 'file:${hit.absolutePath}',
      kind: kind,
      label: base,
      description: dir == '.' ? p.basename(hit.rootPath) : dir,
      icon: hit.isDirectory ? AppIcons.folder : AppIcons.fileText,
      replacement: replacement,
      payload: {
        'path': hit.absolutePath,
        'relativePath': hit.relativePath,
        'isDirectory': hit.isDirectory,
      },
    );
  }
}
