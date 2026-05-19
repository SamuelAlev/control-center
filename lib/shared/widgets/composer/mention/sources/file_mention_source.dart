import 'package:cc_natives/cc_natives.dart';
import 'package:control_center/l10n/app_localizations.dart';
import 'package:control_center/shared/widgets/composer/composer_models.dart';
import 'package:control_center/shared/widgets/composer/mention/mention_source.dart';
import 'package:flutter/widgets.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:path/path.dart' as p;

/// Streams file/folder mentions from a [FileSearch] over the configured roots.
class FileMentionSource extends MentionSource {
  /// Creates a new [FileMentionSource].
  FileMentionSource({required this.search, required this.roots});

  /// File search service used to resolve queries.
  final FileSearch search;

  /// Root directories to search within.
  final List<String> roots;

  @override
  String get kind => 'file';

  @override
  Set<MentionTrigger> get triggers => {MentionTrigger.at};

  @override
  String? sectionLabel(BuildContext context) => AppLocalizations.of(context).filesMentionSection;

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
    return search
        .search(roots: roots, query: query.partial, limit: 12)
        .map((hits) => [
              for (final h in hits) _hitToSuggestion(h),
            ]);
  }

  MentionSuggestion _hitToSuggestion(FileSearchHit hit) {
    final base = p.basename(hit.relativePath);
    final dir = p.dirname(hit.relativePath);
    final needsQuote = base.contains(' ');
    final replacement =
        needsQuote ? "@'$base' " : '@${hit.relativePath} ';
    return MentionSuggestion(
      id: 'file:${hit.absolutePath}',
      kind: kind,
      label: base,
      description: dir == '.' ? p.basename(hit.rootPath) : dir,
      icon: hit.isDirectory ? LucideIcons.folder : LucideIcons.fileText,
      replacement: replacement,
      payload: {
        'path': hit.absolutePath,
        'relativePath': hit.relativePath,
        'isDirectory': hit.isDirectory,
      },
    );
  }
}

