// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Dutch Flemish (`nl`).
class AppLocalizationsNl extends AppLocalizations {
  AppLocalizationsNl([String locale = 'nl']) : super(locale);

  @override
  String get navCalendar => 'Agenda';

  @override
  String get calendarViewMonth => 'Maand';

  @override
  String get calendarViewWeek => 'Week';

  @override
  String get calendarViewAgenda => 'Agenda';

  @override
  String get calendarConnectGoogle => 'Google Agenda verbinden';

  @override
  String get calendarConnectDescription =>
      'Synchroniseer je Google Agenda om afspraken hier te zien en meldingen te krijgen voordat vergaderingen beginnen.';

  @override
  String get calendarDisconnect => 'Verbinding verbreken';

  @override
  String get calendarReconnect => 'Opnieuw verbinden';

  @override
  String get calendarEmptyNoEvents => 'Geen afspraken in dit bereik';

  @override
  String get calendarStartRecording => 'Opname starten';

  @override
  String get calendarStartRecordingAndLink => 'Opnemen en koppelen';

  @override
  String get calendarJoinMeet => 'Deelnemen aan vergadering';

  @override
  String get calendarFromCalendar => 'Uit de agenda';

  @override
  String get calendarLinkedMeeting => 'Gekoppelde vergadering';

  @override
  String get calendarToday => 'Vandaag';

  @override
  String get calendarAllDay => 'Hele dag';

  @override
  String calendarWeekNumber(int number) {
    return 'Week $number';
  }

  @override
  String get calendarPreviousPeriod => 'Vorige';

  @override
  String get calendarNextPeriod => 'Volgende';

  @override
  String calendarLastSynced(String time) {
    return 'Gesynchroniseerd $time';
  }

  @override
  String get calendarNeverSynced => 'Nog niet gesynchroniseerd';

  @override
  String get calendarSyncing => 'Synchroniseren…';

  @override
  String get calendarViewDay => 'Dag';

  @override
  String get calendarSectionCalendars => 'Agenda\'s';

  @override
  String get calendarShow => 'Tonen';

  @override
  String get calendarHide => 'Verbergen';

  @override
  String get calendarRsvpGoing => 'Aanwezig?';

  @override
  String get calendarRsvpYes => 'Ja';

  @override
  String get calendarRsvpNo => 'Nee';

  @override
  String get calendarRsvpMaybe => 'Misschien';

  @override
  String get calendarRsvpFailed => 'Kon je reactie niet bijwerken';

  @override
  String get calendarAddAccount => 'Agenda-account toevoegen';

  @override
  String get calendarSettingsTitle => 'Google Agenda';

  @override
  String get calendarSettingsDescription =>
      'Verbind een Google-account om afspraken in deze werkruimte te synchroniseren.';

  @override
  String get calendarNotConnected => 'Geen Google-account verbonden';

  @override
  String get calendarConnecting => 'Verbinden…';

  @override
  String get calendarSyncNow => 'Nu synchroniseren';

  @override
  String get calendarNoWorkspace =>
      'Selecteer een werkruimte om de agenda te bekijken';

  @override
  String get calendarConnectError => 'Kan Google Agenda niet verbinden';

  @override
  String get notificationMeetingStartsSoon => 'Vergadering begint zo';

  @override
  String get notifyMeetingStartsSoon =>
      'Wanneer een afspraak in de agenda bijna begint';

  @override
  String get notificationCalendarAuthExpiredTitle => 'Agenda losgekoppeld';

  @override
  String notificationCalendarAuthExpiredBody(String email) {
    return 'Verbind $email opnieuw om het synchroniseren te hervatten';
  }

  @override
  String get notificationCalendarAuthExpiredBodyNoEmail =>
      'Verbind je agenda opnieuw om het synchroniseren te hervatten';

  @override
  String get notifyCalendarAuthExpired =>
      'Wanneer een agenda-account opnieuw moet worden verbonden';

  @override
  String get calendarAlertLeadTime => 'Voorlooptijd melding';

  @override
  String get calendarAlertLeadTimeSubtitle =>
      'Hoe lang voor een vergadering je een melding krijgt';

  @override
  String calendarConnectedAs(String email) {
    return 'Verbonden als $email';
  }

  @override
  String calendarAttendeesCount(int count) {
    return '$count deelnemers';
  }

  @override
  String get calendarEventLabel => 'Afspraak';

  @override
  String get calendarRecurring => 'Terugkerende afspraak';

  @override
  String get calendarGoogleMeet => 'Google Meet';

  @override
  String get calendarOrganizer => 'Organisator';

  @override
  String get calendarYou => 'Jij';

  @override
  String get calendarShowFewer => 'Minder tonen';

  @override
  String get calendarRsvpAwaiting => 'In afwachting';

  @override
  String calendarParticipantsCount(int count) {
    return '$count deelnemers';
  }

  @override
  String calendarSeeAllParticipants(int count) {
    return 'Alle $count deelnemers tonen';
  }

  @override
  String calendarRsvpCountYes(int count) {
    return '$count ja';
  }

  @override
  String calendarRsvpCountNo(int count) {
    return '$count nee';
  }

  @override
  String calendarRsvpCountMaybe(int count) {
    return '$count misschien';
  }

  @override
  String calendarRsvpCountAwaiting(int count) {
    return '$count in afwachting';
  }

  @override
  String calendarLeadMinutesOption(int count) {
    return '$count minuten';
  }

  @override
  String get openInEditorPrompt => 'In welke editor openen?';

  @override
  String get ideNotInstalled => 'Niet geïnstalleerd';

  @override
  String openInIde(String editor) {
    return 'Openen in $editor';
  }

  @override
  String failedToOpenInIde(String editor, String error) {
    return 'Kan $editor niet openen: $error';
  }

  @override
  String get profileSearchHint => 'Pull requests zoeken…';

  @override
  String get profileClickToLoad => 'Klik om te laden';

  @override
  String get profileStateOpenHint => 'Momenteel open';

  @override
  String get profileStateMergedHint => 'Samengevoegde geschiedenis';

  @override
  String get profileStateClosedHint => 'Gesloten, niet samengevoegd';

  @override
  String get profileNoPrsForFilter =>
      'Geen pull requests voor de geselecteerde statussen';

  @override
  String get byAuthorPrefix => 'door';

  @override
  String get youLabel => 'jij';

  @override
  String get readyToMerge => 'Klaar om te mergen';

  @override
  String get laneReadyHint => 'Checks groen';

  @override
  String get laneReviewHint => 'Wacht op jou';

  @override
  String get inProgress => 'Bezig';

  @override
  String get laneInProgressHint => 'Open · in bewerking';

  @override
  String get needsAttention => 'Vereist aandacht';

  @override
  String get laneAttentionHint => 'Mislukt of verouderd';

  @override
  String get drafts => 'Concepten';

  @override
  String get laneDraftsHint => 'Nog niet geopend';

  @override
  String get allOpenPrs => 'Alle open PR\'s';

  @override
  String showAllCount(int count) {
    return 'Alle tonen ($count)';
  }

  @override
  String get sortOldest => 'Oudste';

  @override
  String get sortLargest => 'Grootste';

  @override
  String get selectAction => 'Selecteren';

  @override
  String mergeCountReady(int count) {
    return '$count klaar mergen';
  }

  @override
  String countSelected(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count geselecteerd',
      one: '1 geselecteerd',
    );
    return '$_temp0';
  }

  @override
  String get mergeReadyAction => 'Klaar mergen';

  @override
  String get nothingInLane => 'Niets in deze baan';

  @override
  String get nothingInLaneHint =>
      'Kies hierboven een andere baan of toon alle open PR\'s.';

  @override
  String get summary => 'Samenvatting';

  @override
  String get openFullDiff => 'Volledige diff openen';

  @override
  String get viewFiles => 'Bestanden bekijken';

  @override
  String get checksLabel => 'Checks';

  @override
  String get commentsLabel => 'Reacties';

  @override
  String get mergeReadyConfirmTitle => 'Klaarstaande pull requests mergen?';

  @override
  String mergeReadyConfirmBody(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other:
          '$count klaarstaande PR\'s squash-mergen? Kan niet ongedaan worden gemaakt.',
      one: '1 klaarstaande PR squash-mergen? Kan niet ongedaan worden gemaakt.',
    );
    return '$_temp0';
  }

  @override
  String mergedCountPrs(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count PR\'s gemerged',
      one: '1 PR gemerged',
    );
    return '$_temp0';
  }

  @override
  String get keybindingSelectPr => 'PR selecteren';

  @override
  String get keybindingMergePr => 'PR mergen';

  @override
  String get keybindingPeekPr => 'PR-voorvertoning';

  @override
  String get keybindingToggleSelectionOfTheFocusedPullRequestDescription =>
      'Selectie van de gerichte PR omschakelen';

  @override
  String get keybindingMergeTheFocusedPullRequestDescription =>
      'De gerichte PR mergen als die klaar is';

  @override
  String get keybindingExpandOrCollapseTheFocusedPullRequestPeekDescription =>
      'Het voorvertoningspaneel van de gerichte PR uit- of inklappen';

  @override
  String get kbMove => 'verplaatsen';

  @override
  String get kbSelect => 'selecteren';

  @override
  String get kbMerge => 'mergen';

  @override
  String get kbOpen => 'openen';

  @override
  String get kbPeek => 'voorvertoning';

  @override
  String get kbTabs => 'tabbladen';

  @override
  String get kbSearch => 'zoeken';

  @override
  String get kbViewed => 'bekeken';

  @override
  String get kbCollapse => 'inklappen';

  @override
  String get appearance => 'Weergave';

  @override
  String get appearanceSettingsDescription => 'Thema, taal en typografie.';

  @override
  String get notificationsSettingsDescription =>
      'Kies welke agent- en werkruimtegebeurtenissen je een melding sturen.';

  @override
  String get integrationsSettingsDescription =>
      'Verbind GitHub, ticketing en de MCP-server.';

  @override
  String get advanced => 'Geavanceerd';

  @override
  String get advancedSettingsDescription =>
      'Branchnaamgeving, spraak, semantisch zoeken, privacy en logboekregistratie.';

  @override
  String get agentRegistry => 'Agentregister';

  @override
  String get settingsGroupGeneral => 'Algemeen';

  @override
  String get settingsGroupAgents => 'Agenten';

  @override
  String get settingsGroupResources => 'Bronnen';

  @override
  String get filterSettingsHint => 'Instellingen filteren';

  @override
  String get needsSetupLabel => 'Configuratie vereist';

  @override
  String noSettingsMatch(String query) {
    return 'Geen instelling komt overeen met \"$query\"';
  }

  @override
  String get privacy => 'Privacy';

  @override
  String get sendDiffContentTitle => 'Diff-inhoud naar AI-adapter sturen';

  @override
  String get diffSharingOnSubtitle =>
      'Ruwe diff-regels worden opgenomen in agentprompts voor een grondigere review.';

  @override
  String get diffSharingOffSubtitle =>
      'Agenten gebruiken alleen gestructureerde metadata (bestandspaden, regelnummers, PR-beschrijving); er verlaat geen ruwe code de app.';

  @override
  String get errorReportingTitle => 'Crashrapporten delen';

  @override
  String get errorReportingOnSubtitle =>
      'Crash-, fout- en prestatiediagnostiek wordt verzonden om bugs te helpen oplossen (alleen in release-builds).';

  @override
  String get errorReportingOffSubtitle =>
      'Diagnostiek is uitgeschakeld. Er worden geen crash- of foutrapporten verzonden.';

  @override
  String get onboardingDiagnosticsTitle => 'Help Control Center verbeteren';

  @override
  String get onboardingDiagnosticsSubtitle =>
      'Verzend crash-, fout- en prestatiediagnostiek zodat we problemen sneller kunnen oplossen (alleen in release-builds). Je kunt dit altijd wijzigen in Instellingen → Privacy.';

  @override
  String get blocked => 'Geblokkeerd';

  @override
  String get idle => 'Inactief';

  @override
  String get noRunsYet => 'Nog geen uitvoeringen';

  @override
  String runsInLastSixMonths(String count) {
    return '$count uitvoeringen in de afgelopen 6 maanden';
  }

  @override
  String lastActiveAgo(String duration) {
    return '$duration geleden actief';
  }

  @override
  String get reportsToNobody => 'Geen manager';

  @override
  String get copyPath => 'Pad kopiëren';

  @override
  String get pathCopied => 'Pad gekopieerd naar klembord';

  @override
  String get editAgent => 'Agent bewerken';

  @override
  String get nameRequired => 'Naam is verplicht';

  @override
  String get titleRequired => 'Titel is verplicht';

  @override
  String get import => 'Importeren';

  @override
  String discoverAgentsFound(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count agentdefinities gevonden',
      one: '1 agentdefinitie gevonden',
    );
    return '$_temp0';
  }

  @override
  String get noAgentsToDiscover => 'Geen nieuwe agenten om te importeren';

  @override
  String get noAgentsToDiscoverHint =>
      'Agentdefinities in deze werkruimte zijn al geïmporteerd.';

  @override
  String get sortByStatus => 'Status';

  @override
  String get sortByName => 'Naam';

  @override
  String get noMatchingAgents => 'Geen agenten komen overeen met je filter';

  @override
  String get selectAnAgentHint =>
      'Kies een agent om de status, activiteit en details te zien.';

  @override
  String watchVideoOn(String provider) {
    return 'Bekijk video op $provider';
  }

  @override
  String get branchTemplate => 'Sjabloon voor branchnaam';

  @override
  String get branchTemplateDescription =>
      'Patroon voor de branch die wordt aangemaakt wanneer een ticket in een geïsoleerde worktree wordt gestart.';

  @override
  String branchTemplatePreview(String example) {
    return 'Voorbeeld: $example';
  }

  @override
  String get deletePipelineRun => 'Pipelineuitvoering verwijderen';

  @override
  String deletePipelineRunConfirm(String template) {
    return 'Deze uitvoering van \"$template\" verwijderen? Dit kan niet ongedaan worden gemaakt.';
  }

  @override
  String errorDeletingPipelineRun(String error) {
    return 'Fout bij het verwijderen van de pipelineuitvoering: $error';
  }

  @override
  String get deleteTicket => 'Ticket verwijderen';

  @override
  String deleteTicketConfirm(String title) {
    return '\"$title\" verwijderen? Dit kan niet ongedaan worden gemaakt.';
  }

  @override
  String errorDeletingTicket(String error) {
    return 'Fout bij het verwijderen van het ticket: $error';
  }

  @override
  String deleteWorkspaceConfirm(String name) {
    return '\"$name\" verwijderen? Gekoppelde repository\'s op schijf blijven onaangeroerd.';
  }

  @override
  String errorDeletingWorkspace(String error) {
    return 'Fout bij het verwijderen van de werkruimte: $error';
  }

  @override
  String get indexCode => 'Code indexeren';

  @override
  String get indexing => 'Indexeren…';

  @override
  String get indexNoGrammars => 'Codegrammatica\'s niet geïnstalleerd';

  @override
  String get indexFailed => 'Indexeren mislukt';

  @override
  String indexedSymbolsCount(int count) {
    return '$count symbolen geïndexeerd';
  }

  @override
  String get nodeConfigAdvanced => 'Geavanceerd';

  @override
  String get nodeConfigReducer => 'Reducer';

  @override
  String get nodeConfigReducerHelp =>
      'Hoe samen te voegen wanneer deze uitvoersleutel al een waarde heeft';

  @override
  String get nodeConfigTimeoutMs => 'Time-out (ms)';

  @override
  String get nodeConfigRetryAttempts => 'Nieuwe pogingen';

  @override
  String get nodeConfigContinueOnFail => 'Doorgaan als deze stap mislukt';

  @override
  String get nodeConfigTeamId => 'Team-ID';

  @override
  String get nodeConfigDispatchMode => 'Verzendmodus';

  @override
  String get nodeConfigOutputSchema => 'Uitvoerschema (JSON)';

  @override
  String get nodeConfigOutputSchemaHelp =>
      'JSON-schema waaraan de stapuitvoer moet voldoen';

  @override
  String get diffLineDisplay => 'Lange regels in diffs';

  @override
  String get diffLineDisplayDescription =>
      'Lange regels afbreken of horizontaal scrollen';

  @override
  String get diffLineWrap => 'Afbreken';

  @override
  String get diffLineScroll => 'Horizontaal scrollen';

  @override
  String get actions => 'Acties';

  @override
  String get activate => 'Activeren';

  @override
  String get activity => 'Activiteit';

  @override
  String get activityLabel => 'ACTIVITEIT';

  @override
  String adRulesCount(int count) {
    return '$count advertentieregels';
  }

  @override
  String get adapter => 'Adapter';

  @override
  String get adapterLabel => 'Adapter';

  @override
  String get adapters => 'Adapters';

  @override
  String get adaptersAutoDetected =>
      'Automatisch gedetecteerde agent-runners beschikbaar op deze machine. Installeer ontbrekende CLI-tools om extra runners in te schakelen.';

  @override
  String get add => 'Toevoegen';

  @override
  String get addAComment => 'Een reactie toevoegen';

  @override
  String get addAReaction => 'Een reactie toevoegen';

  @override
  String get addASuggestion => 'Een suggestie toevoegen';

  @override
  String get addAgent => 'Agent toevoegen';

  @override
  String get addAgents => 'Agenten toevoegen';

  @override
  String get addAgentsToEnable =>
      'Voeg agenten toe om multi-agent-orkestratie in te schakelen';

  @override
  String get addEmoji => 'Emoji toevoegen';

  @override
  String get addFeed => 'Feed toevoegen';

  @override
  String get addFromFile => 'Uit bestand toevoegen';

  @override
  String get addGif => 'GIF toevoegen';

  @override
  String get addGithubRepoPrompt =>
      'Voeg minimaal één GitHub-repository toe om pull requests te zien';

  @override
  String get addLocalCheckoutDescription =>
      'Voeg een lokale checkout toe om er vanuit deze werkruimte op te richten.';

  @override
  String get addRepository => 'Repository toevoegen';

  @override
  String get addToken => 'Token toevoegen';

  @override
  String get addWorkspace => 'Werkruimte toevoegen';

  @override
  String get addWorkspaceEllipsis => 'Werkruimte toevoegen…';

  @override
  String get added => 'Toegevoegd';

  @override
  String get addingEllipsis => 'Toevoegen…';

  @override
  String get advancedLabel => 'Geavanceerd';

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
  String get agentMdPath => 'Agent-MD-pad';

  @override
  String get agentName => 'Agentnaam';

  @override
  String get agentTitle => 'Agenttitel';

  @override
  String get agentUpdated => 'Agent bijgewerkt.';

  @override
  String get agents => 'Agenten';

  @override
  String agentsCount(int count, num plural) {
    return 'Agenten ($count)';
  }

  @override
  String get agentsLabel => 'AGENTEN';

  @override
  String get agentsMentionSection => 'Agenten';

  @override
  String get aiReview => 'AI-review';

  @override
  String get all => 'Alles';

  @override
  String get allAgentsAlreadyInChannel => 'Alle agenten zijn al in dit kanaal.';

  @override
  String allAgentsCount(int count) {
    return 'Alle agenten · $count';
  }

  @override
  String get allCommits => 'Alle commits';

  @override
  String get allSessionsReset => 'Alle sandbox-sessies gereset.';

  @override
  String get allSources => 'Alle bronnen';

  @override
  String get allStarBadge => 'All-Star';

  @override
  String get allTimeLabel => 'Alles';

  @override
  String get allow => 'Toestaan';

  @override
  String get allowGitPush => 'git push toestaan';

  @override
  String get allowGithubApi => 'GitHub API-aanroepen toestaan';

  @override
  String get allowNetwork => 'Algemene netwerktoegang toestaan';

  @override
  String get apiKeys => 'API-sleutels';

  @override
  String get appFont => 'App-lettertype';

  @override
  String get appLogLevelDebugDescription =>
      'Voegt gedetailleerde traces toe - voor ontwikkeling.';

  @override
  String get appLogLevelDebugLabel => 'Debug';

  @override
  String get appLogLevelErrorDescription =>
      'Alleen fouten en onverwachte uitzonderingen.';

  @override
  String get appLogLevelErrorLabel => 'Fout';

  @override
  String get appLogLevelInfoDescription =>
      'Voegt levenscyclus- en statusberichten toe.';

  @override
  String get appLogLevelInfoLabel => 'Info';

  @override
  String get appLogLevelNoneDescription => 'Geen console-uitvoer.';

  @override
  String get appLogLevelNoneLabel => 'Geen';

  @override
  String get appLogLevelVerboseDescription =>
      'Alles. Extreem verbose - alleen voor debugging gebruiken.';

  @override
  String get appLogLevelVerboseLabel => 'Verbose';

  @override
  String get appLogLevelWarningDescription =>
      'Voegt waarschuwingen en herstelbare problemen toe.';

  @override
  String get appLogLevelWarningLabel => 'Waarschuwing';

  @override
  String get appTitle => 'Control Center';

  @override
  String get appearanceLanguage => 'Weergave en taal';

  @override
  String get apply => 'Toepassen';

  @override
  String get approve => 'Goedkeuren';

  @override
  String get approveAndCompact => 'Goedkeuren en context comprimeren';

  @override
  String get approveAndExecute => 'Goedkeuren en uitvoeren';

  @override
  String get approveAndHire => 'Goedkeuren en aannemen';

  @override
  String get approved => 'Goedgekeurd';

  @override
  String get articlesSubscribed => 'Artikelen uit je geabonneerde feeds.';

  @override
  String get askAi => 'Ask AI';

  @override
  String get askAiReview => 'AI-review aanvragen';

  @override
  String get askAiReviewDescription => 'Vraag de AI om deze PR te reviewen';

  @override
  String get askAnything =>
      'Vraag iets… (@ om agenten te noemen, / voor commando\'s)';

  @override
  String get assignees => 'TOEGEWEZENEN';

  @override
  String get attachFiles => 'Bestanden bijvoegen';

  @override
  String get attachImage => 'Afbeelding bijvoegen';

  @override
  String get attachedAgents => 'Gekoppelde agenten';

  @override
  String get audioInput => 'Audio-invoer';

  @override
  String get authentication => 'Authenticatie';

  @override
  String get authenticationToken => 'Authenticatietoken';

  @override
  String authoredByLabel(String role) {
    return 'Door: $role';
  }

  @override
  String get authorsLabel => 'Auteurs';

  @override
  String authorsWithCount(int count) {
    return 'Auteurs · $count';
  }

  @override
  String get autoRecommended => 'Automatisch (aanbevolen)';

  @override
  String get available => 'Beschikbaar';

  @override
  String get avgDuration => 'Gem. duur';

  @override
  String get awaitingYourApproval => 'Wachtend op jouw goedkeuring';

  @override
  String get awaitingYourReview => 'Wachtend op jouw review';

  @override
  String get back => 'Terug';

  @override
  String get backLabel => 'Terug';

  @override
  String get backend => 'Backend';

  @override
  String get blockAdsDescription =>
      'Advertenties, trackers en cookiebanners blokkeren';

  @override
  String get blockAdsTrackers =>
      'Advertenties, trackers en cookiebanners blokkeren';

  @override
  String get blocking => 'Blokkerend';

  @override
  String get blockingLabel => 'Blokkerend';

  @override
  String get bookmarkLabel => 'Bladwijzer';

  @override
  String get briefDescription => 'Korte beschrijving';

  @override
  String get bugLabel => 'BUG';

  @override
  String get bundledDefaultsNeverUpdated =>
      'Vooraf geïnstalleerd - nooit bijgewerkt';

  @override
  String get cached => 'In cache';

  @override
  String get cancel => 'Annuleren';

  @override
  String get cancelEdit => 'Bewerking annuleren';

  @override
  String get categoryCreation => 'Aanmaken';

  @override
  String get categoryDeletion => 'Verwijdering';

  @override
  String get categoryEditing => 'Bewerken';

  @override
  String get categoryNavigation => 'Navigatie';

  @override
  String get categorySystem => 'Systeem';

  @override
  String get categoryView => 'Weergave';

  @override
  String get centurionBadge => 'Centurion';

  @override
  String get change => 'Wijzigen';

  @override
  String get changesRequested => 'Wijzigingen aangevraagd';

  @override
  String get changesSummary => 'Samenvatting van wijzigingen';

  @override
  String get channelsMentionSection => 'Kanalen';

  @override
  String get checkForUpdates => 'Controleren op updates';

  @override
  String get checking => 'Controleren';

  @override
  String get checkingEllipsis => 'Controleren…';

  @override
  String get checkingGhCli => 'gh CLI controleren…';

  @override
  String get chooseAppFont => 'App-lettertype kiezen';

  @override
  String get chooseCodeFont => 'Codelettertype kiezen';

  @override
  String get chooseRunner => 'Kies je agent-runner.';

  @override
  String get clear => 'Wissen';

  @override
  String get clickToRetry => 'Klik om opnieuw te proberen';

  @override
  String get close => 'Sluiten';

  @override
  String get closeEsc => 'Sluiten (Esc)';

  @override
  String get closeKeyboardHint => 'Sneltoetsen sluiten';

  @override
  String get closePanel => 'Paneel sluiten';

  @override
  String get closeReader => 'Lezer sluiten';

  @override
  String get closeThread => 'Thread sluiten';

  @override
  String get closed => 'Gesloten';

  @override
  String get codeFont => 'Codelettertype';

  @override
  String get collapse => 'Samenvouwen';

  @override
  String get commandPalette => 'Commandopalet';

  @override
  String get commandPaletteOrgMembers => 'Organization members';

  @override
  String get commandPaletteBrowseTeam => 'Browse team';

  @override
  String get commandPaletteBrowseTeamDesc => 'View all organization members';

  @override
  String get commandsMentionSection => 'Commando\'s';

  @override
  String get comment => 'Reactie';

  @override
  String get commentOnFile => 'Reageren op dit bestand';

  @override
  String get commentOnThisFile => 'Reageren op dit bestand';

  @override
  String get commentSelected => 'Selectie becommentariëren';

  @override
  String get commented => 'Gereageerd';

  @override
  String get commits => 'Commits';

  @override
  String commitsShowingLatest(int loaded, int total) {
    return 'Toont de laatste $loaded van $total commits';
  }

  @override
  String get prCloneProgressCloningTitle => 'Repository klonen';

  @override
  String prCloneProgressCloningSubtitle(int fileCount) {
    return 'Deze PR wijzigt $fileCount bestanden, wat het API-limiet van GitHub overschrijdt. Repository wordt lokaal gekloond…';
  }

  @override
  String get prCloneProgressCloningSubtitleNoCount =>
      'Deze PR overschrijdt het bestandslimiet van de GitHub-API. Repository wordt lokaal gekloond…';

  @override
  String get prCloneProgressFetchingTitle => 'Refs ophalen';

  @override
  String get prCloneProgressFetchingSubtitle =>
      'Basistak en PR-ref worden opgehaald…';

  @override
  String get prCloneProgressComputingTitle => 'Diff berekenen';

  @override
  String get prCloneProgressComputingSubtitle =>
      'Git diff wordt lokaal uitgevoerd…';

  @override
  String get prCloneProgressErrorTitle => 'Laden van diff mislukt';

  @override
  String get prCloneProgressErrorSubtitle =>
      'Er is een fout opgetreden bij het klonen of berekenen van de diff.';

  @override
  String prCloneProgressElapsed(String elapsed) {
    return 'Nog bezig… $elapsed verstreken';
  }

  @override
  String confidenceLabel(int percent) {
    return 'Betrouwbaarheid: $percent%';
  }

  @override
  String get configureAgentIdentities =>
      'Configureer agent-identiteiten, prompts, vaardigheden en bekijk runs.';

  @override
  String get configureDefaultRunners =>
      'Configureer welke adapter en model worden gebruikt voor nieuwe gesprekken en titelgeneratie.';

  @override
  String get configuredLabel => 'Geconfigureerd.';

  @override
  String get confirmedBy => 'Bevestigd door';

  @override
  String get consensus => 'Consensus';

  @override
  String get contentBlockingDescription =>
      'Advertenties, trackers en cookiebanners blokkeren';

  @override
  String get contentHint => 'Wat moet worden onthouden';

  @override
  String get contentLabel => 'Inhoud';

  @override
  String get contentMarkdown => 'Inhoud (Markdown)';

  @override
  String get contextWindowSize => 'Contextvenstergrootte';

  @override
  String get continueLabel => 'Doorgaan';

  @override
  String get conversationMode => 'Gespreksmodus';

  @override
  String get convertToGroup => 'Converteren naar groep?';

  @override
  String get convertToGroupBody =>
      'Het toevoegen van een andere agent maakt van dit een groepsgesprek.';

  @override
  String cookieRulesCount(int count) {
    return '$count cookieregels';
  }

  @override
  String get copied => 'Gekopieerd!';

  @override
  String get copy => 'Kopiëren';

  @override
  String get copyBaseBranchTooltip => 'Naam van doelbranch kopiëren';

  @override
  String get copyHeadBranchTooltip => 'Naam van bronbranch kopiëren';

  @override
  String get couldNotCheckGhCli => 'Kon gh CLI niet controleren.';

  @override
  String couldNotListDevices(String error) {
    return 'Kan apparaten niet weergeven: $error';
  }

  @override
  String get create => 'Aanmaken';

  @override
  String get createFirstAgent => 'Maak je eerste agent aan om te beginnen.';

  @override
  String get createOrSelectWorkspace =>
      'Maak of selecteer een werkruimte voordat je repository\'s toevoegt.';

  @override
  String get createPr => 'PR aanmaken';

  @override
  String get createPullRequest => 'Pull request aanmaken';

  @override
  String get createdByMe => 'Door mij aangemaakt';

  @override
  String createdLabel(String date) {
    return 'Aangemaakt: $date';
  }

  @override
  String get currentParticipants => 'Huidige deelnemers';

  @override
  String get customCapabilitiesDescription =>
      'Aangepaste mogelijkheden voor deze agent';

  @override
  String get customSystemPrompt =>
      'Aangepaste systeem-prompt voor deze agent...';

  @override
  String daysAgo(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count dagen geleden',
      one: '1 dag geleden',
    );
    return '$_temp0';
  }

  @override
  String get deactivate => 'Deactiveren';

  @override
  String get defaultCapabilities =>
      'Standaardmogelijkheden · nieuwe gesprekken';

  @override
  String get defaultChat => 'Standaard-chat';

  @override
  String defaultPort(int port) {
    return 'Standaard: $port.';
  }

  @override
  String defaultPortHint(int port) {
    return 'Standaard: $port.';
  }

  @override
  String get defaultRunners => 'Standaard-runners';

  @override
  String get delete => 'Verwijderen';

  @override
  String get deleteAgent => 'Agent verwijderen';

  @override
  String deleteAgentConfirm(String name) {
    return '\\\"$name\\\" verwijderen? Dit kan niet ongedaan worden gemaakt.';
  }

  @override
  String get deleteChannel => 'Kanaal verwijderen';

  @override
  String deleteConfirmName(String name) {
    return '\\\"$name\\\" verwijderen?';
  }

  @override
  String get deleteConversation => 'Gesprek verwijderen';

  @override
  String get deleteConversationConfirm =>
      'Dit gesprek verwijderen? Alle berichten gaan verloren.';

  @override
  String get deleteFact => 'Feit verwijderen';

  @override
  String get deleteFeedBody =>
      'Dit verwijdert de feed en alle gecachte artikelen. Opgeslagen artikelen uit deze feed worden ook verwijderd.';

  @override
  String deleteFeedConfirm(String name) {
    return '\\\"$name\\\" verwijderen?';
  }

  @override
  String deleteNamedConversation(String name) {
    return '\"$name\" verwijderen? Alle berichten gaan verloren.';
  }

  @override
  String get deletePolicy => 'Beleidsregel verwijderen';

  @override
  String get deletePolicyConfirm =>
      'Deze beleidsregel verwijderen? Dit kan niet ongedaan worden gemaakt.';

  @override
  String deleteTopicConfirm(String topic) {
    return '\"$topic\" verwijderen? Dit kan niet ongedaan worden gemaakt.';
  }

  @override
  String get deleteWorkspace => 'Werkruimte verwijderen';

  @override
  String get deny => 'Weigeren';

  @override
  String get descriptionLabel => 'Beschrijving';

  @override
  String get detailsLabel => 'Details';

  @override
  String detectedBackend(String label) {
    return 'Gedetecteerd: $label';
  }

  @override
  String detectedRunners(int count) {
    return 'Gedetecteerde runners ($count)';
  }

  @override
  String get detectingAdapters => 'Adapters detecteren…';

  @override
  String get detectingGhCli => 'gh CLI detecteren…';

  @override
  String get detectingInputDevices => 'Invoerapparaten detecteren…';

  @override
  String detectionFailed(String error) {
    return 'Detectie mislukt: $error';
  }

  @override
  String diffFailed(String message) {
    return 'Diff mislukt: $message';
  }

  @override
  String get diffWorkerPool => 'Workerpool';

  @override
  String get directMessage => 'Direct bericht';

  @override
  String get directMessages => 'Directe berichten';

  @override
  String get disabled => 'Uitgeschakeld';

  @override
  String get discover => 'Ontdekken';

  @override
  String get discoverAgents => 'Agenten ontdekken';

  @override
  String get discoverAgentsDescription =>
      'Agentontdekking scant werkruimtepaden naar AGENTS.md- en TEAM.md-bestanden en parseert ze in het agentenregister.\n\nConfigureer eerst een werkruimte en gebruik dan deze functie om agenten automatisch te vullen.';

  @override
  String get dismissed => 'Gesloten';

  @override
  String get domainHint => 'bijv. api-performance';

  @override
  String get domainLabel => 'Domein';

  @override
  String get download => 'Downloaden';

  @override
  String get downloadingLabel => 'Downloaden';

  @override
  String downloadingModel(int pct) {
    return 'Model downloaden… $pct%';
  }

  @override
  String get draft => 'Concept';

  @override
  String get draftLabel => 'Concept';

  @override
  String get earnTiersDescription =>
      'Verdien niveaus door het Control Center te gebruiken';

  @override
  String get edit => 'Bewerken';

  @override
  String get editFact => 'Feit bewerken';

  @override
  String get editPolicy => 'Beleidsregel bewerken';

  @override
  String get editSuggestedCodeHint => 'Voorgestelde code bewerken…';

  @override
  String get editSuggestion => 'Suggestie bewerken';

  @override
  String get editTheSuggestedCodeHint => 'De voorgestelde code bewerken…';

  @override
  String get egArchitect => 'bijv. architect';

  @override
  String get egControlCenter => 'bijv. control-center';

  @override
  String get egPlatform => 'bijv. macOS';

  @override
  String get egSamuelAlev => 'bijv. SamuelAlev';

  @override
  String get egSoftwareArchitect => 'bijv. Software Architect';

  @override
  String get egTheVerge => 'bijv. The Verge';

  @override
  String get egTokenLimit => 'bijv. 128000';

  @override
  String embeddingInstallFailed(String error) {
    return 'Installatie mislukt: $error';
  }

  @override
  String get embeddingInstalled =>
      'Lokaal embedding-model geïnstalleerd. Hybride zoeken is ingeschakeld.';

  @override
  String get embeddingModel => 'Embedding-model (ONNX)';

  @override
  String get embeddingNotInstalled =>
      'Niet geïnstalleerd. Zoeken valt terug op alleen trefwoorden tot dit is ingeschakeld.';

  @override
  String get embeddingRedownloadBody =>
      'De bestaande modelbestanden worden verwijderd en opnieuw gedownload. Semantisch zoeken is niet beschikbaar tot de download is voltooid.';

  @override
  String get embeddingRemoveBody =>
      'Semantisch zoeken wordt uitgeschakeld tot je het opnieuw installeert. Je kunt het op elk moment opnieuw installeren.';

  @override
  String get speakerDiarization => 'Sprekerdiarisatie';

  @override
  String get diarizationModel => 'Diarisatiemodel';

  @override
  String get diarizationInstalled =>
      'Geïnstalleerd — benoemt afzonderlijke sprekers in vergadertranscripties';

  @override
  String get diarizationNotInstalled =>
      'Niet geïnstalleerd — sprekers in vergaderingen worden niet gescheiden';

  @override
  String diarizationInstallFailed(String error) {
    return 'Installatie mislukt: $error';
  }

  @override
  String get redownloadDiarizationModel => 'Diarisatiemodel opnieuw downloaden';

  @override
  String get diarizationRedownloadBody =>
      'Hiermee worden de huidige diarisatiemodellen verwijderd en opnieuw gedownload.';

  @override
  String get removeDiarizationModel => 'Diarisatiemodel verwijderen';

  @override
  String get diarizationRemoveBody =>
      'Hiermee worden de diarisatiemodellen op het apparaat verwijderd. Reeds geproduceerde vergadertranscripties blijven onaangetast.';

  @override
  String get onboardingDiarizationTitle => 'Sprekerdiarisatie (optioneel)';

  @override
  String get onboardingDiarizationSubtitle =>
      'Download om afzonderlijke sprekers (Persoon 1, Persoon 2…) te labelen in vergadernotities. Je kunt dit later in instellingen toevoegen.';

  @override
  String get enableMcpServer => 'MCP-server inschakelen';

  @override
  String get enableNotifications => 'Meldingen inschakelen';

  @override
  String get enableSandboxing => 'Sandboxing inschakelen';

  @override
  String get enabled => 'Ingeschakeld';

  @override
  String enterToken(String name) {
    return '$name-token invoeren';
  }

  @override
  String get enterTokenToAuth =>
      'Voer een token in om authenticatie te vereisen';

  @override
  String errorCreatingAgent(String error) {
    return 'Fout bij aanmaken agent: $error';
  }

  @override
  String errorDeletingAgent(String error) {
    return 'Fout bij verwijderen agent: $error';
  }

  @override
  String get errorLoadingAgents => 'Fout bij het laden van agenten';

  @override
  String errorWithDetail(String error) {
    return 'Fout: $error';
  }

  @override
  String get errored => 'Met fouten';

  @override
  String get erroredLabel => 'Met fouten';

  @override
  String get exitSelection => 'Selectie verlaten';

  @override
  String get expand => 'Uitvouwen';

  @override
  String get extractingLabel => 'Uitpakken';

  @override
  String extractingModel(int pct) {
    return 'Model uitpakken… $pct%';
  }

  @override
  String get fact => 'Feit';

  @override
  String factCount(int count) {
    return '$count feit';
  }

  @override
  String factCountPlural(int count) {
    return '$count feiten';
  }

  @override
  String get facts => 'Feiten';

  @override
  String factsPoliciesCount(int factCount, int policyCount) {
    return '$factCount feiten · $policyCount beleidsregels';
  }

  @override
  String get failed => 'Mislukt';

  @override
  String failedToDispatch(String error) {
    return 'Verzenden mislukt: $error';
  }

  @override
  String get failedToLoad => 'Laden mislukt';

  @override
  String failedToLoadAgents(String error) {
    return 'Agenten laden mislukt: $error';
  }

  @override
  String failedToLoadFeeds(String error) {
    return 'Feeds laden mislukt: $error';
  }

  @override
  String get failedToLoadGifs => 'GIFs laden mislukt';

  @override
  String failedToLoadLogs(String error) {
    return 'Logboeken laden mislukt: $error';
  }

  @override
  String get failedToLoadRepos => 'Repository\'s laden mislukt';

  @override
  String get failedToLoadWorkspaces => 'Werkruimtes laden mislukt';

  @override
  String failedToStartAiReview(String error) {
    return 'AI-review starten mislukt: $error';
  }

  @override
  String get failedToStartMicTest => 'Microfoontest starten mislukt.';

  @override
  String failedToSubmitReview(String error) {
    return 'Review indienen mislukt: $error';
  }

  @override
  String failedToUpload(String name, String error) {
    return '$name uploaden mislukt: $error';
  }

  @override
  String failedWithError(String error) {
    return 'Mislukt: $error';
  }

  @override
  String get failure => 'Mislukt';

  @override
  String get feedAlreadyExists => 'Er bestaat al een feed met deze URL.';

  @override
  String get feedUrl => 'Feed-URL';

  @override
  String get feedUrlExample => 'bijv. https://example.com/feed.xml';

  @override
  String get feedUrlExists => 'Er bestaat al een feed met deze URL.';

  @override
  String get feedUrlLabel => 'Feed-URL';

  @override
  String feedsCount(int count) {
    return 'Feeds ($count)';
  }

  @override
  String get feedsLabel => 'Feeds';

  @override
  String get filesChanged => 'Bestanden gewijzigd';

  @override
  String filesCount(int count) {
    return '$count bestand(en)';
  }

  @override
  String get filesMentionSection => 'Bestanden';

  @override
  String get filterAgents => 'Agenten filteren...';

  @override
  String get filterAgentsPlaceholder => 'Agenten filteren…';

  @override
  String get filterFilesHint => 'Bestanden filteren…';

  @override
  String get filterLists => 'Filterlijsten';

  @override
  String get filterSkillsPlaceholder => 'Vaardigheden filteren…';

  @override
  String get finish => 'Afronden';

  @override
  String get firstReviewBadge => 'Eerste review';

  @override
  String get fix => 'Repareren';

  @override
  String get fixSelected => 'Selectie repareren';

  @override
  String get flawlessBadge => 'Vlekkeloos';

  @override
  String get forks => 'Forks';

  @override
  String get forward => 'Doorsturen';

  @override
  String get gatesGithubPatPush =>
      'Stuurt GitHub PAT-injectie aan. Vereist om de agent te laten pushen.';

  @override
  String get general => 'Algemeen';

  @override
  String get generalSettingsDescription =>
      'Weergave, typografie, integraties en MCP-server.';

  @override
  String get ghCliAuthButPatOverrideBody =>
      'GitHub CLI is geauthenticeerd en gereed, maar een persoonlijk toegangstoken is hieronder ingesteld en zal daarvoor in de plaats worden gebruikt. Verwijder het PAT om gh CLI-authenticatie te gebruiken.';

  @override
  String get ghCliInstalledAuth =>
      'Geïnstalleerd. Voer `gh auth login` uit en tik vervolgens op Vernieuwen.';

  @override
  String get ghCliNotInstalled =>
      'gh CLI niet geïnstalleerd — installeer via cli.github.com.';

  @override
  String get ghCliNotInstalledLabel => 'gh CLI niet geïnstalleerd';

  @override
  String get githubCli => 'GitHub CLI';

  @override
  String get githubCliIntegration => 'GitHub CLI-integratie';

  @override
  String get githubCliReady => 'GitHub CLI is geauthenticeerd en klaar.';

  @override
  String get githubLink => 'GitHub-link';

  @override
  String get githubPersonalAccessToken => 'GitHub persoonlijk toegangstoken';

  @override
  String get githubStatusAllOperational => 'Alle systemen operationeel';

  @override
  String get githubStatusComponents => 'Componenten';

  @override
  String get githubStatusFetchFailed => 'Kon githubstatus.com niet bereiken';

  @override
  String get githubStatusIncidents => 'Actieve incidenten';

  @override
  String get githubStatusOpenInBrowser => 'Openen in browser';

  @override
  String get githubStatusRefresh => 'Vernieuwen';

  @override
  String get githubStatusTitle => 'GitHub-status';

  @override
  String githubStatusUpdated(String time) {
    return 'Bijgewerkt $time';
  }

  @override
  String lastChecked(String time) {
    return 'Gecontroleerd $time';
  }

  @override
  String get lastCheckedRecently => 'Recent gecontroleerd';

  @override
  String get githubToken => 'GitHub-token';

  @override
  String get giveAgentsAMemory => 'Agenten een geheugen geven.';

  @override
  String get giveYourWorkAHome => 'Geef je werk een thuis.';

  @override
  String get goBack => 'Ga terug';

  @override
  String get goForward => 'Ga vooruit';

  @override
  String get googleFonts => 'Google Fonts';

  @override
  String get groupLabel => 'Groep';

  @override
  String get groupName => 'Groepsnaam';

  @override
  String get groups => 'Groepen';

  @override
  String get hideContainerTerminal => 'Container-terminal verbergen';

  @override
  String get high => 'Hoog';

  @override
  String get hotStreakBadge => 'Winningreeks';

  @override
  String hoursAgo(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count uur geleden',
      one: '1 uur geleden',
    );
    return '$_temp0';
  }

  @override
  String get idleStatus => 'Inactief';

  @override
  String get images => 'Afbeeldingen';

  @override
  String get inFlightLabel => 'Bezig';

  @override
  String get inactive => 'Inactief';

  @override
  String get install => 'Installeren';

  @override
  String get installGhCliBody =>
      'Installeer gh vanaf https://cli.github.com/ en voer `gh auth login` uit, tik dan op Vernieuwen.';

  @override
  String get installRequired => 'Installatie vereist';

  @override
  String get installedNotSignedIn => 'Geïnstalleerd - niet aangemeld';

  @override
  String installedVersion(String version) {
    return 'Geïnstalleerd $version';
  }

  @override
  String get integrations => 'Integraties';

  @override
  String get invite => 'Uitnodigen';

  @override
  String get inviteAgent => 'Agent uitnodigen';

  @override
  String get isolateAgentExecution => 'Agentuitvoering isoleren.';

  @override
  String jobCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 's',
      one: '',
    );
    return '$count taak$_temp0';
  }

  @override
  String get justNow => 'zojuist';

  @override
  String get keepMessages => 'Berichten behouden';

  @override
  String get keepSandboxing => 'Sandboxing behouden';

  @override
  String get keybindingAdapters => 'Adapters';

  @override
  String get keybindingAddARepositoryDescription => 'Een repository toevoegen';

  @override
  String get keybindingAddRepository => 'Repository toevoegen';

  @override
  String get keybindingAgents => 'Agenten';

  @override
  String get keybindingApprove => 'Goedkeuren';

  @override
  String get keybindingApproveThePeerReviewDescription =>
      'Peer review goedkeuren';

  @override
  String get keybindingBookmarkOrUnbookmarkTheSelectedArticleDescription =>
      'Geselecteerd artikel bookmarken of verwijderen';

  @override
  String get keybindingCommandPalette => 'Commandopalet';

  @override
  String get keybindingConversationTab => 'Conversatie-tab';

  @override
  String get keybindingCreateANewAgentDescription => 'Nieuwe agent aanmaken';

  @override
  String get keybindingCreateANewGroupChannelDescription =>
      'Nieuw groepskanaal aanmaken';

  @override
  String get keybindingCreateANewWorkspaceDescription =>
      'Nieuwe werkruimte aanmaken';

  @override
  String get keybindingDeleteAgent => 'Agent verwijderen';

  @override
  String get keybindingDeleteChannel => 'Kanaal verwijderen';

  @override
  String get keybindingDeleteTheSelectedAgentDescription =>
      'Geselecteerde agent verwijderen';

  @override
  String get keybindingDeleteTheSelectedChannelDescription =>
      'Geselecteerde kanaal verwijderen';

  @override
  String get keybindingDeleteTheSelectedWorkspaceDescription =>
      'Geselecteerde werkruimte verwijderen';

  @override
  String get keybindingDeleteWorkspace => 'Werkruimte verwijderen';

  @override
  String get keybindingFilesChangedTab => 'Gewijzigde bestanden-tab';

  @override
  String get keybindingFocusSearch => 'Zoeken focussen';

  @override
  String get keybindingFocusThePullRequestSearchFieldDescription =>
      'Het zoekveld voor pull requests focussen';

  @override
  String get keybindingGeneral => 'Algemeen';

  @override
  String get keybindingGoToAgents => 'Naar agenten gaan';

  @override
  String get keybindingGoToAnalytics => 'Naar analyse gaan';

  @override
  String get keybindingGoToDashboard => 'Naar dashboard gaan';

  @override
  String get keybindingGoToMemory => 'Naar geheugen gaan';

  @override
  String get keybindingGoToNewsfeed => 'Naar nieuwsfeed gaan';

  @override
  String get keybindingGoToPipelines => 'Naar pipelines gaan';

  @override
  String get keybindingGoToPullRequests => 'Naar pull requests gaan';

  @override
  String get keybindingGoToTickets => 'Naar tickets gaan';

  @override
  String get keybindingKeybindings => 'Sneltoetsen';

  @override
  String get keybindingNavigateToTheAgentsRegistryDescription =>
      'Navigeren naar agentenregister';

  @override
  String get keybindingNavigateToTheAnalyticsDashboardDescription =>
      'Navigeren naar analyse-dashboard';

  @override
  String get keybindingNavigateToTheGlobalDashboardDescription =>
      'Navigeren naar globaal dashboard';

  @override
  String get keybindingNavigateToTheMemoryDescription =>
      'Ga naar de kennisbank';

  @override
  String get keybindingNavigateToTheNewsfeedDescription =>
      'Navigeren naar nieuwsfeed';

  @override
  String get keybindingNavigateToThePipelinesListDescription =>
      'Ga naar de pipelinelijst';

  @override
  String get keybindingNavigateToThePullRequestListDescription =>
      'Navigeren naar pull request-lijst';

  @override
  String get keybindingNavigateToTheTicketsBoardDescription =>
      'Ga naar het ticketbord';

  @override
  String get keybindingNewAgent => 'Nieuwe agent';

  @override
  String get keybindingNewDirectMessage => 'Nieuw direct bericht';

  @override
  String get keybindingNewGroup => 'Nieuwe groep';

  @override
  String get keybindingNewWorkspace => 'Nieuwe werkruimte';

  @override
  String get keybindingNextArticle => 'Volgend artikel';

  @override
  String get keybindingNextChannel => 'Volgend kanaal';

  @override
  String get keybindingNextPr => 'Volgende PR';

  @override
  String get keybindingNextWorkspace => 'Volgende werkruimte';

  @override
  String get keybindingOpenArticle => 'Artikel openen';

  @override
  String
  get keybindingOpenOrCloseTheWorkspaceSwitcherPopupInTheSidebarDescription =>
      'Werkruimte-wisselaar-popup in zijbalk openen of sluiten';

  @override
  String get keybindingOpenPr => 'PR openen';

  @override
  String get keybindingOpenSettings => 'Instellingen openen';

  @override
  String get keybindingOpenTheAdaptersSettingsPageDescription =>
      'Adapter-instellingenpagina openen';

  @override
  String get keybindingOpenTheAgentsSettingsPageDescription =>
      'Agent-instellingenpagina openen';

  @override
  String get keybindingOpenTheApplicationSettingsDescription =>
      'Applicatie-instellingen openen';

  @override
  String get keybindingOpenTheCommandPaletteDescription =>
      'Commandopalet openen';

  @override
  String get keybindingOpenTheGeneralSettingsPageDescription =>
      'Algemene instellingenpagina openen';

  @override
  String get keybindingOpenTheKeybindingsSettingsPageDescription =>
      'Sneltoetsen-instellingenpagina openen';

  @override
  String get keybindingOpenTheRepositoriesSettingsPageDescription =>
      'Repository-instellingenpagina openen';

  @override
  String get keybindingOpenTheSelectedArticleDescription =>
      'Geselecteerd artikel openen';

  @override
  String get keybindingOpenTheSelectedPullRequestDescription =>
      'Geselecteerde pull request openen';

  @override
  String get keybindingOpenTheSelectedWorkspaceDescription =>
      'Geselecteerde werkruimte openen';

  @override
  String get keybindingOpenTheSkillsSettingsPageDescription =>
      'Vaardigheden-instellingenpagina openen';

  @override
  String get keybindingOpenWorkspace => 'Werkruimte openen';

  @override
  String get keybindingPreviousArticle => 'Vorig artikel';

  @override
  String get keybindingPreviousChannel => 'Vorig kanaal';

  @override
  String get keybindingPreviousPr => 'Vorige PR';

  @override
  String get keybindingPreviousWorkspace => 'Vorige werkruimte';

  @override
  String get keybindingRefresh => 'Vernieuwen';

  @override
  String get keybindingRefreshAllFeedsDescription => 'Alle feeds vernieuwen';

  @override
  String get keybindingRefreshAnalyticsDataDescription =>
      'Analysedata vernieuwen';

  @override
  String get keybindingRefreshDashboardDataDescription =>
      'Dashboarddata vernieuwen';

  @override
  String get keybindingRefreshThePullRequestListDescription =>
      'Pull request-lijst vernieuwen';

  @override
  String get keybindingRemoveRepository => 'Repository verwijderen';

  @override
  String get keybindingRemoveTheSelectedRepositoryDescription =>
      'Geselecteerde repository verwijderen';

  @override
  String get keybindingRepositories => 'Repository\'s';

  @override
  String get keybindingRequestChanges => 'Wijzigingen aanvragen';

  @override
  String get keybindingRequestChangesOnThePeerReviewDescription =>
      'Wijzigingen aanvragen op peer review';

  @override
  String get keybindingRescanForAdaptersDescription =>
      'Opnieuw scannen naar adapters';

  @override
  String get keybindingSearchInDiff => 'Zoeken in diff';

  @override
  String get keybindingSearchWithinTheDiffViewDescription =>
      'Zoeken in diff-weergave';

  @override
  String get keybindingToggleViewed => 'Bekeken wisselen';

  @override
  String get keybindingMarkTheFocusedFileAsViewedOrUnviewedDescription =>
      'Markeer het gefocuste bestand als bekeken of niet bekeken';

  @override
  String get keybindingToggleCollapse => 'Samenvouwen wisselen';

  @override
  String get keybindingCollapseOrExpandTheFocusedFileDescription =>
      'Gefocuste bestand samenvouwen of uitvouwen';

  @override
  String get keybindingSelectTheNextArticleDescription =>
      'Volgend artikel selecteren';

  @override
  String get keybindingSelectTheNextChannelDescription =>
      'Volgend kanaal selecteren';

  @override
  String get keybindingSelectTheNextPullRequestDescription =>
      'Volgende pull request selecteren';

  @override
  String get keybindingSelectThePreviousArticleDescription =>
      'Vorig artikel selecteren';

  @override
  String get keybindingSelectThePreviousChannelDescription =>
      'Vorig kanaal selecteren';

  @override
  String get keybindingSelectThePreviousPullRequestDescription =>
      'Vorige pull request selecteren';

  @override
  String get keybindingSendMessage => 'Bericht versturen';

  @override
  String get keybindingSendTheCurrentMessageDescription =>
      'Huidige bericht versturen';

  @override
  String get keybindingSkills => 'Vaardigheden';

  @override
  String get keybindingStartANewDirectMessageDescription =>
      'Nieuw direct bericht starten';

  @override
  String get keybindingSwitchBetweenLightAndDarkModeDescription =>
      'Wisselen tussen lichte en donkere modus';

  @override
  String get keybindingSwitchToTheConversationTabDescription =>
      'Wisselen naar conversatie-tab';

  @override
  String get keybindingSwitchToTheEighthWorkspaceDescription =>
      'Wisselen naar achtste werkruimte';

  @override
  String get keybindingSwitchToTheFifthWorkspaceDescription =>
      'Wisselen naar vijfde werkruimte';

  @override
  String get keybindingSwitchToTheFilesChangedTabDescription =>
      'Wisselen naar gewijzigde bestanden-tab';

  @override
  String get keybindingSwitchToTheFirstWorkspaceDescription =>
      'Wisselen naar eerste werkruimte';

  @override
  String get keybindingSwitchToTheFourthWorkspaceDescription =>
      'Wisselen naar vierde werkruimte';

  @override
  String get keybindingSwitchToTheNextWorkspaceDescription =>
      'Wisselen naar volgende werkruimte';

  @override
  String get keybindingSwitchToTheNinthWorkspaceDescription =>
      'Wisselen naar negende werkruimte';

  @override
  String get keybindingSwitchToThePreviousWorkspaceDescription =>
      'Wisselen naar vorige werkruimte';

  @override
  String get keybindingSwitchToTheSecondWorkspaceDescription =>
      'Wisselen naar tweede werkruimte';

  @override
  String get keybindingSwitchToTheSeventhWorkspaceDescription =>
      'Wisselen naar zevende werkruimte';

  @override
  String get keybindingSwitchToTheSixthWorkspaceDescription =>
      'Wisselen naar zesde werkruimte';

  @override
  String get keybindingSwitchToTheThirdWorkspaceDescription =>
      'Wisselen naar derde werkruimte';

  @override
  String get keybindingToggleBookmark => 'Bookmark wisselen';

  @override
  String get keybindingToggleTheme => 'Thema wisselen';

  @override
  String get keybindingToggleWorkspaceSwitcher =>
      'Werkruimte-wisselaar wisselen';

  @override
  String get keybindingWorkspace1 => 'Workspace1';

  @override
  String get keybindingWorkspace2 => 'Workspace2';

  @override
  String get keybindingWorkspace3 => 'Workspace3';

  @override
  String get keybindingWorkspace4 => 'Workspace4';

  @override
  String get keybindingWorkspace5 => 'Workspace5';

  @override
  String get keybindingWorkspace6 => 'Workspace6';

  @override
  String get keybindingWorkspace7 => 'Workspace7';

  @override
  String get keybindingWorkspace8 => 'Workspace8';

  @override
  String get keybindingWorkspace9 => 'Workspace9';

  @override
  String get keybindings => 'Sneltoetsen';

  @override
  String get keybindingsDescription =>
      'Alle sneltoetsen. Sneltoetsen zijn vast en kunnen niet opnieuw worden toegewezen.';

  @override
  String get killRunning => 'Actieve stoppen';

  @override
  String get klipyNotConfigured => 'KLIPY_APP_KEY niet geconfigureerd';

  @override
  String get klipyNotConfiguredHint =>
      'Geef --dart-define=KLIPY_APP_KEY=... op\\nof stel deze in in de .env voor het uitvoeren.';

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
  String get languageSystem => 'Systeem';

  @override
  String lastMonths(int count) {
    return 'Laatste $count maanden';
  }

  @override
  String get latestLabel => 'Nieuwste';

  @override
  String get leaderboardLabel => 'KLASSEMENT';

  @override
  String get leaderboardLabelShort => 'Klassement';

  @override
  String get leaveACommentEllipsis => 'Reactie achterlaten…';

  @override
  String get legendLabel => 'Legenda';

  @override
  String get lessLabel => 'Minder';

  @override
  String get letsPluginTools => 'Laten we je tools aansluiten.';

  @override
  String get level => 'Niveau';

  @override
  String levelLabel(int level) {
    return 'Niveau $level';
  }

  @override
  String get liveDiff => 'Live diff';

  @override
  String get liveSync => 'Live sync';

  @override
  String get loadingAgents => 'Agenten laden…';

  @override
  String get loadingModels => 'Modellen laden…';

  @override
  String get lockedLabel => 'Vergrendeld';

  @override
  String get logLevel => 'Logniveau';

  @override
  String get logs => 'Logboeken';

  @override
  String get low => 'Laag';

  @override
  String get maintenance => 'Onderhoud';

  @override
  String get manageParticipants => 'Deelnemers beheren';

  @override
  String get manageWorkspaces => 'Werkruimtes beheren';

  @override
  String get masterToggle => 'Hoofdschakelaar';

  @override
  String get matchOsAppearance =>
      'Pas het uiterlijk aan aan je OS of kies een vaste modus.';

  @override
  String get mcpActiveAccepting =>
      'MCP-server is actief en accepteert verbindingen.';

  @override
  String get mcpAuthToken => 'MCP-authenticatietoken';

  @override
  String get mcpAuthentication => 'Authenticatie';

  @override
  String get mcpAutoStartDescription =>
      'Als dit uit staat, blijft de server gestopt totdat je hem start.';

  @override
  String mcpDefaultPort(int port) {
    return 'Standaard: $port';
  }

  @override
  String mcpListeningOn(int port) {
    return 'Luistert op 127.0.0.1:$port';
  }

  @override
  String mcpListeningOnPort(int port) {
    return 'Luistert op 127.0.0.1:$port.';
  }

  @override
  String get mcpNotRunning =>
      'Server is niet actief. Start de server om MCP-verbindingen in te schakelen.';

  @override
  String get mcpRestartPortChanges =>
      'De server moet opnieuw worden gestart om poortwijzigingen toe te passen.';

  @override
  String get mcpServer => 'MCP-server';

  @override
  String get mcpServerStopped => 'Server is gestopt';

  @override
  String get mcpStatus => 'Status';

  @override
  String get medium => 'Middel';

  @override
  String get memoryDataHint =>
      'Feiten en beleidsregels verschijnen hier terwijl agenten werken.';

  @override
  String get memoryLabel => 'GEHEUGEN';

  @override
  String get merge => 'Merge';

  @override
  String get mergeMasterBadge => 'Merge master';

  @override
  String get merged => 'Samengevoegd';

  @override
  String get messagePlaceholder =>
      'Bericht… (@ om te noemen, / voor commando\'s)';

  @override
  String get messagingLabel => 'Berichten';

  @override
  String get microphonePermissionDenied => 'Microfoontoestemming geweigerd.';

  @override
  String minutesAgo(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count minuten geleden',
      one: '1 minuut geleden',
    );
    return '$_temp0';
  }

  @override
  String get modelLabel => 'Model';

  @override
  String get modified => 'Gewijzigd';

  @override
  String monthsAgo(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count maanden geleden',
      one: '1 maand geleden',
    );
    return '$_temp0';
  }

  @override
  String get more => 'Meer';

  @override
  String get moreLabel => 'Meer';

  @override
  String get mozillaUserAgent => 'Mozilla/5.0 …';

  @override
  String get name => 'Naam';

  @override
  String get nameAndTitleRequired => 'Naam en titel zijn vereist.';

  @override
  String get nameAndUrlRequired => 'Naam en URL zijn vereist';

  @override
  String get nameLabel => 'Naam';

  @override
  String nativeSandboxAvailable(String platform) {
    return 'Native sandbox is beschikbaar op $platform.';
  }

  @override
  String get nativeSandboxNeedsInstall =>
      'Installatie vereist voor native sandbox';

  @override
  String get navAnalytics => 'Analyse';

  @override
  String get navDashboard => 'Dashboard';

  @override
  String get navSaved => 'Opgeslagen';

  @override
  String get navSettings => 'Instellingen';

  @override
  String get navigateLabel => 'Navigeren';

  @override
  String networkBlockCount(int count) {
    return '$count netwerkblokkades';
  }

  @override
  String get neutral => 'Neutraal';

  @override
  String get newAgent => 'Nieuwe agent';

  @override
  String get newCommitsPushed =>
      'Nieuwe commits zijn gepusht — klik om de diff opnieuw te laden';

  @override
  String get newFact => 'Nieuw feit';

  @override
  String get newGroup => 'Nieuwe groep';

  @override
  String get newLabel => 'Nieuw';

  @override
  String get newMessage => 'Nieuw bericht';

  @override
  String get newPolicy => 'Nieuwe beleidsregel';

  @override
  String get newPrToReview => 'Nieuwe PR om te reviewen';

  @override
  String get newsfeed => 'Nieuwsfeed';

  @override
  String get newsfeedLabel => 'Nieuwsfeed';

  @override
  String get newsfeedSettingsDescription =>
      'Beheer je geabonneerde feeds en lezersvoorkeuren.';

  @override
  String get newsfeedSettingsTitle => 'Nieuwsfeed-instellingen';

  @override
  String get nextMatch => 'Volgende overeenkomst (↵)';

  @override
  String get noAccessGrants => 'Geen toegangsrechten geconfigureerd';

  @override
  String get noActiveWorkspace =>
      'Geen actieve werkruimte of repository geselecteerd.';

  @override
  String get noActiveWorkspaceCreate => 'Geen actieve werkruimte';

  @override
  String get noActiveWorkspaceGithub =>
      'Geen actieve werkruimte met een GitHub-repository.';

  @override
  String get noAgentAssigned => 'Geen agent toegewezen';

  @override
  String get noAgentProcessesRunning => 'Geen agentprocessen actief';

  @override
  String get noAgents => 'Geen agenten';

  @override
  String get noAgentsConfigured => 'Geen agenten geconfigureerd';

  @override
  String get noAgentsDiscovered => 'Geen agenten ontdekt';

  @override
  String get noAgentsDiscoveredHint =>
      'Klik op \"Ontdekken\" om AGENTS.md-bestanden te scannen of \"Agent toevoegen\" om er handmatig een te configureren';

  @override
  String get noAgentsMatchSearch =>
      'Geen agenten komen overeen met je zoekopdracht';

  @override
  String get noAgentsRegisteredYet => 'Nog geen agenten geregistreerd';

  @override
  String get noArticlesYet => 'Nog geen artikelen';

  @override
  String get noArticlesYetBody => 'De artikelen van je feeds verschijnen hier.';

  @override
  String get noData => 'Geen gegevens';

  @override
  String get noDirectMessagesYet => 'Nog geen directe berichten';

  @override
  String get noDomains => 'Nog geen domeinen';

  @override
  String get noExecutionLogsYet => 'Nog geen uitvoeringslogboeken';

  @override
  String get noFacts => 'Nog geen feiten';

  @override
  String get noFeedsYet => 'Nog geen feeds';

  @override
  String get noFileAnchor =>
      'Geen bestandsanker — kan geen inline-reactie plaatsen.';

  @override
  String get noFileChangesInScope => 'Geen bestandswijzigingen in dit bereik';

  @override
  String get noGifsFound => 'Geen GIFs gevonden';

  @override
  String get noGroupsYet => 'Nog geen groepen';

  @override
  String get noInputDevicesDetected =>
      'Geen invoerapparaten gedetecteerd — systeemstandaard wordt gebruikt.';

  @override
  String get noMatchingFiles => 'Geen overeenkomende bestanden';

  @override
  String get noMatchingGoogleFonts => 'Geen overeenkomstige Google Fonts.';

  @override
  String get noMemoryData => 'Nog geen geheugengegevens';

  @override
  String get noMessagesYet => 'Nog geen berichten';

  @override
  String get noModelsAdvertised =>
      'Geen modellen aangeboden door deze adapter.';

  @override
  String get noOpenPullRequests => 'Geen open pull requests';

  @override
  String get noPolicies => 'Nog geen beleidsregels';

  @override
  String get noReposInWorkspaceYet =>
      'Nog geen repository\'s in deze werkruimte';

  @override
  String get noRunnersDetected =>
      'Nog geen runners gedetecteerd. Vernieuw om opnieuw te scannen.';

  @override
  String get noSavedArticles => 'Nog geen opgeslagen artikelen';

  @override
  String get noSavedArticlesBody =>
      'De artikelen die je opslaat verschijnen hier.';

  @override
  String noShortcutsMatch(String query) {
    return 'Geen sneltoetsen komen overeen met \\\"$query\\\"';
  }

  @override
  String get noSystemFonts => 'Geen systeemlettertypen gedetecteerd.';

  @override
  String get noTokenSet => 'Geen token ingesteld — toegang is onbeperkt.';

  @override
  String get noTokenSetUnrestricted =>
      'Geen token ingesteld — toegang is onbeperkt.';

  @override
  String get noTokenUnrestricted => 'Geen token — toegang is onbeperkt';

  @override
  String get noWorkingMemory => 'Nog geen werkgeheugennotities.';

  @override
  String get noneAllRoles => 'Geen (alle rollen)';

  @override
  String get notAvailable => 'Niet beschikbaar';

  @override
  String get notConfiguredLabel => 'Niet geconfigureerd.';

  @override
  String get notDetected => 'Niet gedetecteerd';

  @override
  String get notEarnedYet => 'Nog niet verdiend';

  @override
  String get notFoundLabel => 'Niet gevonden';

  @override
  String get notYetSpawned => 'Nog niet gestart';

  @override
  String get notes => 'Notities';

  @override
  String get notificationAgentFinished => 'Agent voltooid';

  @override
  String get notificationExternalPr => 'Externe PR\'s';

  @override
  String get notificationNewMessages => 'Nieuwe berichten';

  @override
  String get notificationPrMerged => 'PR samengevoegd';

  @override
  String get notificationPrPublished => 'PR gepubliceerd';

  @override
  String get notifications => 'Meldingen';

  @override
  String get notifyAgentRunCompleted =>
      'Melding wanneer een agent een run voltooit.';

  @override
  String get notifyExternalPr =>
      'Melding wanneer een nieuwe PR wordt gedetecteerd via polling.';

  @override
  String get notifyNewMessages =>
      'Melding bij nieuwe agent-berichten in andere kanalen.';

  @override
  String get notifyPrMerged =>
      'Melding wanneer een pull request wordt samengevoegd.';

  @override
  String get notifyPrPublished =>
      'Melding wanneer een agent een pull request publiceert.';

  @override
  String get onboardingLinuxDescription =>
      'Control Center kan Linux-containers gebruiken om de uitvoering van agenten te isoleren.';

  @override
  String get onboardingMacosDescription =>
      'Control Center gebruikt native sandbox op macOS om de uitvoering van agenten te isoleren.';

  @override
  String get onboardingUnsupportedDescription =>
      'Sandbox is niet beschikbaar op dit platform. De uitvoering van agenten zal zonder isolatie plaatsvinden.';

  @override
  String get openAction => 'Openen';

  @override
  String get openApplicationSettings => 'Toepassingsinstellingen openen';

  @override
  String get openArticlesBrowserFallback => 'Artikel in browser openen';

  @override
  String get openArticlesInApp => 'Artikelen in app openen';

  @override
  String get openContainerTerminal => 'Container-terminal openen';

  @override
  String get openFolder => 'Map openen';

  @override
  String get openInBrowser => 'Openen in browser';

  @override
  String get openLabel => 'Open';

  @override
  String get openOnGithub => 'Openen op GitHub';

  @override
  String get openStatus => 'Open';

  @override
  String get optionalPersonaDescription => 'Optionele persona-beschrijving';

  @override
  String get otherLabel => 'Overig';

  @override
  String get ownerOrganization => 'Eigenaar / Organisatie';

  @override
  String get p0 => 'P0';

  @override
  String get p1 => 'P1';

  @override
  String get p2 => 'P2';

  @override
  String get p3 => 'P3';

  @override
  String get parsingDiff => 'Diff parseren…';

  @override
  String get passed => 'Geslaagd';

  @override
  String get pasteTokenHere => 'Token hier plakken';

  @override
  String get pasteValueHere => 'Waarde hier plakken';

  @override
  String get patNotNeededGhCli => 'Niet nodig — gh CLI is ingelogd.';

  @override
  String get patOverridesGhCli => 'Geconfigureerd — overschrijft gh CLI.';

  @override
  String get pathLabel => 'Pad';

  @override
  String get pendingApproval => 'In afwachting van jouw goedkeuring';

  @override
  String get perfectionistBadge => 'Perfectionist';

  @override
  String get persona => 'Persona';

  @override
  String get personaColon => 'Persona:';

  @override
  String get personaOptional => 'Persona (optioneel)';

  @override
  String get personalAccessTokenOptional =>
      'Persoonlijk toegangstoken (optioneel)';

  @override
  String get planLabel => 'Plan';

  @override
  String get policies => 'Beleidsregels';

  @override
  String get policiesHint =>
      'Beleidsregels verschijnen hier zodra agenten feiten promoveren.';

  @override
  String get policy => 'Beleidsregel';

  @override
  String get popular => 'Populair';

  @override
  String get port => 'Poort';

  @override
  String get portLabel => 'Poort';

  @override
  String get postingEllipsis => 'Publiceren…';

  @override
  String get prCommits => 'Commits';

  @override
  String get prDescriptionPlaceholder => 'PR-beschrijving in markdown...';

  @override
  String get prDraftCreated => 'PR-concept aangemaakt';

  @override
  String get prMachineBadge => 'PR-machine';

  @override
  String get prMergedBody => 'Een pull request is samengevoegd';

  @override
  String get prMoreActions => 'More actions';

  @override
  String get prTitle => 'PR-titel';

  @override
  String get previewLabel => 'Voorbeeld';

  @override
  String get previousArticle => 'Vorig artikel';

  @override
  String get previousChannel => 'Vorig kanaal';

  @override
  String get previousMatch => 'Vorige overeenkomst (⇧↵)';

  @override
  String get previousPr => 'Vorige PR';

  @override
  String get previousWorkspace => 'Vorige werkruimte';

  @override
  String get priorityReviews => 'Prioriteitsreviews';

  @override
  String get priorityReviewsDescription =>
      'Prioriteitsreviews en overzicht van repository\'s.';

  @override
  String get progressLabel => 'Voortgang';

  @override
  String get proposeToCreateDomain =>
      'Stel een feit of beleidsregel voor om er een aan te maken.';

  @override
  String get prsCreated => 'PR\'s aangemaakt';

  @override
  String get prsCreatedLabel => 'PR\'s aangemaakt';

  @override
  String get prsMerged => 'PR\'s samengevoegd';

  @override
  String get publishToGithub => 'Publiceren naar GitHub';

  @override
  String get published => 'Gepubliceerd';

  @override
  String get pullRequestApproved => 'Pull request goedgekeurd';

  @override
  String get pullRequests => 'Pull requests';

  @override
  String get questionLabel => 'VRAAG';

  @override
  String get queued => 'In wachtrij';

  @override
  String get react => 'Reageren';

  @override
  String get readPrsIssuesMetadata =>
      'Stelt de agent in staat PR\'s, issues en repository-metadata te lezen.';

  @override
  String get readerPreferences => 'Lezersvoorkeuren';

  @override
  String get reasoningEffort => 'Reasoning-inspanning';

  @override
  String get recommendLabel => 'AANBEVELEN';

  @override
  String recordingFromDevice(String device) {
    return 'Opname van $device.';
  }

  @override
  String get redownload => 'Opnieuw downloaden';

  @override
  String get redownloadEmbeddingModel => 'Embedding-model opnieuw downloaden?';

  @override
  String get redownloadVoiceModel => 'Spraakmodel opnieuw downloaden?';

  @override
  String get refinePlan => 'Plan verfijnen';

  @override
  String get refiningPlan => 'Plan verfijnen…';

  @override
  String get refresh => 'Vernieuwen';

  @override
  String get refreshAll => 'Alles vernieuwen';

  @override
  String get refreshAllFeeds => 'Alle feeds vernieuwen';

  @override
  String get refreshLabel => 'Vernieuwen';

  @override
  String get refreshPrData => 'PR-gegevens vernieuwen';

  @override
  String get reject => 'Afwijzen';

  @override
  String get rejected => 'Afgewezen';

  @override
  String get reload => 'Herladen';

  @override
  String get remove => 'Verwijderen';

  @override
  String get removeBookmark => 'Bladwijzer verwijderen';

  @override
  String get removeEmbeddingModel => 'Embedding-model verwijderen?';

  @override
  String get removeLogo => 'Logo verwijderen';

  @override
  String get removeRepoFromWorkspace =>
      'Repository uit werkruimte verwijderen?';

  @override
  String get removeRepository => 'Repository verwijderen';

  @override
  String get removeRepositoryConfirm =>
      'Repository uit werkruimte verwijderen?';

  @override
  String get removeVoiceModel => 'Spraakmodel verwijderen?';

  @override
  String get removed => 'Verwijderd';

  @override
  String get renamed => 'Hernoemd';

  @override
  String get reopen => 'Heropenen';

  @override
  String get replyEllipsis => 'Beantwoorden…';

  @override
  String repoRemovedFromWorkspace(String name) {
    return '$name wordt verwijderd uit deze werkruimte. De lokale bestanden op schijf worden niet aangeraakt.';
  }

  @override
  String get reportsTo => 'Rapporteert aan';

  @override
  String get reportsToOptional => 'Rapporteert aan (optioneel)';

  @override
  String reposCount(int count) {
    return 'Repository\'s ($count)';
  }

  @override
  String get reposDescription =>
      'De lokale checkouts waar deze werkruimte op gericht is.';

  @override
  String get repositories => 'Repository\'s';

  @override
  String get repositoriesSettings => 'Repository-instellingen';

  @override
  String get repositoryName => 'Repository-naam';

  @override
  String get requestChanges => 'Wijzigingen aanvragen';

  @override
  String get requested => 'Aangevraagd';

  @override
  String get requestedChanges => 'Wijzigingen aangevraagd';

  @override
  String get requiredIfGhCliUnavailable =>
      'Vereist als gh CLI niet beschikbaar is';

  @override
  String requiredRoleLabel(String role) {
    return 'Vereiste rol: $role';
  }

  @override
  String get requiredRoleOptional => 'Vereiste rol (optioneel)';

  @override
  String get requirements => 'Vereisten';

  @override
  String get reset => 'Resetten';

  @override
  String get resetAllSandboxes => 'Alle sandboxes resetten';

  @override
  String get resolve => 'Oplossen';

  @override
  String get resolved => 'Opgelost';

  @override
  String get restartServerToApply =>
      'Start de server opnieuw op om de wijzigingen toe te passen.';

  @override
  String get restartShell => 'Shell herstarten';

  @override
  String get restartToApply =>
      'Start de server opnieuw op om wijzigingen toe te passen.';

  @override
  String get retry => 'Opnieuw proberen';

  @override
  String get review => 'Review';

  @override
  String get reviewChanges => 'Wijzigingen reviewen';

  @override
  String get reviewedByMe => 'Door mij gereviewd';

  @override
  String get reviewers => 'REVIEWERS';

  @override
  String get reviewersActive => 'Actieve reviewers';

  @override
  String get reviewsLabel => 'Reviews';

  @override
  String get roleLabel => 'Rol';

  @override
  String get ruleHint =>
      'De regel van de beleidsregel (markdown wordt ondersteund)';

  @override
  String get ruleLabel => 'Regel';

  @override
  String get runCompleted => 'Uitvoering voltooid';

  @override
  String get runGhAuthLoginBody =>
      'Voer `gh auth login` uit in je terminal, tik dan op Vernieuwen.';

  @override
  String get running => 'Actief';

  @override
  String get runningLabel => 'actief';

  @override
  String get runningStatus => 'Actief';

  @override
  String get runs => 'Runs';

  @override
  String get runsAcrossAllAgents => 'Runs over alle agenten';

  @override
  String get runsLabel => 'Runs';

  @override
  String get sandboxBackendNativeLabel => 'Native sandbox';

  @override
  String get sandboxBackendNoneLabel => 'No isolation';

  @override
  String get sandboxLinuxInstall =>
      'Native sandbox op Linux/WSL2 gebruikt bubblewrap. Installeer met:\\n\\n  sudo apt-get install bubblewrap socat ripgrep   # Debian/Ubuntu\\n  sudo dnf install bubblewrap socat ripgrep       # Fedora/RHEL\\n  sudo pacman -S bubblewrap socat ripgrep         # Arch';

  @override
  String get sandboxMacosBuiltIn =>
      'Native sandbox is ingebouwd in macOS — gebruikt Apple Seatbelt (`sandbox-exec`). Geen installatie vereist.';

  @override
  String get sandboxPermissions => 'Sandbox-machtigingen';

  @override
  String get sandboxUnsupported =>
      'Native sandbox wordt op dit platform nog niet ondersteund. Val terug op \"Geen isolatie\".';

  @override
  String get sandboxing => 'Sandboxing';

  @override
  String get sandboxingDescription =>
      'Voer agenten uit in een sandbox op OS-niveau zodat ze niet bij je thuismap, SSH-sleutels of tokens die je niet hebt verleend, kunnen komen.';

  @override
  String get sandboxingDisabledDescription =>
      'Agenten worden direct op de host uitgevoerd met volledige env — niet aanbevolen.';

  @override
  String sandboxingEnabledDescription(String backend) {
    return 'Alle agentaanroepen worden gerouteerd via $backend.';
  }

  @override
  String get save => 'Opslaan';

  @override
  String get saveChanges => 'Wijzigingen opslaan';

  @override
  String get savedArticlesDescription => 'Artikelen die je hebt opgeslagen.';

  @override
  String get savedLabel => 'Opgeslagen';

  @override
  String get savingChanges => 'Wijzigingen opslaan…';

  @override
  String get savingEllipsis => 'Opslaan…';

  @override
  String get scopeDiffToCommits =>
      'Diff beperken tot commits — Shift-klik voor bereik';

  @override
  String get searchAgents => 'Agenten zoeken';

  @override
  String get searchAuthors => 'Auteurs zoeken…';

  @override
  String get searchPullRequestsHint => 'Zoeken… bijv. author:@user';

  @override
  String get noPrsMatchSearch => 'Geen overeenkomende pull requests';

  @override
  String get noPrsMatchSearchHint =>
      'Geen open PR\'s komen overeen met je zoekopdracht. Probeer andere termen of wis de zoekopdracht.';

  @override
  String get searchAuthorsPlaceholder => 'Auteurs zoeken…';

  @override
  String get searchFactsHint => 'Feiten zoeken...';

  @override
  String get searchFonts => 'Lettertypen zoeken…';

  @override
  String get searchGifs => 'GIFs zoeken';

  @override
  String get searchGifsHint => 'GIFs zoeken...';

  @override
  String get searchInDiff => 'Zoeken in diff';

  @override
  String get searchInDiffHint => 'Zoeken in diff…';

  @override
  String get searchOrTypeModel => 'Zoek of typ een modelnaam…';

  @override
  String get searchPlaceholder => 'Zoeken…';

  @override
  String get searchShortcuts => 'Sneltoetsen zoeken…';

  @override
  String get searching => 'Zoeken…';

  @override
  String secondsAgo(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count seconden geleden',
      one: '1 seconde geleden',
    );
    return '$_temp0';
  }

  @override
  String get selectAdapter => 'Adapter selecteren';

  @override
  String get selectAdapterFirst => 'Selecteer eerst een adapter';

  @override
  String get selectAgentToReportTo => 'Selecteer agent om aan te rapporteren…';

  @override
  String get selectAnAgent => 'Een agent selecteren';

  @override
  String get selectConversation => 'Een gesprek selecteren';

  @override
  String get selectEffortLevel => 'Inspanningsniveau selecteren';

  @override
  String get selectLabel => 'Selecteren';

  @override
  String get selectRunner => 'Een runner selecteren';

  @override
  String get semanticSearch => 'Semantisch zoeken';

  @override
  String get send => 'Verzenden';

  @override
  String get sendFirstMessage => 'Verstuur het eerste bericht';

  @override
  String get sendMessage => 'Bericht verzenden';

  @override
  String sentFindingsToAgent(int count) {
    return '$count bevinding(en) naar agent gestuurd.';
  }

  @override
  String get serverRunning => 'Server actief';

  @override
  String get serverStopped => 'Server gestopt';

  @override
  String setGithubLinkDescription(String name) {
    return 'Stel de GitHub-eigenaar en repository-naam in voor $name. Dit wordt gebruikt om PR- en issue-referenties zoals #123 in markdown-inhoud op te lossen.';
  }

  @override
  String get setLabel => 'Instellen';

  @override
  String get setToken => 'Token instellen';

  @override
  String get settingsGeneralDescription =>
      'Weergave, typografie, integraties en MCP-server.';

  @override
  String get settingsLabel => 'Instellingen';

  @override
  String get settingsLanguage => 'Taal';

  @override
  String get settingsLanguageDescription => 'Kies de taal van de app.';

  @override
  String get sharedSecretToken => 'Gedeeld geheim token';

  @override
  String get sharpshooterBadge => 'Scherpschutter';

  @override
  String get shortTask => 'Korte taak';

  @override
  String get showNativeNotifications =>
      'Systeemmeldingen van macOS tonen voor gebeurtenissen.';

  @override
  String get showSuperseded => 'Vervangen tonen';

  @override
  String get signInWithGhAuth =>
      'Log in met gh auth login of voeg een token toe in Instellingen > API-sleutels';

  @override
  String get signedIn => 'Ingelogd.';

  @override
  String signedInAs(String username) {
    return 'Ingelogd als $username.';
  }

  @override
  String get skillEditor => 'Vaardighedeneditor';

  @override
  String get skillNameRequired => 'Vaardigheidsnaam is vereist.';

  @override
  String skillSaved(String name) {
    return 'Vaardigheid \\\"$name\\\" opgeslagen.';
  }

  @override
  String get skills => 'Vaardigheden';

  @override
  String get skillsColon => 'Vaardigheden:';

  @override
  String get skillsCommaSeparated => 'Vaardigheden (door komma\'s gescheiden)';

  @override
  String get skillsLabel => 'VAARDIGHEDEN';

  @override
  String get skipAcceptRisk => 'Overslaan — Ik accepteer het risico';

  @override
  String get skipForNow => 'Voorlopig overslaan';

  @override
  String get skipSandboxing => 'Sandboxing overslaan';

  @override
  String get skipSandboxingDialogContent =>
      'Weet je zeker dat je sandboxing wilt overslaan? Dit staat agenten toe om code op je systeem uit te voeren zonder isolatie.';

  @override
  String get somethingWentWrong => 'Er is iets misgegaan';

  @override
  String sourceCount(int count) {
    return '$count bron';
  }

  @override
  String sourceCountPlural(int count) {
    return '$count bronnen';
  }

  @override
  String get sourceFacts => 'Bronfeiten:';

  @override
  String get splitDiff => 'Diff naast elkaar';

  @override
  String get startDmWithAgent => 'Direct bericht met agent starten';

  @override
  String get startFresh => 'Opnieuw beginnen';

  @override
  String get startLabel => 'Starten';

  @override
  String get startOnAppLaunch => 'Starten bij app-lancering';

  @override
  String get startServerToAccept =>
      'Start de server om MCP-verbindingen te accepteren.';

  @override
  String get stats => 'Statistieken';

  @override
  String get statusLabel => 'Status';

  @override
  String stepConnect(int number) {
    return 'Stap $number · Verbinden';
  }

  @override
  String get stop => 'Stoppen';

  @override
  String get stopped => 'Gestopt';

  @override
  String get streaks => 'Reeksen';

  @override
  String get streaksLabel => 'Reeksen';

  @override
  String get strictIdentityCheck => 'Strikte identiteitscontrole';

  @override
  String get success => 'Succes';

  @override
  String get successLabel => 'Succes';

  @override
  String get successLabelShort => 'Succes';

  @override
  String get successRate => 'Succespercentage';

  @override
  String get suggestAChange => 'Wijziging voorstellen';

  @override
  String get suggestAChangeEllipsis => 'Wijziging voorstellen…';

  @override
  String get suggestLabel => 'SUGGESTIE';

  @override
  String get superseded => 'Vervangen';

  @override
  String get synced => 'Gesynchroniseerd';

  @override
  String get systemDefault => 'Systeemstandaard';

  @override
  String get systemFonts => 'Systeemlettertypen';

  @override
  String get systemPrompt => 'Systeem-prompt';

  @override
  String get systemPromptLabel => 'Systeem-prompt';

  @override
  String get talkToControlCenter => 'Praat met Control Center.';

  @override
  String get tapBadgeDescription => 'Tik op een badge om te zien hoe je stijgt';

  @override
  String get tapBadgeToLevelUp => 'Tik op een badge om te zien hoe je stijgt';

  @override
  String get taskMentionSection => 'Taak';

  @override
  String get testLabel => 'Testen';

  @override
  String get theme => 'Thema';

  @override
  String get themeDark => 'Donker';

  @override
  String get themeLight => 'Licht';

  @override
  String get themeSystem => 'Systeem';

  @override
  String get thisCannotBeUndone => 'Dit kan niet ongedaan worden gemaakt.';

  @override
  String get thisConversation => 'dit gesprek';

  @override
  String get threadLabel => 'Thread';

  @override
  String get throughput => 'Doorvoer';

  @override
  String get ticketLabel => 'TICKET';

  @override
  String tierLabel(String tier) {
    return 'Niveau $tier';
  }

  @override
  String get titleDescription => 'Beschrijving';

  @override
  String get titleLabel => 'Titel';

  @override
  String get todayLabel => 'Vandaag';

  @override
  String get toggleBookmark => 'Bladwijzer wisselen';

  @override
  String get toggleTheme => 'Thema wisselen';

  @override
  String get toggleWorkspaceSwitcher => 'Werkruimtewisselaar wisselen';

  @override
  String get tokenConfigured =>
      'Geconfigureerd — clients moeten dit token presenteren.';

  @override
  String get tokenConfiguredClients =>
      'Geconfigureerd — clients moeten dit token presenteren.';

  @override
  String tokenName(String name) {
    return '$name-token';
  }

  @override
  String get topPerformerLabel => 'TOPPERFORMER';

  @override
  String get topPerformersDescription =>
      'Topperformers, doorvoer en werkruimtegezondheid.';

  @override
  String get topic => 'Onderwerp';

  @override
  String get topicHint => 'bijv. Tech Stack, Design System';

  @override
  String get totalRuns => 'Totaal runs';

  @override
  String get totalRunsLabel => 'Totaal runs';

  @override
  String trackingParamsCount(int count) {
    return '$count trackingparameters';
  }

  @override
  String get typeCommandOrSearch => 'Typ een commando of zoek…';

  @override
  String get typography => 'Typografie';

  @override
  String get unavailable => 'Niet beschikbaar';

  @override
  String get unexpectedError => 'Er is een onverwachte fout opgetreden.';

  @override
  String get unifiedDiff => 'Uniforme diff';

  @override
  String get unknownAuthor => 'Onbekend';

  @override
  String get unnamedAgent => 'Naamloze agent';

  @override
  String get updateKey => 'Sleutel bijwerken';

  @override
  String get updateLabel => 'Bijwerken';

  @override
  String get updateToken => 'Token bijwerken';

  @override
  String updatedDaysAgo(int count) {
    return '$count dagen geleden bijgewerkt';
  }

  @override
  String updatedHoursAgo(int count) {
    return '$count uur geleden bijgewerkt';
  }

  @override
  String get updatedJustNow => 'Zojuist bijgewerkt';

  @override
  String updatedMinutesAgo(int count) {
    return '$count minuten geleden bijgewerkt';
  }

  @override
  String get useSandbox => 'Sandbox gebruiken';

  @override
  String get useWorkspaceDefault => 'Werkruimtestandaard gebruiken';

  @override
  String get userAgent => 'User-Agent';

  @override
  String get userAgentDescription =>
      'Laat leeg om de standaard app User-Agent te gebruiken. Sommige sites blokkeren niet-browser User-Agents.';

  @override
  String get usingSystemDefaultMicrophone =>
      'Standaardmicrofoon van het systeem wordt gebruikt.';

  @override
  String get viewAll => 'Alles bekijken';

  @override
  String get viewLabel => 'Bekijken';

  @override
  String get viewLog => 'Log bekijken';

  @override
  String get viewLogs => 'Logs bekijken';

  @override
  String voiceInstallFailed(String error) {
    return 'Installatie mislukt: $error';
  }

  @override
  String get voiceModelNotInstalled =>
      'Niet geïnstalleerd. Download ~200 MB eenmalig; draait volledig op het apparaat.';

  @override
  String get voiceModelNotInstalledLabel => 'Spraakmodel niet geïnstalleerd.';

  @override
  String get voiceRedownloadBody =>
      'De bestaande modelbestanden worden verwijderd en het ~200 MB-archief opnieuw gedownload. Spraaktranscriptie is niet beschikbaar tot de download is voltooid.';

  @override
  String get voiceRemoveBody =>
      'Spraaktranscriptie wordt uitgeschakeld totdat je het opnieuw installeert. Je kunt het op elk moment opnieuw installeren.';

  @override
  String get voiceTranscription => 'Spraaktranscriptie';

  @override
  String get weakIsolationDescription =>
      'Zwakke isolatie — alleen namespace-grens, geen kernel-grens.';

  @override
  String get whenOffNoDefaultRoute =>
      'Als dit uit staat, start de sandbox zonder een standaardroute.';

  @override
  String get whenOffServerStaysStopped =>
      'Als dit uit staat, blijft de server gestopt totdat je hem start.';

  @override
  String get whisperBaseEn => 'Whisper base.en (sherpa-onnx)';

  @override
  String get whisperInstalled =>
      'Whisper base.en geïnstalleerd. Gebruikt door de microfoonknop in de composer.';

  @override
  String workerLabel(int index) {
    return 'Worker $index';
  }

  @override
  String workersCount(int count) {
    return '$count workers';
  }

  @override
  String get workingMemory => 'Werkgeheugen';

  @override
  String get workspaceName => 'Naam van werkruimte';

  @override
  String get workspaceNotFound => 'Werkruimte niet gevonden';

  @override
  String get workspaceNotesScratchpad => 'Werkruimtenotities en kladblok';

  @override
  String get workspacePulse => 'WERKRUIMTEPOLS';

  @override
  String get workspaceScopedSkills =>
      'Vaardigheidsbestanden toegewezen aan werkruimte, gekoppeld aan agenten.';

  @override
  String workspaceTitle(String name) {
    return 'Werkruimte: $name';
  }

  @override
  String get workspaces => 'Werkruimtes';

  @override
  String get writeLabel => 'Schrijven';

  @override
  String get writePrivateNotes =>
      'Schrijf privénotities, observaties, plannen...';

  @override
  String get writeSkillContent =>
      'Schrijf hier je vaardigheidsinhoud (Markdown)…';

  @override
  String get xp => 'XP';

  @override
  String yearsAgo(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count jaar geleden',
      one: '1 jaar geleden',
    );
    return '$_temp0';
  }

  @override
  String get yesterday => 'gisteren';

  @override
  String get yourAchievements => 'JOUW PRESTATIES';

  @override
  String get focusModeStart => 'Focussessie starten';

  @override
  String get focusModeConfigTitle => 'Focussessie starten';

  @override
  String get focusModeGoalLabel => 'Doel';

  @override
  String get focusModeGoalHint => 'Waar werk je aan?';

  @override
  String get focusModeDurationLabel => 'Duur';

  @override
  String get focusModeBlockNotifications => 'Meldingen blokkeren';

  @override
  String get focusModeStartButton => 'Starten';

  @override
  String get focusModeEndSession => 'Sessie beëindigen';

  @override
  String get focusModeExpand => 'App uitvouwen';

  @override
  String get focusModeFloat => 'Naar balk minimaliseren';

  @override
  String get focusModeActiveTooltip =>
      'Focusmodus actief — tik om te beëindigen';

  @override
  String get dismiss => 'Afwijzen';

  @override
  String get acceptAndResolve => 'Accepteren en oplossen';

  @override
  String reviewFatigueWarning(int minutes) {
    return 'Het lijkt erop dat je veel reviews achter elkaar doet. Neem even pauze!';
  }

  @override
  String get notificationSound => 'Meldingsgeluid';

  @override
  String get notificationSoundDescription =>
      'Geluid dat wordt afgespeeld wanneer een melding wordt weergegeven.';

  @override
  String get notificationSoundNone => 'Geen';

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
  String get notificationSoundTest => 'Testen';

  @override
  String get notificationVolume => 'Volume';

  @override
  String get viewProfile => 'Profiel bekijken';

  @override
  String get clearAllFilters => '× Alles wissen';

  @override
  String acrossNRepos(num count) {
    final intl.NumberFormat countNumberFormat = intl.NumberFormat.compact(
      locale: localeName,
    );
    final String countString = countNumberFormat.format(count);

    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Over $countString repos',
      one: 'Over 1 repo',
    );
    return '$_temp0';
  }

  @override
  String get pullRequestsLabel => 'PRs';

  @override
  String noPrsByUserInWorkspace(String login) {
    return 'Geen PRs van @$login in deze werkruimte';
  }

  @override
  String get usersLabel => 'Gebruikers';

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
  String get checksFailing => 'Controles mislukt';

  @override
  String get reviewsPending => 'Some reviews are pending';

  @override
  String get confirm => 'Confirm';

  @override
  String get trustedSitesSectionTitle => 'Vertrouwde sites';

  @override
  String get trustedSitesEmpty =>
      'Geen vertrouwde sites. Voeg een domein toe om blokkeren daar uit te schakelen.';

  @override
  String get addTrustedSite => 'Vertrouwde site toevoegen';

  @override
  String get removeTrustedSite => 'Verwijderen';

  @override
  String get disableBlockingForThisSite =>
      'Blokkeren uitschakelen op deze site';

  @override
  String get enableBlockingForThisSite => 'Blokkeren inschakelen op deze site';

  @override
  String get enterDomainHint => 'bijv. voorbeeld.com';

  @override
  String get invalidDomain => 'Voer een geldig domein in (bijv. voorbeeld.com)';

  @override
  String get pageLoadTimedOut =>
      'Pagina laden duurde te lang. Herlaad of open in browser.';

  @override
  String get pipelinesScreenTitle => 'Pipelines';

  @override
  String get pipelinesScreenSubtitle =>
      'Declarative multi-step agent workflows';

  @override
  String get pipelinesRunHello => 'Run hello pipeline';

  @override
  String get pipelinesRunPipeline => 'Pipeline uitvoeren';

  @override
  String get pipelineRunLauncherTitle => 'Pipeline uitvoeren';

  @override
  String get pipelineRunSubtitle =>
      'Kies een pipeline en vul de invoer in om een uitvoering te starten.';

  @override
  String get pipelineRunNoInputsBadge => 'Geen invoer';

  @override
  String pipelineRunInputsCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count invoervelden',
      one: '1 invoerveld',
    );
    return '$_temp0';
  }

  @override
  String get pipelineRunNoInputs => 'Deze pipeline heeft geen invoer nodig.';

  @override
  String get pipelineRunSubmit => 'Pipeline uitvoeren';

  @override
  String get pipelineRunCouldNotStart => 'Kan de uitvoering niet starten.';

  @override
  String pipelineRunStarted(String name) {
    return '$name gestart';
  }

  @override
  String get pipelineRunEmptyTitle => 'Geen pipelines klaar om uit te voeren';

  @override
  String get pipelineRunEmptyHint =>
      'Schakel een pipeline in en zet handmatige uitvoering aan in de editor om deze hier te starten.';

  @override
  String get pipelineRunManageTemplates => 'Pipelines beheren';

  @override
  String get pipelineRunSettingsTitle => 'Handmatige uitvoering';

  @override
  String get pipelineRunSettingsAllow => 'Handmatige uitvoering toestaan';

  @override
  String get pipelineRunSettingsAllowHelp =>
      'Toon deze pipeline op de uitvoeringspagina zodat deze handmatig gestart kan worden.';

  @override
  String get pipelineRunSettingsInputsTitle => 'Invoer';

  @override
  String get pipelineRunSettingsAddInput => 'Invoer toevoegen';

  @override
  String get pipelineRunSettingsNoInputs => 'Nog geen invoer.';

  @override
  String get pipelineInputEditTitle => 'Invoerveld';

  @override
  String get pipelineInputKeyLabel => 'Sleutel';

  @override
  String get pipelineInputKeyHelp =>
      'Statussleutel waaronder de waarde wordt opgeslagen (bijv. repoFullName).';

  @override
  String get pipelineInputLabelLabel => 'Label';

  @override
  String get pipelineInputTypeLabel => 'Type';

  @override
  String get pipelineInputOptionsLabel => 'Opties (door komma\'s gescheiden)';

  @override
  String get pipelineInputDefaultLabel => 'Standaardwaarde';

  @override
  String get pipelineInputPlaceholderLabel => 'Tijdelijke aanduiding';

  @override
  String get pipelineInputHelpLabel => 'Helptekst';

  @override
  String get pipelineInputRequiredLabel => 'Verplicht';

  @override
  String get pipelineInputTypeText => 'Tekst';

  @override
  String get pipelineInputTypeMultiline => 'Tekst met meerdere regels';

  @override
  String get pipelineInputTypeNumber => 'Getal';

  @override
  String get pipelineInputTypeBoolean => 'Schakelaar';

  @override
  String get pipelineInputTypeSelect => 'Selectie';

  @override
  String get pipelinesEmpty => 'No pipeline runs yet';

  @override
  String get pipelinesEmptyHint =>
      'Klik op \'Pipeline uitvoeren\' om er een te starten.';

  @override
  String get pipelinesSelectRun => 'Select a pipeline run to view steps';

  @override
  String get pipelinesNoSteps => 'No steps recorded yet';

  @override
  String get pipelinesNoActiveWorkspace =>
      'Selecteer een werkruimte om de pipelines te bekijken';

  @override
  String pipelinesLoadError(String error) {
    return 'Pipelines konden niet worden geladen: $error';
  }

  @override
  String pipelinesRunFailed(String error) {
    return 'Pipeline kon niet worden gestart: $error';
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
    return '$completed van $total stappen';
  }

  @override
  String get pipelineStepStarted => 'Gestart';

  @override
  String get pipelineStepFinished => 'Voltooid';

  @override
  String get pipelineStepDurationLabel => 'Duur';

  @override
  String get pipelineStepBranch => 'Tak';

  @override
  String get pipelineStepError => 'Fout';

  @override
  String get pipelineStepInput => 'Invoer';

  @override
  String get pipelineStepOutput => 'Uitvoer';

  @override
  String get pipelineStepNotExecuted => 'Nog niet uitgevoerd';

  @override
  String get pipelineRunViewTimeline => 'Tijdlijn';

  @override
  String get pipelineRunViewGraph => 'Grafiek';

  @override
  String pipelineRunFailedAtStep(String step) {
    return 'Mislukt bij $step';
  }

  @override
  String get pipelineRunTriggerManual => 'Handmatig';

  @override
  String get pipelineRunTriggerAuto => 'Automatisch';

  @override
  String get pipelineStepSkippedReason => 'Overgeslagen';

  @override
  String get pipelineRunFilterAll => 'Alle';

  @override
  String get pipelineRunFilterEmpty => 'Geen runs komen overeen met dit filter';

  @override
  String get relativeJustNow => 'zojuist';

  @override
  String relativeMinutesAgo(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count min geleden',
      one: '1 min geleden',
    );
    return '$_temp0';
  }

  @override
  String relativeHoursAgo(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count uur geleden',
      one: '1 uur geleden',
    );
    return '$_temp0';
  }

  @override
  String relativeDaysAgo(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count dagen geleden',
      one: '1 dag geleden',
    );
    return '$_temp0';
  }

  @override
  String get automationsTitle => 'Automatiseringen';

  @override
  String get automationsSubtitle =>
      'Start pipelines automatisch wanneer domeingebeurtenissen worden geactiveerd';

  @override
  String get automationsNoTriggers =>
      'Geen triggers geconfigureerd voor deze gebeurtenis.';

  @override
  String get automationsAddTrigger => 'Trigger toevoegen';

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
  String get tasksNoTasks => 'Geen tickets';

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
  String get pipelineTemplatesNav => 'Pipelinesjablonen';

  @override
  String get pipelineTemplatesTitle => 'Pipeline-templates';

  @override
  String get pipelineTemplatesSubtitle =>
      'Drag-and-drop-editor voor de pipelines die je agents orkestreren.';

  @override
  String get pipelineTemplatesNew => 'Nieuwe template';

  @override
  String get pipelineTemplatesEmpty =>
      'Nog geen pipeline-templates. Maak er een om te beginnen.';

  @override
  String get pipelineTemplateIdLabel => 'Template-ID';

  @override
  String get pipelineTemplateBuiltInBadge => 'Ingebouwd';

  @override
  String get pipelineTemplateDeleteConfirmTitle => 'Template verwijderen?';

  @override
  String pipelineTemplateDeleteConfirmBody(String name) {
    return 'Pipeline-template $name verwijderen? Dit kan niet ongedaan worden gemaakt.';
  }

  @override
  String get pipelineTemplateSaved => 'Pipeline-template opgeslagen';

  @override
  String get pipelineTemplateEditorTitle => 'Pipeline bewerken';

  @override
  String get pipelineTemplateEditorSubtitle =>
      'Sleep node-types vanuit de zijbalk naar het canvas en verbind ze.';

  @override
  String get unsavedChanges => 'Niet-opgeslagen wijzigingen';

  @override
  String get nodeLibraryTitle => 'Node-bibliotheek';

  @override
  String get nodeLibraryHint =>
      'Sleep een item naar het canvas om een node toe te voegen.';

  @override
  String get editorDragHint =>
      'Sleep vanuit de bibliotheek, klik een node om te bewerken';

  @override
  String get editorEmptyCanvas =>
      'Sleep een node vanuit de bibliotheek om te beginnen.';

  @override
  String get nodeConfigTitle => 'Node-configuratie';

  @override
  String get nodeConfigKind => 'Type';

  @override
  String get nodeConfigLabel => 'Label';

  @override
  String get nodeConfigAgent => 'Agent';

  @override
  String get nodeConfigAgentHint => 'Kies een agent…';

  @override
  String get nodeConfigInputKeys => 'Invoersleutels (door komma\'s gescheiden)';

  @override
  String get nodeConfigInputKeysHelp =>
      'State-sleutels die deze node gebruikt. Gebruikt voor placeholder-substitutie in de prompt.';

  @override
  String get nodeConfigOutputKey => 'Uitvoersleutel';

  @override
  String get nodeConfigPrompt => 'Prompt-template';

  @override
  String get nodeConfigPromptHelp =>
      'Gebruik placeholders met dubbele accolades om waarden uit de state in te voegen op runtime.';

  @override
  String get nodeConfigScript => 'Bash-script';

  @override
  String get nodeConfigScriptHelp =>
      'Uitgevoerd met bash -c. GITHUB_TOKEN is ingesteld. Placeholders worden vóór uitvoering vervangen.';

  @override
  String get nodeConfigTriggers => 'Geactiveerd door';

  @override
  String get nodeConfigNoUpstream =>
      'Er zijn geen andere nodes om vanaf te verbinden.';

  @override
  String get nodeConfigRouteKeys => 'Routesleutels';

  @override
  String nodeConfigRouteKeyFrom(String source) {
    return 'Routesleutel van $source';
  }

  @override
  String get conditionSectionTitle => 'Voorwaarde';

  @override
  String get conditionMode => 'Modus';

  @override
  String get conditionModeFilesAny => 'Bestand(en) aanwezig — een';

  @override
  String get conditionModeFilesAll => 'Bestanden aanwezig — alle';

  @override
  String get conditionModeComparison => 'Vergelijking';

  @override
  String get conditionModeSwitch => 'Schakelaar';

  @override
  String get conditionFilePaths => 'Bestandspaden';

  @override
  String get conditionFilePathsAnyHelp =>
      'Eén pad per regel, relatief aan de basismap. Geeft true als er een bestaat.';

  @override
  String get conditionFilePathsAllHelp =>
      'Eén pad per regel, relatief aan de basismap. Geeft true alleen als alle bestaan.';

  @override
  String get conditionBaseKey => 'Sleutel van de basismap';

  @override
  String get conditionBaseKeyHelp =>
      'Statussleutel met de map waartegen paden worden opgelost (standaard repoLocalPath).';

  @override
  String get conditionRecursive => 'Submappen doorzoeken';

  @override
  String get conditionNegate => 'Omkeren: true als ontbreekt';

  @override
  String get conditionLeft => 'Linkerwaarde';

  @override
  String get conditionOperator => 'Operator';

  @override
  String get conditionRight => 'Rechterwaarde';

  @override
  String get conditionSwitchKey => 'Schakelen op statussleutel';

  @override
  String get conditionCases => 'Gevallen (door komma\'s gescheiden)';

  @override
  String get conditionCasesHelp =>
      'Routesleutels om met de waarde te vergelijken, op volgorde.';

  @override
  String get conditionDefaultCase => 'Standaardgeval';

  @override
  String get triggerPanelTitle => 'Triggers';

  @override
  String get triggerPanelHelp => 'Wat deze pipeline start.';

  @override
  String get triggerManualHelp =>
      'Toon op de uitvoerpagina en start handmatig.';

  @override
  String get triggerSectionAutomatic => 'Automatische triggers';

  @override
  String get triggerAddButton => 'Trigger toevoegen';

  @override
  String get triggerNoneYet => 'Nog geen automatische triggers.';

  @override
  String get triggerAddDialogTitle => 'Trigger toevoegen';

  @override
  String get triggerKindLabel => 'Triggertype';

  @override
  String get triggerKindEvent => 'Bij een gebeurtenis';

  @override
  String get triggerKindSchedule => 'Volgens een schema';

  @override
  String get triggerIntervalLabel => 'Uitvoeren elke (seconden)';

  @override
  String get triggerEventFieldLabel => 'Gebeurtenis';

  @override
  String get triggerNoMoreEvents =>
      'Alle beschikbare gebeurtenissen zijn al gekoppeld.';

  @override
  String get triggerMatchStatusLabel => 'Alleen wanneer de status is';

  @override
  String get triggerSummaryNone => 'Geen triggers';

  @override
  String triggerEverySeconds(int seconds) {
    return 'Elke ${seconds}s';
  }

  @override
  String get triggerEventManual => 'Handmatige uitvoering';

  @override
  String get triggerEventSchedule => 'Schema';

  @override
  String get triggerEventPrStatusChanged => 'PR-status gewijzigd';

  @override
  String get triggerEventExternalPr => 'Externe PR geopend';

  @override
  String get triggerEventPrPublished => 'PR gepubliceerd';

  @override
  String get triggerEventPrMerged => 'PR samengevoegd';

  @override
  String get triggerEventRepoAdded => 'Repository toegevoegd';

  @override
  String get triggerEventMessageReceived => 'Bericht ontvangen';

  @override
  String get triggerEventTicketCompleted => 'Taak voltooid';

  @override
  String get triggerEventTicketFailed => 'Taak mislukt';

  @override
  String get triggerEventTicketCancelled => 'Taak geannuleerd';

  @override
  String get triggerEventBudgetCrossed => 'Budgetdrempel overschreden';

  @override
  String get automationsManagedHint =>
      'Triggers worden per pipeline in de editor geconfigureerd. Zet ze hier aan of uit.';

  @override
  String get automationsEditInPipeline => 'Bewerken in pipeline';

  @override
  String get nodeLibrarySearchHint => 'Knooppunten zoeken';

  @override
  String get nodeLibraryNoMatches => 'Geen overeenkomende knooppunten';

  @override
  String get nodeCategoryFlow => 'Flow en logica';

  @override
  String get nodeCategoryPr => 'PR-review';

  @override
  String get nodeCategoryAgents => 'Agents';

  @override
  String get nodeCategoryMessaging => 'Berichten';

  @override
  String get nodeCategoryCode => 'Code';

  @override
  String get nodeCategoryDemo => 'Demo';

  @override
  String get triggerDisabledTag => 'uit';

  @override
  String get pipelineInputTypeRepo => 'Repository';

  @override
  String get pipelineRunNoRepos => 'Nog geen repository\'s in deze werkruimte.';

  @override
  String get allowTicketingApi => 'Ticketing-API-aanroepen toestaan';

  @override
  String get ticketingApiKey => 'Ticketing-API-sleutel';

  @override
  String get ticketingApiKeySubtitle =>
      'Injecteert de API-sleutel van de ticketingprovider in de sandbox.';

  @override
  String get ticketingProvider => 'Ticketingprovider';

  @override
  String get connectGitHubAndTicketing =>
      'Verbind GitHub zodat Control Center je pull requests, issues en reviews kan lezen. Verbind optioneel een ticketingprovider. Niets verlaat deze machine.';

  @override
  String get triggerEventTicketAssigned => 'Ticket toegewezen';

  @override
  String get navTickets => 'Tickets';

  @override
  String get ticketsTitle => 'Tickets';

  @override
  String get newTicket => 'Nieuw ticket';

  @override
  String get noTicketsYet => 'Nog geen tickets';

  @override
  String get assignTicket => 'Ticket toewijzen';

  @override
  String get addCollaborator => 'Medewerker toevoegen';

  @override
  String get noCollaborators => 'Nog geen medewerkers';

  @override
  String get linkedPullRequests => 'Gekoppelde pull requests';

  @override
  String get noLinkedPullRequests => 'Nog geen gekoppelde pull requests';

  @override
  String get ticketActivity => 'Activiteit';

  @override
  String get ticketDispatchHint => '@vermeld een agent om die in te zetten…';

  @override
  String get stopAgent => 'Agent stoppen';

  @override
  String get removeQueuedMessage => 'Bericht in wachtrij verwijderen';

  @override
  String get ticketProperties => 'Eigenschappen';

  @override
  String get ticketTabIssue => 'Ticket';

  @override
  String get ticketTabActivity => 'Activiteit';

  @override
  String get ticketTabChanges => 'Wijzigingen';

  @override
  String get ticketTabTerminal => 'Terminal';

  @override
  String get ticketSelectPrompt =>
      'Selecteer een ticket om de details te bekijken';

  @override
  String get ticketNoChanges =>
      'Nog geen wijzigingen in de gekoppelde repository\'s';

  @override
  String get ticketTerminalNoAgent =>
      'Wijs een agent toe om een terminal te openen';

  @override
  String get unassigned => 'Niet toegewezen';

  @override
  String get ticketStatusBacklog => 'Backlog';

  @override
  String get ticketStatusOpen => 'Te doen';

  @override
  String get ticketStatusInProgress => 'Bezig';

  @override
  String get ticketStatusInReview => 'In review';

  @override
  String get ticketStatusDone => 'Klaar';

  @override
  String get ticketStatusBlocked => 'Geblokkeerd';

  @override
  String get ticketStatusFailed => 'Mislukt';

  @override
  String get ticketStatusCancelled => 'Geannuleerd';

  @override
  String get notificationTicketAssigned => 'Ticket toegewezen';

  @override
  String get notificationTicketStatusChanged => 'Ticketstatus gewijzigd';

  @override
  String get notificationTicketCollaboratorAdded => 'Medewerker toegevoegd';

  @override
  String get priority => 'Prioriteit';

  @override
  String get status => 'Status';

  @override
  String get assignee => 'Toegewezen aan';

  @override
  String get ticketDescription => 'Beschrijving';

  @override
  String get ticketPriorityNone => 'Geen';

  @override
  String get ticketPriorityUrgent => 'Urgent';

  @override
  String get ticketPriorityHigh => 'Hoog';

  @override
  String get ticketPriorityMedium => 'Gemiddeld';

  @override
  String get ticketPriorityLow => 'Laag';

  @override
  String get ticketViewList => 'Lijst';

  @override
  String get ticketViewBoard => 'Bord';

  @override
  String get ticketTitlePlaceholder => 'Tickettitel';

  @override
  String get ticketDescriptionPlaceholder => 'Beschrijving toevoegen…';

  @override
  String get createMore => 'Meer aanmaken';

  @override
  String selectedCount(int count) {
    return '$count geselecteerd';
  }

  @override
  String get clearSelection => 'Selectie wissen';

  @override
  String get bulkDeleteTitle => 'Tickets verwijderen';

  @override
  String bulkDeleteMessage(int count) {
    return '$count geselecteerde tickets verwijderen? Dit kan niet ongedaan worden gemaakt.';
  }

  @override
  String get assignTo => 'Toewijzen aan…';

  @override
  String get sectionMembers => 'Leden';

  @override
  String get sectionAgents => 'Agenten';

  @override
  String get sidebarGroupWork => 'Werk';

  @override
  String get sidebarGroupTeam => 'Team';

  @override
  String get notificationsTitle => 'Meldingen';

  @override
  String get notificationsTooltip => 'Meldingen';

  @override
  String get notificationsEmpty => 'Je bent helemaal bij';

  @override
  String get markAllRead => 'Alles als gelezen markeren';

  @override
  String get toggleThemeLabel => 'Thema wisselen';

  @override
  String get teamsNav => 'Teams';

  @override
  String get dashboardGreeting => 'Grüezi';

  @override
  String get dashboardSubtitle => 'Dit is waar je agenten aan werken.';

  @override
  String get recentActivityTitle => 'Recente activiteit';

  @override
  String get noRecentActivity => 'Nog geen recente activiteit';

  @override
  String get noRecentActivitySubtitle =>
      'Agentruns, pull requests en berichten verschijnen hier.';

  @override
  String get noWorkspace => 'Geen werkruimte';

  @override
  String get allAgentsIdle => 'Alle agents inactief';

  @override
  String get statWorkspaces => 'Werkruimtes';

  @override
  String get statAgents => 'Agenten';

  @override
  String get statRunning => 'Actief';

  @override
  String get activeAgentsTitle => 'Actieve agenten';

  @override
  String get noAgentProcessesSubtitle =>
      'Agentactiviteit verschijnt hier wanneer een run start.';

  @override
  String agentIdShort(String id) {
    return 'ID $id';
  }

  @override
  String runningProcessesLabel(int count) {
    return 'Actief · $count';
  }

  @override
  String get noneLabel => 'Geen';

  @override
  String get sidebarGroupKnowledge => 'Kennis';

  @override
  String get navMemory => 'Geheugen';

  @override
  String get memoryTabFacts => 'Feiten';

  @override
  String get memoryTabPolicies => 'Beleid';

  @override
  String get memoryTabGraph => 'Kennisgrafiek';

  @override
  String get memoryNoWorkspace =>
      'Selecteer een werkruimte om het geheugen te bekijken.';

  @override
  String get topStory => 'Uitgelicht';

  @override
  String get searchArticles => 'Artikelen zoeken';

  @override
  String get filterAll => 'Alle';

  @override
  String get filterUnread => 'Ongelezen';

  @override
  String get filterSaved => 'Opgeslagen';

  @override
  String get saveArticle => 'Artikel opslaan';

  @override
  String get removeFromSaved => 'Verwijderen uit opgeslagen';

  @override
  String get filterBySource => 'Filteren op bron';

  @override
  String get viewAsList => 'Lijstweergave';

  @override
  String get viewAsGrid => 'Rasterweergave';

  @override
  String get noMatchingArticles => 'Geen overeenkomende artikelen';

  @override
  String get noMatchingArticlesBody =>
      'Probeer een andere zoekopdracht of bronfilter.';

  @override
  String get allCaughtUp => 'Helemaal bij';

  @override
  String get allCaughtUpBody => 'Geen ongelezen artikelen — kom later terug.';

  @override
  String get openArticlesInAppDescription =>
      'Links openen in de ingebouwde lezer in plaats van je standaardbrowser.';

  @override
  String get blockAdsTrackersDescription =>
      'Advertenties, trackers en cookiebanners verwijderen uit artikelen die je in de lezer opent.';

  @override
  String get agentQuestionHeader => 'Vraag voor jou';

  @override
  String get agentQuestionAnsweredLabel => 'Beantwoord';

  @override
  String get agentQuestionSubmit => 'Antwoord versturen';

  @override
  String get agentQuestionFreeformHint => 'Typ je antwoord…';

  @override
  String get agentQuestionAnswerLabel => 'Jouw antwoord';

  @override
  String get reviewRequested => 'Review aangevraagd';

  @override
  String get loadMorePrs => 'Meer laden';

  @override
  String get loadingMorePrs => 'Meer laden…';

  @override
  String get noPrsMatchFilters =>
      'Geen pull requests komen overeen met de filters in deze repo';

  @override
  String get connectGitHubToLoadPrs =>
      'Verbind GitHub om pull requests te laden';

  @override
  String get noRepositoriesConfigured => 'Geen repository\'s geconfigureerd';

  @override
  String get noAuthors => 'Geen auteurs';

  @override
  String get noAuthorMatches => 'Geen resultaten';

  @override
  String openedAgo(String age) {
    return 'Geopend $age';
  }

  @override
  String updatedAgo(String age) {
    return 'Bijgewerkt $age';
  }

  @override
  String get checksPassing => 'Controles geslaagd';

  @override
  String get checksRunning => 'Controles bezig';

  @override
  String get needsYourReview => 'Vereist jouw review';

  @override
  String diffSummary(int additions, int deletions) {
    return '+$additions −$deletions regels';
  }

  @override
  String get checks => 'Controles';

  @override
  String get noReviewersAssigned => 'Geen reviewers toegewezen';

  @override
  String get noAssignees => 'Geen toegewezen personen';

  @override
  String get noChecksYet => 'Nog geen controles uitgevoerd';

  @override
  String checksFailingCount(int count) {
    return '$count mislukt';
  }

  @override
  String get showMore => 'Meer tonen';

  @override
  String get showLess => 'Minder tonen';

  @override
  String get backToPullRequests => 'Terug naar pull requests';

  @override
  String get pullRequestNotFound => 'Pull request niet gevonden';

  @override
  String get pullRequestNotFoundBody =>
      'Mogelijk is deze samengevoegd, gesloten of verplaatst.';

  @override
  String get couldntLoadPullRequest => 'Kan deze pull request niet laden';

  @override
  String get showDetails => 'Details tonen';

  @override
  String loadingPullRequestNumber(int number) {
    return 'Pull request #$number laden…';
  }

  @override
  String get noDescriptionProvided => 'Geen beschrijving opgegeven.';

  @override
  String get factsHint => 'Feiten verschijnen hier naarmate je agents leren.';

  @override
  String get noFactsMatch => 'Geen feiten komen overeen met je zoekopdracht';

  @override
  String get memoryLoadError => 'Kan geheugen niet laden';

  @override
  String get sortRecent => 'Recent';

  @override
  String get sortConfidence => 'Vertrouwen';

  @override
  String get confidenceTooltip =>
      'Hoe zeker agents zijn dat dit feit klopt, van 0 tot 100%.';

  @override
  String get supersededTooltip => 'Een nieuwer feit heeft dit vervangen.';

  @override
  String get domain => 'Domein';

  @override
  String get fitToView => 'Passend maken';

  @override
  String get project => 'Project';

  @override
  String get projects => 'Projecten';

  @override
  String get newProject => 'Nieuw project';

  @override
  String get editProject => 'Project bewerken';

  @override
  String get deleteProject => 'Project verwijderen';

  @override
  String get noProject => 'Geen project';

  @override
  String get allTickets => 'Alle tickets';

  @override
  String get projectNamePlaceholder => 'Projectnaam';

  @override
  String get projectDescriptionPlaceholder => 'Beschrijving (optioneel)';

  @override
  String get projectColorLabel => 'Kleur';

  @override
  String get noProjectsYet => 'Nog geen projecten';

  @override
  String get projectTicketsEmpty => 'Nog geen tickets in dit project';

  @override
  String get createProject => 'Project aanmaken';

  @override
  String projectProgress(int done, int total) {
    return '$done van $total klaar';
  }

  @override
  String deleteProjectConfirm(String name) {
    return '\"$name\" verwijderen? De tickets blijven behouden en worden uit het project verwijderd.';
  }

  @override
  String get projectStatusActive => 'Actief';

  @override
  String get projectStatusCompleted => 'Voltooid';

  @override
  String get projectStatusArchived => 'Gearchiveerd';

  @override
  String get markProjectCompleted => 'Markeren als voltooid';

  @override
  String get markProjectActive => 'Markeren als actief';

  @override
  String get archiveProject => 'Archiveren';

  @override
  String get restoreProject => 'Herstellen';

  @override
  String get relations => 'Relaties';

  @override
  String get relateTo => 'Koppelen aan';

  @override
  String get relationSubIssueOf => 'Subtaak van…';

  @override
  String get relationParentOf => 'Bovenliggend van…';

  @override
  String get relationBlockedBy => 'Geblokkeerd door…';

  @override
  String get relationBlocking => 'Blokkeert…';

  @override
  String get relationRelatedTo => 'Gerelateerd aan…';

  @override
  String get relationDuplicateOf => 'Duplicaat van…';

  @override
  String get relationGroupParent => 'Bovenliggend';

  @override
  String get relationGroupSubIssues => 'Subtaken';

  @override
  String get relationGroupBlockedBy => 'Geblokkeerd door';

  @override
  String get relationGroupBlocking => 'Blokkeert';

  @override
  String get relationGroupRelated => 'Gerelateerd';

  @override
  String get relationGroupDuplicateOf => 'Duplicaat van';

  @override
  String get relationGroupDuplicatedBy => 'Gedupliceerd door';

  @override
  String get copyId => 'ID kopiëren';

  @override
  String get ticketIdCopied => 'Ticket-ID gekopieerd';

  @override
  String get selectTicket => 'Een ticket selecteren';

  @override
  String get searchTicketsHint => 'Tickets zoeken…';

  @override
  String get noMatchingTickets => 'Geen overeenkomende tickets';

  @override
  String get addToProject => 'Aan project toevoegen';

  @override
  String get activeFleet => 'Actieve vloot';

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
  String get blockedStatus => 'Geblokkeerd';

  @override
  String get failedStatus => 'Mislukt';

  @override
  String get neverRunStatus => 'Nooit uitgevoerd';

  @override
  String get noActiveRun => 'Geen actieve run';

  @override
  String get allPullRequests => 'Alle pull requests';

  @override
  String get clearAll => 'Alles wissen';

  @override
  String get needsYouNow => 'Heeft je nu nodig';

  @override
  String get pipelinesSectionTitle => 'Pipelines';

  @override
  String get allRuns => 'Alle runs';

  @override
  String get triage => 'Triage';

  @override
  String agentsRunningCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count agents actief',
      one: '1 agent actief',
    );
    return '$_temp0';
  }

  @override
  String blockedCountLabel(int count) {
    return '$count geblokkeerd';
  }

  @override
  String needsYouCountLabel(int count) {
    return '$count voor jou';
  }

  @override
  String reviewSummary(int prs, int repos) {
    String _temp0 = intl.Intl.pluralLogic(
      prs,
      locale: localeName,
      other: '$prs PRs wachten',
      one: '1 PR wacht',
    );
    String _temp1 = intl.Intl.pluralLogic(
      repos,
      locale: localeName,
      other: '$repos repo\'s',
      one: '1 repo',
    );
    return '$_temp0 op je review in $_temp1';
  }

  @override
  String reviewsAwaitingYou(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count reviews',
      one: '1 review',
    );
    return '$_temp0 wachten op jou';
  }

  @override
  String reviewsOverTwoDays(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count ouder dan 2 dagen',
      one: '1 ouder dan 2 dagen',
    );
    return '$_temp0';
  }

  @override
  String agentBlockedTitle(String name) {
    return '$name is geblokkeerd';
  }

  @override
  String get agentBlockedSubtitle => 'Wacht op je bevestiging';

  @override
  String get pipelineFailedTitle => 'Pipeline mislukt';

  @override
  String prStaleTitle(String number) {
    return 'PR $number verouderd';
  }

  @override
  String get prStaleSubtitle => 'Geen recente activiteit';

  @override
  String get reviewRequestedBadge => 'Review aangevraagd';

  @override
  String get draftBadge => 'Concept';

  @override
  String get staleLabel => 'Verouderd';

  @override
  String stepsProgress(int done, int total) {
    return '$done van $total stappen';
  }

  @override
  String get allCaughtUpSubtitle =>
      'Geen reviews, blokkades of fouten hebben je nu nodig.';

  @override
  String dashboardGreetingNamed(String name) {
    return 'Grüezi, $name';
  }

  @override
  String workspaceEyebrow(String name) {
    return '$name-werkruimte';
  }

  @override
  String get pipelineTriggerNode => 'Trigger';

  @override
  String get priorityReviewsTooltip =>
      'Open PR\'s die om je review vragen en al meer dan 24 uur wachten.';

  @override
  String get workspaceSettings => 'Werkruimte-instellingen';

  @override
  String get manageWorkspacesSubtitle =>
      'Hernoem een werkruimte en wijzig het merkteken — kies er links een om te bewerken.';

  @override
  String workspaceCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count werkruimtes',
      one: '1 werkruimte',
      zero: 'Geen werkruimtes',
    );
    return '$_temp0';
  }

  @override
  String workspaceReposAgents(int repos, int agents) {
    String _temp0 = intl.Intl.pluralLogic(
      repos,
      locale: localeName,
      other: '$repos repo\'s',
      one: '1 repo',
      zero: 'Geen repo\'s',
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
  String get identity => 'Identiteit';

  @override
  String get uploadImage => 'Afbeelding uploaden';

  @override
  String get workspaceLogoHint =>
      'PNG, JPG of GIF tot 2 MB. Anders gebruiken we de eerste letter van de werkruimte.';

  @override
  String get workspaceNameFieldHelp =>
      'Wordt getoond in de wisselaar, het broodkruimelpad en op elk scherm.';

  @override
  String get dangerZone => 'Gevarenzone';

  @override
  String get deleteThisWorkspace => 'Deze werkruimte verwijderen';

  @override
  String deleteWorkspaceLongDescription(String name) {
    return 'Verwijdert $name, de bijbehorende repositorykoppelingen, agents en geheugen definitief. Dit kan niet ongedaan worden gemaakt.';
  }

  @override
  String get discard => 'Negeren';

  @override
  String discardChangesQuestion(String name) {
    return 'Niet-opgeslagen wijzigingen aan $name negeren?';
  }

  @override
  String get workspaceUpdated => 'Werkruimte bijgewerkt';

  @override
  String get editTitle => 'Titel bewerken';

  @override
  String get editDescription => 'Beschrijving bewerken';

  @override
  String get addDescription => 'Een beschrijving toevoegen';

  @override
  String get prTitlePlaceholder => 'Titel';

  @override
  String get prBodyPlaceholder => 'Voeg een beschrijving toe';

  @override
  String get write => 'Schrijven';

  @override
  String get diff => 'Diff';

  @override
  String get preview => 'Voorbeeld';

  @override
  String get prTemplateLabel => 'Sjabloon';

  @override
  String get prTemplateDefault => 'Standaard';

  @override
  String get addReviewers => 'Reviewers toevoegen';

  @override
  String get addAssignees => 'Toegewezenen toevoegen';

  @override
  String get searchUsers => 'Personen zoeken…';

  @override
  String get searchReviewers => 'Personen en teams zoeken…';

  @override
  String get usersSectionLabel => 'Personen';

  @override
  String get teamsSectionLabel => 'Teams';

  @override
  String get noMatchingUsers => 'Geen overeenkomende personen';

  @override
  String get noMatchingReviewers => 'Geen overeenkomsten';

  @override
  String addCount(int count) {
    return 'Toevoegen ($count)';
  }

  @override
  String get requiredByCodeOwners => 'Vereist door code-eigenaren';

  @override
  String reviewedOnBehalfOf(String login) {
    return 'via $login';
  }

  @override
  String get team => 'Team';

  @override
  String get markdownBold => 'Vet';

  @override
  String get markdownItalic => 'Cursief';

  @override
  String get markdownHeading => 'Kop';

  @override
  String get markdownBulletList => 'Opsommingslijst';

  @override
  String get markdownChecklist => 'Checklist';

  @override
  String get markdownCode => 'Code';

  @override
  String get markdownLink => 'Link';

  @override
  String get markdownQuote => 'Citaat';

  @override
  String failedToUpdateTitle(String error) {
    return 'Kan titel niet bijwerken: $error';
  }

  @override
  String failedToUpdateDescription(String error) {
    return 'Kan beschrijving niet bijwerken: $error';
  }

  @override
  String failedToUpdateReviewers(String error) {
    return 'Kan reviewers niet bijwerken: $error';
  }

  @override
  String failedToUpdateAssignees(String error) {
    return 'Kan toegewezenen niet bijwerken: $error';
  }

  @override
  String get discardChangesConfirm => 'Wijzigingen negeren?';

  @override
  String get newPr => 'Nieuwe PR';

  @override
  String get openPullRequest => 'Een pull request openen';

  @override
  String get composePrSubtitle =>
      'Vanaf een branch die je hebt gepusht — zonder agents of tickets';

  @override
  String get createAsDraft => 'Als concept aanmaken';

  @override
  String get composePrNoRepo => 'Geen GitHub-repository geselecteerd';

  @override
  String get composePrNoRepoHint =>
      'Selecteer een werkruimte met een aan GitHub gekoppelde repository om een pull request te openen.';

  @override
  String get composePrPickBranches =>
      'Kies een basis- en vergelijkingsbranch om de wijzigingen te bekijken.';

  @override
  String get composePrNothingToCompare =>
      'Er zijn geen wijzigingen tussen deze branches.';

  @override
  String get repository => 'Repository';

  @override
  String get baseBranchLabel => 'Basis';

  @override
  String get compareBranchLabel => 'Vergelijken';

  @override
  String get selectBranch => 'Selecteer een branch';

  @override
  String get navMeetings => 'Vergaderingen';

  @override
  String get meetingsNoWorkspace =>
      'Selecteer een werkruimte om vergaderingen te zien.';

  @override
  String get meetingsEmpty =>
      'Nog geen vergaderingen. Start een opname om er een vast te leggen.';

  @override
  String get meetingsStartRecording => 'Opname starten';

  @override
  String get meetingsStopRecording => 'Opname stoppen';

  @override
  String get meetingsProcessing => 'Samenvatten…';

  @override
  String get meetingEnhancedNotes => 'Verrijkte notities';

  @override
  String get meetingYourNotes => 'Jouw notities';

  @override
  String get meetingNotesHint =>
      'Maak korte notities — de agent werkt ze na de vergadering uit.';

  @override
  String get meetingTranscriptTitle => 'Transcriptie';

  @override
  String get meetingNoTranscriptYet =>
      'De transcriptie verschijnt hier terwijl mensen praten.';

  @override
  String get meetingSpeakerMe => 'Jij';

  @override
  String get meetingSpeakerThem => 'Zij';

  @override
  String get meetingStatusRecording => 'Opname';

  @override
  String get meetingStatusProcessing => 'Verwerken';

  @override
  String get meetingStatusDone => 'Klaar';

  @override
  String get meetingStatusFailed => 'Mislukt';

  @override
  String get keybindingGoToMeetings => 'Ga naar vergaderingen';

  @override
  String get keybindingNavigateToTheMeetingsDescription =>
      'Navigeer naar de vergaderingenlijst';

  @override
  String get meetingsOverlineKnowledge => 'Kennis';

  @override
  String get meetingsOverlineEngine => 'Op het apparaat · Whisper base.en';

  @override
  String get meetingsSubtitle =>
      'Lokale opname van je vergaderingen. We tappen de vergaderingsaudio en je microfoon af, transcriberen op het apparaat en laten een agent je summiere notities omzetten in beslissingen en actiepunten — er sluit nooit een bot aan bij het gesprek.';

  @override
  String get meetingsRecordMeeting => 'Vergadering opnemen';

  @override
  String meetingsProcessingNow(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count worden nu verwerkt',
      one: '1 wordt nu verwerkt',
    );
    return '$_temp0';
  }

  @override
  String get meetingsStatThisWeek => 'Deze week';

  @override
  String get meetingsStatThisWeekUnit => 'vergaderingen vastgelegd';

  @override
  String get meetingsStatRecorded => 'Opgenomen';

  @override
  String get meetingsStatRecordedUnit => 'lokaal getranscribeerd';

  @override
  String get meetingsStatOpen => 'Open';

  @override
  String get meetingsStatOpenUnit => 'openstaande actiepunten';

  @override
  String get meetingsStatLogged => 'Vastgelegd';

  @override
  String get meetingsStatLoggedUnit => 'beslissingen geëxtraheerd';

  @override
  String get meetingsCaptureTitle =>
      'Stuurloze systeemaudio-opname staat scherp.';

  @override
  String get meetingsCaptureBody =>
      'Control Center tapt de luidsprekeruitvoer af van de app waarin je bezig bent — Slack Huddle, Meet, Zoom, Tuple — plus je microfoon, en decodeert beide streams op dit apparaat.';

  @override
  String get meetingsCapturePermission => 'Toestemming verleend';

  @override
  String get meetingsCaptureOnDevice => '100% op het apparaat';

  @override
  String get meetingsCaptureNoBot => 'Geen bot sluit aan';

  @override
  String get meetingsScopeAll => 'Alle vergaderingen';

  @override
  String get meetingsFilterAll => 'Alle';

  @override
  String get meetingsFilterDone => 'Klaar';

  @override
  String get meetingsFilterProcessing => 'Bezig';

  @override
  String get meetingsSearchHint => 'Filter op titel, persoon, app…';

  @override
  String get meetingsBucketToday => 'Vandaag';

  @override
  String get meetingsBucketYesterday => 'Gisteren';

  @override
  String get meetingsBucketEarlierThisWeek => 'Eerder deze week';

  @override
  String get meetingsBucketLastWeek => 'Vorige week';

  @override
  String get meetingsBucketOlder => 'Ouder';

  @override
  String meetingsDecisionsCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count beslissingen',
      one: '1 beslissing',
    );
    return '$_temp0';
  }

  @override
  String meetingsActionItemsProgress(int done, int total) {
    return '$done / $total actiepunten';
  }

  @override
  String get meetingsEnhancedPill => 'verrijkt';

  @override
  String get meetingsTranscribing => 'transcriberen en samenvatten…';

  @override
  String get meetingsOpenAction => 'Openen';

  @override
  String get meetingsStopProcessing => 'Stoppen';

  @override
  String get meetingsStillTranscribing =>
      'Nog aan het transcriberen — de samenvatting verschijnt zodra het klaar is.';

  @override
  String get meetingsNoMatch => 'Geen vergadering komt overeen';

  @override
  String get meetingsNoMatchHint => 'Probeer een ander filter of zoekterm.';

  @override
  String get meetingBackAllMeetings => 'Alle vergaderingen';

  @override
  String meetingPeopleCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count personen',
      one: '1 persoon',
    );
    return '$_temp0';
  }

  @override
  String get meetingReRunSummary => 'Samenvatting opnieuw maken';

  @override
  String get meetingExport => 'Exporteren';

  @override
  String get meetingAugmentingBanner =>
      'Je notities worden verrijkt vanuit het transcript — beslissingen en actiepunten worden geëxtraheerd…';

  @override
  String get meetingTabNotes => 'Notities';

  @override
  String get meetingTabTranscript => 'Transcript';

  @override
  String get meetingTabActionItems => 'Actiepunten';

  @override
  String get meetingTabDecisions => 'Beslissingen';

  @override
  String get meetingNotesEnhancedToggle => 'Verrijkt';

  @override
  String get meetingNotesYoursToggle => 'Jouw notities';

  @override
  String get meetingEnhancedByAgent =>
      'Verrijkt door de agent · uit het transcript';

  @override
  String get meetingEnhancedPending =>
      'De agent werkt nog aan deze samenvatting.';

  @override
  String get meetingNotesEmpty => 'Nog geen verrijkte notities.';

  @override
  String get meetingNotesSavedLocally => 'Lokaal opgeslagen';

  @override
  String get meetingNotesSaving => 'Opslaan…';

  @override
  String get meetingViewFullTranscript => 'Volledig transcript bekijken';

  @override
  String get meetingTranscriptSearchHint => 'Zoek in het transcript…';

  @override
  String get meetingSpeakerEveryone => 'Iedereen';

  @override
  String get meetingSpeakerOthers => 'Anderen';

  @override
  String get meetingTranscriptEmpty => 'Nog geen transcript.';

  @override
  String get meetingActionItemsEmpty => 'Geen actiepunten geëxtraheerd.';

  @override
  String get meetingActionItemFrom => 'uit deze vergadering';

  @override
  String get meetingCreateTicket => 'Ticket aanmaken';

  @override
  String meetingTicketCreated(String key) {
    return 'Ticket $key aangemaakt en verstuurd.';
  }

  @override
  String get meetingTicketFailed => 'Kon het ticket niet aanmaken.';

  @override
  String get meetingDecisionsEmpty => 'Geen beslissingen vastgelegd.';

  @override
  String get meetingEditTitle => 'Titel bewerken';

  @override
  String get meetingTitleLabel => 'Titel';

  @override
  String get meetingAddActionItem => 'Actiepunt toevoegen';

  @override
  String get meetingEditActionItem => 'Actiepunt bewerken';

  @override
  String get meetingDeleteActionItem => 'Actiepunt verwijderen';

  @override
  String get meetingActionItemContentLabel => 'Actiepunt';

  @override
  String get meetingActionItemContentHint => 'Wat moet er gebeuren?';

  @override
  String get meetingActionItemOwnerLabel => 'Eigenaar';

  @override
  String get meetingActionItemOwnerHint =>
      'Wie is verantwoordelijk? (optioneel)';

  @override
  String get meetingAddDecision => 'Beslissing toevoegen';

  @override
  String get meetingEditDecision => 'Beslissing bewerken';

  @override
  String get meetingDeleteDecision => 'Beslissing verwijderen';

  @override
  String get meetingDecisionContentLabel => 'Beslissing';

  @override
  String get meetingDecisionContentHint => 'Wat is er besloten?';

  @override
  String get meetingReRunStarted =>
      'Samenvatting wordt opnieuw op het transcript gemaakt…';

  @override
  String get meetingReRunDone => 'Samenvatting bijgewerkt.';

  @override
  String get meetingReRunNoTranscript =>
      'Er is nog geen transcript om samen te vatten.';

  @override
  String get meetingExportCopied =>
      'Notities als Markdown naar het klembord gekopieerd.';

  @override
  String get meetingExportNothing => 'Er is nog niets om te exporteren.';

  @override
  String get meetingsRecordingCrumb => 'Opnemen…';

  @override
  String get meetingRecordTitleHint => 'Vergaderingstitel';

  @override
  String get meetingRecordTappingLabel => 'Aftappen:';

  @override
  String get meetingRecordMic => 'Microfoon';

  @override
  String get meetingRecordSystemAudio => 'Systeemaudio';

  @override
  String get meetingRecordPause => 'Pauzeren';

  @override
  String get meetingRecordResume => 'Hervatten';

  @override
  String get meetingRecordStop => 'Stoppen en samenvatten';

  @override
  String get meetingRecordYourNotes => 'Jouw notities';

  @override
  String get meetingRecordNotesTagline =>
      'noteer summier — de agent vult de rest aan';

  @override
  String get meetingRecordNotesPlaceholder =>
      'Typ terwijl je luistert. Een paar fragmenten is genoeg — na het stoppen breidt de agent ze uit met het transcript.';

  @override
  String get meetingRecordLiveTranscript => 'Live transcript';

  @override
  String get meetingRecordDecoding => 'decoderen op het apparaat';

  @override
  String get meetingRecordListening =>
      'Aan het luisteren… spraak verschijnt hier binnen een seconde of twee, gelabeld als Jij / Anderen.';

  @override
  String get meetingRecordPausedHint =>
      'Gepauzeerd — audio wordt genegeerd tot je hervat.';

  @override
  String get meetingRecordNotActive => 'Geen actieve opname.';

  @override
  String get meetingHudRecording => 'opnemen';

  @override
  String get meetingHudPaused => 'gepauzeerd';

  @override
  String get meetingHudOpen => 'Openen';

  @override
  String get meetingHudStop => 'Stoppen';

  @override
  String get orchestrate => 'Orkestreren';

  @override
  String get orchestrationUnavailable => 'Orkestratie niet beschikbaar';

  @override
  String get orchestrationApprove => 'Plan goedkeuren';

  @override
  String get orchestrationReject => 'Afwijzen';

  @override
  String get orchestrationCancel => 'Orkestratie annuleren';

  @override
  String orchestrationRolesSummary(int count, int hires) {
    return '$count rollen — $hires nieuwe aanstellingen';
  }

  @override
  String orchestrationSubTicketsSummary(int count) {
    return '$count subtickets';
  }

  @override
  String orchestrationEstimatedCost(String amount) {
    return 'Geschatte kosten: $amount \$';
  }

  @override
  String orchestrationProgress(int done, int total) {
    return '$done/$total subtickets klaar';
  }

  @override
  String get orchestrationStatusProposed => 'Voorgesteld';

  @override
  String get orchestrationStatusApproved => 'Goedgekeurd';

  @override
  String get orchestrationStatusExecuting => 'Bezig';

  @override
  String get orchestrationStatusSynthesizing => 'Synthese';

  @override
  String get orchestrationStatusCompleted => 'Voltooid';

  @override
  String get orchestrationStatusFailed => 'Mislukt';

  @override
  String get orchestrationStatusCancelled => 'Geannuleerd';

  @override
  String get messageFailed => 'Run mislukt';

  @override
  String get retried => 'Opnieuw geprobeerd';

  @override
  String replyingTo(String name) {
    return 'in reactie op $name';
  }

  @override
  String get recentRuns => 'Recente runs';

  @override
  String get runIdCopied => 'Run-id gekopieerd';

  @override
  String get copyRunId => 'Run-id kopiëren';

  @override
  String get copyLogPath => 'Logpad kopiëren';

  @override
  String get silenceTimeoutLabel => 'Stilte-time-out (minuten)';

  @override
  String get silenceTimeoutHint =>
      'bijv. 15 — beëindigt een run na deze tijd zonder uitvoer';

  @override
  String get ticketOutput => 'Uitvoer';

  @override
  String missingRequiredField(String field) {
    return 'Verplicht veld ontbreekt: $field';
  }

  @override
  String get capabilityJsonMode => 'JSON-modus';

  @override
  String get capabilityModelSelection => 'Modelselectie';

  @override
  String get transcriptThinking => 'Aan het denken…';

  @override
  String transcriptThoughtFor(String duration) {
    return 'Heeft $duration nagedacht';
  }

  @override
  String get transcriptStatusMakingEdits => 'Bewerkingen aanbrengen…';

  @override
  String get transcriptStatusReadingFiles => 'Bestanden lezen…';

  @override
  String get transcriptStatusSearching => 'Codebase doorzoeken…';

  @override
  String get transcriptStatusRunningCommands => 'Opdrachten uitvoeren…';

  @override
  String get transcriptStatusResponding => 'Aan het antwoorden…';

  @override
  String transcriptStatusRunningTool(String tool) {
    return '$tool uitvoeren…';
  }

  @override
  String get transcriptInput => 'Invoer';

  @override
  String get transcriptOutput => 'Uitvoer';

  @override
  String get transcriptShowMore => 'Meer tonen';

  @override
  String get transcriptShowLess => 'Minder tonen';

  @override
  String transcriptToolCalls(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count tool-aanroepen',
      one: '1 tool-aanroep',
    );
    return '$_temp0';
  }

  @override
  String get transcriptErrorLabel => 'Fout';

  @override
  String get transcriptInterrupted => 'Onderbroken';

  @override
  String get transcriptSandboxBlocked => 'Sandbox heeft een actie geblokkeerd';

  @override
  String get transcriptOutputTruncated => 'Uitvoer ingekort';

  @override
  String transcriptDiffStats(int adds, int dels) {
    return '$adds toevoegingen, $dels verwijderingen';
  }

  @override
  String meetingSpeakerPerson(int number) {
    return 'Persoon $number';
  }

  @override
  String get meetingRenameSpeakerTooltip => 'Spreker hernoemen';

  @override
  String get meetingRenameSpeakerTitle => 'Spreker hernoemen';

  @override
  String get meetingSpeakerNameLabel => 'Naam';

  @override
  String get meetingLinkEvent => 'Koppelen aan gebeurtenis';

  @override
  String get meetingChangeEvent => 'Gebeurtenis wijzigen';

  @override
  String get meetingLinkEventTitle => 'Koppelen aan een agendagebeurtenis';

  @override
  String get meetingLinkEventSearchHint => 'Gebeurtenissen zoeken';

  @override
  String get meetingLinkEventEmpty => 'Geen agendagebeurtenissen in de buurt';

  @override
  String get meetingUnlinkEvent => 'Koppeling verwijderen';

  @override
  String get calendarLinkExistingMeeting =>
      'Koppelen aan bestaande vergadering';

  @override
  String get calendarLinkMeetingTitle => 'Een vergadering koppelen';

  @override
  String get calendarLinkMeetingSearchHint => 'Vergaderingen zoeken';

  @override
  String get calendarLinkMeetingEmpty => 'Geen vergaderingen om te koppelen';

  @override
  String get meetingRenameSpeakerFailed => 'Kan de spreker niet hernoemen';

  @override
  String get calendarLinkUpdateFailed =>
      'Kan de agendakoppeling niet bijwerken';
}
