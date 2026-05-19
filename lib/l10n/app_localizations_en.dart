// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get navCalendar => 'Calendar';

  @override
  String get calendarViewMonth => 'Month';

  @override
  String get calendarViewWeek => 'Week';

  @override
  String get calendarViewAgenda => 'Agenda';

  @override
  String get calendarConnectGoogle => 'Connect Google Calendar';

  @override
  String get calendarConnectDescription =>
      'Sync your Google Calendar to see events here and get alerts before meetings start.';

  @override
  String get calendarDisconnect => 'Disconnect';

  @override
  String get calendarReconnect => 'Reconnect';

  @override
  String get calendarEmptyNoEvents => 'No events in this range';

  @override
  String get calendarStartRecording => 'Start recording';

  @override
  String get calendarStartRecordingAndLink => 'Start recording & link';

  @override
  String get calendarJoinMeet => 'Join meeting';

  @override
  String get calendarFromCalendar => 'From calendar';

  @override
  String get calendarLinkedMeeting => 'Linked meeting';

  @override
  String get calendarToday => 'Today';

  @override
  String get calendarAllDay => 'All day';

  @override
  String calendarWeekNumber(int number) {
    return 'Week $number';
  }

  @override
  String get calendarPreviousPeriod => 'Previous';

  @override
  String get calendarNextPeriod => 'Next';

  @override
  String calendarLastSynced(String time) {
    return 'Synced $time';
  }

  @override
  String get calendarNeverSynced => 'Not synced yet';

  @override
  String get calendarSyncing => 'Syncing…';

  @override
  String get calendarViewDay => 'Day';

  @override
  String get calendarSectionCalendars => 'Calendars';

  @override
  String get calendarShow => 'Show';

  @override
  String get calendarHide => 'Hide';

  @override
  String get calendarRsvpGoing => 'Going?';

  @override
  String get calendarRsvpYes => 'Yes';

  @override
  String get calendarRsvpNo => 'No';

  @override
  String get calendarRsvpMaybe => 'Maybe';

  @override
  String get calendarRsvpFailed => 'Couldn\'t update your response';

  @override
  String get calendarAddAccount => 'Add calendar account';

  @override
  String get calendarSettingsTitle => 'Google Calendar';

  @override
  String get calendarSettingsDescription =>
      'Connect a Google account to sync events into this workspace.';

  @override
  String get calendarNotConnected => 'No Google account connected';

  @override
  String get calendarConnecting => 'Connecting…';

  @override
  String get calendarSyncNow => 'Sync now';

  @override
  String get calendarNoWorkspace => 'Select a workspace to view its calendar';

  @override
  String get calendarConnectError => 'Couldn\'t connect Google Calendar';

  @override
  String get notificationMeetingStartsSoon => 'Meeting starting soon';

  @override
  String get notifyMeetingStartsSoon =>
      'When a calendar meeting is about to start';

  @override
  String get notificationCalendarAuthExpiredTitle => 'Calendar disconnected';

  @override
  String notificationCalendarAuthExpiredBody(String email) {
    return 'Reconnect $email to resume syncing';
  }

  @override
  String get notificationCalendarAuthExpiredBodyNoEmail =>
      'Reconnect your calendar to resume syncing';

  @override
  String get notifyCalendarAuthExpired =>
      'When a calendar account needs to be reconnected';

  @override
  String get calendarAlertLeadTime => 'Alert lead time';

  @override
  String get calendarAlertLeadTimeSubtitle =>
      'How long before a meeting to alert you';

  @override
  String calendarConnectedAs(String email) {
    return 'Connected as $email';
  }

  @override
  String calendarAttendeesCount(int count) {
    return '$count attendees';
  }

  @override
  String get calendarEventLabel => 'Event';

  @override
  String get calendarRecurring => 'Recurring event';

  @override
  String get calendarGoogleMeet => 'Google Meet';

  @override
  String get calendarOrganizer => 'Organizer';

  @override
  String get calendarYou => 'You';

  @override
  String get calendarShowFewer => 'Show fewer';

  @override
  String get calendarRsvpAwaiting => 'Awaiting';

  @override
  String calendarParticipantsCount(int count) {
    return '$count participants';
  }

  @override
  String calendarSeeAllParticipants(int count) {
    return 'See all $count participants';
  }

  @override
  String calendarRsvpCountYes(int count) {
    return '$count yes';
  }

  @override
  String calendarRsvpCountNo(int count) {
    return '$count no';
  }

  @override
  String calendarRsvpCountMaybe(int count) {
    return '$count maybe';
  }

  @override
  String calendarRsvpCountAwaiting(int count) {
    return '$count awaiting';
  }

  @override
  String calendarLeadMinutesOption(int count) {
    return '$count minutes';
  }

  @override
  String get openInEditorPrompt => 'Open in which editor?';

  @override
  String get ideNotInstalled => 'Not installed';

  @override
  String openInIde(String editor) {
    return 'Open in $editor';
  }

  @override
  String failedToOpenInIde(String editor, String error) {
    return 'Couldn\'t open $editor: $error';
  }

  @override
  String get profileSearchHint => 'Search pull requests…';

  @override
  String get profileClickToLoad => 'Click to load';

  @override
  String get profileStateOpenHint => 'Currently open';

  @override
  String get profileStateMergedHint => 'Merged history';

  @override
  String get profileStateClosedHint => 'Closed, not merged';

  @override
  String get profileNoPrsForFilter =>
      'No pull requests for the selected states';

  @override
  String get byAuthorPrefix => 'by';

  @override
  String get youLabel => 'you';

  @override
  String get readyToMerge => 'Ready to merge';

  @override
  String get laneReadyHint => 'Checks green';

  @override
  String get laneReviewHint => 'Waiting on you';

  @override
  String get inProgress => 'In progress';

  @override
  String get laneInProgressHint => 'Open · being worked';

  @override
  String get needsAttention => 'Needs attention';

  @override
  String get laneAttentionHint => 'Failing or stale';

  @override
  String get drafts => 'Drafts';

  @override
  String get laneDraftsHint => 'Not opened yet';

  @override
  String get allOpenPrs => 'All open PRs';

  @override
  String showAllCount(int count) {
    return 'Show all $count';
  }

  @override
  String get sortOldest => 'Oldest';

  @override
  String get sortLargest => 'Largest';

  @override
  String get selectAction => 'Select';

  @override
  String mergeCountReady(int count) {
    return 'Merge $count ready';
  }

  @override
  String countSelected(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count selected',
      one: '1 selected',
    );
    return '$_temp0';
  }

  @override
  String get mergeReadyAction => 'Merge ready';

  @override
  String get nothingInLane => 'Nothing in this lane';

  @override
  String get nothingInLaneHint =>
      'Pick another lane above, or show all open PRs.';

  @override
  String get summary => 'Summary';

  @override
  String get openFullDiff => 'Open full diff';

  @override
  String get viewFiles => 'View files';

  @override
  String get checksLabel => 'Checks';

  @override
  String get commentsLabel => 'Comments';

  @override
  String get mergeReadyConfirmTitle => 'Merge ready pull requests?';

  @override
  String mergeReadyConfirmBody(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Squash-merge $count ready pull requests? This can\'t be undone.',
      one: 'Squash-merge 1 ready pull request? This can\'t be undone.',
    );
    return '$_temp0';
  }

  @override
  String mergedCountPrs(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Merged $count pull requests',
      one: 'Merged 1 pull request',
    );
    return '$_temp0';
  }

  @override
  String get keybindingSelectPr => 'Select PR';

  @override
  String get keybindingMergePr => 'Merge PR';

  @override
  String get keybindingPeekPr => 'Peek PR';

  @override
  String get keybindingToggleSelectionOfTheFocusedPullRequestDescription =>
      'Toggle selection of the focused pull request';

  @override
  String get keybindingMergeTheFocusedPullRequestDescription =>
      'Merge the focused pull request if it\'s ready';

  @override
  String get keybindingExpandOrCollapseTheFocusedPullRequestPeekDescription =>
      'Expand or collapse the focused pull request\'s peek panel';

  @override
  String get kbMove => 'move';

  @override
  String get kbSelect => 'select';

  @override
  String get kbMerge => 'merge';

  @override
  String get kbOpen => 'open';

  @override
  String get kbPeek => 'peek';

  @override
  String get kbTabs => 'tabs';

  @override
  String get kbSearch => 'search';

  @override
  String get kbViewed => 'viewed';

  @override
  String get kbCollapse => 'collapse';

  @override
  String get appearance => 'Appearance';

  @override
  String get appearanceSettingsDescription =>
      'Theme, language, and typography.';

  @override
  String get notificationsSettingsDescription =>
      'Choose which agent and workspace events notify you.';

  @override
  String get integrationsSettingsDescription =>
      'Connect GitHub, ticketing, and the MCP server.';

  @override
  String get advanced => 'Advanced';

  @override
  String get advancedSettingsDescription =>
      'Branch naming, voice, semantic search, privacy, and logging.';

  @override
  String get agentRegistry => 'Agent registry';

  @override
  String get settingsGroupGeneral => 'General';

  @override
  String get settingsGroupAgents => 'Agents';

  @override
  String get settingsGroupResources => 'Resources';

  @override
  String get filterSettingsHint => 'Filter settings';

  @override
  String get needsSetupLabel => 'Needs setup';

  @override
  String noSettingsMatch(String query) {
    return 'No settings match \"$query\"';
  }

  @override
  String get privacy => 'Privacy';

  @override
  String get sendDiffContentTitle => 'Send diff content to AI adapter';

  @override
  String get diffSharingOnSubtitle =>
      'Raw diff lines are included in agent prompts for deeper review.';

  @override
  String get diffSharingOffSubtitle =>
      'Agents use only structured metadata (file paths, line numbers, PR description); no raw code leaves the app.';

  @override
  String get errorReportingTitle => 'Share crash reports';

  @override
  String get errorReportingOnSubtitle =>
      'Crash, error, and performance diagnostics are sent to help fix bugs (release builds only).';

  @override
  String get errorReportingOffSubtitle =>
      'Diagnostics are off. No crash or error reports are sent.';

  @override
  String get onboardingDiagnosticsTitle => 'Help improve Control Center';

  @override
  String get onboardingDiagnosticsSubtitle =>
      'Send crash, error, and performance diagnostics so we can fix problems faster (release builds only). You can change this any time in Settings → Privacy.';

  @override
  String get blocked => 'Blocked';

  @override
  String get idle => 'Idle';

  @override
  String get noRunsYet => 'No runs yet';

  @override
  String runsInLastSixMonths(String count) {
    return '$count runs in the last 6 months';
  }

  @override
  String lastActiveAgo(String duration) {
    return 'Active $duration ago';
  }

  @override
  String get reportsToNobody => 'No manager';

  @override
  String get copyPath => 'Copy path';

  @override
  String get pathCopied => 'Path copied to clipboard';

  @override
  String get editAgent => 'Edit agent';

  @override
  String get nameRequired => 'Name is required';

  @override
  String get titleRequired => 'Title is required';

  @override
  String get import => 'Import';

  @override
  String discoverAgentsFound(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count agent definitions found',
      one: '1 agent definition found',
    );
    return '$_temp0';
  }

  @override
  String get noAgentsToDiscover => 'No new agents to import';

  @override
  String get noAgentsToDiscoverHint =>
      'Agent definitions in this workspace are already imported.';

  @override
  String get sortByStatus => 'Status';

  @override
  String get sortByName => 'Name';

  @override
  String get noMatchingAgents => 'No agents match your filter';

  @override
  String get selectAnAgentHint =>
      'Choose an agent to see its status, activity, and details.';

  @override
  String watchVideoOn(String provider) {
    return 'Watch video on $provider';
  }

  @override
  String get branchTemplate => 'Branch name template';

  @override
  String get branchTemplateDescription =>
      'Pattern for the branch created when a ticket is started in an isolated worktree.';

  @override
  String branchTemplatePreview(String example) {
    return 'Example: $example';
  }

  @override
  String get deletePipelineRun => 'Delete pipeline run';

  @override
  String deletePipelineRunConfirm(String template) {
    return 'Delete this run of \"$template\"? This cannot be undone.';
  }

  @override
  String errorDeletingPipelineRun(String error) {
    return 'Error deleting pipeline run: $error';
  }

  @override
  String get deleteTicket => 'Delete ticket';

  @override
  String deleteTicketConfirm(String title) {
    return 'Delete \"$title\"? This cannot be undone.';
  }

  @override
  String errorDeletingTicket(String error) {
    return 'Error deleting ticket: $error';
  }

  @override
  String deleteWorkspaceConfirm(String name) {
    return 'Delete \"$name\"? Linked repositories on disk are not touched.';
  }

  @override
  String errorDeletingWorkspace(String error) {
    return 'Error deleting workspace: $error';
  }

  @override
  String get indexCode => 'Index code';

  @override
  String get indexing => 'Indexing…';

  @override
  String get indexNoGrammars => 'Code grammars not installed';

  @override
  String get indexFailed => 'Indexing failed';

  @override
  String indexedSymbolsCount(int count) {
    return '$count symbols indexed';
  }

  @override
  String get nodeConfigAdvanced => 'Advanced';

  @override
  String get nodeConfigReducer => 'Reducer';

  @override
  String get nodeConfigReducerHelp =>
      'How to merge when this output key already has a value';

  @override
  String get nodeConfigTimeoutMs => 'Timeout (ms)';

  @override
  String get nodeConfigRetryAttempts => 'Retry attempts';

  @override
  String get nodeConfigContinueOnFail => 'Continue if this step fails';

  @override
  String get nodeConfigTeamId => 'Team ID';

  @override
  String get nodeConfigDispatchMode => 'Dispatch mode';

  @override
  String get nodeConfigOutputSchema => 'Output schema (JSON)';

  @override
  String get nodeConfigOutputSchemaHelp =>
      'JSON Schema the step output must satisfy';

  @override
  String get diffLineDisplay => 'Long lines in diffs';

  @override
  String get diffLineDisplayDescription =>
      'Wrap long lines or scroll them horizontally';

  @override
  String get diffLineWrap => 'Wrap';

  @override
  String get diffLineScroll => 'Scroll horizontally';

  @override
  String get actions => 'Actions';

  @override
  String get activate => 'Activate';

  @override
  String get activity => 'Activity';

  @override
  String get activityLabel => 'ACTIVITY';

  @override
  String adRulesCount(int count) {
    return '$count ad rules';
  }

  @override
  String get adapter => 'Adapter';

  @override
  String get adapterLabel => 'Adapter';

  @override
  String get adapters => 'Adapters';

  @override
  String get adaptersAutoDetected =>
      'Auto-detected agent runners available on this machine. Install any missing CLI tools to enable additional runners.';

  @override
  String get add => 'Add';

  @override
  String get addAComment => 'Add a comment';

  @override
  String get addAReaction => 'Add a reaction';

  @override
  String get addASuggestion => 'Add a suggestion';

  @override
  String get addAgent => 'Add agent';

  @override
  String get addAgents => 'Add agents';

  @override
  String get addAgentsToEnable =>
      'Add agents to enable multi-agent orchestration';

  @override
  String get addEmoji => 'Add emoji';

  @override
  String get addFeed => 'Add feed';

  @override
  String get addFromFile => 'Add from file';

  @override
  String get addGif => 'Add GIF';

  @override
  String get addGithubRepoPrompt =>
      'Add at least one GitHub repository to see pull requests';

  @override
  String get addLocalCheckoutDescription =>
      'Add a local checkout to start targeting it from this workspace.';

  @override
  String get addRepository => 'Add repository';

  @override
  String get addToken => 'Add token';

  @override
  String get addWorkspace => 'Add workspace';

  @override
  String get addWorkspaceEllipsis => 'Add workspace…';

  @override
  String get added => 'Added';

  @override
  String get addingEllipsis => 'Adding…';

  @override
  String get advancedLabel => 'Advanced';

  @override
  String get agent => 'Agent';

  @override
  String agentCount(int count, int plural) {
    String _temp0 = intl.Intl.pluralLogic(
      plural,
      locale: localeName,
      other: 's',
      one: '',
    );
    return '$count agent$_temp0';
  }

  @override
  String get agentMdPath => 'Agent MD path';

  @override
  String get agentName => 'Agent name';

  @override
  String get agentTitle => 'Agent title';

  @override
  String get agentUpdated => 'Agent updated.';

  @override
  String get agents => 'Agents';

  @override
  String agentsCount(int count, num plural) {
    return 'Agents ($count)';
  }

  @override
  String get agentsLabel => 'AGENTS';

  @override
  String get agentsMentionSection => 'Agents';

  @override
  String get aiReview => 'AI review';

  @override
  String get all => 'All';

  @override
  String get allAgentsAlreadyInChannel =>
      'All agents are already in this channel.';

  @override
  String allAgentsCount(int count) {
    return 'All agents · $count';
  }

  @override
  String get allCommits => 'All commits';

  @override
  String get allSessionsReset => 'All sandbox sessions reset.';

  @override
  String get allSources => 'All sources';

  @override
  String get allStarBadge => 'All-Star';

  @override
  String get allTimeLabel => 'All';

  @override
  String get allow => 'Allow';

  @override
  String get allowGitPush => 'Allow git push';

  @override
  String get allowGithubApi => 'Allow GitHub API calls';

  @override
  String get allowNetwork => 'Allow general network access';

  @override
  String get apiKeys => 'API keys';

  @override
  String get appFont => 'App font';

  @override
  String get appLogLevelDebugDescription =>
      'Adds detailed traces - for development.';

  @override
  String get appLogLevelDebugLabel => 'Debug';

  @override
  String get appLogLevelErrorDescription =>
      'Only unexpected errors and exceptions.';

  @override
  String get appLogLevelErrorLabel => 'Error';

  @override
  String get appLogLevelInfoDescription =>
      'Adds lifecycle and status messages.';

  @override
  String get appLogLevelInfoLabel => 'Info';

  @override
  String get appLogLevelNoneDescription => 'No console output at all.';

  @override
  String get appLogLevelNoneLabel => 'None';

  @override
  String get appLogLevelVerboseDescription =>
      'Everything. Extremely noisy - use for debugging only.';

  @override
  String get appLogLevelVerboseLabel => 'Verbose';

  @override
  String get appLogLevelWarningDescription =>
      'Adds warnings and recoverable issues.';

  @override
  String get appLogLevelWarningLabel => 'Warning';

  @override
  String get appTitle => 'Control Center';

  @override
  String get appearanceLanguage => 'Appearance & language';

  @override
  String get apply => 'Apply';

  @override
  String get approve => 'Approve';

  @override
  String get approveAndCompact => 'Approve and compact context';

  @override
  String get approveAndExecute => 'Approve and execute';

  @override
  String get approveAndHire => 'Approve & hire';

  @override
  String get approved => 'Approved';

  @override
  String get articlesSubscribed => 'Articles across your subscribed feeds.';

  @override
  String get askAi => 'Ask AI';

  @override
  String get askAiReview => 'Ask AI review';

  @override
  String get askAiReviewDescription => 'Ask AI to review this PR';

  @override
  String get askAnything =>
      'Ask anything… (@ to mention agents, / for commands)';

  @override
  String get assignees => 'Assignees';

  @override
  String get attachFiles => 'Attach files';

  @override
  String get attachImage => 'Attach image';

  @override
  String get attachedAgents => 'Attached agents';

  @override
  String get audioInput => 'Audio input';

  @override
  String get authentication => 'Authentication';

  @override
  String get authenticationToken => 'Authentication token';

  @override
  String authoredByLabel(String role) {
    return 'By: $role';
  }

  @override
  String get authorsLabel => 'Authors';

  @override
  String authorsWithCount(int count) {
    return 'Authors · $count';
  }

  @override
  String get autoRecommended => 'Auto (recommended)';

  @override
  String get available => 'Available';

  @override
  String get avgDuration => 'Avg duration';

  @override
  String get awaitingYourApproval => 'Awaiting your approval';

  @override
  String get awaitingYourReview => 'Awaiting your review';

  @override
  String get back => 'Back';

  @override
  String get backLabel => 'Back';

  @override
  String get backend => 'Backend';

  @override
  String get blockAdsDescription => 'Block ads, trackers & cookie banners';

  @override
  String get blockAdsTrackers => 'Block ads, trackers & cookie banners';

  @override
  String get blocking => 'Blocking';

  @override
  String get blockingLabel => 'Blocking';

  @override
  String get bookmarkLabel => 'Bookmark';

  @override
  String get briefDescription => 'Brief description';

  @override
  String get bugLabel => 'BUG';

  @override
  String get bundledDefaultsNeverUpdated => 'Bundled defaults — never updated';

  @override
  String get cached => 'Cached';

  @override
  String get cancel => 'Cancel';

  @override
  String get cancelEdit => 'Cancel edit';

  @override
  String get categoryCreation => 'Creation';

  @override
  String get categoryDeletion => 'Category deletion';

  @override
  String get categoryEditing => 'Editing';

  @override
  String get categoryNavigation => 'Navigation';

  @override
  String get categorySystem => 'System';

  @override
  String get categoryView => 'Category view';

  @override
  String get centurionBadge => 'Centurion';

  @override
  String get change => 'Change';

  @override
  String get changesRequested => 'Changes requested';

  @override
  String get changesSummary => 'Changes summary';

  @override
  String get channelsMentionSection => 'Channels';

  @override
  String get checkForUpdates => 'Check for updates';

  @override
  String get checking => 'Checking';

  @override
  String get checkingEllipsis => 'Checking…';

  @override
  String get checkingGhCli => 'Checking gh CLI…';

  @override
  String get chooseAppFont => 'Choose app font';

  @override
  String get chooseCodeFont => 'Choose code font';

  @override
  String get chooseRunner => 'Choose your agent runner.';

  @override
  String get clear => 'Clear';

  @override
  String get clickToRetry => 'Click to retry';

  @override
  String get close => 'Close';

  @override
  String get closeEsc => 'Close (Esc)';

  @override
  String get closeKeyboardHint => 'Close';

  @override
  String get closePanel => 'Close panel';

  @override
  String get closeReader => 'Close reader';

  @override
  String get closeThread => 'Close thread';

  @override
  String get closed => 'Closed';

  @override
  String get codeFont => 'Code font';

  @override
  String get collapse => 'Collapse';

  @override
  String get commandPalette => 'Command palette';

  @override
  String get commandPaletteOrgMembers => 'Organization members';

  @override
  String get commandPaletteBrowseTeam => 'Browse team';

  @override
  String get commandPaletteBrowseTeamDesc => 'View all organization members';

  @override
  String get commandsMentionSection => 'Commands';

  @override
  String get comment => 'Comment';

  @override
  String get commentOnFile => 'Comment on this file';

  @override
  String get commentOnThisFile => 'Comment on this file';

  @override
  String get commentSelected => 'Comment selected';

  @override
  String get commented => 'Commented';

  @override
  String get commits => 'Commits';

  @override
  String commitsShowingLatest(int loaded, int total) {
    return 'Showing latest $loaded of $total commits';
  }

  @override
  String get prCloneProgressCloningTitle => 'Cloning repository';

  @override
  String prCloneProgressCloningSubtitle(int fileCount) {
    return 'This PR changes $fileCount files, which exceeds GitHub\'s API limit. Cloning the repository locally…';
  }

  @override
  String get prCloneProgressCloningSubtitleNoCount =>
      'This PR exceeds GitHub\'s API file limit. Cloning the repository locally…';

  @override
  String get prCloneProgressFetchingTitle => 'Fetching PR refs';

  @override
  String get prCloneProgressFetchingSubtitle =>
      'Fetching the base branch and PR head ref…';

  @override
  String get prCloneProgressComputingTitle => 'Computing diff';

  @override
  String get prCloneProgressComputingSubtitle => 'Running git diff locally…';

  @override
  String get prCloneProgressErrorTitle => 'Failed to load diff';

  @override
  String get prCloneProgressErrorSubtitle =>
      'An error occurred while cloning or computing the diff. Please try refreshing.';

  @override
  String prCloneProgressElapsed(String elapsed) {
    return 'Still working… $elapsed elapsed';
  }

  @override
  String confidenceLabel(int percent) {
    return 'Confidence: $percent%';
  }

  @override
  String get configureAgentIdentities =>
      'Configure agent identities, prompts, skills, and view runs.';

  @override
  String get configureDefaultRunners =>
      'Configure which adapter and model are used for new conversations and title generation.';

  @override
  String get configuredLabel => 'Configured.';

  @override
  String get confirmedBy => 'Confirmed by';

  @override
  String get consensus => 'Consensus';

  @override
  String get contentBlockingDescription =>
      'Block ads, trackers and cookie banners';

  @override
  String get contentHint => 'What should be remembered';

  @override
  String get contentLabel => 'Content';

  @override
  String get contentMarkdown => 'Content (Markdown)';

  @override
  String get contextWindowSize => 'Context window size';

  @override
  String get continueLabel => 'Continue';

  @override
  String get conversationMode => 'Conversation mode';

  @override
  String get convertToGroup => 'Convert to group?';

  @override
  String get convertToGroupBody =>
      'Adding another agent turns this into a group conversation.';

  @override
  String cookieRulesCount(int count) {
    return '$count cookie rules';
  }

  @override
  String get copied => 'Copied!';

  @override
  String get copy => 'Copy';

  @override
  String get copyBaseBranchTooltip => 'Copy base branch name';

  @override
  String get copyHeadBranchTooltip => 'Copy head branch name';

  @override
  String get couldNotCheckGhCli => 'Could not check gh CLI.';

  @override
  String couldNotListDevices(String error) {
    return 'Could not list devices: $error';
  }

  @override
  String get create => 'Create';

  @override
  String get createFirstAgent => 'Create your first agent to get started.';

  @override
  String get createOrSelectWorkspace =>
      'Create or select a workspace before adding repositories.';

  @override
  String get createPr => 'Create PR';

  @override
  String get createPullRequest => 'Create pull request';

  @override
  String get createdByMe => 'Created by me';

  @override
  String createdLabel(String date) {
    return 'Created: $date';
  }

  @override
  String get currentParticipants => 'Current participants';

  @override
  String get customCapabilitiesDescription => 'Custom capabilities description';

  @override
  String get customSystemPrompt => 'Custom system prompt for this agent...';

  @override
  String daysAgo(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count days ago',
      one: '1 day ago',
    );
    return '$_temp0';
  }

  @override
  String get deactivate => 'Deactivate';

  @override
  String get defaultCapabilities => 'Default capabilities · new conversations';

  @override
  String get defaultChat => 'Default chat';

  @override
  String defaultPort(int port) {
    return 'Default: $port.';
  }

  @override
  String defaultPortHint(int port) {
    return 'Default: $port.';
  }

  @override
  String get defaultRunners => 'Default runners';

  @override
  String get delete => 'Delete';

  @override
  String get deleteAgent => 'Delete agent';

  @override
  String deleteAgentConfirm(String name) {
    return 'Delete \"$name\"? This cannot be undone.';
  }

  @override
  String get deleteChannel => 'Delete channel';

  @override
  String deleteConfirmName(String name) {
    return 'Delete \"$name\"?';
  }

  @override
  String get deleteConversation => 'Delete conversation';

  @override
  String get deleteConversationConfirm =>
      'Delete this conversation? All messages will be lost.';

  @override
  String get deleteFact => 'Delete fact';

  @override
  String get deleteFeedBody =>
      'This removes the feed and all its cached articles. Bookmarked articles from this feed will also be removed.';

  @override
  String deleteFeedConfirm(String name) {
    return 'Delete \"$name\"?';
  }

  @override
  String deleteNamedConversation(String name) {
    return 'Delete \"$name\"? All messages will be lost.';
  }

  @override
  String get deletePolicy => 'Delete policy';

  @override
  String get deletePolicyConfirm =>
      'Delete this policy? This cannot be undone.';

  @override
  String deleteTopicConfirm(String topic) {
    return 'Delete \"$topic\"? This cannot be undone.';
  }

  @override
  String get deleteWorkspace => 'Delete workspace';

  @override
  String get deny => 'Deny';

  @override
  String get descriptionLabel => 'Description';

  @override
  String get detailsLabel => 'Details';

  @override
  String detectedBackend(String label) {
    return 'Detected: $label';
  }

  @override
  String detectedRunners(int count) {
    return 'Detected runners ($count)';
  }

  @override
  String get detectingAdapters => 'Detecting adapters…';

  @override
  String get detectingGhCli => 'Detecting gh CLI…';

  @override
  String get detectingInputDevices => 'Detecting input devices…';

  @override
  String detectionFailed(String error) {
    return 'Detection failed: $error';
  }

  @override
  String diffFailed(String message) {
    return 'Diff failed: $message';
  }

  @override
  String get diffWorkerPool => 'Worker pool';

  @override
  String get directMessage => 'Direct message';

  @override
  String get directMessages => 'Direct messages';

  @override
  String get disabled => 'Disabled';

  @override
  String get discover => 'Discover';

  @override
  String get discoverAgents => 'Discover agents';

  @override
  String get discoverAgentsDescription =>
      'Agent discovery scans workspace paths for AGENTS.md and TEAM.md files, parsing them into the agent registry.\n\nConfigure a workspace first, then use this feature to auto-populate agents.';

  @override
  String get dismissed => 'Dismissed';

  @override
  String get domainHint => 'e.g. api-performance';

  @override
  String get domainLabel => 'Domain';

  @override
  String get download => 'Download';

  @override
  String get downloadingLabel => 'Downloading';

  @override
  String downloadingModel(int pct) {
    return 'Downloading model… $pct%';
  }

  @override
  String get draft => 'Draft';

  @override
  String get draftLabel => 'Draft';

  @override
  String get earnTiersDescription => 'Earn tiers as you use the control center';

  @override
  String get edit => 'Edit';

  @override
  String get editFact => 'Edit fact';

  @override
  String get editPolicy => 'Edit policy';

  @override
  String get editSuggestedCodeHint => 'Edit suggested code…';

  @override
  String get editSuggestion => 'Edit suggestion';

  @override
  String get editTheSuggestedCodeHint => 'Edit the suggested code…';

  @override
  String get egArchitect => 'e.g. architect';

  @override
  String get egControlCenter => 'e.g. control-center';

  @override
  String get egPlatform => 'e.g. macOS';

  @override
  String get egSamuelAlev => 'e.g. SamuelAlev';

  @override
  String get egSoftwareArchitect => 'e.g. Software Architect';

  @override
  String get egTheVerge => 'e.g. The Verge';

  @override
  String get egTokenLimit => 'e.g. 128000';

  @override
  String embeddingInstallFailed(String error) {
    return 'Install failed: $error';
  }

  @override
  String get embeddingInstalled =>
      'Local embedding model installed. Hybrid search is enabled.';

  @override
  String get embeddingModel => 'Embedding model (ONNX)';

  @override
  String get embeddingNotInstalled =>
      'Not installed. Search falls back to keyword-only until enabled.';

  @override
  String get embeddingRedownloadBody =>
      'The existing model files will be deleted and downloaded again. Semantic search will be unavailable until the download completes.';

  @override
  String get embeddingRemoveBody =>
      'Semantic search will be disabled until you reinstall it. You can install it again at any time.';

  @override
  String get speakerDiarization => 'Speaker diarization';

  @override
  String get diarizationModel => 'Diarization model';

  @override
  String get diarizationInstalled =>
      'Installed — names individual speakers in meeting transcripts';

  @override
  String get diarizationNotInstalled =>
      'Not installed — meeting speakers won\'t be separated';

  @override
  String diarizationInstallFailed(String error) {
    return 'Install failed: $error';
  }

  @override
  String get redownloadDiarizationModel => 'Re-download diarization model';

  @override
  String get diarizationRedownloadBody =>
      'This removes the current diarization models and downloads them again.';

  @override
  String get removeDiarizationModel => 'Remove diarization model';

  @override
  String get diarizationRemoveBody =>
      'This deletes the on-device diarization models. Meeting transcripts already produced are unaffected.';

  @override
  String get onboardingDiarizationTitle => 'Speaker diarization (optional)';

  @override
  String get onboardingDiarizationSubtitle =>
      'Download to label individual speakers (Person 1, Person 2…) in meeting notes. You can add this later in settings.';

  @override
  String get enableMcpServer => 'Enable MCP server';

  @override
  String get enableNotifications => 'Enable notifications';

  @override
  String get enableSandboxing => 'Enable sandboxing';

  @override
  String get enabled => 'Enabled';

  @override
  String enterToken(String name) {
    return 'Enter $name Token';
  }

  @override
  String get enterTokenToAuth => 'Enter a token to require authentication';

  @override
  String errorCreatingAgent(String error) {
    return 'Error creating agent: $error';
  }

  @override
  String errorDeletingAgent(String error) {
    return 'Error deleting agent: $error';
  }

  @override
  String get errorLoadingAgents => 'Error loading agents';

  @override
  String errorWithDetail(String error) {
    return 'Error: $error';
  }

  @override
  String get errored => 'Errored';

  @override
  String get erroredLabel => 'Errored';

  @override
  String get exitSelection => 'Exit selection';

  @override
  String get expand => 'Expand';

  @override
  String get extractingLabel => 'Extracting';

  @override
  String extractingModel(int pct) {
    return 'Extracting model… $pct%';
  }

  @override
  String get fact => 'Fact';

  @override
  String factCount(int count) {
    return '$count fact';
  }

  @override
  String factCountPlural(int count) {
    return '$count facts';
  }

  @override
  String get facts => 'Facts';

  @override
  String factsPoliciesCount(int factCount, int policyCount) {
    return '$factCount facts · $policyCount policies';
  }

  @override
  String get failed => 'Failed';

  @override
  String failedToDispatch(String error) {
    return 'Failed to dispatch: $error';
  }

  @override
  String get failedToLoad => 'Failed to load';

  @override
  String failedToLoadAgents(String error) {
    return 'Failed to load agents: $error';
  }

  @override
  String failedToLoadFeeds(String error) {
    return 'Failed to load feeds: $error';
  }

  @override
  String get failedToLoadGifs => 'Failed to load GIFs';

  @override
  String failedToLoadLogs(String error) {
    return 'Failed to load logs: $error';
  }

  @override
  String get failedToLoadRepos => 'Failed to load repositories';

  @override
  String get failedToLoadWorkspaces => 'Failed to load workspaces';

  @override
  String failedToStartAiReview(String error) {
    return 'Failed to start AI review: $error';
  }

  @override
  String get failedToStartMicTest => 'Failed to start mic test.';

  @override
  String failedToSubmitReview(String error) {
    return 'Failed to submit review: $error';
  }

  @override
  String failedToUpload(String name, String error) {
    return 'Failed to upload $name: $error';
  }

  @override
  String failedWithError(String error) {
    return 'Failed: $error';
  }

  @override
  String get failure => 'Failure';

  @override
  String get feedAlreadyExists => 'A feed with this URL already exists.';

  @override
  String get feedUrl => 'Feed URL';

  @override
  String get feedUrlExample => 'e.g. https://example.com/feed.xml';

  @override
  String get feedUrlExists => 'A feed with this URL already exists.';

  @override
  String get feedUrlLabel => 'Feed URL';

  @override
  String feedsCount(int count) {
    return 'Feeds ($count)';
  }

  @override
  String get feedsLabel => 'Feeds';

  @override
  String get filesChanged => 'Files changed';

  @override
  String filesCount(int count) {
    return '$count file(s)';
  }

  @override
  String get filesMentionSection => 'Files';

  @override
  String get filterAgents => 'Filter agents...';

  @override
  String get filterAgentsPlaceholder => 'Filter agents…';

  @override
  String get filterFilesHint => 'Filter files…';

  @override
  String get filterLists => 'Filter lists';

  @override
  String get filterSkillsPlaceholder => 'Filter skills…';

  @override
  String get finish => 'Finish';

  @override
  String get firstReviewBadge => 'First review';

  @override
  String get fix => 'Fix';

  @override
  String get fixSelected => 'Fix selected';

  @override
  String get flawlessBadge => 'Flawless';

  @override
  String get forks => 'Forks';

  @override
  String get forward => 'Forward';

  @override
  String get gatesGithubPatPush =>
      'Gates GitHub PAT injection. Required for the agent to push.';

  @override
  String get general => 'General';

  @override
  String get generalSettingsDescription =>
      'Appearance, typography, integrations, and MCP server.';

  @override
  String get ghCliAuthButPatOverrideBody =>
      'GitHub CLI is authenticated and ready, but a personal access token is set below and will be used instead. Clear the PAT to use gh CLI auth.';

  @override
  String get ghCliInstalledAuth =>
      'Installed. Run `gh auth login`, then tap Refresh.';

  @override
  String get ghCliNotInstalled =>
      'gh CLI not installed — install from cli.github.com.';

  @override
  String get ghCliNotInstalledLabel => 'gh CLI not installed';

  @override
  String get githubCli => 'GitHub CLI';

  @override
  String get githubCliIntegration => 'GitHub CLI integration';

  @override
  String get githubCliReady => 'GitHub CLI is authenticated and ready.';

  @override
  String get githubLink => 'GitHub link';

  @override
  String get githubPersonalAccessToken => 'GitHub personal access token';

  @override
  String get githubStatusAllOperational => 'All systems operational';

  @override
  String get githubStatusComponents => 'Components';

  @override
  String get githubStatusFetchFailed => 'Couldn\'t reach githubstatus.com';

  @override
  String get githubStatusIncidents => 'Active incidents';

  @override
  String get githubStatusOpenInBrowser => 'Open githubstatus.com';

  @override
  String get githubStatusRefresh => 'Refresh';

  @override
  String get githubStatusTitle => 'GitHub status';

  @override
  String githubStatusUpdated(String time) {
    return 'Updated $time';
  }

  @override
  String lastChecked(String time) {
    return 'Checked $time';
  }

  @override
  String get lastCheckedRecently => 'Checked recently';

  @override
  String get githubToken => 'GitHub token';

  @override
  String get giveAgentsAMemory => 'Give agents a memory.';

  @override
  String get giveYourWorkAHome => 'Give your work a home.';

  @override
  String get goBack => 'Go back';

  @override
  String get goForward => 'Go forward';

  @override
  String get googleFonts => 'Google fonts';

  @override
  String get groupLabel => 'Group';

  @override
  String get groupName => 'Group name';

  @override
  String get groups => 'Groups';

  @override
  String get hideContainerTerminal => 'Hide container terminal';

  @override
  String get high => 'High';

  @override
  String get hotStreakBadge => 'Hot streak';

  @override
  String hoursAgo(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count hours ago',
      one: '1 hour ago',
    );
    return '$_temp0';
  }

  @override
  String get idleStatus => 'Idle';

  @override
  String get images => 'Images';

  @override
  String get inFlightLabel => 'In flight';

  @override
  String get inactive => 'Inactive';

  @override
  String get install => 'Install';

  @override
  String get installGhCliBody =>
      'Install gh from https://cli.github.com/ and run `gh auth login`, then tap Refresh.';

  @override
  String get installRequired => 'Installation required';

  @override
  String get installedNotSignedIn => 'Installed - not signed in';

  @override
  String installedVersion(String version) {
    return 'Installed $version';
  }

  @override
  String get integrations => 'Integrations';

  @override
  String get invite => 'Invite';

  @override
  String get inviteAgent => 'Invite agent';

  @override
  String get isolateAgentExecution => 'Isolate agent execution.';

  @override
  String jobCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 's',
      one: '',
    );
    return '$count job$_temp0';
  }

  @override
  String get justNow => 'Just now';

  @override
  String get keepMessages => 'Keep messages';

  @override
  String get keepSandboxing => 'Keep sandboxing';

  @override
  String get keybindingAdapters => 'Adapters';

  @override
  String get keybindingAddARepositoryDescription => 'Add a repository';

  @override
  String get keybindingAddRepository => 'Add repository';

  @override
  String get keybindingAgents => 'Agents';

  @override
  String get keybindingApprove => 'Approve';

  @override
  String get keybindingApproveThePeerReviewDescription =>
      'Approve the peer review';

  @override
  String get keybindingBookmarkOrUnbookmarkTheSelectedArticleDescription =>
      'Bookmark or unbookmark the selected article';

  @override
  String get keybindingCommandPalette => 'Command palette';

  @override
  String get keybindingConversationTab => 'Conversation tab';

  @override
  String get keybindingCreateANewAgentDescription => 'Create a new agent';

  @override
  String get keybindingCreateANewGroupChannelDescription =>
      'Create a new group channel';

  @override
  String get keybindingCreateANewWorkspaceDescription =>
      'Create a new workspace';

  @override
  String get keybindingDeleteAgent => 'Delete agent';

  @override
  String get keybindingDeleteChannel => 'Delete channel';

  @override
  String get keybindingDeleteTheSelectedAgentDescription =>
      'Delete the selected agent';

  @override
  String get keybindingDeleteTheSelectedChannelDescription =>
      'Delete the selected channel';

  @override
  String get keybindingDeleteTheSelectedWorkspaceDescription =>
      'Delete the selected workspace';

  @override
  String get keybindingDeleteWorkspace => 'Delete workspace';

  @override
  String get keybindingFilesChangedTab => 'Files changed tab';

  @override
  String get keybindingFocusSearch => 'Focus search';

  @override
  String get keybindingFocusThePullRequestSearchFieldDescription =>
      'Focus the pull request search field';

  @override
  String get keybindingGeneral => 'General';

  @override
  String get keybindingGoToAgents => 'Go to Agents';

  @override
  String get keybindingGoToAnalytics => 'Go to Analytics';

  @override
  String get keybindingGoToDashboard => 'Go to Dashboard';

  @override
  String get keybindingGoToMemory => 'Go to Memory';

  @override
  String get keybindingGoToNewsfeed => 'Go to Newsfeed';

  @override
  String get keybindingGoToPipelines => 'Go to Pipelines';

  @override
  String get keybindingGoToPullRequests => 'Go to Pull Requests';

  @override
  String get keybindingGoToTickets => 'Go to Tickets';

  @override
  String get keybindingKeybindings => 'Keybindings';

  @override
  String get keybindingNavigateToTheAgentsRegistryDescription =>
      'Navigate to the agents registry';

  @override
  String get keybindingNavigateToTheAnalyticsDashboardDescription =>
      'Navigate to the analytics dashboard';

  @override
  String get keybindingNavigateToTheGlobalDashboardDescription =>
      'Navigate to the global dashboard';

  @override
  String get keybindingNavigateToTheMemoryDescription =>
      'Navigate to the memory knowledge base';

  @override
  String get keybindingNavigateToTheNewsfeedDescription =>
      'Navigate to the newsfeed';

  @override
  String get keybindingNavigateToThePipelinesListDescription =>
      'Navigate to the pipelines list';

  @override
  String get keybindingNavigateToThePullRequestListDescription =>
      'Navigate to the pull request list';

  @override
  String get keybindingNavigateToTheTicketsBoardDescription =>
      'Navigate to the tickets board';

  @override
  String get keybindingNewAgent => 'New agent';

  @override
  String get keybindingNewDirectMessage => 'New direct message';

  @override
  String get keybindingNewGroup => 'New group';

  @override
  String get keybindingNewWorkspace => 'New workspace';

  @override
  String get keybindingNextArticle => 'Next article';

  @override
  String get keybindingNextChannel => 'Next channel';

  @override
  String get keybindingNextPr => 'Next PR';

  @override
  String get keybindingNextWorkspace => 'Next workspace';

  @override
  String get keybindingOpenArticle => 'Open article';

  @override
  String
  get keybindingOpenOrCloseTheWorkspaceSwitcherPopupInTheSidebarDescription =>
      'Open or close the workspace switcher popup in the sidebar';

  @override
  String get keybindingOpenPr => 'Open PR';

  @override
  String get keybindingOpenSettings => 'Open settings';

  @override
  String get keybindingOpenTheAdaptersSettingsPageDescription =>
      'Open the Adapters settings page';

  @override
  String get keybindingOpenTheAgentsSettingsPageDescription =>
      'Open the Agents settings page';

  @override
  String get keybindingOpenTheApplicationSettingsDescription =>
      'Open the application settings';

  @override
  String get keybindingOpenTheCommandPaletteDescription =>
      'Open the command palette';

  @override
  String get keybindingOpenTheGeneralSettingsPageDescription =>
      'Open the General settings page';

  @override
  String get keybindingOpenTheKeybindingsSettingsPageDescription =>
      'Open the Keybindings settings page';

  @override
  String get keybindingOpenTheRepositoriesSettingsPageDescription =>
      'Open the Repositories settings page';

  @override
  String get keybindingOpenTheSelectedArticleDescription =>
      'Open the selected article';

  @override
  String get keybindingOpenTheSelectedPullRequestDescription =>
      'Open the selected pull request';

  @override
  String get keybindingOpenTheSelectedWorkspaceDescription =>
      'Open the selected workspace';

  @override
  String get keybindingOpenTheSkillsSettingsPageDescription =>
      'Open the Skills settings page';

  @override
  String get keybindingOpenWorkspace => 'Open workspace';

  @override
  String get keybindingPreviousArticle => 'Previous article';

  @override
  String get keybindingPreviousChannel => 'Previous channel';

  @override
  String get keybindingPreviousPr => 'Previous PR';

  @override
  String get keybindingPreviousWorkspace => 'Previous workspace';

  @override
  String get keybindingRefresh => 'Refresh';

  @override
  String get keybindingRefreshAllFeedsDescription => 'Refresh all feeds';

  @override
  String get keybindingRefreshAnalyticsDataDescription =>
      'Refresh analytics data';

  @override
  String get keybindingRefreshDashboardDataDescription =>
      'Refresh dashboard data';

  @override
  String get keybindingRefreshThePullRequestListDescription =>
      'Refresh the pull request list';

  @override
  String get keybindingRemoveRepository => 'Remove repository';

  @override
  String get keybindingRemoveTheSelectedRepositoryDescription =>
      'Remove the selected repository';

  @override
  String get keybindingRepositories => 'Repositories';

  @override
  String get keybindingRequestChanges => 'Request changes';

  @override
  String get keybindingRequestChangesOnThePeerReviewDescription =>
      'Request changes on the peer review';

  @override
  String get keybindingRescanForAdaptersDescription => 'Rescan for adapters';

  @override
  String get keybindingSearchInDiff => 'Search in diff';

  @override
  String get keybindingSearchWithinTheDiffViewDescription =>
      'Search within the diff view';

  @override
  String get keybindingToggleViewed => 'Toggle viewed';

  @override
  String get keybindingMarkTheFocusedFileAsViewedOrUnviewedDescription =>
      'Mark the focused file as viewed or unviewed';

  @override
  String get keybindingToggleCollapse => 'Toggle collapse';

  @override
  String get keybindingCollapseOrExpandTheFocusedFileDescription =>
      'Collapse or expand the focused file';

  @override
  String get keybindingSelectTheNextArticleDescription =>
      'Select the next article';

  @override
  String get keybindingSelectTheNextChannelDescription =>
      'Select the next channel';

  @override
  String get keybindingSelectTheNextPullRequestDescription =>
      'Select the next pull request';

  @override
  String get keybindingSelectThePreviousArticleDescription =>
      'Select the previous article';

  @override
  String get keybindingSelectThePreviousChannelDescription =>
      'Select the previous channel';

  @override
  String get keybindingSelectThePreviousPullRequestDescription =>
      'Select the previous pull request';

  @override
  String get keybindingSendMessage => 'Send message';

  @override
  String get keybindingSendTheCurrentMessageDescription =>
      'Send the current message';

  @override
  String get keybindingSkills => 'Skills';

  @override
  String get keybindingStartANewDirectMessageDescription =>
      'Start a new direct message';

  @override
  String get keybindingSwitchBetweenLightAndDarkModeDescription =>
      'Switch between light and dark mode';

  @override
  String get keybindingSwitchToTheConversationTabDescription =>
      'Switch to the conversation tab';

  @override
  String get keybindingSwitchToTheEighthWorkspaceDescription =>
      'Switch to the eighth workspace';

  @override
  String get keybindingSwitchToTheFifthWorkspaceDescription =>
      'Switch to the fifth workspace';

  @override
  String get keybindingSwitchToTheFilesChangedTabDescription =>
      'Switch to the files changed tab';

  @override
  String get keybindingSwitchToTheFirstWorkspaceDescription =>
      'Switch to the first workspace';

  @override
  String get keybindingSwitchToTheFourthWorkspaceDescription =>
      'Switch to the fourth workspace';

  @override
  String get keybindingSwitchToTheNextWorkspaceDescription =>
      'Switch to the next workspace';

  @override
  String get keybindingSwitchToTheNinthWorkspaceDescription =>
      'Switch to the ninth workspace';

  @override
  String get keybindingSwitchToThePreviousWorkspaceDescription =>
      'Switch to the previous workspace';

  @override
  String get keybindingSwitchToTheSecondWorkspaceDescription =>
      'Switch to the second workspace';

  @override
  String get keybindingSwitchToTheSeventhWorkspaceDescription =>
      'Switch to the seventh workspace';

  @override
  String get keybindingSwitchToTheSixthWorkspaceDescription =>
      'Switch to the sixth workspace';

  @override
  String get keybindingSwitchToTheThirdWorkspaceDescription =>
      'Switch to the third workspace';

  @override
  String get keybindingToggleBookmark => 'Toggle bookmark';

  @override
  String get keybindingToggleTheme => 'Toggle theme';

  @override
  String get keybindingToggleWorkspaceSwitcher => 'Toggle workspace switcher';

  @override
  String get keybindingWorkspace1 => 'Workspace 1';

  @override
  String get keybindingWorkspace2 => 'Workspace 2';

  @override
  String get keybindingWorkspace3 => 'Workspace 3';

  @override
  String get keybindingWorkspace4 => 'Workspace 4';

  @override
  String get keybindingWorkspace5 => 'Workspace 5';

  @override
  String get keybindingWorkspace6 => 'Workspace 6';

  @override
  String get keybindingWorkspace7 => 'Workspace 7';

  @override
  String get keybindingWorkspace8 => 'Workspace 8';

  @override
  String get keybindingWorkspace9 => 'Workspace 9';

  @override
  String get keybindings => 'Keybindings';

  @override
  String get keybindingsDescription =>
      'All keyboard shortcuts. Shortcuts are fixed and cannot be reassigned.';

  @override
  String get killRunning => 'Kill running';

  @override
  String get klipyNotConfigured => 'KLIPY_APP_KEY not configured';

  @override
  String get klipyNotConfiguredHint =>
      'Pass --dart-define=KLIPY_APP_KEY=...\nor set it in .env before running.';

  @override
  String get languageDutch => 'Nederlands';

  @override
  String get languageEnglish => 'English';

  @override
  String get languageFrench => 'Français';

  @override
  String get languageGerman => 'Deutsch';

  @override
  String get languageItalian => 'Italiano';

  @override
  String get languagePortuguese => 'Português';

  @override
  String get languageSpanish => 'Español';

  @override
  String get languageSystem => 'System';

  @override
  String lastMonths(int count) {
    return 'Last $count months';
  }

  @override
  String get latestLabel => 'Latest';

  @override
  String get leaderboardLabel => 'LEADERBOARD';

  @override
  String get leaderboardLabelShort => 'Leaderboard';

  @override
  String get leaveACommentEllipsis => 'Leave a comment…';

  @override
  String get legendLabel => 'Legend';

  @override
  String get lessLabel => 'Less';

  @override
  String get letsPluginTools => 'Let\'s plug in your tools.';

  @override
  String get level => 'Level';

  @override
  String levelLabel(int level) {
    return 'Level $level';
  }

  @override
  String get liveDiff => 'Live diff';

  @override
  String get liveSync => 'Live sync';

  @override
  String get loadingAgents => 'Loading agents…';

  @override
  String get loadingModels => 'Loading models…';

  @override
  String get lockedLabel => 'Locked';

  @override
  String get logLevel => 'Log level';

  @override
  String get logs => 'Logs';

  @override
  String get low => 'Low';

  @override
  String get maintenance => 'Maintenance';

  @override
  String get manageParticipants => 'Manage participants';

  @override
  String get manageWorkspaces => 'Manage workspaces';

  @override
  String get masterToggle => 'Master toggle';

  @override
  String get matchOsAppearance =>
      'Match your OS appearance or pick a fixed mode.';

  @override
  String get mcpActiveAccepting =>
      'MCP server is active and accepting connections.';

  @override
  String get mcpAuthToken => 'MCP authentication token';

  @override
  String get mcpAuthentication => 'Authentication';

  @override
  String get mcpAutoStartDescription =>
      'When off, the server stays stopped until you start it.';

  @override
  String mcpDefaultPort(int port) {
    return 'Default: $port';
  }

  @override
  String mcpListeningOn(int port) {
    return 'Listening on 127.0.0.1:$port';
  }

  @override
  String mcpListeningOnPort(int port) {
    return 'Listening on 127.0.0.1:$port.';
  }

  @override
  String get mcpNotRunning =>
      'Server is not running. Start it to enable MCP connections.';

  @override
  String get mcpRestartPortChanges =>
      'Server must be restarted to apply port changes.';

  @override
  String get mcpServer => 'MCP server';

  @override
  String get mcpServerStopped => 'Server is stopped';

  @override
  String get mcpStatus => 'Status';

  @override
  String get medium => 'Medium';

  @override
  String get memoryDataHint =>
      'Facts and policies will appear here as agents work.';

  @override
  String get memoryLabel => 'Memory';

  @override
  String get merge => 'Merge';

  @override
  String get mergeMasterBadge => 'Merge master';

  @override
  String get merged => 'Merged';

  @override
  String get messagePlaceholder => 'Message… (@ to mention, / for commands)';

  @override
  String get messagingLabel => 'Messaging';

  @override
  String get microphonePermissionDenied => 'Microphone permission denied.';

  @override
  String minutesAgo(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count minutes ago',
      one: '1 minute ago',
    );
    return '$_temp0';
  }

  @override
  String get modelLabel => 'Model';

  @override
  String get modified => 'Modified';

  @override
  String monthsAgo(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count months ago',
      one: '1 month ago',
    );
    return '$_temp0';
  }

  @override
  String get more => 'More';

  @override
  String get moreLabel => 'More';

  @override
  String get mozillaUserAgent => 'Mozilla/5.0 …';

  @override
  String get name => 'Name';

  @override
  String get nameAndTitleRequired => 'Name and title are required.';

  @override
  String get nameAndUrlRequired => 'Name and URL required';

  @override
  String get nameLabel => 'Name';

  @override
  String nativeSandboxAvailable(String platform) {
    return 'Native sandbox is available on $platform.';
  }

  @override
  String get nativeSandboxNeedsInstall =>
      'Native sandbox installation required';

  @override
  String get navAnalytics => 'Analytics';

  @override
  String get navDashboard => 'Dashboard';

  @override
  String get navSaved => 'Saved';

  @override
  String get navSettings => 'Settings';

  @override
  String get navigateLabel => 'Navigate';

  @override
  String networkBlockCount(int count) {
    return '$count network blocks';
  }

  @override
  String get neutral => 'Neutral';

  @override
  String get newAgent => 'New agent';

  @override
  String get newCommitsPushed =>
      'New commits were pushed — click to reload the diff';

  @override
  String get newFact => 'New fact';

  @override
  String get newGroup => 'New group';

  @override
  String get newLabel => 'New';

  @override
  String get newMessage => 'New message';

  @override
  String get newPolicy => 'New policy';

  @override
  String get newPrToReview => 'New PR to review';

  @override
  String get newsfeed => 'Newsfeed';

  @override
  String get newsfeedLabel => 'Newsfeed';

  @override
  String get newsfeedSettingsDescription =>
      'Manage your subscribed feeds and reader preferences.';

  @override
  String get newsfeedSettingsTitle => 'Newsfeed settings';

  @override
  String get nextMatch => 'Next match (↵)';

  @override
  String get noAccessGrants => 'No access grants configured';

  @override
  String get noActiveWorkspace => 'No active workspace or repo selected.';

  @override
  String get noActiveWorkspaceCreate => 'No active workspace';

  @override
  String get noActiveWorkspaceGithub =>
      'No active workspace with a GitHub repo.';

  @override
  String get noAgentAssigned => 'No agent assigned';

  @override
  String get noAgentProcessesRunning => 'No agent processes running';

  @override
  String get noAgents => 'No agents';

  @override
  String get noAgentsConfigured => 'No agents configured';

  @override
  String get noAgentsDiscovered => 'No agents discovered';

  @override
  String get noAgentsDiscoveredHint =>
      'Click \"Discover\" to scan for AGENTS.md files or \"Add Agent\" to configure one manually';

  @override
  String get noAgentsMatchSearch => 'No agents match your search';

  @override
  String get noAgentsRegisteredYet => 'No agents registered yet';

  @override
  String get noArticlesYet => 'No articles yet';

  @override
  String get noArticlesYetBody => 'Articles from your feeds will appear here.';

  @override
  String get noData => 'No data';

  @override
  String get noDirectMessagesYet => 'No direct messages yet';

  @override
  String get noDomains => 'No domains yet';

  @override
  String get noExecutionLogsYet => 'No execution logs yet';

  @override
  String get noFacts => 'No facts yet';

  @override
  String get noFeedsYet => 'No feeds yet';

  @override
  String get noFileAnchor => 'No file anchor — cannot post inline comment.';

  @override
  String get noFileChangesInScope => 'No file changes in this scope';

  @override
  String get noGifsFound => 'No GIFs found';

  @override
  String get noGroupsYet => 'No groups yet';

  @override
  String get noInputDevicesDetected =>
      'No input devices detected — using system default.';

  @override
  String get noMatchingFiles => 'No matching files';

  @override
  String get noMatchingGoogleFonts => 'No matching Google Fonts.';

  @override
  String get noMemoryData => 'No memory data yet';

  @override
  String get noMessagesYet => 'No messages yet';

  @override
  String get noModelsAdvertised => 'No models advertised by this adapter.';

  @override
  String get noOpenPullRequests => 'No open pull requests';

  @override
  String get noPolicies => 'No policies yet';

  @override
  String get noReposInWorkspaceYet => 'No repositories in this workspace yet';

  @override
  String get noRunnersDetected =>
      'No runners detected yet. Refresh to scan again.';

  @override
  String get noSavedArticles => 'No saved articles';

  @override
  String get noSavedArticlesBody => 'Articles you save will appear here.';

  @override
  String noShortcutsMatch(String query) {
    return 'No shortcuts match \"$query\"';
  }

  @override
  String get noSystemFonts => 'No system fonts detected.';

  @override
  String get noTokenSet => 'No token set — access is unrestricted.';

  @override
  String get noTokenSetUnrestricted => 'No token set — access is unrestricted.';

  @override
  String get noTokenUnrestricted => 'No token — access is unrestricted';

  @override
  String get noWorkingMemory => 'No working memory notes yet.';

  @override
  String get noneAllRoles => 'None (all roles)';

  @override
  String get notAvailable => 'Not available';

  @override
  String get notConfiguredLabel => 'Not configured.';

  @override
  String get notDetected => 'Not detected';

  @override
  String get notEarnedYet => 'Not earned yet';

  @override
  String get notFoundLabel => 'Not found';

  @override
  String get notYetSpawned => 'Not yet spawned';

  @override
  String get notes => 'Notes';

  @override
  String get notificationAgentFinished => 'Agent finished';

  @override
  String get notificationExternalPr => 'External PRs';

  @override
  String get notificationNewMessages => 'New messages';

  @override
  String get notificationPrMerged => 'PR merged';

  @override
  String get notificationPrPublished => 'PR published';

  @override
  String get notifications => 'Notifications';

  @override
  String get notifyAgentRunCompleted => 'Notify when an agent completes a run.';

  @override
  String get notifyExternalPr =>
      'Notify when a new PR is detected from polling.';

  @override
  String get notifyNewMessages =>
      'Notify on new agent messages in other channels.';

  @override
  String get notifyPrMerged => 'Notify when a pull request is merged.';

  @override
  String get notifyPrPublished =>
      'Notify when an agent publishes a pull request.';

  @override
  String get onboardingLinuxDescription =>
      'Control Center can use Linux containers to isolate agent execution.';

  @override
  String get onboardingMacosDescription =>
      'Control Center uses native sandbox on macOS to isolate agent execution.';

  @override
  String get onboardingUnsupportedDescription =>
      'Sandbox is not available on this platform. Agent execution will be without isolation.';

  @override
  String get openAction => 'Open';

  @override
  String get openApplicationSettings => 'Open application settings';

  @override
  String get openArticlesBrowserFallback => 'Open article in browser';

  @override
  String get openArticlesInApp => 'Open articles in app';

  @override
  String get openContainerTerminal => 'Open container terminal';

  @override
  String get openFolder => 'Open folder';

  @override
  String get openInBrowser => 'Open in browser';

  @override
  String get openLabel => 'Open';

  @override
  String get openOnGithub => 'Open on GitHub';

  @override
  String get openStatus => 'Open';

  @override
  String get optionalPersonaDescription => 'Optional persona description';

  @override
  String get otherLabel => 'Other';

  @override
  String get ownerOrganization => 'Owner / Organization';

  @override
  String get p0 => 'P0';

  @override
  String get p1 => 'P1';

  @override
  String get p2 => 'P2';

  @override
  String get p3 => 'P3';

  @override
  String get parsingDiff => 'Parsing diff…';

  @override
  String get passed => 'Passed';

  @override
  String get pasteTokenHere => 'Paste token here';

  @override
  String get pasteValueHere => 'Paste value here';

  @override
  String get patNotNeededGhCli => 'Not needed — gh CLI is signed in.';

  @override
  String get patOverridesGhCli => 'Configured — overrides gh CLI.';

  @override
  String get pathLabel => 'Path';

  @override
  String get pendingApproval => 'Pending your approval';

  @override
  String get perfectionistBadge => 'Perfectionist';

  @override
  String get persona => 'Persona';

  @override
  String get personaColon => 'Persona:';

  @override
  String get personaOptional => 'Persona (optional)';

  @override
  String get personalAccessTokenOptional => 'Personal access token (optional)';

  @override
  String get planLabel => 'Plan';

  @override
  String get policies => 'Policies';

  @override
  String get policiesHint =>
      'Policies will appear here once agents promote facts.';

  @override
  String get policy => 'Policy';

  @override
  String get popular => 'Popular';

  @override
  String get port => 'Port';

  @override
  String get portLabel => 'Port';

  @override
  String get postingEllipsis => 'Posting…';

  @override
  String get prCommits => 'Commits';

  @override
  String get prDescriptionPlaceholder => 'PR description in markdown...';

  @override
  String get prDraftCreated => 'PR draft created';

  @override
  String get prMachineBadge => 'PR machine';

  @override
  String get prMergedBody => 'A pull request was merged';

  @override
  String get prMoreActions => 'More actions';

  @override
  String get prTitle => 'PR title';

  @override
  String get previewLabel => 'Preview';

  @override
  String get previousArticle => 'Previous article';

  @override
  String get previousChannel => 'Previous channel';

  @override
  String get previousMatch => 'Previous match (⇧↵)';

  @override
  String get previousPr => 'Previous PR';

  @override
  String get previousWorkspace => 'Previous workspace';

  @override
  String get priorityReviews => 'Priority reviews';

  @override
  String get priorityReviewsDescription =>
      'Priority reviews and repository overview.';

  @override
  String get progressLabel => 'Progress';

  @override
  String get proposeToCreateDomain => 'Propose a fact or policy to create one.';

  @override
  String get prsCreated => 'PRs created';

  @override
  String get prsCreatedLabel => 'PRs created';

  @override
  String get prsMerged => 'PRs merged';

  @override
  String get publishToGithub => 'Publish to GitHub';

  @override
  String get published => 'Published';

  @override
  String get pullRequestApproved => 'Pull request approved';

  @override
  String get pullRequests => 'Pull requests';

  @override
  String get questionLabel => 'QUESTION';

  @override
  String get queued => 'Queued';

  @override
  String get react => 'React';

  @override
  String get readPrsIssuesMetadata =>
      'Lets the agent read PRs, issues, and repo metadata.';

  @override
  String get readerPreferences => 'Reader preferences';

  @override
  String get reasoningEffort => 'Reasoning effort';

  @override
  String get recommendLabel => 'RECOMMEND';

  @override
  String recordingFromDevice(String device) {
    return 'Recording from $device.';
  }

  @override
  String get redownload => 'Redownload';

  @override
  String get redownloadEmbeddingModel => 'Redownload the embedding model?';

  @override
  String get redownloadVoiceModel => 'Redownload the voice model?';

  @override
  String get refinePlan => 'Refine plan';

  @override
  String get refiningPlan => 'Refining plan…';

  @override
  String get refresh => 'Refresh';

  @override
  String get refreshAll => 'Refresh all';

  @override
  String get refreshAllFeeds => 'Refresh all feeds';

  @override
  String get refreshLabel => 'Refresh';

  @override
  String get refreshPrData => 'Refresh PR data';

  @override
  String get reject => 'Reject';

  @override
  String get rejected => 'Rejected';

  @override
  String get reload => 'Reload';

  @override
  String get remove => 'Remove';

  @override
  String get removeBookmark => 'Remove bookmark';

  @override
  String get removeEmbeddingModel => 'Remove the embedding model?';

  @override
  String get removeLogo => 'Remove logo';

  @override
  String get removeRepoFromWorkspace => 'Remove repository from workspace?';

  @override
  String get removeRepository => 'Remove repository';

  @override
  String get removeRepositoryConfirm => 'Remove repository from workspace?';

  @override
  String get removeVoiceModel => 'Remove the voice model?';

  @override
  String get removed => 'Removed';

  @override
  String get renamed => 'Renamed';

  @override
  String get reopen => 'Reopen';

  @override
  String get replyEllipsis => 'Reply…';

  @override
  String repoRemovedFromWorkspace(String name) {
    return '$name will be removed from this workspace. The local files on disk are not touched.';
  }

  @override
  String get reportsTo => 'Reports to';

  @override
  String get reportsToOptional => 'Reports to (optional)';

  @override
  String reposCount(int count) {
    return 'Repositories ($count)';
  }

  @override
  String get reposDescription => 'The local checkouts this workspace targets.';

  @override
  String get repositories => 'Repositories';

  @override
  String get repositoriesSettings => 'Repositories settings';

  @override
  String get repositoryName => 'Repository name';

  @override
  String get requestChanges => 'Request changes';

  @override
  String get requested => 'Requested';

  @override
  String get requestedChanges => 'Requested changes';

  @override
  String get requiredIfGhCliUnavailable =>
      'Required if gh CLI is not available';

  @override
  String requiredRoleLabel(String role) {
    return 'Required role: $role';
  }

  @override
  String get requiredRoleOptional => 'Required role (optional)';

  @override
  String get requirements => 'Requirements';

  @override
  String get reset => 'Reset';

  @override
  String get resetAllSandboxes => 'Reset all sandboxes';

  @override
  String get resolve => 'Resolve';

  @override
  String get resolved => 'Resolved';

  @override
  String get restartServerToApply => 'Restart the server to apply changes.';

  @override
  String get restartShell => 'Restart shell';

  @override
  String get restartToApply => 'Restart the server to apply changes.';

  @override
  String get retry => 'Retry';

  @override
  String get review => 'Review';

  @override
  String get reviewChanges => 'Review changes';

  @override
  String get reviewedByMe => 'Reviewed by me';

  @override
  String get reviewers => 'Reviewers';

  @override
  String get reviewersActive => 'Reviewers active';

  @override
  String get reviewsLabel => 'Reviews';

  @override
  String get roleLabel => 'Role';

  @override
  String get ruleHint => 'The policy rule (markdown supported)';

  @override
  String get ruleLabel => 'Rule';

  @override
  String get runCompleted => 'Run completed';

  @override
  String get runGhAuthLoginBody =>
      'Run `gh auth login` in your terminal, then tap Refresh.';

  @override
  String get running => 'Running';

  @override
  String get runningLabel => 'running';

  @override
  String get runningStatus => 'Running';

  @override
  String get runs => 'Runs';

  @override
  String get runsAcrossAllAgents => 'Runs across all agents';

  @override
  String get runsLabel => 'Runs';

  @override
  String get sandboxBackendNativeLabel => 'Native sandbox';

  @override
  String get sandboxBackendNoneLabel => 'No isolation';

  @override
  String get sandboxLinuxInstall =>
      'Native sandbox on Linux/WSL2 uses bubblewrap. Install with:\\n\\n  sudo apt-get install bubblewrap socat ripgrep   # Debian/Ubuntu\\n  sudo dnf install bubblewrap socat ripgrep       # Fedora/RHEL\\n  sudo pacman -S bubblewrap socat ripgrep         # Arch';

  @override
  String get sandboxMacosBuiltIn =>
      'Native sandbox is built in on macOS - uses Apple Seatbelt (`sandbox-exec`). No install required.';

  @override
  String get sandboxPermissions => 'Sandbox permissions';

  @override
  String get sandboxUnsupported =>
      'Native sandbox is not supported on this platform yet. Falls back to \"No isolation\".';

  @override
  String get sandboxing => 'Sandboxing';

  @override
  String get sandboxingDescription =>
      'Run agents inside an OS-level sandbox so they can\'t touch your home folder, SSH keys, or tokens you haven\'t granted.';

  @override
  String get sandboxingDisabledDescription =>
      'Agents run directly on the host with full env - not recommended.';

  @override
  String sandboxingEnabledDescription(String backend) {
    return 'All agent invocations route through $backend.';
  }

  @override
  String get save => 'Save';

  @override
  String get saveChanges => 'Save changes';

  @override
  String get savedArticlesDescription => 'Articles you bookmarked.';

  @override
  String get savedLabel => 'Saved';

  @override
  String get savingChanges => 'Saving changes…';

  @override
  String get savingEllipsis => 'Saving…';

  @override
  String get scopeDiffToCommits =>
      'Scope diff to commits — Shift-click for range';

  @override
  String get searchAgents => 'Search agents';

  @override
  String get searchAuthors => 'Search authors…';

  @override
  String get searchPullRequestsHint => 'Search… e.g. author:@user';

  @override
  String get noPrsMatchSearch => 'No matching pull requests';

  @override
  String get noPrsMatchSearchHint =>
      'No open PRs match your search. Try different terms or clear the search.';

  @override
  String get searchAuthorsPlaceholder => 'Search authors…';

  @override
  String get searchFactsHint => 'Search facts...';

  @override
  String get searchFonts => 'Search fonts…';

  @override
  String get searchGifs => 'Search GIFs';

  @override
  String get searchGifsHint => 'Search GIFs...';

  @override
  String get searchInDiff => 'Search in diff';

  @override
  String get searchInDiffHint => 'Search in diff…';

  @override
  String get searchOrTypeModel => 'Search or type a model name…';

  @override
  String get searchPlaceholder => 'Search…';

  @override
  String get searchShortcuts => 'Search shortcuts…';

  @override
  String get searching => 'Searching…';

  @override
  String secondsAgo(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count seconds ago',
      one: '1 second ago',
    );
    return '$_temp0';
  }

  @override
  String get selectAdapter => 'Select adapter';

  @override
  String get selectAdapterFirst => 'Select an adapter first';

  @override
  String get selectAgentToReportTo => 'Select agent to report to…';

  @override
  String get selectAnAgent => 'Select an agent';

  @override
  String get selectConversation => 'Select a conversation';

  @override
  String get selectEffortLevel => 'Select effort level';

  @override
  String get selectLabel => 'Select';

  @override
  String get selectRunner => 'Select a runner';

  @override
  String get semanticSearch => 'Semantic search';

  @override
  String get send => 'Send';

  @override
  String get sendFirstMessage => 'Send the first message';

  @override
  String get sendMessage => 'Send message';

  @override
  String sentFindingsToAgent(int count) {
    return 'Sent $count finding(s) to agent.';
  }

  @override
  String get serverRunning => 'Server running';

  @override
  String get serverStopped => 'Server stopped';

  @override
  String setGithubLinkDescription(String name) {
    return 'Set the GitHub owner and repository name for $name. This is used to resolve PR and issue references like #123 in markdown content.';
  }

  @override
  String get setLabel => 'Set';

  @override
  String get setToken => 'Set token';

  @override
  String get settingsGeneralDescription =>
      'Appearance, typography, integrations, and MCP server.';

  @override
  String get settingsLabel => 'Settings';

  @override
  String get settingsLanguage => 'Language';

  @override
  String get settingsLanguageDescription => 'Choose the app language.';

  @override
  String get sharedSecretToken => 'Shared secret token';

  @override
  String get sharpshooterBadge => 'Sharpshooter';

  @override
  String get shortTask => 'Short task';

  @override
  String get showNativeNotifications =>
      'Show native macOS notifications for events.';

  @override
  String get showSuperseded => 'Show superseded';

  @override
  String get signInWithGhAuth =>
      'Sign in with gh auth login or add a token in Settings > API keys';

  @override
  String get signedIn => 'Signed in.';

  @override
  String signedInAs(String username) {
    return 'Signed in as $username.';
  }

  @override
  String get skillEditor => 'Skill editor';

  @override
  String get skillNameRequired => 'Skill name is required.';

  @override
  String skillSaved(String name) {
    return 'Skill \"$name\" saved.';
  }

  @override
  String get skills => 'Skills';

  @override
  String get skillsColon => 'Skills:';

  @override
  String get skillsCommaSeparated => 'Skills (comma separated)';

  @override
  String get skillsLabel => 'SKILLS';

  @override
  String get skipAcceptRisk => 'Skip — I accept the risk';

  @override
  String get skipForNow => 'Skip for now';

  @override
  String get skipSandboxing => 'Skip sandboxing';

  @override
  String get skipSandboxingDialogContent =>
      'Are you sure you want to skip sandboxing? This allows agents to execute code on your system without isolation.';

  @override
  String get somethingWentWrong => 'Something went wrong';

  @override
  String sourceCount(int count) {
    return '$count source';
  }

  @override
  String sourceCountPlural(int count) {
    return '$count sources';
  }

  @override
  String get sourceFacts => 'Source facts:';

  @override
  String get splitDiff => 'Split (side-by-side) diff';

  @override
  String get startDmWithAgent => 'Start DM with agent';

  @override
  String get startFresh => 'Start fresh';

  @override
  String get startLabel => 'Start';

  @override
  String get startOnAppLaunch => 'Start on app launch';

  @override
  String get startServerToAccept =>
      'Start the server to accept MCP connections.';

  @override
  String get stats => 'Stats';

  @override
  String get statusLabel => 'Status';

  @override
  String stepConnect(int number) {
    return 'Step $number · Connect';
  }

  @override
  String get stop => 'Stop';

  @override
  String get stopped => 'Stopped';

  @override
  String get streaks => 'Streaks';

  @override
  String get streaksLabel => 'Streaks';

  @override
  String get strictIdentityCheck => 'Strict identity check';

  @override
  String get success => 'Success';

  @override
  String get successLabel => 'Success';

  @override
  String get successLabelShort => 'Success';

  @override
  String get successRate => 'Success rate';

  @override
  String get suggestAChange => 'Suggest a change';

  @override
  String get suggestAChangeEllipsis => 'Suggest a change…';

  @override
  String get suggestLabel => 'SUGGEST';

  @override
  String get superseded => 'Superseded';

  @override
  String get synced => 'Synced';

  @override
  String get systemDefault => 'System default';

  @override
  String get systemFonts => 'System fonts';

  @override
  String get systemPrompt => 'System prompt';

  @override
  String get systemPromptLabel => 'System prompt';

  @override
  String get talkToControlCenter => 'Talk to Control Center.';

  @override
  String get tapBadgeDescription => 'Tap a badge to see how to level up';

  @override
  String get tapBadgeToLevelUp => 'Tap a badge to see how to level up';

  @override
  String get taskMentionSection => 'Task';

  @override
  String get testLabel => 'Test';

  @override
  String get theme => 'Theme';

  @override
  String get themeDark => 'Dark';

  @override
  String get themeLight => 'Light';

  @override
  String get themeSystem => 'System';

  @override
  String get thisCannotBeUndone => 'This cannot be undone.';

  @override
  String get thisConversation => 'This conversation';

  @override
  String get threadLabel => 'Thread';

  @override
  String get throughput => 'Throughput';

  @override
  String get ticketLabel => 'TICKET';

  @override
  String tierLabel(String tier) {
    return '$tier tier';
  }

  @override
  String get titleDescription => 'Description';

  @override
  String get titleLabel => 'Title';

  @override
  String get todayLabel => 'Today';

  @override
  String get toggleBookmark => 'Toggle bookmark';

  @override
  String get toggleTheme => 'Toggle theme';

  @override
  String get toggleWorkspaceSwitcher => 'Toggle workspace switcher';

  @override
  String get tokenConfigured => 'Configured — clients must present this token.';

  @override
  String get tokenConfiguredClients =>
      'Configured — clients must present this token.';

  @override
  String tokenName(String name) {
    return '$name Token';
  }

  @override
  String get topPerformerLabel => 'TOP PERFORMER';

  @override
  String get topPerformersDescription =>
      'Top performers, throughput, and workspace health.';

  @override
  String get topic => 'Topic';

  @override
  String get topicHint => 'e.g. Tech Stack, Design System';

  @override
  String get totalRuns => 'Total runs';

  @override
  String get totalRunsLabel => 'Total runs';

  @override
  String trackingParamsCount(int count) {
    return '$count tracking params';
  }

  @override
  String get typeCommandOrSearch => 'Type a command or search…';

  @override
  String get typography => 'Typography';

  @override
  String get unavailable => 'Unavailable';

  @override
  String get unexpectedError => 'An unexpected error occurred.';

  @override
  String get unifiedDiff => 'Unified diff';

  @override
  String get unknownAuthor => 'Unknown';

  @override
  String get unnamedAgent => 'Unnamed agent';

  @override
  String get updateKey => 'Update key';

  @override
  String get updateLabel => 'Update';

  @override
  String get updateToken => 'Update token';

  @override
  String updatedDaysAgo(int count) {
    return 'Updated ${count}d ago';
  }

  @override
  String updatedHoursAgo(int count) {
    return 'Updated ${count}h ago';
  }

  @override
  String get updatedJustNow => 'Updated just now';

  @override
  String updatedMinutesAgo(int count) {
    return 'Updated ${count}min ago';
  }

  @override
  String get useSandbox => 'Use sandbox';

  @override
  String get useWorkspaceDefault => 'Use workspace default';

  @override
  String get userAgent => 'User-Agent';

  @override
  String get userAgentDescription =>
      'Leave empty to use the default app User-Agent. Some sites block non-browser User-Agents.';

  @override
  String get usingSystemDefaultMicrophone =>
      'Using the system default microphone.';

  @override
  String get viewAll => 'View all';

  @override
  String get viewLabel => 'View';

  @override
  String get viewLog => 'View log';

  @override
  String get viewLogs => 'View logs';

  @override
  String voiceInstallFailed(String error) {
    return 'Install failed: $error';
  }

  @override
  String get voiceModelNotInstalled =>
      'Not installed. Downloads ~200 MB once; runs fully on-device.';

  @override
  String get voiceModelNotInstalledLabel => 'Voice model not installed.';

  @override
  String get voiceRedownloadBody =>
      'The existing model files will be deleted and the ~200 MB archive downloaded again. Voice transcription will be unavailable until the download completes.';

  @override
  String get voiceRemoveBody =>
      'Voice transcription will be disabled until you reinstall it. You can install it again at any time.';

  @override
  String get voiceTranscription => 'Voice transcription';

  @override
  String get weakIsolationDescription =>
      'Weak isolation - namespace boundary only, no kernel boundary.';

  @override
  String get whenOffNoDefaultRoute =>
      'When off, the sandbox boots without a default route.';

  @override
  String get whenOffServerStaysStopped =>
      'When off, the server stays stopped until you start it.';

  @override
  String get whisperBaseEn => 'Whisper base.en (sherpa-onnx)';

  @override
  String get whisperInstalled =>
      'Whisper base.en installed. Used by the composer mic button.';

  @override
  String workerLabel(int index) {
    return 'Worker $index';
  }

  @override
  String workersCount(int count) {
    return '$count workers';
  }

  @override
  String get workingMemory => 'Working memory';

  @override
  String get workspaceName => 'Workspace name';

  @override
  String get workspaceNotFound => 'Workspace not found';

  @override
  String get workspaceNotesScratchpad => 'Workspace notes & scratchpad';

  @override
  String get workspacePulse => 'Workspace pulse';

  @override
  String get workspaceScopedSkills =>
      'Workspace-scoped skill files attached to agents.';

  @override
  String workspaceTitle(String name) {
    return 'Workspace: $name';
  }

  @override
  String get workspaces => 'Workspaces';

  @override
  String get writeLabel => 'Write';

  @override
  String get writePrivateNotes => 'Write private notes, observations, plans...';

  @override
  String get writeSkillContent => 'Write your skill content here (Markdown)…';

  @override
  String get xp => 'XP';

  @override
  String yearsAgo(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count years ago',
      one: '1 year ago',
    );
    return '$_temp0';
  }

  @override
  String get yesterday => 'Yesterday';

  @override
  String get yourAchievements => 'Your achievements';

  @override
  String get focusModeStart => 'Start focus session';

  @override
  String get focusModeConfigTitle => 'Start focus session';

  @override
  String get focusModeGoalLabel => 'Goal';

  @override
  String get focusModeGoalHint => 'What are you working on?';

  @override
  String get focusModeDurationLabel => 'Duration';

  @override
  String get focusModeBlockNotifications => 'Block notifications';

  @override
  String get focusModeStartButton => 'Start';

  @override
  String get focusModeEndSession => 'End session';

  @override
  String get focusModeExpand => 'Expand app';

  @override
  String get focusModeFloat => 'Minimize to bar';

  @override
  String get focusModeActiveTooltip => 'Focus mode active — tap to end';

  @override
  String get dismiss => 'Dismiss';

  @override
  String get acceptAndResolve => 'Accept & resolve';

  @override
  String reviewFatigueWarning(int minutes) {
    return 'You\'ve been reviewing for ${minutes}m — research suggests review quality can dip past 60 min. Consider a break.';
  }

  @override
  String get notificationSound => 'Notification sound';

  @override
  String get notificationSoundDescription =>
      'Sound played when a notification is shown.';

  @override
  String get notificationSoundNone => 'None';

  @override
  String get notificationSoundPing => 'Ping';

  @override
  String get notificationSoundChime => 'Chime';

  @override
  String get notificationSoundPop => 'Pop';

  @override
  String get notificationSoundDing => 'Ding';

  @override
  String get notificationSoundWhoosh => 'Whoosh';

  @override
  String get notificationSoundMigrosSoft => 'Migros (soft)';

  @override
  String get notificationSoundMigrosHard => 'Migros (hard)';

  @override
  String get notificationSoundSbb => 'SBB';

  @override
  String get notificationSoundCff => 'CFF';

  @override
  String get notificationSoundFfs => 'FFS';

  @override
  String get notificationSoundPost => 'Post';

  @override
  String get notificationSoundTest => 'Test';

  @override
  String get notificationVolume => 'Volume';

  @override
  String get viewProfile => 'View profile';

  @override
  String get clearAllFilters => '× Clear all';

  @override
  String acrossNRepos(num count) {
    final intl.NumberFormat countNumberFormat = intl.NumberFormat.compact(
      locale: localeName,
    );
    final String countString = countNumberFormat.format(count);

    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Across $countString repos',
      one: 'Across 1 repo',
    );
    return '$_temp0';
  }

  @override
  String get pullRequestsLabel => 'PRs';

  @override
  String noPrsByUserInWorkspace(String login) {
    return 'No PRs by @$login in this workspace';
  }

  @override
  String get usersLabel => 'Users';

  @override
  String get mergePullRequest => 'Merge pull request';

  @override
  String get forceMergePullRequest => 'Force merge pull request';

  @override
  String get closePullRequest => 'Close pull request';

  @override
  String get closePullRequestConfirm =>
      'Are you sure you want to close this pull request?';

  @override
  String get squashAndMerge => 'Squash and merge';

  @override
  String get createMergeCommit => 'Create a merge commit';

  @override
  String get rebaseAndMerge => 'Rebase and merge';

  @override
  String get commitTitle => 'Commit title';

  @override
  String get commitDescription => 'Commit description';

  @override
  String get pullRequestMerged => 'Pull request merged';

  @override
  String get pullRequestClosed => 'Pull request closed';

  @override
  String failedToMergePr(String error) {
    return 'Failed to merge: $error';
  }

  @override
  String failedToClosePr(String error) {
    return 'Failed to close: $error';
  }

  @override
  String get checksFailing => 'Checks failing';

  @override
  String get reviewsPending => 'Some reviews are pending';

  @override
  String get confirm => 'Confirm';

  @override
  String get trustedSitesSectionTitle => 'Trusted sites';

  @override
  String get trustedSitesEmpty =>
      'No trusted sites. Add a domain to disable blocking on it.';

  @override
  String get addTrustedSite => 'Add trusted site';

  @override
  String get removeTrustedSite => 'Remove';

  @override
  String get disableBlockingForThisSite => 'Disable blocking on this site';

  @override
  String get enableBlockingForThisSite => 'Enable blocking on this site';

  @override
  String get enterDomainHint => 'e.g. example.com';

  @override
  String get invalidDomain => 'Enter a valid domain (e.g. example.com)';

  @override
  String get pageLoadTimedOut =>
      'Page load timed out. Reload or open in browser.';

  @override
  String get pipelinesScreenTitle => 'Pipelines';

  @override
  String get pipelinesScreenSubtitle =>
      'Declarative multi-step agent workflows';

  @override
  String get pipelinesRunHello => 'Run hello pipeline';

  @override
  String get pipelinesRunPipeline => 'Run pipeline';

  @override
  String get pipelineRunLauncherTitle => 'Run pipeline';

  @override
  String get pipelineRunSubtitle =>
      'Pick a pipeline and fill in its inputs to start a run.';

  @override
  String get pipelineRunNoInputsBadge => 'No inputs';

  @override
  String pipelineRunInputsCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count inputs',
      one: '1 input',
    );
    return '$_temp0';
  }

  @override
  String get pipelineRunNoInputs => 'This pipeline takes no inputs.';

  @override
  String get pipelineRunSubmit => 'Run pipeline';

  @override
  String get pipelineRunCouldNotStart => 'Could not start the run.';

  @override
  String pipelineRunStarted(String name) {
    return 'Started $name';
  }

  @override
  String get pipelineRunEmptyTitle => 'No pipelines ready to run';

  @override
  String get pipelineRunEmptyHint =>
      'Enable a pipeline and turn on manual run in its editor to launch it here.';

  @override
  String get pipelineRunManageTemplates => 'Manage pipelines';

  @override
  String get pipelineRunSettingsTitle => 'Manual run';

  @override
  String get pipelineRunSettingsAllow => 'Allow manual run';

  @override
  String get pipelineRunSettingsAllowHelp =>
      'Show this pipeline on the run page so it can be started by hand.';

  @override
  String get pipelineRunSettingsInputsTitle => 'Inputs';

  @override
  String get pipelineRunSettingsAddInput => 'Add input';

  @override
  String get pipelineRunSettingsNoInputs => 'No inputs yet.';

  @override
  String get pipelineInputEditTitle => 'Input field';

  @override
  String get pipelineInputKeyLabel => 'Key';

  @override
  String get pipelineInputKeyHelp =>
      'State key the value is stored under (e.g. repoFullName).';

  @override
  String get pipelineInputLabelLabel => 'Label';

  @override
  String get pipelineInputTypeLabel => 'Type';

  @override
  String get pipelineInputOptionsLabel => 'Options (comma-separated)';

  @override
  String get pipelineInputDefaultLabel => 'Default value';

  @override
  String get pipelineInputPlaceholderLabel => 'Placeholder';

  @override
  String get pipelineInputHelpLabel => 'Help text';

  @override
  String get pipelineInputRequiredLabel => 'Required';

  @override
  String get pipelineInputTypeText => 'Text';

  @override
  String get pipelineInputTypeMultiline => 'Multi-line text';

  @override
  String get pipelineInputTypeNumber => 'Number';

  @override
  String get pipelineInputTypeBoolean => 'Toggle';

  @override
  String get pipelineInputTypeSelect => 'Select';

  @override
  String get pipelinesEmpty => 'No pipeline runs yet';

  @override
  String get pipelinesEmptyHint => 'Click \'Run pipeline\' to start one.';

  @override
  String get pipelinesSelectRun => 'Select a pipeline run to view steps';

  @override
  String get pipelinesNoSteps => 'No steps recorded yet';

  @override
  String get pipelinesNoActiveWorkspace =>
      'Select a workspace to view its pipelines';

  @override
  String pipelinesLoadError(String error) {
    return 'Failed to load pipelines: $error';
  }

  @override
  String pipelinesRunFailed(String error) {
    return 'Failed to start pipeline: $error';
  }

  @override
  String get pipelineStatusPending => 'Pending';

  @override
  String get pipelineStatusRunning => 'Running';

  @override
  String get pipelineStatusSuspended => 'Suspended';

  @override
  String get pipelineStatusCompleted => 'Completed';

  @override
  String get pipelineStatusFailed => 'Failed';

  @override
  String get pipelineStatusCancelled => 'Cancelled';

  @override
  String get pipelineStatusSkipped => 'Skipped';

  @override
  String pipelineRunDuration(int seconds) {
    return '${seconds}s';
  }

  @override
  String pipelineStepDuration(int seconds) {
    return '${seconds}s';
  }

  @override
  String pipelineRunStepProgress(int completed, int total) {
    return '$completed of $total steps';
  }

  @override
  String get pipelineStepStarted => 'Started';

  @override
  String get pipelineStepFinished => 'Finished';

  @override
  String get pipelineStepDurationLabel => 'Duration';

  @override
  String get pipelineStepBranch => 'Branch';

  @override
  String get pipelineStepError => 'Error';

  @override
  String get pipelineStepInput => 'Input';

  @override
  String get pipelineStepOutput => 'Output';

  @override
  String get pipelineStepNotExecuted => 'Not yet executed';

  @override
  String get pipelineRunViewTimeline => 'Timeline';

  @override
  String get pipelineRunViewGraph => 'Graph';

  @override
  String pipelineRunFailedAtStep(String step) {
    return 'Failed at $step';
  }

  @override
  String get pipelineRunTriggerManual => 'Manual';

  @override
  String get pipelineRunTriggerAuto => 'Automatic';

  @override
  String get pipelineStepSkippedReason => 'Skipped';

  @override
  String get pipelineRunFilterAll => 'All';

  @override
  String get pipelineRunFilterEmpty => 'No runs match this filter';

  @override
  String get relativeJustNow => 'just now';

  @override
  String relativeMinutesAgo(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count min ago',
      one: '1 min ago',
    );
    return '$_temp0';
  }

  @override
  String relativeHoursAgo(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count hours ago',
      one: '1 hour ago',
    );
    return '$_temp0';
  }

  @override
  String relativeDaysAgo(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count days ago',
      one: '1 day ago',
    );
    return '$_temp0';
  }

  @override
  String get automationsTitle => 'Automations';

  @override
  String get automationsSubtitle =>
      'Auto-start pipelines when domain events fire';

  @override
  String get automationsNoTriggers => 'No triggers configured for this event.';

  @override
  String get automationsAddTrigger => 'Add trigger';

  @override
  String get tasksTitle => 'Tasks';

  @override
  String get taskStatusPending => 'Pending';

  @override
  String get taskStatusInProgress => 'In progress';

  @override
  String get taskStatusCompleted => 'Completed';

  @override
  String get taskStatusFailed => 'Failed';

  @override
  String get taskStatusCancelled => 'Cancelled';

  @override
  String get tasksNoTasks => 'No tickets';

  @override
  String get teamsTitle => 'Teams';

  @override
  String get teamsNoTeams => 'No teams configured';

  @override
  String get teamsAddTeam => 'Add team';

  @override
  String get pipelineRunTitle => 'Pipeline run';

  @override
  String get pipelineNotFound => 'Pipeline run not found';

  @override
  String get pipelineTemplatesNav => 'Pipeline templates';

  @override
  String get pipelineTemplatesTitle => 'Pipeline templates';

  @override
  String get pipelineTemplatesSubtitle =>
      'Drag-and-drop editor for the pipelines that orchestrate your agents.';

  @override
  String get pipelineTemplatesNew => 'New template';

  @override
  String get pipelineTemplatesEmpty =>
      'No pipeline templates yet. Create one to get started.';

  @override
  String get pipelineTemplateIdLabel => 'Template ID';

  @override
  String get pipelineTemplateBuiltInBadge => 'Built-in';

  @override
  String get pipelineTemplateDeleteConfirmTitle => 'Delete template?';

  @override
  String pipelineTemplateDeleteConfirmBody(String name) {
    return 'Delete pipeline template $name? This cannot be undone.';
  }

  @override
  String get pipelineTemplateSaved => 'Pipeline template saved';

  @override
  String get pipelineTemplateEditorTitle => 'Edit pipeline';

  @override
  String get pipelineTemplateEditorSubtitle =>
      'Drag node types from the sidebar onto the canvas, then wire them together.';

  @override
  String get unsavedChanges => 'Unsaved changes';

  @override
  String get nodeLibraryTitle => 'Node library';

  @override
  String get nodeLibraryHint => 'Drag any entry onto the canvas to add a node.';

  @override
  String get editorDragHint => 'Drag from the library, click a node to edit';

  @override
  String get editorEmptyCanvas => 'Drag a node from the library to start.';

  @override
  String get nodeConfigTitle => 'Node config';

  @override
  String get nodeConfigKind => 'Kind';

  @override
  String get nodeConfigLabel => 'Label';

  @override
  String get nodeConfigAgent => 'Agent';

  @override
  String get nodeConfigAgentHint => 'Pick an agent…';

  @override
  String get nodeConfigInputKeys => 'Input keys (comma-separated)';

  @override
  String get nodeConfigInputKeysHelp =>
      'State keys this node consumes. Used for placeholder substitution in the prompt.';

  @override
  String get nodeConfigOutputKey => 'Output key';

  @override
  String get nodeConfigPrompt => 'Prompt template';

  @override
  String get nodeConfigPromptHelp =>
      'Use double-brace placeholders to pull values from state at runtime.';

  @override
  String get nodeConfigScript => 'Bash script';

  @override
  String get nodeConfigScriptHelp =>
      'Runs with bash -c. GITHUB_TOKEN is set. Placeholders are substituted before execution.';

  @override
  String get nodeConfigTriggers => 'Triggers from';

  @override
  String get nodeConfigNoUpstream => 'No other nodes to connect from.';

  @override
  String get nodeConfigRouteKeys => 'Route keys';

  @override
  String nodeConfigRouteKeyFrom(String source) {
    return 'Route key from $source';
  }

  @override
  String get conditionSectionTitle => 'Condition';

  @override
  String get conditionMode => 'Mode';

  @override
  String get conditionModeFilesAny => 'File(s) exist — any';

  @override
  String get conditionModeFilesAll => 'Files exist — all';

  @override
  String get conditionModeComparison => 'Comparison';

  @override
  String get conditionModeSwitch => 'Switch';

  @override
  String get conditionFilePaths => 'File paths';

  @override
  String get conditionFilePathsAnyHelp =>
      'One path per line, relative to the base directory. Routes true when any exists.';

  @override
  String get conditionFilePathsAllHelp =>
      'One path per line, relative to the base directory. Routes true only when all exist.';

  @override
  String get conditionBaseKey => 'Base directory key';

  @override
  String get conditionBaseKeyHelp =>
      'State key holding the directory paths resolve against (default repoLocalPath).';

  @override
  String get conditionRecursive => 'Search subdirectories';

  @override
  String get conditionNegate => 'Invert: route true when missing';

  @override
  String get conditionLeft => 'Left value';

  @override
  String get conditionOperator => 'Operator';

  @override
  String get conditionRight => 'Right value';

  @override
  String get conditionSwitchKey => 'Switch on state key';

  @override
  String get conditionCases => 'Cases (comma-separated)';

  @override
  String get conditionCasesHelp =>
      'Route keys to match against the value, in order.';

  @override
  String get conditionDefaultCase => 'Default case';

  @override
  String get triggerPanelTitle => 'Triggers';

  @override
  String get triggerPanelHelp => 'What starts this pipeline.';

  @override
  String get triggerManualHelp => 'Show on the run page and start by hand.';

  @override
  String get triggerSectionAutomatic => 'Automatic triggers';

  @override
  String get triggerAddButton => 'Add trigger';

  @override
  String get triggerNoneYet => 'No automatic triggers yet.';

  @override
  String get triggerAddDialogTitle => 'Add trigger';

  @override
  String get triggerKindLabel => 'Trigger type';

  @override
  String get triggerKindEvent => 'On an event';

  @override
  String get triggerKindSchedule => 'On a schedule';

  @override
  String get triggerIntervalLabel => 'Run every (seconds)';

  @override
  String get triggerEventFieldLabel => 'Event';

  @override
  String get triggerNoMoreEvents => 'All available events are already wired.';

  @override
  String get triggerMatchStatusLabel => 'Only when the status is';

  @override
  String get triggerSummaryNone => 'No triggers';

  @override
  String triggerEverySeconds(int seconds) {
    return 'Every ${seconds}s';
  }

  @override
  String get triggerEventManual => 'Manual run';

  @override
  String get triggerEventSchedule => 'Schedule';

  @override
  String get triggerEventPrStatusChanged => 'PR status changed';

  @override
  String get triggerEventExternalPr => 'External PR opened';

  @override
  String get triggerEventPrPublished => 'PR published';

  @override
  String get triggerEventPrMerged => 'PR merged';

  @override
  String get triggerEventRepoAdded => 'Repository added';

  @override
  String get triggerEventMessageReceived => 'Message received';

  @override
  String get triggerEventTicketCompleted => 'Ticket completed';

  @override
  String get triggerEventTicketFailed => 'Ticket failed';

  @override
  String get triggerEventBudgetCrossed => 'Budget threshold crossed';

  @override
  String get automationsManagedHint =>
      'Triggers are configured per pipeline in its editor. Toggle them on or off here.';

  @override
  String get automationsEditInPipeline => 'Edit in pipeline';

  @override
  String get nodeLibrarySearchHint => 'Search nodes';

  @override
  String get nodeLibraryNoMatches => 'No matching nodes';

  @override
  String get nodeCategoryFlow => 'Flow & logic';

  @override
  String get nodeCategoryPr => 'PR review';

  @override
  String get nodeCategoryAgents => 'Agents';

  @override
  String get nodeCategoryMessaging => 'Messaging';

  @override
  String get nodeCategoryCode => 'Code';

  @override
  String get nodeCategoryDemo => 'Demo';

  @override
  String get triggerDisabledTag => 'off';

  @override
  String get pipelineInputTypeRepo => 'Repository';

  @override
  String get pipelineRunNoRepos => 'No repositories in this workspace yet.';

  @override
  String get allowTicketingApi => 'Allow ticketing API calls';

  @override
  String get ticketingApiKey => 'Ticketing API key';

  @override
  String get ticketingApiKeySubtitle =>
      'Injects the ticketing provider API key into the sandbox.';

  @override
  String get ticketingProvider => 'Ticketing provider';

  @override
  String get connectGitHubAndTicketing =>
      'Connect GitHub so Control Center can read your pull requests, issues, and reviews. Optionally connect a ticketing provider. Nothing leaves this machine.';

  @override
  String get triggerEventTicketAssigned => 'Ticket assigned';

  @override
  String get navTickets => 'Tickets';

  @override
  String get ticketsTitle => 'Tickets';

  @override
  String get newTicket => 'New ticket';

  @override
  String get noTicketsYet => 'No tickets yet';

  @override
  String get assignTicket => 'Assign ticket';

  @override
  String get addCollaborator => 'Add collaborator';

  @override
  String get noCollaborators => 'No collaborators yet';

  @override
  String get linkedPullRequests => 'Linked pull requests';

  @override
  String get noLinkedPullRequests => 'No linked pull requests yet';

  @override
  String get ticketActivity => 'Activity';

  @override
  String get ticketDispatchHint => '@mention an agent to dispatch them…';

  @override
  String get stopAgent => 'Stop agent';

  @override
  String get removeQueuedMessage => 'Remove queued message';

  @override
  String get ticketProperties => 'Properties';

  @override
  String get ticketTabIssue => 'Issue';

  @override
  String get ticketTabActivity => 'Activity';

  @override
  String get ticketTabChanges => 'Changes';

  @override
  String get ticketTabTerminal => 'Terminal';

  @override
  String get ticketSelectPrompt => 'Select a ticket to view its details';

  @override
  String get ticketNoChanges => 'No changes in the linked repositories yet';

  @override
  String get ticketTerminalNoAgent => 'Assign an agent to open a terminal';

  @override
  String get unassigned => 'Unassigned';

  @override
  String get ticketStatusBacklog => 'Backlog';

  @override
  String get ticketStatusOpen => 'To do';

  @override
  String get ticketStatusInProgress => 'In progress';

  @override
  String get ticketStatusInReview => 'In review';

  @override
  String get ticketStatusDone => 'Done';

  @override
  String get ticketStatusBlocked => 'Blocked';

  @override
  String get ticketStatusFailed => 'Failed';

  @override
  String get ticketStatusCancelled => 'Cancelled';

  @override
  String get notificationTicketAssigned => 'Ticket assigned';

  @override
  String get notificationTicketStatusChanged => 'Ticket status changed';

  @override
  String get notificationTicketCollaboratorAdded => 'Collaborator added';

  @override
  String get priority => 'Priority';

  @override
  String get status => 'Status';

  @override
  String get assignee => 'Assignee';

  @override
  String get ticketDescription => 'Description';

  @override
  String get ticketPriorityNone => 'None';

  @override
  String get ticketPriorityUrgent => 'Urgent';

  @override
  String get ticketPriorityHigh => 'High';

  @override
  String get ticketPriorityMedium => 'Medium';

  @override
  String get ticketPriorityLow => 'Low';

  @override
  String get ticketViewList => 'List';

  @override
  String get ticketViewBoard => 'Board';

  @override
  String get ticketTitlePlaceholder => 'Issue title';

  @override
  String get ticketDescriptionPlaceholder => 'Add description…';

  @override
  String get createMore => 'Create more';

  @override
  String selectedCount(int count) {
    return '$count selected';
  }

  @override
  String get clearSelection => 'Clear selection';

  @override
  String get bulkDeleteTitle => 'Delete tickets';

  @override
  String bulkDeleteMessage(int count) {
    return 'Delete $count selected tickets? This can\'t be undone.';
  }

  @override
  String get assignTo => 'Assign to…';

  @override
  String get sectionMembers => 'Members';

  @override
  String get sectionAgents => 'Agents';

  @override
  String get sidebarGroupWork => 'Work';

  @override
  String get sidebarGroupTeam => 'Team';

  @override
  String get notificationsTitle => 'Notifications';

  @override
  String get notificationsTooltip => 'Notifications';

  @override
  String get notificationsEmpty => 'You\'re all caught up';

  @override
  String get markAllRead => 'Mark all as read';

  @override
  String get toggleThemeLabel => 'Toggle theme';

  @override
  String get teamsNav => 'Teams';

  @override
  String get dashboardGreeting => 'Grüezi';

  @override
  String get dashboardSubtitle => 'Here\'s what your agents are working on.';

  @override
  String get recentActivityTitle => 'Recent activity';

  @override
  String get noRecentActivity => 'No recent activity yet';

  @override
  String get noRecentActivitySubtitle =>
      'Agent runs, pull requests, and messages will appear here.';

  @override
  String get noWorkspace => 'No workspace';

  @override
  String get allAgentsIdle => 'All agents idle';

  @override
  String get statWorkspaces => 'Workspaces';

  @override
  String get statAgents => 'Agents';

  @override
  String get statRunning => 'Running';

  @override
  String get activeAgentsTitle => 'Active agents';

  @override
  String get noAgentProcessesSubtitle =>
      'Agent activity will appear here when a run starts.';

  @override
  String agentIdShort(String id) {
    return 'ID $id';
  }

  @override
  String runningProcessesLabel(int count) {
    return 'Running · $count';
  }

  @override
  String get noneLabel => 'None';

  @override
  String get sidebarGroupKnowledge => 'Knowledge';

  @override
  String get navMemory => 'Memory';

  @override
  String get memoryTabFacts => 'Facts';

  @override
  String get memoryTabPolicies => 'Policies';

  @override
  String get memoryTabGraph => 'Knowledge graph';

  @override
  String get memoryNoWorkspace => 'Select a workspace to view its memory.';

  @override
  String get topStory => 'Top story';

  @override
  String get searchArticles => 'Search articles';

  @override
  String get filterAll => 'All';

  @override
  String get filterUnread => 'Unread';

  @override
  String get filterSaved => 'Saved';

  @override
  String get saveArticle => 'Save article';

  @override
  String get removeFromSaved => 'Remove from saved';

  @override
  String get filterBySource => 'Filter by source';

  @override
  String get viewAsList => 'List view';

  @override
  String get viewAsGrid => 'Grid view';

  @override
  String get noMatchingArticles => 'No matching articles';

  @override
  String get noMatchingArticlesBody =>
      'Try a different search or source filter.';

  @override
  String get allCaughtUp => 'All caught up';

  @override
  String get allCaughtUpBody => 'No unread articles — check back later.';

  @override
  String get openArticlesInAppDescription =>
      'Open links in the built-in reader instead of your default browser.';

  @override
  String get blockAdsTrackersDescription =>
      'Strip ads, trackers and cookie banners from articles you open in the reader.';

  @override
  String get agentQuestionHeader => 'Question for you';

  @override
  String get agentQuestionAnsweredLabel => 'Answered';

  @override
  String get agentQuestionSubmit => 'Submit answer';

  @override
  String get agentQuestionFreeformHint => 'Type your answer…';

  @override
  String get agentQuestionAnswerLabel => 'Your answer';

  @override
  String get reviewRequested => 'Review requested';

  @override
  String get loadMorePrs => 'Load more';

  @override
  String get loadingMorePrs => 'Loading more…';

  @override
  String get noPrsMatchFilters =>
      'No pull requests match the filters in this repo';

  @override
  String get connectGitHubToLoadPrs => 'Connect GitHub to load pull requests';

  @override
  String get noRepositoriesConfigured => 'No repositories configured';

  @override
  String get noAuthors => 'No authors';

  @override
  String get noAuthorMatches => 'No matches';

  @override
  String openedAgo(String age) {
    return 'Opened $age';
  }

  @override
  String updatedAgo(String age) {
    return 'Updated $age';
  }

  @override
  String get checksPassing => 'Checks passing';

  @override
  String get checksRunning => 'Checks running';

  @override
  String get needsYourReview => 'Needs your review';

  @override
  String diffSummary(int additions, int deletions) {
    return '+$additions −$deletions lines';
  }

  @override
  String get checks => 'Checks';

  @override
  String get noReviewersAssigned => 'No reviewers assigned';

  @override
  String get noAssignees => 'No assignees';

  @override
  String get noChecksYet => 'No checks have run yet';

  @override
  String checksFailingCount(int count) {
    return '$count failing';
  }

  @override
  String get showMore => 'Show more';

  @override
  String get showLess => 'Show less';

  @override
  String get backToPullRequests => 'Back to pull requests';

  @override
  String get pullRequestNotFound => 'Pull request not found';

  @override
  String get pullRequestNotFoundBody =>
      'It may have been merged, closed, or moved.';

  @override
  String get couldntLoadPullRequest => 'Couldn\'t load this pull request';

  @override
  String get showDetails => 'Show details';

  @override
  String loadingPullRequestNumber(int number) {
    return 'Loading pull request #$number…';
  }

  @override
  String get noDescriptionProvided => 'No description provided.';

  @override
  String get factsHint => 'Facts will appear here as your agents learn.';

  @override
  String get noFactsMatch => 'No facts match your search';

  @override
  String get memoryLoadError => 'Couldn\'t load memory';

  @override
  String get sortRecent => 'Recent';

  @override
  String get sortConfidence => 'Confidence';

  @override
  String get confidenceTooltip =>
      'How sure agents are that this fact is true, from 0 to 100%.';

  @override
  String get supersededTooltip => 'A newer fact has replaced this one.';

  @override
  String get domain => 'Domain';

  @override
  String get fitToView => 'Fit to view';

  @override
  String get project => 'Project';

  @override
  String get projects => 'Projects';

  @override
  String get newProject => 'New project';

  @override
  String get editProject => 'Edit project';

  @override
  String get deleteProject => 'Delete project';

  @override
  String get noProject => 'No project';

  @override
  String get allTickets => 'All tickets';

  @override
  String get projectNamePlaceholder => 'Project name';

  @override
  String get projectDescriptionPlaceholder => 'Description (optional)';

  @override
  String get projectColorLabel => 'Color';

  @override
  String get noProjectsYet => 'No projects yet';

  @override
  String get projectTicketsEmpty => 'No tickets in this project yet';

  @override
  String get createProject => 'Create project';

  @override
  String projectProgress(int done, int total) {
    return '$done of $total done';
  }

  @override
  String deleteProjectConfirm(String name) {
    return 'Delete \"$name\"? Its tickets are kept and removed from the project.';
  }

  @override
  String get projectStatusActive => 'Active';

  @override
  String get projectStatusCompleted => 'Completed';

  @override
  String get projectStatusArchived => 'Archived';

  @override
  String get markProjectCompleted => 'Mark completed';

  @override
  String get markProjectActive => 'Mark active';

  @override
  String get archiveProject => 'Archive';

  @override
  String get restoreProject => 'Restore';

  @override
  String get relations => 'Relations';

  @override
  String get relateTo => 'Relate to';

  @override
  String get relationSubIssueOf => 'Sub-issue of…';

  @override
  String get relationParentOf => 'Parent of…';

  @override
  String get relationBlockedBy => 'Blocked by…';

  @override
  String get relationBlocking => 'Blocking…';

  @override
  String get relationRelatedTo => 'Related to…';

  @override
  String get relationDuplicateOf => 'Duplicate of…';

  @override
  String get relationGroupParent => 'Parent';

  @override
  String get relationGroupSubIssues => 'Sub-issues';

  @override
  String get relationGroupBlockedBy => 'Blocked by';

  @override
  String get relationGroupBlocking => 'Blocking';

  @override
  String get relationGroupRelated => 'Related';

  @override
  String get relationGroupDuplicateOf => 'Duplicate of';

  @override
  String get relationGroupDuplicatedBy => 'Duplicated by';

  @override
  String get copyId => 'Copy ID';

  @override
  String get ticketIdCopied => 'Copied ticket ID';

  @override
  String get selectTicket => 'Select a ticket';

  @override
  String get searchTicketsHint => 'Search tickets…';

  @override
  String get noMatchingTickets => 'No tickets match';

  @override
  String get addToProject => 'Add to project';

  @override
  String get activeFleet => 'Active fleet';

  @override
  String agentsCountLabel(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count agents',
      one: '1 agent',
    );
    return '$_temp0';
  }

  @override
  String get blockedStatus => 'Blocked';

  @override
  String get failedStatus => 'Failed';

  @override
  String get neverRunStatus => 'Never run';

  @override
  String get noActiveRun => 'No active run';

  @override
  String get allPullRequests => 'All pull requests';

  @override
  String get clearAll => 'Clear all';

  @override
  String get needsYouNow => 'Needs you now';

  @override
  String get pipelinesSectionTitle => 'Pipelines';

  @override
  String get allRuns => 'All runs';

  @override
  String get triage => 'Triage';

  @override
  String agentsRunningCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count agents running',
      one: '1 agent running',
    );
    return '$_temp0';
  }

  @override
  String blockedCountLabel(int count) {
    return '$count blocked';
  }

  @override
  String needsYouCountLabel(int count) {
    return '$count needs you';
  }

  @override
  String reviewSummary(int prs, int repos) {
    String _temp0 = intl.Intl.pluralLogic(
      prs,
      locale: localeName,
      other: '$prs PRs',
      one: '1 PR',
    );
    String _temp1 = intl.Intl.pluralLogic(
      repos,
      locale: localeName,
      other: '$repos repos',
      one: '1 repo',
    );
    return '$_temp0 awaiting your review across $_temp1';
  }

  @override
  String reviewsAwaitingYou(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count reviews',
      one: '1 review',
    );
    return '$_temp0 awaiting you';
  }

  @override
  String reviewsOverTwoDays(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count over 2 days old',
      one: '1 over 2 days old',
    );
    return '$_temp0';
  }

  @override
  String agentBlockedTitle(String name) {
    return '$name is blocked';
  }

  @override
  String get agentBlockedSubtitle => 'Waiting on your confirmation';

  @override
  String get pipelineFailedTitle => 'Pipeline failed';

  @override
  String prStaleTitle(String number) {
    return 'PR $number stale';
  }

  @override
  String get prStaleSubtitle => 'No recent activity';

  @override
  String get reviewRequestedBadge => 'Review requested';

  @override
  String get draftBadge => 'Draft';

  @override
  String get staleLabel => 'Stale';

  @override
  String stepsProgress(int done, int total) {
    return '$done of $total steps';
  }

  @override
  String get allCaughtUpSubtitle =>
      'No reviews, blocks, or failures need you right now.';

  @override
  String dashboardGreetingNamed(String name) {
    return 'Grüezi, $name';
  }

  @override
  String workspaceEyebrow(String name) {
    return '$name workspace';
  }

  @override
  String get pipelineTriggerNode => 'Trigger';

  @override
  String get priorityReviewsTooltip =>
      'Open PRs that request your review and have been waiting more than 24 hours.';

  @override
  String get workspaceSettings => 'Workspace settings';

  @override
  String get manageWorkspacesSubtitle =>
      'Rename a workspace and change its mark — pick one on the left to edit it.';

  @override
  String workspaceCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count workspaces',
      one: '1 workspace',
      zero: 'No workspaces',
    );
    return '$_temp0';
  }

  @override
  String workspaceReposAgents(int repos, int agents) {
    String _temp0 = intl.Intl.pluralLogic(
      repos,
      locale: localeName,
      other: '$repos repos',
      one: '1 repo',
      zero: 'No repos',
    );
    String _temp1 = intl.Intl.pluralLogic(
      agents,
      locale: localeName,
      other: '$agents agents',
      one: '1 agent',
      zero: '0 agents',
    );
    return '$_temp0 · $_temp1';
  }

  @override
  String get identity => 'Identity';

  @override
  String get uploadImage => 'Upload image';

  @override
  String get workspaceLogoHint =>
      'PNG, JPG or GIF up to 2 MB. Otherwise we\'ll use the workspace initial.';

  @override
  String get workspaceNameFieldHelp =>
      'Shown in the switcher, the breadcrumb and on every screen.';

  @override
  String get dangerZone => 'Danger zone';

  @override
  String get deleteThisWorkspace => 'Delete this workspace';

  @override
  String deleteWorkspaceLongDescription(String name) {
    return 'Permanently removes $name, its repository connections, agents and memory. This can\'t be undone.';
  }

  @override
  String get discard => 'Discard';

  @override
  String discardChangesQuestion(String name) {
    return 'Discard unsaved changes to $name?';
  }

  @override
  String get workspaceUpdated => 'Workspace updated';

  @override
  String get editTitle => 'Edit title';

  @override
  String get editDescription => 'Edit description';

  @override
  String get addDescription => 'Add a description';

  @override
  String get prTitlePlaceholder => 'Title';

  @override
  String get prBodyPlaceholder => 'Leave a description';

  @override
  String get write => 'Write';

  @override
  String get diff => 'Diff';

  @override
  String get preview => 'Preview';

  @override
  String get prTemplateLabel => 'Template';

  @override
  String get prTemplateDefault => 'Default';

  @override
  String get addReviewers => 'Add reviewers';

  @override
  String get addAssignees => 'Add assignees';

  @override
  String get searchUsers => 'Search people…';

  @override
  String get searchReviewers => 'Search people and teams…';

  @override
  String get usersSectionLabel => 'People';

  @override
  String get teamsSectionLabel => 'Teams';

  @override
  String get noMatchingUsers => 'No matching people';

  @override
  String get noMatchingReviewers => 'No matches';

  @override
  String addCount(int count) {
    return 'Add ($count)';
  }

  @override
  String get requiredByCodeOwners => 'Required by code owners';

  @override
  String reviewedOnBehalfOf(String login) {
    return 'via $login';
  }

  @override
  String get team => 'Team';

  @override
  String get markdownBold => 'Bold';

  @override
  String get markdownItalic => 'Italic';

  @override
  String get markdownHeading => 'Heading';

  @override
  String get markdownBulletList => 'Bulleted list';

  @override
  String get markdownChecklist => 'Checklist';

  @override
  String get markdownCode => 'Code';

  @override
  String get markdownLink => 'Link';

  @override
  String get markdownQuote => 'Quote';

  @override
  String failedToUpdateTitle(String error) {
    return 'Couldn\'t update title: $error';
  }

  @override
  String failedToUpdateDescription(String error) {
    return 'Couldn\'t update description: $error';
  }

  @override
  String failedToUpdateReviewers(String error) {
    return 'Couldn\'t update reviewers: $error';
  }

  @override
  String failedToUpdateAssignees(String error) {
    return 'Couldn\'t update assignees: $error';
  }

  @override
  String get discardChangesConfirm => 'Discard your changes?';

  @override
  String get newPr => 'New PR';

  @override
  String get openPullRequest => 'Open a pull request';

  @override
  String get composePrSubtitle =>
      'From a branch you\'ve pushed — no agents or tickets involved';

  @override
  String get createAsDraft => 'Create as draft';

  @override
  String get composePrNoRepo => 'No GitHub repository selected';

  @override
  String get composePrNoRepoHint =>
      'Select a workspace with a GitHub-linked repository to open a pull request.';

  @override
  String get composePrPickBranches =>
      'Pick a base and compare branch to preview the changes.';

  @override
  String get composePrNothingToCompare =>
      'There are no changes between these branches.';

  @override
  String get repository => 'Repository';

  @override
  String get baseBranchLabel => 'Base';

  @override
  String get compareBranchLabel => 'Compare';

  @override
  String get selectBranch => 'Select a branch';

  @override
  String get navMeetings => 'Meetings';

  @override
  String get meetingsNoWorkspace => 'Select a workspace to see meetings.';

  @override
  String get meetingsEmpty =>
      'No meetings yet. Start a recording to capture one.';

  @override
  String get meetingsStartRecording => 'Start recording';

  @override
  String get meetingsStopRecording => 'Stop recording';

  @override
  String get meetingsProcessing => 'Summarizing…';

  @override
  String get meetingEnhancedNotes => 'Enhanced notes';

  @override
  String get meetingYourNotes => 'Your notes';

  @override
  String get meetingNotesHint =>
      'Jot quick notes — the agent expands them after the meeting.';

  @override
  String get meetingTranscriptTitle => 'Transcript';

  @override
  String get meetingNoTranscriptYet =>
      'The transcript appears here as people speak.';

  @override
  String get meetingSpeakerMe => 'You';

  @override
  String get meetingSpeakerThem => 'Them';

  @override
  String get meetingStatusRecording => 'Recording';

  @override
  String get meetingStatusProcessing => 'Processing';

  @override
  String get meetingStatusDone => 'Done';

  @override
  String get meetingStatusFailed => 'Failed';

  @override
  String get keybindingGoToMeetings => 'Go to meetings';

  @override
  String get keybindingNavigateToTheMeetingsDescription =>
      'Navigate to the meetings list';

  @override
  String get meetingsOverlineKnowledge => 'Knowledge';

  @override
  String get meetingsOverlineEngine => 'On-device · Whisper base.en';

  @override
  String get meetingsSubtitle =>
      'Local meeting capture. We tap the meeting audio and your mic, transcribe on-device, and let an agent turn your sparse notes into decisions and action items — no bot ever joins the call.';

  @override
  String get meetingsRecordMeeting => 'Record meeting';

  @override
  String meetingsProcessingNow(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count processing now',
      one: '1 processing now',
    );
    return '$_temp0';
  }

  @override
  String get meetingsStatThisWeek => 'This week';

  @override
  String get meetingsStatThisWeekUnit => 'meetings captured';

  @override
  String get meetingsStatRecorded => 'Recorded';

  @override
  String get meetingsStatRecordedUnit => 'transcribed locally';

  @override
  String get meetingsStatOpen => 'Open';

  @override
  String get meetingsStatOpenUnit => 'action items pending';

  @override
  String get meetingsStatLogged => 'Logged';

  @override
  String get meetingsStatLoggedUnit => 'decisions extracted';

  @override
  String get meetingsCaptureTitle =>
      'Driver-free system-audio capture is armed.';

  @override
  String get meetingsCaptureBody =>
      'Control Center taps the speaker output of whatever app you are in — Slack Huddle, Meet, Zoom, Tuple — plus your microphone, and decodes both streams on this device.';

  @override
  String get meetingsCapturePermission => 'Permission granted';

  @override
  String get meetingsCaptureOnDevice => '100% on-device';

  @override
  String get meetingsCaptureNoBot => 'No bot joins';

  @override
  String get meetingsScopeAll => 'All meetings';

  @override
  String get meetingsFilterAll => 'All';

  @override
  String get meetingsFilterDone => 'Done';

  @override
  String get meetingsFilterProcessing => 'Processing';

  @override
  String get meetingsSearchHint => 'Filter by title, person, app…';

  @override
  String get meetingsBucketToday => 'Today';

  @override
  String get meetingsBucketYesterday => 'Yesterday';

  @override
  String get meetingsBucketEarlierThisWeek => 'Earlier this week';

  @override
  String get meetingsBucketLastWeek => 'Last week';

  @override
  String get meetingsBucketOlder => 'Older';

  @override
  String meetingsDecisionsCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count decisions',
      one: '1 decision',
    );
    return '$_temp0';
  }

  @override
  String meetingsActionItemsProgress(int done, int total) {
    return '$done / $total action items';
  }

  @override
  String get meetingsEnhancedPill => 'enhanced';

  @override
  String get meetingsTranscribing => 'transcribing & summarizing…';

  @override
  String get meetingsOpenAction => 'Open';

  @override
  String get meetingsStopProcessing => 'Stop';

  @override
  String get meetingsStillTranscribing =>
      'Still transcribing — the summary appears when it finishes.';

  @override
  String get meetingsNoMatch => 'No meetings match';

  @override
  String get meetingsNoMatchHint => 'Try a different filter or search term.';

  @override
  String get meetingBackAllMeetings => 'All meetings';

  @override
  String meetingPeopleCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count people',
      one: '1 person',
    );
    return '$_temp0';
  }

  @override
  String get meetingReRunSummary => 'Re-run summary';

  @override
  String get meetingExport => 'Export';

  @override
  String get meetingAugmentingBanner =>
      'Augmenting your notes from the transcript — extracting decisions and action items…';

  @override
  String get meetingTabNotes => 'Notes';

  @override
  String get meetingTabTranscript => 'Transcript';

  @override
  String get meetingTabActionItems => 'Action items';

  @override
  String get meetingTabDecisions => 'Decisions';

  @override
  String get meetingNotesEnhancedToggle => 'Enhanced';

  @override
  String get meetingNotesYoursToggle => 'Your notes';

  @override
  String get meetingEnhancedByAgent => 'Enhanced by agent · from transcript';

  @override
  String get meetingEnhancedPending =>
      'The agent is still working on this summary.';

  @override
  String get meetingNotesEmpty => 'No enhanced notes yet.';

  @override
  String get meetingNotesSavedLocally => 'Saved locally';

  @override
  String get meetingNotesSaving => 'Saving…';

  @override
  String get meetingViewFullTranscript => 'View full transcript';

  @override
  String get meetingTranscriptSearchHint => 'Search the transcript…';

  @override
  String get meetingSpeakerEveryone => 'Everyone';

  @override
  String get meetingSpeakerOthers => 'Others';

  @override
  String get meetingTranscriptEmpty => 'No transcript yet.';

  @override
  String get meetingActionItemsEmpty => 'No action items extracted.';

  @override
  String get meetingActionItemFrom => 'from this meeting';

  @override
  String get meetingCreateTicket => 'Create ticket';

  @override
  String meetingTicketCreated(String key) {
    return 'Ticket $key created and dispatched.';
  }

  @override
  String get meetingTicketFailed => 'Couldn\'t create the ticket.';

  @override
  String get meetingDecisionsEmpty => 'No decisions logged.';

  @override
  String get meetingReRunStarted =>
      'Re-running the summarizer on the transcript…';

  @override
  String get meetingReRunDone => 'Summary refreshed.';

  @override
  String get meetingReRunNoTranscript =>
      'There\'s no transcript to summarize yet.';

  @override
  String get meetingExportCopied =>
      'Notes copied to the clipboard as Markdown.';

  @override
  String get meetingExportNothing => 'There\'s nothing to export yet.';

  @override
  String get meetingsRecordingCrumb => 'Recording…';

  @override
  String get meetingRecordTitleHint => 'Meeting title';

  @override
  String get meetingRecordTappingLabel => 'Tapping:';

  @override
  String get meetingRecordMic => 'Mic';

  @override
  String get meetingRecordSystemAudio => 'System audio';

  @override
  String get meetingRecordPause => 'Pause';

  @override
  String get meetingRecordResume => 'Resume';

  @override
  String get meetingRecordStop => 'Stop & summarize';

  @override
  String get meetingRecordYourNotes => 'Your notes';

  @override
  String get meetingRecordNotesTagline =>
      'jot sparsely — the agent fills the rest';

  @override
  String get meetingRecordNotesPlaceholder =>
      'Type while you listen. A few fragments is enough — after you stop, the agent expands them using the transcript.';

  @override
  String get meetingRecordLiveTranscript => 'Live transcript';

  @override
  String get meetingRecordDecoding => 'decoding on-device';

  @override
  String get meetingRecordListening =>
      'Listening… speech appears here within a second or two, tagged You / Others.';

  @override
  String get meetingRecordPausedHint =>
      'Paused — audio is ignored until you resume.';

  @override
  String get meetingRecordNotActive => 'No active recording.';

  @override
  String get meetingHudRecording => 'recording';

  @override
  String get meetingHudPaused => 'paused';

  @override
  String get meetingHudOpen => 'Open';

  @override
  String get meetingHudStop => 'Stop';
}
