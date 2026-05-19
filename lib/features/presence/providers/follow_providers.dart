import 'package:cc_domain/core/domain/value_objects/principal.dart';
import 'package:cc_domain/features/presence/domain/value_objects/participant_presence.dart';
import 'package:cc_domain/features/presence/domain/value_objects/presence_locus.dart';
import 'package:control_center/features/identity/providers/identity_providers.dart';
import 'package:control_center/features/messaging/presentation/ide/editor/messaging_tab_kinds.dart';
import 'package:control_center/features/presence/providers/presence_providers.dart';
import 'package:control_center/features/workspaces/providers/workspace_providers.dart';
import 'package:control_center/router/app_router.dart';
import 'package:control_center/router/routes.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Which principal (human or agent) this client is riding the viewport of
/// (PRD 16 §4 — "watch a teammate or an agent work"). Null means nobody is
/// followed.
class FollowedPrincipalNotifier extends Notifier<Principal?> {
  @override
  Principal? build() => null;

  /// Starts following [principal], replacing any prior follow target.
  void follow(Principal principal) => state = principal;

  /// Stops following. No-op if nobody is currently followed.
  void detach() {
    if (state != null) {
      state = null;
    }
  }

  /// Follows [principal], or detaches if it is already the followed one — the
  /// toggle behind clicking a presence avatar a second time.
  void toggle(Principal principal) {
    state = state == principal ? null : principal;
  }
}

/// The currently-followed principal, if any.
final followedPrincipalProvider =
    NotifierProvider<FollowedPrincipalNotifier, Principal?>(
      FollowedPrincipalNotifier.new,
    );

/// Pure decision function (independently unit-tested): follow is "until you
/// act, then detach" (PRD 16 §4). The follow session recorded the last
/// location it drove the router to on the followed principal's behalf; if the
/// visible location has since diverged from that, the user navigated under
/// their own steam and follow should end. A location that still matches (or
/// no programmatic navigation has happened yet) means the follow is still
/// live.
bool followShouldDetach({
  required String currentLocation,
  required String? lastFollowNavigatedLocation,
}) {
  if (lastFollowNavigatedLocation == null) {
    return false;
  }
  return currentLocation != lastFollowNavigatedLocation;
}

/// Resolves the concrete in-app route for a [locus], or null when it has no
/// direct destination (yet) — e.g. [FileLocus]: there is no file-viewer
/// route to jump to, so the roster/tooltip falls back to showing the label.
String? routeForLocus(String workspaceId, PresenceLocus locus) {
  switch (locus) {
    case SpaceLocus(:final spaceId, :final conversationId):
      // A space holds parallel conversations, so the space alone lands on
      // whichever one is standing — not necessarily the one the followed
      // principal is in. `?tab=` focuses theirs, the same deep link the
      // sidebar's conversation rows use.
      return spaceRoute(
        workspaceId,
        spaceId,
        tab: conversationId == null
            ? null
            : MessagingTabKinds.chatTabKey(conversationId),
      );
    case PrLocus(:final repoFullName, :final prNumber):
      return pullRequestDetailRoute(workspaceId, repoFullName, prNumber);
    case TicketLocus(:final ticketId):
      return ticketDetailRoute(workspaceId, ticketId);
    case FileLocus():
    case PlanNodeLocus():
      return null;
  }
}

/// Drives navigation from the followed principal's live locus and detaches
/// the moment the user navigates away under their own steam (PRD 16 §4).
/// Kept alive from the shell alongside [followedPrincipalProvider].
final followSyncProvider = Provider<void>((ref) {
  final router = ref.watch(routerProvider);
  String? lastNavigated;
  var disposed = false;

  void goTo(String location) {
    lastNavigated = location;
    router.go(location);
  }

  void maybeDetach() {
    if (disposed || ref.read(followedPrincipalProvider) == null) {
      return;
    }
    String current;
    try {
      current = router.state.uri.toString();
    } on Object {
      return;
    }
    if (followShouldDetach(
      currentLocation: current,
      lastFollowNavigatedLocation: lastNavigated,
    )) {
      ref.read(followedPrincipalProvider.notifier).detach();
      lastNavigated = null;
    }
  }

  void scheduleDetachCheck() => Future.microtask(maybeDetach);
  router.routerDelegate.addListener(scheduleDetachCheck);
  ref.onDispose(() {
    disposed = true;
    router.routerDelegate.removeListener(scheduleDetachCheck);
  });

  void followTarget() {
    if (disposed) {
      return;
    }
    final followed = ref.read(followedPrincipalProvider);
    final workspaceId = ref.read(activeWorkspaceIdProvider);
    if (followed == null || workspaceId == null) {
      return;
    }
    final roster = ref.read(presenceRosterProvider(workspaceId)).value;
    if (roster == null) {
      return;
    }
    ParticipantPresence? entry;
    for (final p in roster) {
      if (p.principal == followed) {
        entry = p;
        break;
      }
    }
    final locus = entry?.locus;
    if (locus == null) {
      return;
    }
    final route = routeForLocus(workspaceId, locus);
    if (route == null || route == lastNavigated) {
      return;
    }
    goTo(route);
  }

  ref.listen<Principal?>(followedPrincipalProvider, (previous, next) {
    if (next == null) {
      lastNavigated = null;
      return;
    }
    followTarget();
  });

  final workspaceId = ref.watch(activeWorkspaceIdProvider);
  if (workspaceId != null) {
    ref.listen(presenceRosterProvider(workspaceId), (previous, next) {
      followTarget();
    });
  }
});

/// Session-scoped (never persisted) set of `(principal, space)` spotlight
/// instances the user has dismissed, keyed by `"<principal.wire>|<spaceId>"`
/// (PRD 16 §5).
class DismissedSpotlightsNotifier extends Notifier<Set<String>> {
  @override
  Set<String> build() => const {};

  /// The dedup key for a `(principal, spaceId)` spotlight instance.
  static String keyFor(Principal principal, String spaceId) =>
      '${principal.wire}|$spaceId';

  /// Whether this exact spotlight instance has been dismissed.
  bool isDismissed(Principal principal, String spaceId) =>
      state.contains(keyFor(principal, spaceId));

  /// Dismisses this spotlight instance (hides its banner; does not navigate).
  void dismiss(Principal principal, String spaceId) {
    state = {...state, keyFor(principal, spaceId)};
  }
}

/// Dismissed spotlight instances for this session.
final dismissedSpotlightsProvider =
    NotifierProvider<DismissedSpotlightsNotifier, Set<String>>(
      DismissedSpotlightsNotifier.new,
    );

/// Auto-navigates to a teammate's or agent's spotlighted space the first
/// time it appears on the roster (PRD 16 §5) — once per `(principal,
/// space)` instance and never for a pair the user has dismissed. The
/// dismissible `"<name> is presenting"` banner itself is a pure roster read
/// (see `SpotlightBanner`) and needs no sync provider of its own. Kept alive
/// from the shell.
final spotlightSyncProvider = Provider<void>((ref) {
  final workspaceId = ref.watch(activeWorkspaceIdProvider);
  if (workspaceId == null) {
    return;
  }
  final myUserId = ref.watch(currentUserIdProvider);
  final navigated = <String>{};

  ref.listen(presenceRosterProvider(workspaceId), (previous, next) {
    final roster = next.value;
    if (roster == null) {
      return;
    }
    final dismissed = ref.read(dismissedSpotlightsProvider);
    for (final p in roster) {
      if (p.principal is UserPrincipal && p.principal.id == myUserId) {
        continue;
      }
      final spaceId = p.spotlightSpaceId;
      if (spaceId == null) {
        continue;
      }
      final key = DismissedSpotlightsNotifier.keyFor(p.principal, spaceId);
      if (navigated.contains(key) || dismissed.contains(key)) {
        continue;
      }
      navigated.add(key);
      ref.read(routerProvider).go(spaceRoute(workspaceId, spaceId));
    }
  }, fireImmediately: true);
});
