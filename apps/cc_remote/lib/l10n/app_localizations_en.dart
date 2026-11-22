// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'Control Center';

  @override
  String get back => 'Back';

  @override
  String get cancel => 'Cancel';

  @override
  String get retry => 'Retry';

  @override
  String get tryAgain => 'Try again';

  @override
  String get settings => 'Settings';

  @override
  String get refresh => 'Refresh';

  @override
  String get approve => 'Approve';

  @override
  String get deny => 'Deny';

  @override
  String get continueLabel => 'Continue';

  @override
  String get agentQuestionHeader => 'Question for you';

  @override
  String get agentQuestionAnsweredLabel => 'Answered';

  @override
  String get agentQuestionSkip => 'Skip';

  @override
  String get agentQuestionSkippedLabel => 'Skipped';

  @override
  String get agentQuestionFreeformHint => 'Type your answer…';

  @override
  String get agentApprovalRequired => 'Approval required';

  @override
  String get copyCommand => 'Copy command';

  @override
  String get approveAndRemember => 'Approve for 8 hours';

  @override
  String get decline => 'Decline';

  @override
  String get confirm => 'Confirm';

  @override
  String get send => 'Send';

  @override
  String get close => 'Close';

  @override
  String get expand => 'Expand';

  @override
  String get zoomIn => 'Zoom in';

  @override
  String get zoomOut => 'Zoom out';

  @override
  String get resetZoom => 'Reset zoom';

  @override
  String get scanQrPrompt =>
      'Scan the QR code from Control Center to pair this phone.';

  @override
  String get scanQrHelp =>
      'Open your camera and point it at the QR shown in Control Center. This phone connects directly over a private link.';

  @override
  String get connectingToMac => 'Connecting to Control Center…';

  @override
  String get connectingDetail => 'Establishing a secure, direct link.';

  @override
  String get identityChangedTitle => 'Server identity changed';

  @override
  String get identityChangedBody =>
      'This server no longer matches the identity saved when you paired. That can mean the server was reinstalled — or that something is intercepting the connection. To stay safe, this device will not connect. Remove the pairing, then scan a fresh QR code from Control Center to pair again.';

  @override
  String get removePairing => 'Remove pairing';

  @override
  String get couldntConnect => 'Couldn\'t connect';

  @override
  String get pendingPairingTitle => 'Connect to this server?';

  @override
  String get pendingPairingBody =>
      'A link asked Control Center to pair with this server. Only continue if you started it yourself.';

  @override
  String get connect => 'Connect';

  @override
  String get failureNotPaired =>
      'Not paired — scan the QR code from Control Center';

  @override
  String get failureUnreachable =>
      'Couldn\'t reach your server on any path — check it\'s running, or try the same network';

  @override
  String get failureIdentityChanged =>
      'The server\'s identity changed — if it was reinstalled, re-pair this device';

  @override
  String get failureAuthRejected =>
      'The server rejected this device — re-pair it from Control Center';

  @override
  String get failureUnknown => 'Couldn\'t connect — tap to retry';

  @override
  String get statusConnected => 'Connected';

  @override
  String get statusConnecting => 'Connecting';

  @override
  String get statusOffline => 'Offline';

  @override
  String get statusIdentityMismatch => 'Identity mismatch';

  @override
  String get statusNotPaired => 'Not paired';

  @override
  String get statusConfirmPairing => 'Confirm pairing';

  @override
  String get connectionFailed => 'Connection failed';

  @override
  String get identityMismatchBanner =>
      'Server identity changed — connection stopped. Re-pair this device to continue.';

  @override
  String get tabInbox => 'Inbox';

  @override
  String get tabTickets => 'Tickets';

  @override
  String get tabChat => 'Chat';

  @override
  String get tabPrs => 'PRs';

  @override
  String get tabCalendar => 'Calendar';

  @override
  String get tabNews => 'News';

  @override
  String tabWaitingCount(String label, int count) {
    return '$label, $count waiting';
  }

  @override
  String get updateAvailable => 'A new Control Center is available';

  @override
  String get appearance => 'Appearance';

  @override
  String get language => 'Language';

  @override
  String get device => 'Device';

  @override
  String get themeSystem => 'System';

  @override
  String get themeLight => 'Light';

  @override
  String get themeDark => 'Dark';

  @override
  String get languageSystem => 'System';

  @override
  String get disconnectTapAgain =>
      'Tap again to disconnect this device from Control Center';

  @override
  String get disconnectDevice => 'Disconnect this device';

  @override
  String get disconnect => 'Disconnect';

  @override
  String get chooseWorkspace => 'Choose workspace';

  @override
  String get workspaces => 'Workspaces';

  @override
  String get workspacesLoadFailed => 'Couldn\'t load workspaces';

  @override
  String get noWorkspacesYet => 'No workspaces yet';

  @override
  String selectWorkspace(String name) {
    return 'Select $name';
  }

  @override
  String get inboxLoadFailed => 'Couldn\'t load your inbox';

  @override
  String get allCaughtUp => 'You’re all caught up';

  @override
  String get inboxNothingWaiting =>
      'Nothing is blocked and no pull request is waiting on you.';

  @override
  String get blocked => 'Blocked';

  @override
  String get sectionNeedsYourReview => 'Needs your review';

  @override
  String get sectionReturnedToYou => 'Returned to you';

  @override
  String get sectionApprovedAndReady => 'Approved and ready';

  @override
  String get sectionYourDrafts => 'Your drafts';

  @override
  String get sectionWaitingForReviewers => 'Waiting for reviewers';

  @override
  String get sectionMergingAndMerged => 'Merging and recently merged';

  @override
  String get sectionWaitingForAuthor => 'Waiting for author';

  @override
  String waitingAgo(String ago) {
    return 'waiting $ago';
  }

  @override
  String get openConversation => 'Open the conversation';

  @override
  String get calendarLoadFailed => 'Couldn\'t load your calendar';

  @override
  String get nothingScheduled => 'Nothing scheduled';

  @override
  String get calendarEmptyDescription =>
      'Events from your connected calendars appear here.';

  @override
  String get agenda => 'Agenda';

  @override
  String get syncCalendarsNow => 'Sync calendars now';

  @override
  String get event => 'Event';

  @override
  String get eventNotFound => 'Event not found';

  @override
  String get eventNotFoundDescription =>
      'It may be outside the agenda window, or removed upstream.';

  @override
  String get joinMeeting => 'Join meeting';

  @override
  String get join => 'Join';

  @override
  String attendeesCount(int count) {
    return 'Attendees ($count)';
  }

  @override
  String get details => 'Details';

  @override
  String get allDay => 'All day';

  @override
  String get happeningNow => 'Happening now';

  @override
  String inDuration(String duration) {
    return 'In $duration';
  }

  @override
  String eventTimeRange(String start, String end, String duration) {
    return '$start – $end · $duration';
  }

  @override
  String upNextSemantic(String lead, String title) {
    return '$lead: $title';
  }

  @override
  String get attendeeAccepted => 'accepted';

  @override
  String get attendeeDeclined => 'declined';

  @override
  String get attendeeMaybe => 'maybe';

  @override
  String get attendeeNoReply => 'no reply';

  @override
  String get organizer => 'organizer';

  @override
  String get calendarNoAccounts =>
      'No calendar is connected for this workspace. Connect one from the desktop app — the sign-in stores its token on the server.';

  @override
  String get calendarReauthNeeded =>
      'A calendar account needs to be reconnected — what you see below may be out of date. Reconnect it from the desktop app.';

  @override
  String get spacesLoadFailed => 'Couldn\'t load spaces';

  @override
  String get noSpaces => 'No spaces';

  @override
  String get spacesEmptyDescription => 'Spaces in this workspace appear here.';

  @override
  String get newSpaceFolder => 'New folder';

  @override
  String get folderName => 'Folder name';

  @override
  String get renameSpaceFolder => 'Rename folder';

  @override
  String get deleteSpaceFolder => 'Delete folder';

  @override
  String get moveSpaceToFolder => 'Move to folder';

  @override
  String get removeSpaceFromFolder => 'Remove from folder';

  @override
  String get spaceFolderActions => 'Folder actions';

  @override
  String get deleteFolderWithSpacesWarning =>
      'Deleting spaces permanently removes their messages and worktrees for everyone. This cannot be undone.';

  @override
  String get deleteSpacesInFolder =>
      'Permanently delete the spaces in this folder';

  @override
  String get deleteFolderAndSpaces => 'Delete folder and spaces';

  @override
  String get keepSpacesInFolder => 'Otherwise, spaces will remain unfiled.';

  @override
  String get create => 'Create';

  @override
  String get otherSpaces => 'Other spaces';

  @override
  String get folderUpdateFailed => 'Couldn\'t update folders';

  @override
  String get thread => 'Thread';

  @override
  String get agentWorking => 'Agent is working';

  @override
  String get messagesLoadFailed => 'Couldn\'t load messages';

  @override
  String get noMessagesYet => 'No messages yet';

  @override
  String get noMessagesDescription =>
      'Send a message to start the conversation.';

  @override
  String get agentResponding => 'Agent responding';

  @override
  String get agentFinished => 'Agent finished';

  @override
  String attachmentsTooLarge(int count, String names) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$names are too large to send from here.',
      one: '$names is too large to send from here.',
    );
    return '$_temp0';
  }

  @override
  String get teammate => 'Teammate';

  @override
  String get systemSender => 'System';

  @override
  String get agent => 'Agent';

  @override
  String get attachFile => 'Attach a file';

  @override
  String get messageHint => 'Message';

  @override
  String removeAttachment(String name) {
    return 'Remove $name';
  }

  @override
  String get articlesLoadFailed => 'Couldn\'t load articles';

  @override
  String get noArticles => 'No articles';

  @override
  String get articlesEmptyDescription =>
      'New articles appear here as feeds update.';

  @override
  String get unread => 'Unread';

  @override
  String get allFeeds => 'All feeds';

  @override
  String get save => 'Save';

  @override
  String get unsave => 'Unsave';

  @override
  String get readFullArticle => 'Read full article';

  @override
  String get ticketsLoadFailed => 'Couldn\'t load tickets';

  @override
  String get noTickets => 'No tickets';

  @override
  String get ticketsEmptyDescription =>
      'Tickets in this workspace appear here.';

  @override
  String get all => 'All';

  @override
  String get ticket => 'Ticket';

  @override
  String get ticketLoadFailed => 'Couldn\'t load ticket';

  @override
  String assignedTo(String name) {
    return 'Assigned to $name';
  }

  @override
  String get openInBrowser => 'Open in browser';

  @override
  String get status => 'Status';

  @override
  String get assign => 'Assign';

  @override
  String get reassign => 'Reassign';

  @override
  String get noAgents => 'No agents';

  @override
  String get noAgentsDescription => 'Assign an agent from this workspace.';

  @override
  String get statusOpen => 'Open';

  @override
  String get statusInProgress => 'In progress';

  @override
  String get statusBlocked => 'Blocked';

  @override
  String get statusInReview => 'In review';

  @override
  String get statusDone => 'Done';

  @override
  String get statusBacklog => 'Backlog';

  @override
  String get lensNeedsMe => 'Needs me';

  @override
  String get lensMine => 'Mine';

  @override
  String get prsLoadFailed => 'Couldn\'t load pull requests';

  @override
  String get noOpenPullRequests => 'No open pull requests';

  @override
  String get nothingWaitingOnReview => 'Nothing waiting on your review';

  @override
  String get noOwnOpenPullRequests => 'You have no open pull requests';

  @override
  String get nothingBlocked => 'Nothing blocked';

  @override
  String get prsEmptyDescription =>
      'Pull requests across this workspace’s repos appear here.';

  @override
  String get refreshPullRequests => 'Refresh pull requests';

  @override
  String get noForgeConnected =>
      'No forge is connected on the server, so no pull requests can be fetched. Connect one from the desktop app.';

  @override
  String get draft => 'Draft';

  @override
  String get merged => 'Merged';

  @override
  String get closed => 'Closed';

  @override
  String get open => 'Open';

  @override
  String get approved => 'Approved';

  @override
  String get changesRequested => 'Changes requested';

  @override
  String get reviewRequired => 'Review required';

  @override
  String get checksPassing => 'Checks passing';

  @override
  String get checksFailing => 'Checks failing';

  @override
  String get checksRunning => 'Checks running';

  @override
  String prSemanticLabel(String title, String status) {
    return '$title, $status';
  }

  @override
  String get pullRequest => 'Pull request';

  @override
  String get prLoadFailed => 'Couldn\'t load this pull request';

  @override
  String get openOnForge => 'Open on the forge';

  @override
  String get requestChangesNeedsComment =>
      'Add a comment explaining what needs changing.';

  @override
  String get conversation => 'Conversation';

  @override
  String get files => 'Files';

  @override
  String get checks => 'Checks';

  @override
  String labelWithCount(String label, int count) {
    return '$label ($count)';
  }

  @override
  String filesCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count files',
      one: '1 file',
    );
    return '$_temp0';
  }

  @override
  String commitsCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count commits',
      one: '1 commit',
    );
    return '$_temp0';
  }

  @override
  String get conflicts => 'Conflicts';

  @override
  String get reviewers => 'Reviewers';

  @override
  String get noDescriptionNoComments => 'No description and no comments yet.';

  @override
  String get noChangedFiles => 'No changed files.';

  @override
  String get noChecksReported => 'No checks reported for the head commit.';

  @override
  String get reviewCommentHint => 'Leave a review comment…';

  @override
  String get comment => 'Comment';

  @override
  String get commentPosted => 'Comment posted';

  @override
  String get request => 'Request';

  @override
  String get squashAndMerge => 'Squash and merge';

  @override
  String noActionsAvailable(String status) {
    return '$status — no actions available.';
  }

  @override
  String get reviewApproved => 'approved';

  @override
  String get reviewRequestedChanges => 'requested changes';

  @override
  String get reviewCommented => 'reviewed';

  @override
  String get reviewPending => 'pending';

  @override
  String get unknownAuthor => 'unknown';

  @override
  String hideDiffFor(String file) {
    return 'Hide the diff for $file';
  }

  @override
  String showDiffFor(String file) {
    return 'Show the diff for $file';
  }

  @override
  String get checkRunning => 'running';

  @override
  String get checkPassed => 'passed';

  @override
  String get checkFailed => 'failed';

  @override
  String get checkCancelled => 'cancelled';

  @override
  String get checkSkipped => 'skipped';

  @override
  String labelWithDuration(String label, String duration) {
    return '$label · $duration';
  }

  @override
  String checkSemanticLabel(String name, String state) {
    return '$name, $state';
  }

  @override
  String get noTextDiff =>
      'No text diff for this file — it is binary, or too large for the forge to return one.';

  @override
  String showRemainingLines(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Show the remaining $count lines',
      one: 'Show the remaining line',
    );
    return '$_temp0';
  }

  @override
  String unchangedLines(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count unchanged lines',
      one: '1 unchanged line',
    );
    return '$_temp0';
  }

  @override
  String get jumpToLatest => 'Jump to latest';

  @override
  String get streaming => 'Streaming';

  @override
  String get working => 'Working';

  @override
  String get input => 'Input';

  @override
  String get output => 'Output';

  @override
  String get now => 'now';

  @override
  String agoMinutes(int count) {
    return '${count}m';
  }

  @override
  String agoHours(int count) {
    return '${count}h';
  }

  @override
  String agoDays(int count) {
    return '${count}d';
  }

  @override
  String get today => 'Today';

  @override
  String get tomorrow => 'Tomorrow';

  @override
  String get yesterday => 'Yesterday';

  @override
  String durationMinutes(int count) {
    return '${count}m';
  }

  @override
  String durationHours(int count) {
    return '${count}h';
  }

  @override
  String durationHoursMinutes(int hours, int minutes) {
    return '${hours}h ${minutes}m';
  }

  @override
  String get mobileConversations => 'Conversations';

  @override
  String get mobileNewConversation => 'New conversation';

  @override
  String get mobileConversationName => 'Conversation name';

  @override
  String get mobileRename => 'Rename';

  @override
  String get mobileManageSpace => 'Manage space';

  @override
  String get mobileArchived => 'Archived';

  @override
  String get mobileSearchMessages => 'Search all messages in this space';

  @override
  String get mobileSearch => 'Search';

  @override
  String get mobileNoResults => 'No results';

  @override
  String get mobileReopen => 'Reopen';

  @override
  String get mobileArchive => 'Archive';

  @override
  String get mobileProgress => 'Progress and context';

  @override
  String get mobileReadFailed => 'Could not mark this conversation as read';

  @override
  String get mobileSendFailed => 'Message not sent. Your draft is still here.';

  @override
  String get sentAttachmentUnavailable => 'Attachment unavailable';

  @override
  String get sentAttachmentLoadFailed => 'Could not load attachment';

  @override
  String get mobileActionFailed => 'Action failed';

  @override
  String get mobileRemove => 'Remove';

  @override
  String get mobileLinkedMessage => 'Linked message';

  @override
  String get mobileOlderMessages => 'Older messages';

  @override
  String get mobileMessageActions => 'Message actions';

  @override
  String get mobileOpenThread => 'Open thread';

  @override
  String get mobileCopyLink => 'Copy link';

  @override
  String get mobileStopRun => 'Stop run';

  @override
  String get mobileStopRunConfirm =>
      'Stop this agent run? Work already completed will be kept.';

  @override
  String get mobileControlUnsupported =>
      'This run has finished or does not support this control.';

  @override
  String get mobilePauseRequested =>
      'Pause requested at the next turn boundary';

  @override
  String get mobileResumed => 'Run resumed';

  @override
  String get mobileStopRequested => 'Stop requested';

  @override
  String get mobileQueuedMessages => 'Queued messages';

  @override
  String get mobilePauseRun => 'Pause at next turn';

  @override
  String get mobileResumeRun => 'Resume';

  @override
  String get mobileEditQueued => 'Edit queued message';

  @override
  String get mobileSteerNow => 'Steer now';

  @override
  String get mobileMoveUp => 'Move up';

  @override
  String get mobileMoveDown => 'Move down';

  @override
  String get mobileQueueChanged =>
      'The queue changed, or this run cannot accept live steering. Refresh and try again.';

  @override
  String get mobileActivity => 'Activity';

  @override
  String get mobilePermissions => 'Permissions and audit';

  @override
  String get mobilePlans => 'Plans';

  @override
  String get mobileGoals => 'Supervised goals';

  @override
  String get mobileCredentials => 'Connections and credentials';

  @override
  String get mobileWorkspaceUnavailable =>
      'This workspace is unavailable or you no longer have access.';

  @override
  String get mobilePrReviewThreads => 'Review threads';

  @override
  String get mobilePrThreadsLoadFailed => 'Could not load review threads';

  @override
  String get mobilePrNoReviewThreads => 'No inline review threads yet';

  @override
  String get mobilePrCommentPermissionDenied =>
      'You do not have permission to comment on this repository.';

  @override
  String get mobilePrPermissionChecking => 'Checking comment permissions…';

  @override
  String get mobilePrPermissionLoadFailed =>
      'Could not check comment permissions. Retry to comment.';

  @override
  String mobilePrThreadLine(String side, String line) {
    return '$side line $line';
  }

  @override
  String get mobilePrOriginalSide => 'Original';

  @override
  String get mobilePrSelectCommentLine => 'Choose a line to comment on';

  @override
  String get mobilePrUpdatedSide => 'Updated';

  @override
  String get mobilePrThreadResolved => 'Resolved';

  @override
  String get mobilePrReplyHint => 'Write a reply…';

  @override
  String get mobilePrCommentRequired => 'Write a comment before posting.';

  @override
  String get mobilePrReply => 'Reply';

  @override
  String get mobilePrReopenThread => 'Reopen thread';

  @override
  String get mobilePrResolveThread => 'Resolve thread';

  @override
  String get mobilePrResolvePermissionDenied =>
      'Only the pull request author or someone with write access can resolve this thread.';

  @override
  String mobilePrCommentOnLine(String side, String line) {
    return 'Comment on $side line $line';
  }

  @override
  String get mobilePrInlineCommentHint => 'Write an inline comment…';

  @override
  String get mobilePrPostInlineComment => 'Post comment';

  @override
  String get mobilePrCommentUnavailable =>
      'Inline comments are unavailable for this pull request.';

  @override
  String get mobilePrPatchUnavailable =>
      'The forge did not provide a text patch for this file.';

  @override
  String get mobilePrNoPatchForFile =>
      'The patch for this file is not available.';

  @override
  String get mobileTicketNew => 'New ticket';

  @override
  String get mobileTicketCreate => 'Create ticket';

  @override
  String get mobileTicketEdit => 'Edit ticket';

  @override
  String get mobileTicketTitle => 'Title';

  @override
  String get mobileTicketTitleRequired => 'Enter a title to save this ticket.';

  @override
  String get mobileTicketDescription => 'Description';

  @override
  String get mobileTicketMarkdownHint => 'Add details in Markdown';

  @override
  String get mobileTicketPriority => 'Priority';

  @override
  String get mobileTicketPriorityNone => 'No priority';

  @override
  String get mobileTicketPriorityUrgent => 'Urgent';

  @override
  String get mobileTicketPriorityHigh => 'High';

  @override
  String get mobileTicketPriorityMedium => 'Medium';

  @override
  String get mobileTicketPriorityLow => 'Low';

  @override
  String get mobileTicketLabels => 'Labels';

  @override
  String get mobileTicketLabelsHint => 'One label per line';

  @override
  String get mobileTicketLabelsHelp => 'Enter each label on a separate line.';

  @override
  String mobileTicketWorkspaceProvider(String provider) {
    return 'Filed in $provider';
  }

  @override
  String get mobileTicketProviderLocal => 'Control Center';

  @override
  String get mobileTicketUnassigned => 'Unassigned';

  @override
  String get mobileTicketAssignedFilter => 'Assigned';

  @override
  String get mobileTicketAgentsLoadFailed => 'Couldn\'t load agents';

  @override
  String get mobileTicketSearch => 'Search tickets';

  @override
  String get mobileTicketSearchHint =>
      'Title, key, description, label or assignee';

  @override
  String get mobileTicketClearSearch => 'Clear ticket search';

  @override
  String get mobileTicketNoMatches => 'No matching tickets';

  @override
  String get mobileTicketAdjustFilters =>
      'Try another search or change the filters.';

  @override
  String get mobileTicketClearFilters => 'Clear filters';

  @override
  String get mobileTicketNotFound => 'Ticket not found';

  @override
  String get mobileTicketNotFoundDescription =>
      'This ticket may have been deleted or moved out of this workspace.';

  @override
  String get mobileTicketWorkspaceChanged =>
      'The workspace changed. Return to the current workspace before saving.';

  @override
  String get mobileTicketOpenLinkedSpace => 'Open linked space';

  @override
  String get mobileTicketReadOnly =>
      'A workspace member role is required to change tickets.';

  @override
  String get permissionTitle => 'Permissions';

  @override
  String get permissionWorkspaceFailed => 'Couldn\'t load the workspace';

  @override
  String get permissionNoWorkspace =>
      'Select a workspace to inspect permissions.';

  @override
  String get permissionLoading => 'Loading permissions…';

  @override
  String get permissionScopeDescription =>
      'Inspect how each action is decided at this scope. Workspace rules can be inherited by agents and spaces.';

  @override
  String get permissionScope => 'Policy scope';

  @override
  String get permissionWorkspaceScope => 'Workspace';

  @override
  String get permissionAgentScope => 'Agent';

  @override
  String get permissionSpaceScope => 'Space';

  @override
  String get permissionAgentContext => 'Agent acting in this space';

  @override
  String get permissionNoAgentContext => 'No agent selected';

  @override
  String get permissionTargetsFailed => 'Couldn\'t load scope targets';

  @override
  String get permissionNoTargets => 'No targets are available at this scope.';

  @override
  String get permissionRoleFailed => 'Couldn\'t confirm your workspace role';

  @override
  String get permissionMemberRequired =>
      'A workspace member role is required to view policy rules.';

  @override
  String get permissionRulesFailed => 'Couldn\'t load policy rules';

  @override
  String get permissionAuditAdminOnly =>
      'Authorization history is available to workspace admins only.';

  @override
  String get permissionAllow => 'Allow';

  @override
  String get permissionAsk => 'Ask first';

  @override
  String get permissionDeny => 'Deny';

  @override
  String get permissionFileDelete => 'Delete files';

  @override
  String get permissionFileWriteOutsideWorktree => 'Write outside worktree';

  @override
  String get permissionGitCommit => 'Commit changes';

  @override
  String get permissionGitPush => 'Push commits';

  @override
  String get permissionPrCreate => 'Create pull requests';

  @override
  String get permissionPrPublish => 'Update or merge pull requests';

  @override
  String get permissionVendorSyncWrite => 'Write vendor sync';

  @override
  String get permissionNetworkEgress => 'Access network';

  @override
  String get permissionSecretAccess => 'Access secrets';

  @override
  String get permissionPackageInstall => 'Install packages';

  @override
  String get permissionProcessSpawn => 'Spawn processes';

  @override
  String get permissionWorkspaceMutation => 'Change workspace';

  @override
  String get permissionEnclosureControl => 'Control enclosure';

  @override
  String get permissionChangeFailed => 'Couldn\'t change the rule';

  @override
  String get permissionEffectiveDescription =>
      'Effective for this scope without action arguments. Conditional grants below apply only to matching requests; the server makes the final decision.';

  @override
  String get permissionSpaceAgentNote =>
      'No agent selected. Agent-specific rules are omitted until you choose one above.';

  @override
  String get permissionScopedGrants => 'Rules at this scope';

  @override
  String get permissionModePreset => 'Mode preset';

  @override
  String get permissionBuiltInDefault => 'Built-in default';

  @override
  String get permissionRemembered => 'Standing approval';

  @override
  String get permissionSource => 'Source';

  @override
  String permissionSetAtThisScope(String source) {
    return '$source · set here';
  }

  @override
  String permissionInheritedFrom(String source) {
    return '$source · inherited';
  }

  @override
  String permissionExpiresAt(String date) {
    return 'Expires $date';
  }

  @override
  String get permissionSetHere => 'Set a rule here';

  @override
  String get permissionConfirmRevoke => 'Confirm revoke';

  @override
  String get permissionRevokeRule => 'Revoke rule';

  @override
  String permissionCommandPrefix(String prefix) {
    return 'Command prefix: $prefix';
  }

  @override
  String get permissionNoExpiry => 'No expiry';

  @override
  String get permissionExpired => 'Expired';

  @override
  String get permissionExplicitRule => 'Explicit rule';

  @override
  String get permissionEnforcementAdvisory =>
      'Advisory: ask-first rules are logged without prompting';

  @override
  String get permissionEnforcementSoft =>
      'Soft enforcement: override requires authorization';

  @override
  String get permissionEnforcementHard =>
      'Hard enforcement: cannot be overridden';

  @override
  String permissionPaths(String paths) {
    return 'Paths: $paths';
  }

  @override
  String permissionRefs(String refs) {
    return 'Git refs: $refs';
  }

  @override
  String permissionHosts(String hosts) {
    return 'Hosts: $hosts';
  }

  @override
  String permissionCommands(String commands) {
    return 'Commands: $commands';
  }

  @override
  String permissionTools(String tools) {
    return 'Tools: $tools';
  }

  @override
  String get permissionNotInEffect =>
      'Not in effect while this action is denied';

  @override
  String permissionMaxCount(String count) {
    return 'Maximum count: $count';
  }

  @override
  String permissionMaxCents(String cents) {
    return 'Maximum cents: $cents';
  }

  @override
  String get permissionAuditHeading => 'Authorization history';

  @override
  String get permissionAuditDescription =>
      'Recent decisions recorded by the server. Only admins can inspect the log or verify its hash chain.';

  @override
  String permissionOnBehalfOf(String user) {
    return 'on behalf of $user';
  }

  @override
  String get permissionPrompted => 'Human approval requested';

  @override
  String get permissionVerifyChain => 'Verify audit chain';

  @override
  String get permissionVerifyFailed => 'Couldn\'t verify the audit chain';

  @override
  String permissionChainIntact(String count) {
    return 'Chain intact · $count entries checked';
  }

  @override
  String permissionChainBroken(String sequence, String reason) {
    return 'Chain broken at entry $sequence: $reason';
  }

  @override
  String get permissionAuditEmpty => 'No authorization decisions recorded yet.';

  @override
  String get permissionAuditFailed => 'Couldn\'t load authorization history';

  @override
  String get mobilePlansLoadFailed => 'Could not load plans';

  @override
  String get mobilePlansEmpty => 'No plans yet';

  @override
  String get mobilePlansEmptyDescription =>
      'Plans submitted by agents will appear here for review.';

  @override
  String get mobilePlanTitle => 'Plan';

  @override
  String get mobilePlanMissing =>
      'This plan is no longer available in this workspace.';

  @override
  String mobilePlanStepCount(int count) {
    return '$count steps';
  }

  @override
  String get mobilePlanDraft => 'Draft';

  @override
  String get mobilePlanProposed => 'Awaiting review';

  @override
  String get mobilePlanApproved => 'Approved';

  @override
  String get mobilePlanRejected => 'Rejected';

  @override
  String get mobilePlanSuperseded => 'Superseded';

  @override
  String get mobilePlanExecuting => 'Executing';

  @override
  String get mobilePlanSynthesizing => 'Synthesizing';

  @override
  String get mobilePlanCompleted => 'Completed';

  @override
  String get mobilePlanFailed => 'Failed';

  @override
  String get mobilePlanCancelled => 'Cancelled';

  @override
  String mobilePlanRevision(String revision) {
    return 'Revision $revision';
  }

  @override
  String get mobilePlanSteps => 'Steps';

  @override
  String get mobilePlanNoSteps => 'No steps were submitted for this plan.';

  @override
  String get mobilePlanAssumptions => 'Clarifications';

  @override
  String mobilePlanDependsOn(String keys) {
    return 'Depends on $keys';
  }

  @override
  String mobilePlanStepCost(String cost) {
    return 'Estimated up to $cost';
  }

  @override
  String get mobilePlanSelect => 'Select';

  @override
  String get mobilePlanSelected => 'Selected';

  @override
  String get mobilePlanEstimate => 'Estimate cost';

  @override
  String get mobilePlanEstimateRequired =>
      'Estimate the plan before approving execution.';

  @override
  String mobilePlanEstimatedCost(String low, String high) {
    return 'Estimated cost: $low–$high';
  }

  @override
  String get mobilePlanCostUnknown => 'not available';

  @override
  String get mobilePlanNoHardCap => 'no hard cap';

  @override
  String get mobilePlanExceedsBudget =>
      'The estimate exceeds the configured budget. Review before approving.';

  @override
  String get mobilePlanPartialEstimate =>
      'This estimate covers the entire plan; selected steps may cost less.';

  @override
  String get mobilePlanConfirmAll => 'Start the entire plan?';

  @override
  String get mobilePlanConfirmSelected => 'Start selected steps?';

  @override
  String mobilePlanExecutionConfirmation(String cost, String cap) {
    return 'Approving starts execution and can incur charges. Estimated high cost: $cost. Budget cap: $cap.';
  }

  @override
  String get mobilePlanApproveAll => 'Approve all and run';

  @override
  String get mobilePlanApproveSelected => 'Approve selected and run';

  @override
  String get mobilePlanWiden => 'Approve additional steps';

  @override
  String mobilePlanWidenConfirm(String count, String cap) {
    return 'Release $count more steps to execute? They can incur charges. Existing execution cost cap: $cap.';
  }

  @override
  String get mobilePlanChanged =>
      'The plan changed during review. Reopen the latest revision and estimate it again.';

  @override
  String get mobilePlanReject => 'Reject plan';

  @override
  String get mobilePlanRejectConfirm =>
      'Reject this plan? It will not execute.';

  @override
  String get mobilePlanStop => 'Stop execution';

  @override
  String get mobilePlanStopConfirm =>
      'Stop this plan\'s execution? Work already completed will not be undone.';

  @override
  String mobilePlanRunId(String runId) {
    return 'Execution run: $runId';
  }

  @override
  String get mobilePlanExecutionPending =>
      'Approval accepted. Waiting for the execution record…';

  @override
  String mobilePlanProgress(String completed, String total) {
    return '$completed of $total execution steps completed';
  }

  @override
  String get mobilePlanOpenConversation => 'Open conversation';

  @override
  String get mobileGoalsTitle => 'Supervised goals';

  @override
  String get mobileGoalsLoadFailed => 'Could not load supervised goals';

  @override
  String get mobileGoalsEmpty => 'No supervised goals yet';

  @override
  String get mobileGoalsEmptyDescription =>
      'Start one in a space, or send /goal in a conversation.';

  @override
  String get mobileGoalMissing =>
      'This goal is no longer available in this workspace.';

  @override
  String get mobileGoalActive => 'Active';

  @override
  String get mobileGoalPaused => 'Paused';

  @override
  String get mobileGoalCompleted => 'Completed';

  @override
  String get mobileGoalFailed => 'Failed';

  @override
  String get mobileGoalCancelled => 'Cancelled';

  @override
  String get mobileGoalBudgetExhausted => 'Budget reached';

  @override
  String mobileGoalFailures(String count) {
    return 'Consecutive failed runs: $count';
  }

  @override
  String get mobileGoalFailedDescription =>
      'The supervisor stopped after repeated failed runs. Review the conversation for details.';

  @override
  String get mobileGoalPause => 'Pause goal';

  @override
  String get mobileGoalResume => 'Resume goal';

  @override
  String get mobileGoalStop => 'Cancel goal';

  @override
  String get mobileGoalStopConfirm =>
      'Permanently cancel this supervised goal? It cannot be resumed.';

  @override
  String get mobileGoalRaiseBudget => 'Raise budget and resume';

  @override
  String mobileGoalRaiseTo(String amount) {
    return 'Raise budget to $amount and resume';
  }

  @override
  String mobileGoalRaiseConfirm(String oldCap, String newCap) {
    return 'Increase this goal\'s cost cap from $oldCap to $newCap and resume spending?';
  }

  @override
  String get mobileGoalOpenConversation => 'Open goal conversation';

  @override
  String get mobileGoalCreate => 'Start supervised goal';

  @override
  String get mobileGoalChooseSpace => 'Run in space';

  @override
  String get mobileGoalNoSpaces => 'Create a space before starting a goal.';

  @override
  String get mobileGoalChooseAgent => 'Run with agent';

  @override
  String get mobileGoalNoAgents =>
      'Add an active agent before starting a goal.';

  @override
  String mobileGoalSelectedAgent(String name) {
    return '$name selected';
  }

  @override
  String get mobileGoalObjectiveHint => 'What outcome should the agent pursue?';

  @override
  String get mobileGoalBudgetUsd => 'Cost cap (USD)';

  @override
  String get mobileGoalCreateInvalid =>
      'Choose a space and agent, enter an objective and set a positive cost cap in USD.';

  @override
  String mobileGoalCreateConfirm(String cap) {
    return 'Start a supervised goal with a maximum cost of $cap? The agent may begin immediately.';
  }

  @override
  String get mobileGoalUnavailable =>
      'The server connection is not ready. Retry after reconnecting.';

  @override
  String get mobileGoalConversationMissing =>
      'The selected conversation is no longer available in this workspace.';

  @override
  String get mobileGoalCreateSent =>
      'Goal started. Supervisor state will appear in this list.';

  @override
  String get mobileGoalStartRefused =>
      'No goal run started. Review the conversation for the supervisor\'s reason.';

  @override
  String mobileGoalSelectedSpace(String name) {
    return '$name selected';
  }

  @override
  String get requestUnavailable =>
      'This request is no longer available in the active workspace.';

  @override
  String get requestAlreadyResolved =>
      'This request has already been resolved.';

  @override
  String get inboxCredentialsBlocked => 'Credentials blocking runs';

  @override
  String get inboxSyncFailures => 'Failed vendor syncs';

  @override
  String get inboxConfigureCredentials => 'Configure credentials';

  @override
  String get openTicket => 'Open ticket';

  @override
  String get activityTitle => 'Activity';

  @override
  String get activityClearAll => 'Clear activity';

  @override
  String get activityClearConfirm =>
      'This hides all activity recorded so far for you on every device. New activity will still appear.';

  @override
  String get activityMarkAllRead => 'Mark all read';

  @override
  String get activityMarkAllConfirm =>
      'Mark every activity item in this workspace as read on all your devices?';

  @override
  String get activityMarkRead => 'Mark read';

  @override
  String get activityMarkUnread => 'Mark unread';

  @override
  String get activityDismiss => 'Dismiss';

  @override
  String get activityResolved => 'Resolved';

  @override
  String get activityOpen => 'Open';

  @override
  String get activityEmpty => 'No activity yet';

  @override
  String get activityLoadFailed => 'Couldn’t load activity';

  @override
  String get activityAgentWaiting => 'Agent needs input';

  @override
  String get activityAgentBlocked => 'Agent action blocked';

  @override
  String get activityMessage => 'New message';

  @override
  String get activityPullRequest => 'Pull request update';

  @override
  String get activityRig => 'Enclosure update';

  @override
  String get activityEvent => 'Update';

  @override
  String get activityPrReady => 'Pull request ready to merge';

  @override
  String get activityPrBlocked => 'Pull request merge blocked';

  @override
  String get activityPrApproved => 'Pull request approved';

  @override
  String get activityPrChanges => 'Changes requested';

  @override
  String get activityPrChecksFailed => 'Pull request checks failed';

  @override
  String get activityPrChecksRecovered => 'Pull request checks recovered';

  @override
  String get activityPrComment => 'Pull request comment';

  @override
  String get activityPrPublished => 'Pull request published';

  @override
  String get activityPrMerged => 'Pull request merged';

  @override
  String get activityPrMentioned => 'Mentioned in a pull request';

  @override
  String get activityPrReviewRequested => 'Review requested';

  @override
  String get activityPrReviewStale => 'Review needs refreshing';

  @override
  String get activityTicketAssigned => 'Ticket assigned';

  @override
  String get activityTicketChanged => 'Ticket status changed';

  @override
  String get activityMeetingSoon => 'Meeting starting soon';

  @override
  String get activityCalendarExpired => 'Calendar connection expired';

  @override
  String get activityRigControl => 'Enclosure control changed';

  @override
  String get activityRigClosed => 'Enclosure stopped';

  @override
  String get mobileSpacesSearch => 'Search spaces';

  @override
  String get mobileSpacesArchived => 'Archived';

  @override
  String get mobileSpacesActive => 'Active';

  @override
  String get mobileSpacesNew => 'New space';

  @override
  String get mobileSpacesManage => 'Manage space';

  @override
  String get mobileSpacesName => 'Space name';

  @override
  String get mobileSpacesAgents => 'Agents';

  @override
  String get mobileSpacesMembers => 'People';

  @override
  String get mobileSpacesRepos => 'Repositories';

  @override
  String get mobileSpacesAllRepos => 'All linked repositories';

  @override
  String get mobileSpacesNoRepos => 'No repositories';

  @override
  String get mobileSpacesBaseBranch => 'Base branch (optional)';

  @override
  String get mobileSpacesDefaultBranch => 'Default branch';

  @override
  String get mobileSpacesMode => 'Mode';

  @override
  String get mobileSpacesModeChat => 'Chat';

  @override
  String get mobileSpacesModeReview => 'Review (read-only)';

  @override
  String get mobileSpacesModePlan => 'Plan (read-only)';

  @override
  String get mobileSpacesModeOrchestrate => 'Orchestrate';

  @override
  String get mobileSpacesAutonomy => 'Autonomy override';

  @override
  String get mobileSpacesAutonomyInherited => 'Inherited';

  @override
  String get mobileSpacesAutonomyPropose => 'Propose only';

  @override
  String get mobileSpacesAutonomyApproval => 'Act with approval';

  @override
  String get mobileSpacesAutonomyFreely => 'Act freely';

  @override
  String get mobileSpacesAutonomyNotice =>
      'An override cannot bypass action-policy prompts or denials. Only workspace admins can change it.';

  @override
  String get mobileSpacesArchive => 'Archive space';

  @override
  String get mobileSpacesReopen => 'Reopen space';

  @override
  String get mobileSpacesSave => 'Save changes';

  @override
  String get mobileSpacesCreate => 'Create space';

  @override
  String get mobileSpacesOperationFailed => 'Couldn\'t update space';

  @override
  String get mobileSpacesMissing => 'Space not found in this workspace';

  @override
  String get mobileSpacesEmptyName => 'Enter a space name';

  @override
  String get mobileSpacesNoMatches => 'No matching spaces';

  @override
  String get mobileSpacesUnread => 'Unread agent reply';

  @override
  String get mobileSpacesNeedsInput => 'Needs your input';

  @override
  String get mobileSpacesRunning => 'Agent running';

  @override
  String get mobileSpacesNoAgents => 'No agents in this workspace';

  @override
  String get mobileSpacesNoMembers => 'No other workspace members';

  @override
  String get mobileSpacesRepoError => 'Couldn\'t load repositories';

  @override
  String get mobileSpacesRetry => 'Retry';

  @override
  String get mobileSpacesBranchUnavailable =>
      'Choose or type a base branch when creating a space; existing space base branches cannot be changed.';

  @override
  String get mobileSpacesArchivedEmpty => 'No archived spaces';

  @override
  String get mobileSpacesAllRepoWarning =>
      'Newly linked workspace repositories will also be included in this space.';

  @override
  String get mobileSpacesCreatedRetry =>
      'Space created. Retry adding people, or open its management page.';

  @override
  String get progressTitle => 'Progress';

  @override
  String get progressConversation => 'Conversation';

  @override
  String get progressLoadFailed => 'Couldn’t load progress';

  @override
  String get progressUnavailable => 'Conversation unavailable';

  @override
  String get progressUnavailableDescription =>
      'This conversation is not in the active workspace and space. Return to its space to continue.';

  @override
  String get progressSaveFailed => 'Couldn’t update progress';

  @override
  String get progressGoal => 'Goal';

  @override
  String get progressNoGoal => 'No working goal set';

  @override
  String get progressSetGoal => 'Set goal';

  @override
  String get progressEditGoal => 'Edit goal';

  @override
  String get progressClearGoal => 'Clear goal';

  @override
  String get progressGoalRequired => 'Enter a goal before saving.';

  @override
  String get progressTodos => 'Tasks';

  @override
  String get transcriptToolTodos => 'Tasks';

  @override
  String get transcriptToolSearchMemory => 'Search memory';

  @override
  String get transcriptToolRenderMedia => 'Render media';

  @override
  String get progressNoTodos => 'No tasks yet';

  @override
  String get progressNewTodo => 'New task';

  @override
  String get progressAddTodo => 'Add task';

  @override
  String get progressEditTodo => 'Edit task';

  @override
  String get progressTodoRequired => 'Enter a task before saving.';

  @override
  String get progressTodoNoLongerExists =>
      'That task was removed. Reload the list and try again.';

  @override
  String get progressWorkspaceChanged =>
      'The active workspace changed. Return to this conversation and try again.';

  @override
  String progressRemoveTodo(String name) {
    return 'Remove task $name';
  }

  @override
  String get progressPending => 'Pending';

  @override
  String get progressInProgress => 'In progress';

  @override
  String get progressCompleted => 'Completed';

  @override
  String get progressMoveUp => 'Move task up';

  @override
  String get progressMoveDown => 'Move task down';

  @override
  String get progressRunTree => 'Agent runs';

  @override
  String get progressNoRuns => 'No runs in this conversation yet';

  @override
  String get progressRunning => 'Running';

  @override
  String get progressFailed => 'Failed';

  @override
  String get progressUnknown => 'Unknown';

  @override
  String get progressHealthy => 'Active';

  @override
  String get progressBlocked => 'Blocked';

  @override
  String get progressLooping => 'Looping';

  @override
  String get progressStalled => 'Stalled';

  @override
  String get progressDead => 'Stopped unexpectedly';

  @override
  String get progressQuiet => 'No output yet';

  @override
  String get progressCostReported => 'Provider-reported charge';

  @override
  String get progressCostNotional =>
      'Notional subscription list price; not a bill';

  @override
  String get progressCostMixed => 'Mixed cost sources';

  @override
  String get progressCostEstimated => 'Estimated cost';

  @override
  String progressDurationSeconds(String seconds) {
    return '${seconds}s';
  }

  @override
  String progressRunDetails(String model, String duration, String cost) {
    return 'Model: $model · Time: $duration · Cost: $cost';
  }

  @override
  String progressStartedAt(String time) {
    return 'Started $time';
  }

  @override
  String progressLiveness(String state) {
    return 'Health: $state';
  }

  @override
  String progressRunTokens(String input, String output) {
    return 'Input: $input · Output: $output tokens';
  }

  @override
  String get progressOutputPreviewLimited =>
      'Only the first 6,000 characters of structured output are shown.';

  @override
  String progressRetryOf(String runId) {
    return 'Retry of run $runId';
  }

  @override
  String get progressContext => 'Context and limits';

  @override
  String get progressNoAgent => 'No agent to inspect';

  @override
  String progressContextReading(String used, String window) {
    return '$used / $window tokens';
  }

  @override
  String get progressMeasured => 'Provider-reported context on the latest call';

  @override
  String get progressEstimated =>
      'Estimated from stored conversation and persistent context';

  @override
  String get progressContextUnknown => 'Context usage not reported yet';

  @override
  String progressContextPercent(String percent) {
    return '$percent% of context window';
  }

  @override
  String progressMonthlyBudget(String amount) {
    return 'Configured monthly agent limit: $amount';
  }

  @override
  String progressConversationTokens(String tokens) {
    return 'Stored live conversation: $tokens estimated tokens';
  }

  @override
  String progressInspectionFor(String agent, String model) {
    return 'Persistent context for $agent · $model';
  }

  @override
  String get progressContextSystem => 'System prompt';

  @override
  String get progressContextRules => 'Rules';

  @override
  String get progressContextSkills => 'Skills';

  @override
  String get progressContextTools => 'Tool definitions';

  @override
  String get progressContextMcp => 'MCP tools';

  @override
  String get progressContextDeferred => 'Deferred tools';

  @override
  String get progressContextSubagents => 'Subagents';

  @override
  String get progressContextRunner => 'External runner';

  @override
  String get progressContextMemory => 'Memory';

  @override
  String get progressContextHistory => 'Conversation history';

  @override
  String progressContextSegment(String label, String tokens) {
    return '$label · $tokens tokens';
  }

  @override
  String progressContextPart(String title, String tokens) {
    return '$title · $tokens tokens';
  }

  @override
  String get progressOutputs => 'Recent outputs';

  @override
  String get progressNoOutputs => 'No recent agent outputs';

  @override
  String get progressStructuredOutputsAbove =>
      'Structured run outputs are shown in the agent runs above.';

  @override
  String get progressRecentOutputsOnly =>
      'Showing recent messages only. Open the conversation for older work.';

  @override
  String get progressPlan => 'Plan';

  @override
  String get progressArtifact => 'Artifact';

  @override
  String get progressResult => 'Result';

  @override
  String get progressHideArtifact => 'Hide artifact';

  @override
  String get progressReadArtifact => 'Read artifact';

  @override
  String get progressArtifactUnavailable => 'Artifact no longer available';

  @override
  String get progressArtifactPreviewLimited =>
      'Showing a limited preview of this artifact.';

  @override
  String get progressDiagramSource => 'Diagram source';

  @override
  String progressOpenAttachment(String name) {
    return 'Open $name';
  }

  @override
  String get progressOpenPlan => 'Open plan';

  @override
  String progressOpenDiff(String label) {
    return 'Review changed files: $label';
  }

  @override
  String get progressViewMessage => 'View message';

  @override
  String get pushTitle => 'Background notifications';

  @override
  String get pushIntro =>
      'Get a private alert when something needs your attention, even when the app is closed. Details stay inside your encrypted connection.';

  @override
  String get pushLoading => 'Checking notification settings…';

  @override
  String get pushError =>
      'Could not update notifications. Check your connection and try again.';

  @override
  String get pushEnable => 'Enable notifications';

  @override
  String get pushDisable => 'Turn off notifications';

  @override
  String get pushQuiet => 'Pause alerts on this device';

  @override
  String get pushCategories => 'Notify me about';

  @override
  String get pushCategoryAgents => 'Agents';

  @override
  String get pushCategoryMessages => 'Messages';

  @override
  String get pushCategoryPullRequests => 'Pull requests';

  @override
  String get pushCategoryTickets => 'Tickets';

  @override
  String get pushCategoryCalendar => 'Calendar';

  @override
  String get pushCategoryMachines => 'Machines';

  @override
  String get pushSecureOrigin => 'Notifications require HTTPS.';

  @override
  String get pushInstallIos =>
      'On iPhone or iPad, add this app to the Home Screen and open it there to enable notifications.';

  @override
  String get pushUnsupported =>
      'This browser does not support background notifications.';

  @override
  String get pushDenied =>
      'Your browser reports notifications blocked. Check this site\'s permission and your browser or device notification settings, then refresh.';

  @override
  String get pushOsHint =>
      'Your browser also needs permission to show notifications in your device\'s system settings.';

  @override
  String get pushServiceUnavailable =>
      'Your browser\'s push service refused the subscription. Some browsers, such as Brave, turn it off by default: look for a push messaging option in the browser\'s privacy settings, then try again.';

  @override
  String get pushWorkerUnavailable =>
      'The notification service could not start in this browser. Reload the page and try again.';

  @override
  String get pushResubscribe => 'Reconnect notifications';

  @override
  String get pushStatusEnabled => 'Notifications are on for this device.';

  @override
  String get pushStatusDisabled => 'Notifications are off for this device.';

  @override
  String get credentialsTitle => 'Connections & credentials';

  @override
  String get credentialsIntro =>
      'Connect the accounts your runs and integrations use. Secrets are stored on your server, not this phone.';

  @override
  String get credentialsModelProviders => 'Model providers';

  @override
  String get credentialsOwnerOnly =>
      'Only the server owner can add, sign in to, or remove model-provider credentials. These keys are shared across workspaces.';

  @override
  String get credentialsContactOwner =>
      'Ask the server owner to connect the provider needed by your blocked run.';

  @override
  String get credentialsClaudeCode => 'Claude Code';

  @override
  String get credentialsClaudeHostOnly =>
      'Claude Code signs in through the CLI on the host. Ask the server owner to complete or renew the account login on the host terminal; this phone cannot run it.';

  @override
  String get credentialsYourForgeAccounts => 'Your forge accounts';

  @override
  String get credentialsYourTicketingAccount => 'Your ticketing account';

  @override
  String get credentialsLocalTicketsNoLogin =>
      'Local tickets need no login. Connect Linear here if your workspace uses Linear.';

  @override
  String get credentialsMembershipRequired =>
      'Join a workspace to manage your forge or ticketing credentials. Ask a workspace administrator for access.';

  @override
  String get credentialsSwitchWorkspace =>
      'This link points to another workspace. Switch to that workspace before changing credentials.';

  @override
  String get credentialsReturnToInbox =>
      'Return to Inbox to retry a blocked run once its credential is connected. The host also checks parked runs automatically.';

  @override
  String get credentialsLoadFailed =>
      'Could not load connections. Check the server link and retry.';

  @override
  String get credentialsOperationFailed =>
      'Could not change this connection. Check the server link, your access, and the credential, then try again.';

  @override
  String get credentialsConnected => 'Connected';

  @override
  String get credentialsNotConnected => 'Not connected';

  @override
  String credentialsSignedInAs(String username) {
    return 'Signed in as $username';
  }

  @override
  String get credentialsAccount => 'Connected account';

  @override
  String get credentialsStoredKey => 'Stored key';

  @override
  String get credentialsActive => 'Active';

  @override
  String get credentialsRemove => 'Remove';

  @override
  String get credentialsRemoveConfirm =>
      'Remove your saved credential? You may need to sign in again.';

  @override
  String get credentialsApiKey => 'API key';

  @override
  String get credentialsApiKeyHint => 'Paste a provider API key';

  @override
  String get credentialsBrowserLogin => 'Sign in with browser';

  @override
  String get credentialsSignInAgain => 'Sign in again';

  @override
  String get credentialsWaitingForLogin =>
      'Waiting for authorization in your browser…';

  @override
  String get credentialsConnectCodePrompt => 'Confirmation code';

  @override
  String get credentialsConnectCodeMalformed =>
      'That doesn\'t look like a sign-in code. Codes have 8 letters and digits.';

  @override
  String get credentialsSignInInvalidCode =>
      'That code doesn\'t match this sign-in. Check it and try again.';

  @override
  String get credentialsSignInTooManyCodes =>
      'Too many wrong codes. Start the sign-in again.';

  @override
  String get credentialsSignInRetryLater =>
      'The sign-in service isn\'t responding right now. Wait a minute, then try again.';

  @override
  String get credentialsSignInRefused =>
      'The sign-in was refused. Start it again and approve every requested permission.';

  @override
  String get credentialsSignInNotSaved =>
      'The sign-in worked, but the server couldn\'t save it. Try again.';

  @override
  String credentialsSignInUnavailable(String provider) {
    return '$provider sign-in isn\'t set up on this server yet.';
  }

  @override
  String get credentialsSignInPhoneUnreachable =>
      'This server\'s sign-in callback isn\'t reachable securely from a phone. Sign in from the desktop app, or ask the server owner to set up a public HTTPS address.';

  @override
  String get credentialsLoginTimedOut =>
      'The login expired. Start a new sign-in attempt.';

  @override
  String get credentialsCopyCode => 'Copy code';

  @override
  String get credentialsDeviceCodeHint =>
      'Confirm this code on the provider\'s page. Keep this screen open while the server completes sign-in.';

  @override
  String get credentialsPasteRedirect => 'Authorization code or redirect URL';

  @override
  String get credentialsPasteRedirectHint =>
      'Paste the code or full redirect URL from the provider';

  @override
  String get credentialsCompleteLogin => 'Complete sign-in';

  @override
  String get credentialsUpdateToken => 'Update token';

  @override
  String get credentialsAddToken => 'Add token';

  @override
  String get credentialsPersonalToken => 'Personal access token';

  @override
  String get credentialsPersonalTokenHint => 'Paste a personal access token';

  @override
  String get credentialsStopWatching => 'Stop watching';

  @override
  String get transcriptClaudeSignInExpiredTitle =>
      'Claude Code sign-in expired';

  @override
  String get transcriptClaudeSignInExpiredBody =>
      'The run stopped because its account no longer authenticates. Sign in again, then retry the turn.';

  @override
  String get transcriptSignInExpiredTitle => 'Provider sign-in expired';

  @override
  String get transcriptSignInExpiredBody =>
      'The run stopped because its provider credential no longer works. Reconnect it in Settings → Providers, then retry the turn.';

  @override
  String get permissionHostExecution => 'Run commands on the host';

  @override
  String credentialsSignInLapsed(String provider) {
    return 'Your $provider sign-in has lapsed. Sign in again.';
  }

  @override
  String get credentialsSignInPaused =>
      'Paused: this workspace\'s sign-in service changed. It works again once the service is back.';

  @override
  String credentialsProviderUnreachable(String provider) {
    return 'Can\'t reach $provider right now. Retrying.';
  }

  @override
  String get credentialsScopeWorkspace => 'This workspace only';

  @override
  String get credentialsScopeAllWorkspaces => 'All workspaces';

  @override
  String get credentialsRemoveConfirmWorkspace =>
      'Remove your saved credential from this workspace? Other workspaces keep theirs.';

  @override
  String get credentialsRemoveConfirmAllWorkspaces =>
      'Remove your saved credential from every workspace that shares it?';

  @override
  String get credentialsSignInServerRestarted =>
      'The server restarted. Start the sign-in again.';

  @override
  String repoAccessInstallApp(String owner, String names) {
    return 'Install the GitHub App on $owner so automation can reach $names. Tap to open GitHub.';
  }

  @override
  String repoAccessAskAdminInstall(String owner, String names) {
    return 'The GitHub App isn\'t installed on $owner, so automation can\'t reach $names. Ask a workspace admin to install it.';
  }

  @override
  String repoAccessAddToApp(String names) {
    return 'Add $names to the GitHub App\'s repositories. Tap to open GitHub.';
  }

  @override
  String repoAccessAskAdminAdd(String names) {
    return 'The GitHub App can\'t see $names yet. Ask a workspace admin to add them to its repositories.';
  }

  @override
  String repoAccessSuspended(String names) {
    return 'GitHub App installation suspended. Automation for $names is paused until an owner of the account resumes the installation on GitHub.';
  }

  @override
  String repoAccessOwnerCannotSee(String names) {
    return 'The person accountable for this workspace\'s automation can no longer see $names, so nothing runs there on their behalf.';
  }

  @override
  String repoAccessOwnerNotSignedIn(String names) {
    return 'The person accountable for this workspace\'s automation isn\'t signed in to the forge, so automation for $names waits until they sign in.';
  }

  @override
  String repoAccessRetrying(String names) {
    return 'Couldn\'t check access to $names. Retrying.';
  }

  @override
  String hiddenReposSignIn(int count, String forge) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other:
          'Sign in to $forge to see pull requests from $count more repositories',
      one: 'Sign in to $forge to see pull requests from 1 more repository',
    );
    return '$_temp0';
  }

  @override
  String hiddenReposNoForgeAccess(int count, String forge) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other:
          '$count repositories are hidden because your $forge account can\'t see them',
      one: '1 repository is hidden because your $forge account can\'t see it',
    );
    return '$_temp0';
  }

  @override
  String hiddenReposNoGrant(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other:
          '$count repositories are hidden because you don\'t have access to them in this workspace',
      one:
          '1 repository is hidden because you don\'t have access to it in this workspace',
    );
    return '$_temp0';
  }

  @override
  String hiddenReposChecking(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Checking your access to $count more repositories…',
      one: 'Checking your access to 1 more repository…',
    );
    return '$_temp0';
  }

  @override
  String get credentialsAtlassianEmail => 'Atlassian account email';

  @override
  String get credentialsAtlassianEmailInvalid =>
      'Enter the email address of your Atlassian account.';

  @override
  String get credentialsBitbucketApiToken => 'API token';

  @override
  String repoAccessAutomationTokenMissing(String names) {
    return 'No automation token can read $names, so background work there is paused. An admin can add one in Settings → Repositories.';
  }

  @override
  String get credentialsSignInConfirmInBrowser =>
      'Confirm in your browser, then enter the code it shows.';

  @override
  String get credentialsSignInAccountAlreadyBound =>
      'This account is already connected to another person on this server. Sign in with a different account.';

  @override
  String credentialsTokenUnreachable(String provider) {
    return '$provider could not be reached to check this token. Try again in a moment.';
  }

  @override
  String credentialsTokenRejected(String provider) {
    return '$provider does not accept this token. Check that you copied all of it and that it has not been revoked.';
  }

  @override
  String credentialsTokenWrongKind(String provider) {
    return 'This is not a personal token. Paste a personal access token from your own $provider account, not a project, group, workspace or bot token.';
  }

  @override
  String credentialsTokenNarrowScope(String scope) {
    return 'This token is missing the $scope scope, which reviewing and commenting need. Create one that has it.';
  }

  @override
  String get credentialsTokenExpired =>
      'This token has expired. Create a new one and paste it here.';

  @override
  String get credentialsSignInRateLimited =>
      'Too many requests right now. Wait a bit, then try again.';

  @override
  String get credentialsSignInCancelled =>
      'The sign-in was cancelled or declined. Start it again when you\'re ready.';

  @override
  String get credentialsSignInNoLongerOpen =>
      'This sign-in is no longer open: it was cancelled, used or replaced. Start it again.';

  @override
  String get noWorkspacesYetHint =>
      'A workspace admin has to invite you, or the server owner can create a workspace for you.';

  @override
  String repoAccessReplaced(String repos, String forge) {
    return '$repos now points to a different repository on $forge. Relink it from the desktop or web app to keep using it.';
  }

  @override
  String repoAccessAskAdminRelink(String repos, String forge) {
    return '$repos now points to a different repository on $forge. A workspace admin has to relink it before it can be used again.';
  }

  @override
  String get runSandboxUnavailableTitle =>
      'Agents need a sandbox on this server';

  @override
  String get runSandboxUnavailable =>
      'This server has no sandbox, so only its owner can run agents here. The owner can install the sandbox or turn sandboxing off for everyone.';

  @override
  String get scriptToolCalls => 'Tool calls';

  @override
  String scriptCallCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count calls',
      one: '1 call',
    );
    return '$_temp0';
  }

  @override
  String scriptCallsRunning(int count) {
    return '$count running';
  }

  @override
  String scriptCallsOk(int count) {
    return '$count ok';
  }

  @override
  String scriptCallsFailed(int count) {
    return '$count failed';
  }

  @override
  String scriptCallsDenied(int count) {
    return '$count denied';
  }

  @override
  String scriptCallsCancelled(int count) {
    return '$count cancelled';
  }

  @override
  String scriptCallsQueued(int count) {
    return '$count queued';
  }

  @override
  String scriptCallsSkipped(int count) {
    return '$count skipped';
  }

  @override
  String get scriptStepQueued => 'Queued';

  @override
  String get scriptStepSkipped => 'Skipped';

  @override
  String get scriptGroupLoop => 'Loop';

  @override
  String get scriptGroupEach => 'For each';

  @override
  String get scriptGroupParallel => 'In parallel';

  @override
  String get scriptGroupFunction => 'Function';

  @override
  String scriptCallsHidden(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Show $count more calls',
      one: 'Show 1 more call',
    );
    return '$_temp0';
  }

  @override
  String get scriptCallsUnplaced => 'Calls not placed in the script';

  @override
  String get scriptToolComputed => 'Tool';

  @override
  String scriptStepSemantics(String subject, String state) {
    return '$subject, $state';
  }

  @override
  String get scriptSourceLabel => 'Script';

  @override
  String scriptSourceLines(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count lines',
      one: '1 line',
    );
    return '$_temp0';
  }

  @override
  String get scriptStateRunning => 'Running';

  @override
  String get scriptStateCompleted => 'Completed';

  @override
  String get scriptStateFailed => 'Failed';

  @override
  String get scriptStateTimedOut => 'Timed out';

  @override
  String get scriptStateCancelled => 'Cancelled';

  @override
  String get scriptStateMemoryExceeded => 'Out of memory';

  @override
  String get scriptStateOutputExceeded => 'Too much output';

  @override
  String get scriptStateSandboxError => 'Sandbox error';

  @override
  String get scriptStateRefused => 'Refused';

  @override
  String get scriptOriginLine => 'From a script the agent is running';

  @override
  String get codeModeTitle => 'Code mode';

  @override
  String get codeModeAvailable => 'Available';

  @override
  String get codeModeUnavailable => 'Unavailable';

  @override
  String codeModeUnavailableNote(String reason) {
    return 'This server can\'t run scripts, so agents here call their tools one at a time. The server says: $reason';
  }

  @override
  String get codeModeNoReason => 'no reason was given.';

  @override
  String get workKindUnknown => 'For a reason this version doesn\'t name:';

  @override
  String get workRefusalUnknown => 'The server refused this:';

  @override
  String workActionFailed(String error) {
    return 'That did not work: $error';
  }

  @override
  String get wakeKindStopped => 'Held because a person stopped the run.';

  @override
  String get wakeKindAttempts => 'Delivery failed three times.';

  @override
  String get wakeKindAgentDeleted => 'The agent no longer exists.';

  @override
  String get wakeKindAgentNotDispatchable => 'The agent is retired.';

  @override
  String get wakeKindAgentPaused => 'The agent is paused.';

  @override
  String get wakeKindPersonRemoved =>
      'The person it acts for left the workspace.';

  @override
  String get wakeKindBudgetBlocked => 'A budget blocks a run.';

  @override
  String get wakeKindTakeOver => 'A person has taken over the worktree.';

  @override
  String get wakeKindRateCapConversation =>
      'This conversation started 30 runs from wakes in the last hour.';

  @override
  String get wakeKindRateCapWorkspace =>
      'This workspace started 300 runs from wakes in the last hour.';

  @override
  String get wakeKindLiveRunNoInput =>
      'The agent\'s live run here takes no input.';

  @override
  String get wakeKindLiveRunOtherOptions =>
      'The agent\'s live run here runs differently, so this starts its own run after it.';

  @override
  String get wakeKindLiveRunOtherPerson =>
      'The agent\'s live run here acts for someone else, so this starts its own run after it.';

  @override
  String get wakeKindDispatchRefused => 'The run could not start.';

  @override
  String get wakeKindSandboxUnavailable =>
      'No sandbox is available for a read-only run.';

  @override
  String get wakeKindReadOnlyUnavailable =>
      'This agent\'s backend cannot keep a run read-only.';

  @override
  String get wakeKindServerStopped => 'A server restart stopped the run.';

  @override
  String get wakeKindServerRestarted =>
      'The server restarted during a person\'s run.';

  @override
  String get wakeKindGuardFailed => 'A check before delivery failed.';

  @override
  String get wakeKindLimit =>
      'Waiting for the provider\'s usage limit to reset.';

  @override
  String get wakeKindLimitRunLive =>
      'Waiting for the run at the usage limit to end.';

  @override
  String get wakeKindWakeMissed => 'Missed while the server was down.';

  @override
  String get wakeKindPipelineRunEnded => 'Its pipeline run ended.';

  @override
  String get wakeKindGoalEnded => 'Its goal ended.';

  @override
  String get wakeKindGoalBudgetExhausted => 'Its goal used its budget.';

  @override
  String get wakeKindGoalReviewStale =>
      'The goal changed since this review was asked for.';

  @override
  String get wakeKindGoalPaused => 'Its goal is paused.';

  @override
  String get wakeKindGoalHeld => 'Its goal is on hold.';

  @override
  String get wakeKindGoalStopped => 'Its goal was stopped.';

  @override
  String get wakeKindAskSettled =>
      'The question it answers was already settled.';

  @override
  String get wakeKindRuleEnded => 'Its schedule ended.';

  @override
  String get wakeRefusalNotYours =>
      'This wake acts for another person. Only they can deliver or resume it.';

  @override
  String get wakeRefusalSettled => 'This wake has already settled.';

  @override
  String get goalRefusalAlreadyActive =>
      'This agent already has an active goal.';

  @override
  String get goalRefusalNotInReview => 'This goal is not waiting for review.';

  @override
  String get goalRefusalEvidenceIncomplete =>
      'The goal\'s evidence is incomplete.';

  @override
  String get goalRefusalClaimPending =>
      'A claim that it is done is still being checked.';

  @override
  String get goalRefusalNotActiveSegment => 'This goal has no segment running.';

  @override
  String get goalRefusalNotYours =>
      'Only the person who started this goal can do that.';

  @override
  String get goalRefusalNotPaused => 'Pause the goal first.';

  @override
  String get goalRefusalContractInvalid =>
      'The goal\'s contract can\'t be read.';

  @override
  String get goalRefusalCheckerUnknown => 'No agent has that name.';

  @override
  String get goalRefusalCheckerAmbiguous =>
      'More than one agent has that name.';

  @override
  String get goalRefusalCheckerIsGoalAgent =>
      'The checker must be another agent than the one doing the work.';

  @override
  String get goalRefusalCommandInvalid => 'This goal can\'t be read:';

  @override
  String get wakeRuleRefusalIntervalTooShort =>
      'The interval is too short. Pick at least one minute.';

  @override
  String get wakeRuleRefusalTooSoon =>
      'That time is too soon. Pick a later one.';

  @override
  String get wakeRuleRefusalLineageEnded =>
      'This chain of wakes has used its runs or its time.';

  @override
  String get wakeRuleRefusalWatchTargetUnreadable =>
      'You can\'t read what this would watch.';

  @override
  String get wakeRuleRefusalExpiryRequired =>
      'Give it an end date or a number of runs.';

  @override
  String get wakeRuleRefusalLimitReached =>
      'This conversation or agent already has as many schedules as it may.';

  @override
  String get wakeRuleRefusalInvalidWhen => 'The time can\'t be read.';

  @override
  String get wakeRuleRefusalNoteTooLong => 'The note is too long.';

  @override
  String get wakeRuleRefusalExpiryTooLong => 'The end is too far away.';

  @override
  String get wakeRuleRefusalLimitOutOfRange =>
      'A run, day or budget limit is out of range.';

  @override
  String get wakeRuleRefusalNextOutsideLoop =>
      'Only a loop can pick its own next time.';

  @override
  String get wakeRuleRefusalWatchRefused => 'That can\'t be watched.';

  @override
  String get wakeRuleRefusalRuleEnded => 'That schedule has already ended.';

  @override
  String get wakeRuleRefusalNotYours =>
      'That schedule belongs to someone else.';

  @override
  String get wakeRuleEndFired => 'It ran its one time.';

  @override
  String get wakeRuleEndExpired => 'It reached its end date.';

  @override
  String get wakeRuleEndRunCap => 'It used its runs.';

  @override
  String get wakeRuleEndCostCap => 'It reached its cost cap.';

  @override
  String get wakeRuleEndGoalEnded => 'Its goal ended.';

  @override
  String get wakeRuleEndCancelled => 'It was cancelled.';

  @override
  String get wakeRuleEndMemberRemoved => 'Its person left the workspace.';

  @override
  String get wakeRuleEndInvalidRow => 'Its stored settings could not be read.';

  @override
  String goalHoldWorking(int segment) {
    final intl.NumberFormat segmentNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String segmentString = segmentNumberFormat.format(segment);

    return 'Working on segment $segmentString. Nobody needs to act.';
  }

  @override
  String get goalHoldWaiting =>
      'Waiting for work it is owed. It continues by itself.';

  @override
  String goalHoldWaitingUntil(String time) {
    return 'Waiting for work it is owed. It continues by itself at $time at the latest.';
  }

  @override
  String get goalHoldVerifying =>
      'It says it is done. The server runs its checks, then a reviewer decides.';

  @override
  String get goalHoldLimit =>
      'Paused at the provider\'s usage limit. It resumes by itself after the reset.';

  @override
  String goalHoldLimitUntil(String time) {
    return 'Paused at the provider\'s usage limit. It resumes by itself at $time.';
  }

  @override
  String get goalHoldPerson =>
      'Waiting for a person to answer in the conversation. It continues once someone answers.';

  @override
  String get goalHoldByPerson =>
      'Paused by a person. It stays paused until someone resumes it.';

  @override
  String get goalHoldNeedsReview =>
      'Waiting for review: it cannot go on by itself. Approve it as done, resume it or cancel it.';

  @override
  String get goalHoldBudget =>
      'It used its budget. Raise the budget to let it continue.';

  @override
  String goalHoldLimitParks(int count, int max) {
    final intl.NumberFormat countNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String countString = countNumberFormat.format(count);
    final intl.NumberFormat maxNumberFormat = intl.NumberFormat.decimalPattern(
      localeName,
    );
    final String maxString = maxNumberFormat.format(max);

    return 'Usage limit pauses: $countString of $maxString';
  }

  @override
  String get goalHoldDetailStalled => 'No progress in its last segments.';

  @override
  String get goalHoldDetailStalledWaiting =>
      'It waited 24 hours on the same work without progress.';

  @override
  String get goalHoldDetailVerificationFailed => 'The last check failed.';

  @override
  String get goalHoldDetailCannotVerify =>
      'The checker couldn\'t tell whether it is done.';

  @override
  String get goalHoldDetailSandboxUnavailable =>
      'No sandbox is available to run its checks.';

  @override
  String get goalHoldDetailCheckerUnavailable =>
      'Its checker agent is unavailable. Pick another checker, then resume.';

  @override
  String get goalHoldDetailCheckBroken => 'This check can\'t run:';

  @override
  String get goalHoldDetailWakeSkipped => 'Its wake was not delivered.';

  @override
  String get goalHoldDetailClaimPending =>
      'Its claim that it is done waits for a check.';

  @override
  String get goalHoldDetailUnanswered =>
      'A question or approval request to a person went unanswered.';

  @override
  String get goalHoldDetailLimitParks =>
      'It hit usage limits too often. Look it over, then resume.';

  @override
  String get goalHoldDetailInput =>
      'Waiting for an answer in the conversation.';

  @override
  String goalSegments(int run, int max) {
    final intl.NumberFormat runNumberFormat = intl.NumberFormat.decimalPattern(
      localeName,
    );
    final String runString = runNumberFormat.format(run);
    final intl.NumberFormat maxNumberFormat = intl.NumberFormat.decimalPattern(
      localeName,
    );
    final String maxString = maxNumberFormat.format(max);

    return 'Segment $runString of $maxString';
  }

  @override
  String goalSegmentsNoCap(int run) {
    final intl.NumberFormat runNumberFormat = intl.NumberFormat.decimalPattern(
      localeName,
    );
    final String runString = runNumberFormat.format(run);

    return 'Segment $runString, no cap';
  }

  @override
  String goalMoney(String spent, String cap) {
    return 'Spent $spent of $cap';
  }

  @override
  String goalDeadline(String time) {
    return 'Deadline $time';
  }

  @override
  String get goalPipelineStep => 'A pipeline step pursues this goal.';

  @override
  String get goalSummaryHeading => 'Last summary';

  @override
  String get goalDoneMeans => 'Done means';

  @override
  String get goalChecks => 'Checks';

  @override
  String get goalBoundaries => 'Boundaries';

  @override
  String get goalStopWhen => 'Stop and ask when';

  @override
  String get goalNoMachineCheck =>
      'No machine check. A reviewer judges from what it can read.';

  @override
  String get goalCheckEnvironment => 'Environment task';

  @override
  String goalLastCheck(int round, String time) {
    final intl.NumberFormat roundNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String roundString = roundNumberFormat.format(round);

    return 'Last check, round $roundString, $time';
  }

  @override
  String get goalClaim => 'What it claimed';

  @override
  String get goalCheckPassed => 'Passed';

  @override
  String goalCheckFailed(int code) {
    return 'Failed, exit $code';
  }

  @override
  String get goalCheckTimedOut => 'Timed out';

  @override
  String get goalCheckNotRerun => 'Not rerun: nothing changed';

  @override
  String get goalCheckBroken => 'Cannot run';

  @override
  String get goalCriterionMet => 'Met';

  @override
  String get goalCriterionUnmet => 'Not met';

  @override
  String get goalCriterionCannotTell => 'Can\'t tell';

  @override
  String get goalVerdictPass => 'Verdict: done';

  @override
  String get goalVerdictFail => 'Verdict: not done';

  @override
  String get goalVerdictCannotVerify => 'Verdict: couldn\'t tell';

  @override
  String get goalConcerns => 'Concerns';

  @override
  String goalVerifiedBy(String agent) {
    return 'Verified by $agent';
  }

  @override
  String get goalVerifiedBySelf => 'Verified by itself (no separate checker)';

  @override
  String get goalClosedByPerson => 'Closed by a person without a passing check';

  @override
  String get goalApprove => 'Approve completion';

  @override
  String get goalApproveTitle => 'Close this goal as done?';

  @override
  String get goalApproveBody =>
      'No check confirmed it. You close it on your own word, and the goal records that a person closed it unverified.';

  @override
  String get goalApproveConfirm => 'Close as done';

  @override
  String get goalResumeNotYours =>
      'Resuming it or raising its budget belongs to whoever started it.';

  @override
  String get goalChooseChecker => 'Pick another checker';

  @override
  String goalCheckerSet(String agent) {
    return '$agent checks it now. Resume to verify again.';
  }

  @override
  String get goalSchedules => 'Schedules';

  @override
  String get goalRepeat => 'Repeat';

  @override
  String get goalCreateChecks => 'Checks (optional)';

  @override
  String get goalCreateCheckHint =>
      'A command that passes when the work is done';

  @override
  String get goalCreateAddCheck => 'Add check';

  @override
  String get goalCreateRemoveCheck => 'Remove check';

  @override
  String get goalCreateSegmentCap => 'Segment cap (optional)';

  @override
  String get goalCreateSegmentInvalid =>
      'The segment cap is a whole number, at least 1.';

  @override
  String get scheduleCreateTitle => 'Repeat a prompt';

  @override
  String get scheduleCadence => 'How often';

  @override
  String get scheduleEveryMinutes => 'Every N minutes';

  @override
  String get scheduleEveryHours => 'Every N hours';

  @override
  String get scheduleSelfPaced => 'Self-paced';

  @override
  String get scheduleSelfPacedHint =>
      'The agent picks the delay after each run, between 1 minute and 1 hour.';

  @override
  String get scheduleInterval => 'Interval';

  @override
  String get scheduleNote => 'What should each run do?';

  @override
  String get scheduleCostCap => 'Cost cap in USD (optional)';

  @override
  String get scheduleExpiryDays => 'Ends after N days (optional)';

  @override
  String get scheduleCreateInvalid =>
      'Choose a space and an agent, write what each run should do, and give whole numbers of at least 1.';

  @override
  String get scheduleCreateButton => 'Start schedule';

  @override
  String get scheduleCreateConfirmTitle => 'Start this schedule?';

  @override
  String scheduleCreateConfirmEveryMinutes(int count) {
    final intl.NumberFormat countNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String countString = countNumberFormat.format(count);

    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'It runs every $countString minutes, starting now.',
      one: 'It runs every minute, starting now.',
    );
    return '$_temp0';
  }

  @override
  String scheduleCreateConfirmEveryHours(int count) {
    final intl.NumberFormat countNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String countString = countNumberFormat.format(count);

    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'It runs every $countString hours, starting now.',
      one: 'It runs every hour, starting now.',
    );
    return '$_temp0';
  }

  @override
  String get scheduleCreateConfirmSelfPaced =>
      'It runs now, then the agent picks when to run again.';

  @override
  String get scheduleCreated =>
      'Schedule started. It is listed under Schedules.';

  @override
  String get schedulesTitle => 'Schedules';

  @override
  String get schedulesLoadFailed => 'Could not load schedules';

  @override
  String get schedulesEmpty => 'No schedules or watches';

  @override
  String get schedulesEmptyDescription =>
      'Repeat a prompt from the goals screen, or send /loop or /schedule in a conversation.';

  @override
  String get scheduleMissing =>
      'This schedule is no longer available in this workspace.';

  @override
  String scheduleEvery(String interval) {
    return 'Every $interval';
  }

  @override
  String get scheduleSelfPacedLoop => 'Self-paced loop';

  @override
  String get scheduleCron => 'Cron schedule';

  @override
  String scheduleOnce(String time) {
    return 'Once at $time';
  }

  @override
  String scheduleWatch(String event) {
    return 'Watch: $event';
  }

  @override
  String get scheduleWatchPrChecks => 'pull request checks';

  @override
  String get scheduleWatchPrReview => 'pull request reviews';

  @override
  String get scheduleWatchPrMerged => 'pull request merge';

  @override
  String get scheduleWatchEnvironment => 'environment';

  @override
  String get scheduleWatchTicket => 'ticket';

  @override
  String get scheduleWatchPipelineRun => 'pipeline run';

  @override
  String get scheduleStatusActive => 'Active';

  @override
  String get scheduleStatusPaused => 'Paused';

  @override
  String get scheduleStatusEnded => 'Ended';

  @override
  String scheduleWakes(String agent) {
    return 'Wakes $agent';
  }

  @override
  String scheduleNext(String time) {
    return 'Next run $time';
  }

  @override
  String scheduleLast(String time) {
    return 'Last run $time';
  }

  @override
  String scheduleRuns(int count) {
    final intl.NumberFormat countNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String countString = countNumberFormat.format(count);

    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$countString runs',
      one: '1 run',
    );
    return '$_temp0';
  }

  @override
  String scheduleRunsOf(int count, int max) {
    final intl.NumberFormat countNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String countString = countNumberFormat.format(count);
    final intl.NumberFormat maxNumberFormat = intl.NumberFormat.decimalPattern(
      localeName,
    );
    final String maxString = maxNumberFormat.format(max);

    return '$countString of $maxString runs';
  }

  @override
  String scheduleSkipped(int count) {
    final intl.NumberFormat countNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String countString = countNumberFormat.format(count);

    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$countString skipped',
      one: '1 skipped',
    );
    return '$_temp0';
  }

  @override
  String scheduleEnds(String time) {
    return 'Ends $time';
  }

  @override
  String scheduleChain(int count, String time) {
    final intl.NumberFormat countNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String countString = countNumberFormat.format(count);

    return 'Part of a chain: $countString runs left, ends $time';
  }

  @override
  String get scheduleNoteAgent => 'The agent\'s own note, in its words:';

  @override
  String get scheduleNotePerson => 'A person\'s note:';

  @override
  String scheduleActsFor(String name) {
    return 'Acts for $name';
  }

  @override
  String get scheduleActsForBot => 'Acts for no person';

  @override
  String get scheduleGoalBound => 'It ends with its goal.';

  @override
  String get schedulePause => 'Pause';

  @override
  String get scheduleResume => 'Resume';

  @override
  String get scheduleDelete => 'Delete';

  @override
  String get scheduleRemove => 'Remove';

  @override
  String get scheduleDeleteTitle => 'Delete this schedule?';

  @override
  String get scheduleDeleteBody =>
      'It stops for good. Nothing it already did is undone.';

  @override
  String get scheduleRemoveTitle => 'Remove this schedule?';

  @override
  String get scheduleRemoveBody => 'It disappears from the list.';

  @override
  String get scheduleResumeNotYours =>
      'Only the person this schedule acts for can resume it.';

  @override
  String get scheduleResumeAdminOnly =>
      'Only a workspace admin can resume a schedule no person owns.';

  @override
  String get scheduleOpenConversation => 'Open conversation';

  @override
  String get progressWaiting => 'Waiting';

  @override
  String get progressNothingWaiting => 'Nothing is waiting.';

  @override
  String get wakeOriginGoal => 'Goal';

  @override
  String get wakeOriginGoalCheck => 'Goal check';

  @override
  String get wakeOriginGoalReview => 'Goal review';

  @override
  String get wakeOriginSchedule => 'Schedule';

  @override
  String get wakeOriginWatch => 'Watch';

  @override
  String get wakeOriginReply => 'Reply';

  @override
  String get wakeOriginMessage => 'Message';

  @override
  String get wakeOriginWorkFinished => 'Finished work';

  @override
  String get wakeOriginLimitReset => 'Limit reset';

  @override
  String get wakeOriginRecovery => 'Recovery';

  @override
  String get wakeOriginAssignment => 'Assignment';

  @override
  String get wakeOriginPipelineStep => 'Pipeline step';

  @override
  String get wakeOriginImprovementReview => 'Improvement review';

  @override
  String wakeOriginReplyFrom(String agent) {
    return 'Reply from $agent';
  }

  @override
  String wakeOriginMessageFrom(String agent) {
    return 'Message from $agent';
  }

  @override
  String wakeOriginWorkFinishedBy(String agent) {
    return 'Finished work from $agent';
  }

  @override
  String wakeFor(String agent) {
    return 'For $agent';
  }

  @override
  String wakeDue(String time) {
    return 'Due $time';
  }

  @override
  String get wakeDueNow => 'Due now';

  @override
  String get wakeHeld => 'Held';

  @override
  String wakeExpires(String time) {
    return 'Expires $time';
  }

  @override
  String wakeAttempt(int attempt) {
    final intl.NumberFormat attemptNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String attemptString = attemptNumberFormat.format(attempt);

    return 'Attempt $attemptString';
  }

  @override
  String get wakeCancel => 'Cancel';

  @override
  String get wakeDeliverNow => 'Deliver now';

  @override
  String get wakeResume => 'Resume';

  @override
  String get wakeDismiss => 'Dismiss';

  @override
  String get wakeResumeOnlyTheirs =>
      'Only the person whose run this is can resume it.';

  @override
  String get wakeRecovery =>
      'The server restarted during this run. Resume to continue it, or dismiss.';

  @override
  String limitParkTitle(String provider, String time) {
    return 'Paused at $provider\'s usage limit, which resets at $time. The run waits for Resume, for up to 7 days after the reset.';
  }

  @override
  String limitParkTitleUnnamed(String time) {
    return 'Paused at the provider\'s usage limit, which resets at $time. The run waits for Resume, for up to 7 days after the reset.';
  }

  @override
  String get limitParkResumeNow => 'Resume now';

  @override
  String get limitParkCancel => 'Cancel';

  @override
  String limitParkResumed(String provider) {
    return 'Resumed after $provider\'s usage limit.';
  }

  @override
  String limitParkGone(String provider) {
    return 'No longer waiting at $provider\'s usage limit.';
  }

  @override
  String get limitParkProviderUnknown => 'the provider';

  @override
  String get mobileHeldMessages => 'Held messages';

  @override
  String get heldSteeringTitle =>
      'Held because the run ended before it could take them. Send yours now or remove them.';

  @override
  String get heldSteeringRelease => 'Send held messages';

  @override
  String get notifGoalCompleted => 'Goal done';

  @override
  String get notifGoalFailed => 'Goal failed';

  @override
  String get notifGoalCancelled => 'Goal cancelled';

  @override
  String get notifGoalBudgetExhausted => 'Goal used its budget';

  @override
  String get notifGoalNeedsReview => 'A goal waits for your review';

  @override
  String get notifGoalNeedsPerson => 'A goal needs you';

  @override
  String get notifGoalOnHold => 'A goal is on hold';

  @override
  String get notifWakeRuleEnded => 'A schedule ended';

  @override
  String notifWaitingDigest(int count) {
    final intl.NumberFormat countNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String countString = countNumberFormat.format(count);

    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$countString things wait for you',
      one: '1 thing waits for you',
    );
    return '$_temp0';
  }

  @override
  String notifImprovementProposed(int count) {
    final intl.NumberFormat countNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String countString = countNumberFormat.format(count);

    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$countString improvements were proposed',
      one: 'An improvement was proposed',
    );
    return '$_temp0';
  }

  @override
  String get notifPipelineRunHeld => 'A pipeline run is held at its budget';

  @override
  String notifPipelineRunHeldBody(String spent, String cap) {
    return 'Spent $spent of $cap';
  }

  @override
  String get notifNeedsYou => 'Needs you';

  @override
  String get notifDigestGoalReview => 'Goal waits for review';

  @override
  String get notifDigestGoalPerson => 'Goal needs a person';

  @override
  String get notifDigestHeldWake => 'Held wake';

  @override
  String get notifDigestImprovement => 'Proposed improvement';

  @override
  String get wakeKindRulePaused => 'Its schedule was paused.';

  @override
  String get wakeKindRuleBusy =>
      'The agent was busy, and this schedule skips a time when it is.';

  @override
  String get wakeKindRuleFolded =>
      'A later event of the same watch took its place.';

  @override
  String get wakeKindRuleSuperseded =>
      'A later time of its schedule replaced it.';

  @override
  String get wakeKindRuleNotified =>
      'Its schedule only sends a notification, so no run started.';

  @override
  String get wakeKindRuleLimitParked =>
      'Its schedule waits for the provider\'s usage limit to reset.';

  @override
  String get improvementRefusalCooldown =>
      'An improvement review ran in this conversation a short while ago. Try again later.';

  @override
  String get improvementRefusalQueued =>
      'An improvement review of this conversation is already waiting to run.';

  @override
  String get improvementRefusalAgentNotFound =>
      'That agent is not an agent of this workspace.';

  @override
  String get steeringRefusalHeldByLimit =>
      'Messages held at a usage limit can\'t be sent by hand. They wait for the paused run to resume.';

  @override
  String limitParkCancelled(String provider) {
    return 'The wait at $provider\'s usage limit was cancelled.';
  }

  @override
  String limitParkExpired(String provider) {
    return 'The wait at $provider\'s usage limit expired before the run resumed.';
  }

  @override
  String limitParkSkipped(String provider) {
    return 'The run did not resume after $provider\'s usage limit.';
  }

  @override
  String get heldSteeringLimitTitle =>
      'Held while the run waits for the usage limit to reset. They are sent when the person it runs for resumes it.';

  @override
  String heldSteeringLimitAt(String time) {
    return 'Held until the usage limit resets at $time. They are sent when the person it runs for resumes it.';
  }

  @override
  String get heldSteeringOtherTitle =>
      'Held by the server. You can remove them.';

  @override
  String workRowWoke(int count, String agent) {
    final intl.NumberFormat countNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String countString = countNumberFormat.format(count);

    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Woke $agent for $countString waiting items',
      one: 'Woke $agent',
    );
    return '$_temp0';
  }

  @override
  String workRowWakeMissed(String agent) {
    return 'A wake for $agent was missed while the server was down.';
  }

  @override
  String workRowWakeSkipped(String agent) {
    return 'A wake for $agent was not delivered.';
  }

  @override
  String workRowScheduleCreated(String agent) {
    return 'Schedule set for $agent.';
  }

  @override
  String workRowScheduleEnded(String agent) {
    return '$agent\'s schedule ended.';
  }

  @override
  String workRowNoteFromAgent(String agent) {
    return 'Schedule note from $agent:';
  }

  @override
  String get workRowNoteFromPerson => 'Schedule note from a person:';

  @override
  String workRowCommandRefusedNamed(String command) {
    return 'The $command command was refused.';
  }

  @override
  String get workRowCommandRefused => 'A command was refused.';

  @override
  String workRowCapRaised(String person, String from, String to) {
    return '$person raised the pipeline\'s spending cap from $from to $to.';
  }

  @override
  String workRowCapRaisedNoAmounts(String person) {
    return '$person raised the pipeline\'s spending cap.';
  }

  @override
  String get workRowApplyIncomplete =>
      'An accepted change to this skill could not be finished, because the skill changed in the meantime. The proposal was rolled back.';

  @override
  String get workRowOpenSchedule => 'Open schedule';

  @override
  String get heldSteeringOthersTitle =>
      'Held because the run ended before it could take them. Only the person who wrote a message can send it.';

  @override
  String get heldSteeringOnlyYours =>
      'Sends only your messages. The others wait for the people who wrote them.';

  @override
  String heldSteeringWrittenBy(String name) {
    return 'Written by $name';
  }

  @override
  String get steeringRefusalNotYours =>
      'Only the person who wrote a held message can send it, and none of these are yours.';

  @override
  String get steeringRefusalNeedsWrite =>
      'You need write access to this space\'s repositories to steer a run that acts for someone else.';

  @override
  String workRowSchedulePaused(String name, String agent) {
    return '$name paused the schedule for $agent.';
  }

  @override
  String get goalVerdictObjective => 'The objective as a whole';

  @override
  String get notifDigestRequest => 'Waits for your answer';
}

/// The translations for English, as used in the United Kingdom (`en_GB`).
class AppLocalizationsEnGb extends AppLocalizationsEn {
  AppLocalizationsEnGb() : super('en_GB');

  @override
  String get organizer => 'organiser';
}
