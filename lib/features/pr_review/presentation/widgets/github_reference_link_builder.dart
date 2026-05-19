import 'package:control_center/features/pr_review/presentation/widgets/references/commit_reference_chip.dart';
import 'package:control_center/features/pr_review/presentation/widgets/references/pr_reference_chip.dart';
import 'package:control_center/shared/utils/github_reference_parser.dart';
import 'package:control_center/shared/widgets/github_link_handler.dart';
import 'package:flutter/material.dart';
import 'package:flutter_markdown_plus/flutter_markdown_plus.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:markdown/markdown.dart' as md;

/// Markdown element builder for `<a>` tags that swaps GitHub references out
/// for inline preview chips.
///
/// Handles two kinds of references:
///
/// * **Pull requests** — same-repo `#123` (rewritten by the preprocessor
///   to the app's `control-center://` deep-link scheme) and any full PR
///   URL where the target repo is the host repo or one of
///   [knownWorkspaceRepos]. Renders a [PrReferenceChip].
/// * **Commits** — any `https://github.com/<owner>/<repo>/commit/<sha>` URL
///   (host repo or a workspace repo). Renders a [CommitReferenceChip].
///
/// All other links are rendered as tappable text via [_FallbackMarkdownLink]
/// because registering a builder for `'a'` prevents flutter_markdown_plus from
/// creating its own `TapGestureRecognizer`.
class GitHubReferenceLinkBuilder extends MarkdownElementBuilder {
  /// Creates a [GitHubReferenceLinkBuilder].
  GitHubReferenceLinkBuilder({
    required this.currentOwner,
    required this.currentRepo,
    required this.knownWorkspaceRepos,
    this.onSwitchToRepo,
  });

  /// Owner of the host PR — kept for source compatibility with
  /// [parseAnyGitHubReference]; no longer needed for shorthand resolution
  /// now that the preprocessor emits fully-qualified `control-center://`
  /// hrefs.
  final String currentOwner;

  /// Repo of the host PR.
  final String currentRepo;

  /// Lowercased `owner/repo` pairs registered in the active workspace. Used
  /// to decide whether a cross-repo reference should become a chip.
  final Set<String> knownWorkspaceRepos;

  /// Forwarded to the chip's `handleGitHubLink` call when the target repo
  /// is in a different workspace slot.
  final Future<void> Function(String workspaceId, String repoId)?
      onSwitchToRepo;

  bool _isKnownTarget(String owner, String repo) {
    final isSame =
        owner.toLowerCase() == currentOwner.toLowerCase() &&
            repo.toLowerCase() == currentRepo.toLowerCase();
    if (isSame) {
      return true;
    }
    return knownWorkspaceRepos
        .contains('${owner.toLowerCase()}/${repo.toLowerCase()}');
  }

  @override
  Widget? visitElementAfterWithContext(
    BuildContext context,
    md.Element element,
    TextStyle? preferredStyle,
    TextStyle? parentStyle,
  ) {
    final resolved = _resolveReference(element, preferredStyle);
    return resolved == null ? null : _asInlineSpan(resolved);
  }

  /// Resolves an `<a>` element to the widget that represents it inline: a
  /// reference chip for known PR/commit targets, or a tappable
  /// [_FallbackMarkdownLink] for everything else. Returns null when there's no
  /// usable href (the caller renders nothing).
  Widget? _resolveReference(md.Element element, TextStyle? preferredStyle) {
    final href = element.attributes['href'];
    if (href == null || href.isEmpty) {
      return null;
    }

    // Only swap out the link for a chip when the author didn't write custom
    // link text. Auto-linked bare URLs have `textContent == href`; the
    // `#123` / `owner/repo#123` preprocessor emits `control-center://`
    // hrefs. Anything else — e.g. `[PR 2: Settings Components](https://
    // github.com/SamuelAlev/control-center/pull/13593)` — keeps the author's chosen
    // label. Since we registered as a builder for 'a', flutter_markdown_plus
    // won't create a TapGestureRecognizer, so we return a tappable widget.
    final isAutoLinked = element.textContent == href;
    final isShorthand = href.startsWith('control-center://');
    if (!isAutoLinked && !isShorthand) {
      return _fallback(element, preferredStyle, href);
    }

    final reference = parseAnyGitHubReference(
      href,
      currentOwner: currentOwner,
      currentRepo: currentRepo,
    );

    if (reference is GitHubPrReference) {
      if (!_isKnownTarget(reference.owner, reference.repo)) {
        return _fallback(element, preferredStyle, href);
      }
      return PrReferenceChip(
        reference: reference,
        currentOwner: currentOwner,
        currentRepo: currentRepo,
        onSwitchToRepo: onSwitchToRepo,
      );
    }

    if (reference is GitHubCommitReference) {
      if (!_isKnownTarget(reference.owner, reference.repo)) {
        return _fallback(element, preferredStyle, href);
      }
      return CommitReferenceChip(reference: reference);
    }

    return _fallback(element, preferredStyle, href);
  }

  _FallbackMarkdownLink _fallback(
    md.Element element,
    TextStyle? preferredStyle,
    String href,
  ) =>
      _FallbackMarkdownLink(
        text: element.textContent,
        href: href,
        style: preferredStyle,
        currentOwner: currentOwner,
        currentRepo: currentRepo,
        onSwitchToRepo: onSwitchToRepo,
      );

  /// Wraps an inline reference widget in a [WidgetSpan] inside a [Text.rich]
  /// so flutter_markdown_plus merges it into the surrounding paragraph's text
  /// run instead of emitting it as a standalone `Wrap` child.
  ///
  /// flutter_markdown_plus lays each paragraph's inline content out in a `Wrap`
  /// and only merges adjacent *text* widgets into a single `RichText` (see
  /// `MarkdownBuilder._mergeInlineChildren`). A builder that returns a bare
  /// widget becomes a standalone `Wrap` child, which splits the run: the text
  /// *after* the chip/link is then measured and wrapped as one atomic block, so
  /// it jumps to the next line whenever it doesn't fully fit the space left on
  /// the current line — even with room to spare. Returning a [Text.rich] makes
  /// the builder count as "text", so the widget's [WidgetSpan] is merged into
  /// the surrounding run and the following copy wraps naturally. The chip/link
  /// keeps its own [GestureDetector], so its tap lifecycle stays managed and
  /// (being hit-tested first) it still wins the tap inside the selectable
  /// paragraph. Mirrors the same fix on inline `code` in `InlineCodeBuilder`.
  static Widget _asInlineSpan(Widget child) => Text.rich(
        TextSpan(
          children: [
            WidgetSpan(
              alignment: PlaceholderAlignment.middle,
              child: child,
            ),
          ],
        ),
      );
}

/// Tappable fallback for `<a>` tags that aren't replaced by chips.
///
/// Because [GitHubReferenceLinkBuilder] registers as a builder for `'a'`,
/// flutter_markdown_plus skips creating its own `TapGestureRecognizer`.
/// This widget fills the gap — it renders the link text with the stylesheet's
/// link style and routes taps through [handleGitHubLink], which handles
/// in-app navigation for known repos and opens the browser for everything else.
class _FallbackMarkdownLink extends ConsumerWidget {
  const _FallbackMarkdownLink({
    required this.text,
    required this.href,
    required this.style,
    required this.currentOwner,
    required this.currentRepo,
    this.onSwitchToRepo,
  });

  final String text;
  final String href;
  final TextStyle? style;
  final String currentOwner;
  final String currentRepo;
  final Future<void> Function(String workspaceId, String repoId)?
      onSwitchToRepo;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        behavior: HitTestBehavior.translucent,
        onTap: () => handleGitHubLink(
          context: context,
          ref: ref,
          href: href,
          currentOwner: currentOwner,
          currentRepo: currentRepo,
          onSwitchToRepo: onSwitchToRepo,
        ),
        child: Text(text, style: style),
      ),
    );
  }
}
