import 'package:control_center/shared/icons/app_icons.dart';
import 'package:flutter/widgets.dart';

/// The PR detail page's editor tab-kind vocabulary — the opaque
/// `EditorTab.kind` strings this surface uses on the shared editor engine. The
/// engine never interprets them; only the PR body builder does.
// ignore: avoid_classes_with_only_static_members
abstract final class PrTabKinds {
  /// The PR overview (title, actions, description, sidebar).
  static const String overview = 'pr.overview';

  /// The file-tree + diff surface (with a Files/Commits sub-strip).
  static const String diff = 'pr.diff';

  /// A lazygit-style source-control surface: the PR worktree's working-tree
  /// changes + per-file diff + commit & push.
  static const String sourceControl = 'pr.sourceControl';

  /// CI checks grouped by workflow.
  static const String actions = 'pr.actions';

  /// The review ARTIFACT: the run's live progress while the review pipeline
  /// works, then the artifact it published, with the actions on it.
  ///
  /// Deliberately NOT a default tab. A pull request does not have a review
  /// until someone asks for one, and a standing tab that says "no findings yet"
  /// on every PR teaches the reader to ignore it. "Ask AI" opens it.
  static const String reviewArtifact = 'pr.reviewArtifact';

  /// Legacy review kinds — a standing dashboard tab (`pr.review`), and before
  /// it a split Findings / Studio pair. All fold into [reviewArtifact] so a
  /// persisted layout naming one still opens something.
  static const String review = 'pr.review';

  /// See [review].
  static const String aiReview = 'pr.aiReview';

  /// See [review].
  static const String reviewStudio = 'pr.reviewStudio';

  /// A PR-scoped chat conversation (a real space, provisioned at the PR head).
  static const String chat = 'pr.chat';

  /// An interactive terminal on the prepared PR worktree.
  static const String terminal = 'pr.terminal';

  /// A single repo file at the PR head (view + edit).
  static const String file = 'pr.file';

  /// An embedded code-server (VS Code in the browser) on the PR worktree.
  static const String codeServer = 'pr.codeServer';

  /// An in-app webview browser (e.g. a preview / deploy URL).
  static const String browser = 'pr.browser';

  /// A live view of an enclosed VM (a rig) on this PR's worktree: a desktop, a
  /// headless browser or a phone. The `surface` arg names which. Distinct from
  /// [browser] and [preview], which are webviews in THIS app rather than
  /// machines somewhere else.
  static const String rig = 'pr.rig';

  /// An auto-detected deployment preview (Netlify/Vercel/…). One tab per site,
  /// injected after [diff] when a preview URL is found on the PR; the `url`
  /// arg holds the live site. Distinct from [browser] (a user-opened ad-hoc
  /// webview) so it can be reconciled from detection.
  static const String preview = 'pr.preview';

  /// Whether [kind] is a heavyweight webview surface subject to the body host's
  /// LRU suspension (its live platform view is torn down when hidden beyond the
  /// cap and rebuilt on reveal).
  static bool isWebview(String kind) =>
      kind == codeServer || kind == browser || kind == preview;

  /// The tab-strip icon for a PR [kind].
  static IconData iconFor(String kind) {
    switch (kind) {
      case overview:
        return AppIcons.layoutDashboard;
      case diff:
        return AppIcons.fileText;
      case sourceControl:
        return AppIcons.gitBranch;
      case actions:
        return AppIcons.zap;
      case reviewArtifact:
      case review:
      case aiReview:
        return AppIcons.sparkles;
      case reviewStudio:
        return AppIcons.boxes;
      case chat:
        return AppIcons.messageSquareText;
      case terminal:
        return AppIcons.terminal;
      case file:
        return AppIcons.fileCode;
      case codeServer:
        return AppIcons.code;
      case browser:
        return AppIcons.globe;
      case rig:
        return AppIcons.monitor;
      case preview:
        return AppIcons.rocket;
      default:
        return AppIcons.fileText;
    }
  }
}
