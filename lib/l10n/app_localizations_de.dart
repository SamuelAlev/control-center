// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for German (`de`).
class AppLocalizationsDe extends AppLocalizations {
  AppLocalizationsDe([String locale = 'de']) : super(locale);

  @override
  String get navCalendar => 'Kalender';

  @override
  String get calendarViewMonth => 'Monat';

  @override
  String get calendarViewWeek => 'Woche';

  @override
  String get calendarViewAgenda => 'Agenda';

  @override
  String get calendarConnectGoogle => 'Google Calendar verbinden';

  @override
  String get calendarConnectDescription =>
      'Synchronisiere deinen Google Calendar, um Termine hier zu sehen und vor Beginn von Meetings benachrichtigt zu werden.';

  @override
  String get calendarDisconnect => 'Trennen';

  @override
  String get calendarReconnect => 'Erneut verbinden';

  @override
  String get calendarEmptyNoEvents => 'Keine Termine in diesem Zeitraum';

  @override
  String get calendarStartRecording => 'Aufnahme starten';

  @override
  String get calendarStartRecordingAndLink => 'Aufnehmen und verknüpfen';

  @override
  String get calendarJoinMeet => 'Meeting beitreten';

  @override
  String get calendarFromCalendar => 'Aus dem Kalender';

  @override
  String get calendarLinkedMeeting => 'Verknüpftes Meeting';

  @override
  String get calendarToday => 'Heute';

  @override
  String get calendarAllDay => 'Ganztägig';

  @override
  String calendarWeekNumber(int number) {
    return 'Woche $number';
  }

  @override
  String get calendarPreviousPeriod => 'Zurück';

  @override
  String get calendarNextPeriod => 'Weiter';

  @override
  String calendarLastSynced(String time) {
    return 'Synchronisiert $time';
  }

  @override
  String get calendarNeverSynced => 'Noch nicht synchronisiert';

  @override
  String get calendarSyncing => 'Wird synchronisiert…';

  @override
  String get calendarViewDay => 'Tag';

  @override
  String get calendarSectionCalendars => 'Kalender';

  @override
  String get calendarShow => 'Einblenden';

  @override
  String get calendarHide => 'Ausblenden';

  @override
  String get calendarRsvpGoing => 'Dabei?';

  @override
  String get calendarRsvpYes => 'Ja';

  @override
  String get calendarRsvpNo => 'Nein';

  @override
  String get calendarRsvpMaybe => 'Vielleicht';

  @override
  String get calendarRsvpFailed => 'Antwort konnte nicht aktualisiert werden';

  @override
  String get calendarAddAccount => 'Kalenderkonto hinzufügen';

  @override
  String get calendarSettingsTitle => 'Google Calendar';

  @override
  String get calendarSettingsDescription =>
      'Verbinde ein Google-Konto, um Termine in diesen Workspace zu synchronisieren.';

  @override
  String get calendarNotConnected => 'Kein Google-Konto verbunden';

  @override
  String get calendarConnecting => 'Verbinden…';

  @override
  String get calendarSyncNow => 'Jetzt synchronisieren';

  @override
  String get calendarNoWorkspace =>
      'Wähle einen Workspace, um seinen Kalender zu sehen';

  @override
  String get calendarConnectError =>
      'Google Calendar konnte nicht verbunden werden';

  @override
  String get notificationMeetingStartsSoon => 'Meeting beginnt bald';

  @override
  String get notifyMeetingStartsSoon =>
      'Wenn ein Termin im Kalender gleich beginnt';

  @override
  String get notificationCalendarAuthExpiredTitle => 'Kalender getrennt';

  @override
  String notificationCalendarAuthExpiredBody(String email) {
    return 'Verbinde $email erneut, um die Synchronisierung fortzusetzen';
  }

  @override
  String get notificationCalendarAuthExpiredBodyNoEmail =>
      'Verbinde deinen Kalender erneut, um die Synchronisierung fortzusetzen';

  @override
  String get notifyCalendarAuthExpired =>
      'Wenn ein Kalenderkonto erneut verbunden werden muss';

  @override
  String get calendarAlertLeadTime => 'Vorlaufzeit der Erinnerung';

  @override
  String get calendarAlertLeadTimeSubtitle =>
      'Wie lange vor einem Meeting du benachrichtigt wirst';

  @override
  String calendarConnectedAs(String email) {
    return 'Verbunden als $email';
  }

  @override
  String calendarAttendeesCount(int count) {
    return '$count Teilnehmer';
  }

  @override
  String get calendarEventLabel => 'Termin';

  @override
  String get calendarRecurring => 'Wiederkehrender Termin';

  @override
  String get calendarGoogleMeet => 'Google Meet';

  @override
  String get calendarOrganizer => 'Organisator';

  @override
  String get calendarYou => 'Du';

  @override
  String get calendarShowFewer => 'Weniger anzeigen';

  @override
  String get calendarRsvpAwaiting => 'Ausstehend';

  @override
  String calendarParticipantsCount(int count) {
    return '$count Teilnehmer';
  }

  @override
  String calendarSeeAllParticipants(int count) {
    return 'Alle $count Teilnehmer anzeigen';
  }

  @override
  String calendarRsvpCountYes(int count) {
    return '$count zugesagt';
  }

  @override
  String calendarRsvpCountNo(int count) {
    return '$count abgesagt';
  }

  @override
  String calendarRsvpCountMaybe(int count) {
    return '$count vielleicht';
  }

  @override
  String calendarRsvpCountAwaiting(int count) {
    return '$count ausstehend';
  }

  @override
  String calendarLeadMinutesOption(int count) {
    return '$count Minuten';
  }

  @override
  String get openInEditorPrompt => 'In welchem Editor öffnen?';

  @override
  String get ideNotInstalled => 'Nicht installiert';

  @override
  String openInIde(String editor) {
    return 'In $editor öffnen';
  }

  @override
  String failedToOpenInIde(String editor, String error) {
    return '$editor konnte nicht geöffnet werden: $error';
  }

  @override
  String get profileSearchHint => 'Pull Requests suchen…';

  @override
  String get profileClickToLoad => 'Zum Laden klicken';

  @override
  String get profileStateOpenHint => 'Aktuell offen';

  @override
  String get profileStateMergedHint => 'Zusammengeführter Verlauf';

  @override
  String get profileStateClosedHint => 'Geschlossen, nicht zusammengeführt';

  @override
  String get profileNoPrsForFilter =>
      'Keine Pull Requests für die ausgewählten Status';

  @override
  String get byAuthorPrefix => 'von';

  @override
  String get youLabel => 'du';

  @override
  String get readyToMerge => 'Bereit zum Mergen';

  @override
  String get laneReadyHint => 'Checks grün';

  @override
  String get laneReviewHint => 'Wartet auf dich';

  @override
  String get inProgress => 'In Arbeit';

  @override
  String get laneInProgressHint => 'Offen · in Arbeit';

  @override
  String get needsAttention => 'Erfordert Aufmerksamkeit';

  @override
  String get laneAttentionHint => 'Fehlgeschlagen oder veraltet';

  @override
  String get drafts => 'Entwürfe';

  @override
  String get laneDraftsHint => 'Noch nicht geöffnet';

  @override
  String get allOpenPrs => 'Alle offenen PRs';

  @override
  String showAllCount(int count) {
    return 'Alle anzeigen ($count)';
  }

  @override
  String get sortOldest => 'Älteste';

  @override
  String get sortLargest => 'Größte';

  @override
  String get selectAction => 'Auswählen';

  @override
  String mergeCountReady(int count) {
    return '$count bereite mergen';
  }

  @override
  String countSelected(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count ausgewählt',
      one: '1 ausgewählt',
    );
    return '$_temp0';
  }

  @override
  String get mergeReadyAction => 'Bereite mergen';

  @override
  String get nothingInLane => 'Nichts in dieser Spur';

  @override
  String get nothingInLaneHint =>
      'Wähle oben eine andere Spur oder zeige alle offenen PRs.';

  @override
  String get summary => 'Zusammenfassung';

  @override
  String get openFullDiff => 'Vollständigen Diff öffnen';

  @override
  String get viewFiles => 'Dateien anzeigen';

  @override
  String get checksLabel => 'Checks';

  @override
  String get commentsLabel => 'Kommentare';

  @override
  String get mergeReadyConfirmTitle => 'Bereite Pull Requests mergen?';

  @override
  String mergeReadyConfirmBody(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other:
          '$count bereite PRs per Squash mergen? Kann nicht rückgängig gemacht werden.',
      one:
          '1 bereite PR per Squash mergen? Kann nicht rückgängig gemacht werden.',
    );
    return '$_temp0';
  }

  @override
  String mergedCountPrs(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count PRs gemergt',
      one: '1 PR gemergt',
    );
    return '$_temp0';
  }

  @override
  String get keybindingSelectPr => 'PR auswählen';

  @override
  String get keybindingMergePr => 'PR mergen';

  @override
  String get keybindingPeekPr => 'PR-Vorschau';

  @override
  String get keybindingToggleSelectionOfTheFocusedPullRequestDescription =>
      'Auswahl der fokussierten PR umschalten';

  @override
  String get keybindingMergeTheFocusedPullRequestDescription =>
      'Die fokussierte PR mergen, wenn sie bereit ist';

  @override
  String get keybindingExpandOrCollapseTheFocusedPullRequestPeekDescription =>
      'Vorschaufenster der fokussierten PR ein- oder ausklappen';

  @override
  String get kbMove => 'bewegen';

  @override
  String get kbSelect => 'auswählen';

  @override
  String get kbMerge => 'mergen';

  @override
  String get kbOpen => 'öffnen';

  @override
  String get kbPeek => 'vorschau';

  @override
  String get kbTabs => 'tabs';

  @override
  String get kbSearch => 'suchen';

  @override
  String get kbViewed => 'gesehen';

  @override
  String get kbCollapse => 'einklappen';

  @override
  String get appearance => 'Darstellung';

  @override
  String get appearanceSettingsDescription => 'Design, Sprache und Typografie.';

  @override
  String get notificationsSettingsDescription =>
      'Wählen Sie, welche Agenten- und Arbeitsbereichsereignisse Sie benachrichtigen.';

  @override
  String get integrationsSettingsDescription =>
      'Verbinden Sie GitHub, Ticketing und den MCP-Server.';

  @override
  String get advanced => 'Erweitert';

  @override
  String get advancedSettingsDescription =>
      'Branch-Benennung, Sprache, semantische Suche, Datenschutz und Protokollierung.';

  @override
  String get agentRegistry => 'Agenten-Registry';

  @override
  String get settingsGroupGeneral => 'Allgemein';

  @override
  String get settingsGroupAgents => 'Agenten';

  @override
  String get settingsGroupResources => 'Ressourcen';

  @override
  String get filterSettingsHint => 'Einstellungen filtern';

  @override
  String get needsSetupLabel => 'Einrichtung erforderlich';

  @override
  String noSettingsMatch(String query) {
    return 'Keine Einstellung entspricht „$query“';
  }

  @override
  String get privacy => 'Datenschutz';

  @override
  String get sendDiffContentTitle => 'Diff-Inhalt an KI-Adapter senden';

  @override
  String get diffSharingOnSubtitle =>
      'Rohe Diff-Zeilen werden für eine gründlichere Prüfung in die Agenten-Prompts aufgenommen.';

  @override
  String get diffSharingOffSubtitle =>
      'Agenten verwenden nur strukturierte Metadaten (Dateipfade, Zeilennummern, PR-Beschreibung); kein Rohcode verlässt die App.';

  @override
  String get errorReportingTitle => 'Absturzberichte teilen';

  @override
  String get errorReportingOnSubtitle =>
      'Absturz-, Fehler- und Leistungsdiagnosen werden gesendet, um Fehler zu beheben (nur in Release-Builds).';

  @override
  String get errorReportingOffSubtitle =>
      'Diagnosen sind deaktiviert. Es werden keine Absturz- oder Fehlerberichte gesendet.';

  @override
  String get onboardingDiagnosticsTitle =>
      'Hilf mit, Control Center zu verbessern';

  @override
  String get onboardingDiagnosticsSubtitle =>
      'Sende Absturz-, Fehler- und Leistungsdiagnosen, damit wir Probleme schneller beheben können (nur in Release-Builds). Du kannst dies jederzeit unter Einstellungen → Datenschutz ändern.';

  @override
  String get blocked => 'Blockiert';

  @override
  String get idle => 'Inaktiv';

  @override
  String get noRunsYet => 'Noch keine Ausführungen';

  @override
  String runsInLastSixMonths(String count) {
    return '$count Ausführungen in den letzten 6 Monaten';
  }

  @override
  String lastActiveAgo(String duration) {
    return 'Vor $duration aktiv';
  }

  @override
  String get reportsToNobody => 'Kein Vorgesetzter';

  @override
  String get copyPath => 'Pfad kopieren';

  @override
  String get pathCopied => 'Pfad in die Zwischenablage kopiert';

  @override
  String get editAgent => 'Agent bearbeiten';

  @override
  String get nameRequired => 'Name ist erforderlich';

  @override
  String get titleRequired => 'Titel ist erforderlich';

  @override
  String get import => 'Importieren';

  @override
  String discoverAgentsFound(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count Agentendefinitionen gefunden',
      one: '1 Agentendefinition gefunden',
    );
    return '$_temp0';
  }

  @override
  String get noAgentsToDiscover => 'Keine neuen Agenten zum Importieren';

  @override
  String get noAgentsToDiscoverHint =>
      'Agentendefinitionen in diesem Arbeitsbereich sind bereits importiert.';

  @override
  String get sortByStatus => 'Status';

  @override
  String get sortByName => 'Name';

  @override
  String get noMatchingAgents => 'Keine Agenten entsprechen deinem Filter';

  @override
  String get selectAnAgentHint =>
      'Wähle einen Agenten, um Status, Aktivität und Details zu sehen.';

  @override
  String watchVideoOn(String provider) {
    return 'Video auf $provider ansehen';
  }

  @override
  String get branchTemplate => 'Vorlage für Branch-Namen';

  @override
  String get branchTemplateDescription =>
      'Muster für den Branch, der beim Start eines Tickets in einem isolierten Worktree erstellt wird.';

  @override
  String branchTemplatePreview(String example) {
    return 'Beispiel: $example';
  }

  @override
  String get deletePipelineRun => 'Pipeline-Ausführung löschen';

  @override
  String deletePipelineRunConfirm(String template) {
    return 'Diese Ausführung von „$template“ löschen? Dies kann nicht rückgängig gemacht werden.';
  }

  @override
  String errorDeletingPipelineRun(String error) {
    return 'Fehler beim Löschen der Pipeline-Ausführung: $error';
  }

  @override
  String get deleteTicket => 'Ticket löschen';

  @override
  String deleteTicketConfirm(String title) {
    return '„$title“ löschen? Dies kann nicht rückgängig gemacht werden.';
  }

  @override
  String errorDeletingTicket(String error) {
    return 'Fehler beim Löschen des Tickets: $error';
  }

  @override
  String deleteWorkspaceConfirm(String name) {
    return '„$name“ löschen? Verknüpfte Repositories auf der Festplatte bleiben unberührt.';
  }

  @override
  String errorDeletingWorkspace(String error) {
    return 'Fehler beim Löschen des Arbeitsbereichs: $error';
  }

  @override
  String get indexCode => 'Code indizieren';

  @override
  String get indexing => 'Indizierung…';

  @override
  String get indexNoGrammars => 'Code-Grammatiken nicht installiert';

  @override
  String get indexFailed => 'Indizierung fehlgeschlagen';

  @override
  String indexedSymbolsCount(int count) {
    return '$count Symbole indiziert';
  }

  @override
  String get nodeConfigAdvanced => 'Erweitert';

  @override
  String get nodeConfigReducer => 'Reduzierer';

  @override
  String get nodeConfigReducerHelp =>
      'Wie zusammengeführt wird, wenn dieser Ausgabeschlüssel bereits einen Wert hat';

  @override
  String get nodeConfigTimeoutMs => 'Zeitlimit (ms)';

  @override
  String get nodeConfigRetryAttempts => 'Wiederholungsversuche';

  @override
  String get nodeConfigContinueOnFail =>
      'Fortfahren, wenn dieser Schritt fehlschlägt';

  @override
  String get nodeConfigTeamId => 'Team-ID';

  @override
  String get nodeConfigDispatchMode => 'Verteilungsmodus';

  @override
  String get nodeConfigOutputSchema => 'Ausgabeschema (JSON)';

  @override
  String get nodeConfigOutputSchemaHelp =>
      'JSON-Schema, das die Schrittausgabe erfüllen muss';

  @override
  String get diffLineDisplay => 'Lange Zeilen in Diffs';

  @override
  String get diffLineDisplayDescription =>
      'Lange Zeilen umbrechen oder horizontal scrollen';

  @override
  String get diffLineWrap => 'Umbrechen';

  @override
  String get diffLineScroll => 'Horizontal scrollen';

  @override
  String get actions => 'Aktionen';

  @override
  String get activate => 'Aktivieren';

  @override
  String get activity => 'Aktivität';

  @override
  String get activityLabel => 'AKTIVITÄT';

  @override
  String adRulesCount(int count) {
    return '$count Werberegeln';
  }

  @override
  String get adapter => 'Adapter';

  @override
  String get adapterLabel => 'Adapter';

  @override
  String get adapters => 'Adapter';

  @override
  String get adaptersAutoDetected =>
      'Automatisch erkannte Agent-Runner auf diesem Computer. Installiere fehlende CLI-Tools, um zusätzliche Runner zu aktivieren.';

  @override
  String get add => 'Hinzufügen';

  @override
  String get addAComment => 'Einen Kommentar hinzufügen';

  @override
  String get addAReaction => 'Eine Reaktion hinzufügen';

  @override
  String get addASuggestion => 'Einen Vorschlag hinzufügen';

  @override
  String get addAgent => 'Agent hinzufügen';

  @override
  String get addAgents => 'Agenten hinzufügen';

  @override
  String get addAgentsToEnable =>
      'Agenten hinzufügen, um Multi-Agenten-Orchestrierung zu aktivieren';

  @override
  String get addEmoji => 'Emoji hinzufügen';

  @override
  String get addFeed => 'Feed hinzufügen';

  @override
  String get addFromFile => 'Aus Datei hinzufügen';

  @override
  String get addGif => 'GIF hinzufügen';

  @override
  String get addGithubRepoPrompt =>
      'Mindestens ein GitHub-Repository hinzufügen, um Pull Requests zu sehen';

  @override
  String get addLocalCheckoutDescription =>
      'Füge einen lokalen Checkout hinzu, um ihn aus diesem Arbeitsbereich zu steuern.';

  @override
  String get addRepository => 'Repository hinzufügen';

  @override
  String get addToken => 'Token hinzufügen';

  @override
  String get addWorkspace => 'Arbeitsbereich hinzufügen';

  @override
  String get addWorkspaceEllipsis => 'Arbeitsbereich hinzufügen…';

  @override
  String get added => 'Hinzugefügt';

  @override
  String get addingEllipsis => 'Hinzufügen…';

  @override
  String get advancedLabel => 'Erweitert';

  @override
  String get agent => 'Agent';

  @override
  String agentCount(int count, int plural) {
    String _temp0 = intl.Intl.pluralLogic(
      plural,
      locale: localeName,
      other: 'en',
      one: '',
    );
    return '$count Agent$_temp0';
  }

  @override
  String get agentMdPath => 'Agent-MD-Pfad';

  @override
  String get agentName => 'Agentname';

  @override
  String get agentTitle => 'Agenttitel';

  @override
  String get agentUpdated => 'Agent aktualisiert.';

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
  String get aiReview => 'KI-Review';

  @override
  String get all => 'Alle';

  @override
  String get allAgentsAlreadyInChannel =>
      'Alle Agenten sind bereits in diesem Kanal.';

  @override
  String allAgentsCount(int count) {
    return 'Alle Agenten · $count';
  }

  @override
  String get allCommits => 'Alle Commits';

  @override
  String get allSessionsReset => 'Alle Sandbox-Sitzungen zurückgesetzt.';

  @override
  String get allSources => 'Alle Quellen';

  @override
  String get allStarBadge => 'All-Star';

  @override
  String get allTimeLabel => 'Alle';

  @override
  String get allow => 'Erlauben';

  @override
  String get allowGitPush => 'git push erlauben';

  @override
  String get allowGithubApi => 'GitHub-API-Aufrufe erlauben';

  @override
  String get allowNetwork => 'Allgemeinen Netzwerkzugriff erlauben';

  @override
  String get apiKeys => 'API-Schlüssel';

  @override
  String get appFont => 'App-Schriftart';

  @override
  String get appLogLevelDebugDescription =>
      'Fügt detaillierte Traces hinzu - für Entwicklung.';

  @override
  String get appLogLevelDebugLabel => 'Debug';

  @override
  String get appLogLevelErrorDescription =>
      'Nur Fehler und unerwartete Ausnahmen.';

  @override
  String get appLogLevelErrorLabel => 'Fehler';

  @override
  String get appLogLevelInfoDescription =>
      'Fügt Lebenszyklus- und Statusmeldungen hinzu.';

  @override
  String get appLogLevelInfoLabel => 'Info';

  @override
  String get appLogLevelNoneDescription => 'Keine Konsolenausgabe.';

  @override
  String get appLogLevelNoneLabel => 'Keine';

  @override
  String get appLogLevelVerboseDescription =>
      'Alles. Extrem verbose - nur zum Debuggen verwenden.';

  @override
  String get appLogLevelVerboseLabel => 'Verbose';

  @override
  String get appLogLevelWarningDescription =>
      'Fügt Warnungen und behebbare Probleme hinzu.';

  @override
  String get appLogLevelWarningLabel => 'Warnung';

  @override
  String get appTitle => 'Control Center';

  @override
  String get appearanceLanguage => 'Erscheinungsbild & Sprache';

  @override
  String get apply => 'Anwenden';

  @override
  String get approve => 'Genehmigen';

  @override
  String get approveAndCompact => 'Genehmigen und Kontext komprimieren';

  @override
  String get approveAndExecute => 'Genehmigen und ausführen';

  @override
  String get approveAndHire => 'Genehmigen und einstellen';

  @override
  String get approved => 'Genehmigt';

  @override
  String get articlesSubscribed => 'Artikel aus deinen abonnierten Feeds.';

  @override
  String get askAi => 'Ask AI';

  @override
  String get askAiReview => 'KI-Review anfordern';

  @override
  String get askAiReviewDescription => 'KI bitten, diesen PR zu reviewen';

  @override
  String get askAnything =>
      'Frag alles… (@ für Agenten-Erwähnung, / für Befehle)';

  @override
  String get assignees => 'ZUGEWIESENE';

  @override
  String get attachFiles => 'Dateien anhängen';

  @override
  String get attachImage => 'Bild anhängen';

  @override
  String get attachedAgents => 'Zugeordnete Agenten';

  @override
  String get audioInput => 'Audioeingabe';

  @override
  String get authentication => 'Authentifizierung';

  @override
  String get authenticationToken => 'Authentifizierungstoken';

  @override
  String authoredByLabel(String role) {
    return 'Von: $role';
  }

  @override
  String get authorsLabel => 'Autoren';

  @override
  String authorsWithCount(int count) {
    return 'Autoren · $count';
  }

  @override
  String get autoRecommended => 'Auto (empfohlen)';

  @override
  String get available => 'Verfügbar';

  @override
  String get avgDuration => 'Dauer ø';

  @override
  String get awaitingYourApproval => 'Wartet auf deine Genehmigung';

  @override
  String get awaitingYourReview => 'Wartet auf dein Review';

  @override
  String get back => 'Zurück';

  @override
  String get backLabel => 'Zurück';

  @override
  String get backend => 'Backend';

  @override
  String get blockAdsDescription =>
      'Werbung, Tracker und Cookie-Banner blockieren';

  @override
  String get blockAdsTrackers => 'Werbung, Tracker & Cookie-Banner blockieren';

  @override
  String get blocking => 'Blockiert';

  @override
  String get blockingLabel => 'Blockiert';

  @override
  String get bookmarkLabel => 'Lesezeichen';

  @override
  String get briefDescription => 'Kurze Beschreibung';

  @override
  String get bugLabel => 'BUG';

  @override
  String get bundledDefaultsNeverUpdated => 'Vorinstalliert - nie aktualisiert';

  @override
  String get cached => 'Zwischengespeichert';

  @override
  String get cancel => 'Abbrechen';

  @override
  String get cancelEdit => 'Bearbeitung abbrechen';

  @override
  String get categoryCreation => 'Erstellung';

  @override
  String get categoryDeletion => 'Löschung';

  @override
  String get categoryEditing => 'Bearbeitung';

  @override
  String get categoryNavigation => 'Navigation';

  @override
  String get categorySystem => 'System';

  @override
  String get categoryView => 'Ansicht';

  @override
  String get centurionBadge => 'Centurion';

  @override
  String get change => 'Ändern';

  @override
  String get changesRequested => 'Änderungen angefordert';

  @override
  String get changesSummary => 'Änderungszusammenfassung';

  @override
  String get channelsMentionSection => 'Kanäle';

  @override
  String get checkForUpdates => 'Nach Updates suchen';

  @override
  String get checking => 'Überprüfung';

  @override
  String get checkingEllipsis => 'Überprüfung…';

  @override
  String get checkingGhCli => 'Überprüfe gh CLI…';

  @override
  String get chooseAppFont => 'App-Schriftart wählen';

  @override
  String get chooseCodeFont => 'Code-Schriftart wählen';

  @override
  String get chooseRunner => 'Wähle deinen Agent-Runner.';

  @override
  String get clear => 'Löschen';

  @override
  String get clickToRetry => 'Klicken, um erneut zu versuchen';

  @override
  String get close => 'Schließen';

  @override
  String get closeEsc => 'Schließen (Esc)';

  @override
  String get closeKeyboardHint => 'Tastenkürzel schließen';

  @override
  String get closePanel => 'Panel schließen';

  @override
  String get closeReader => 'Leser schließen';

  @override
  String get closeThread => 'Thread schließen';

  @override
  String get closed => 'Geschlossen';

  @override
  String get codeFont => 'Code-Schriftart';

  @override
  String get collapse => 'Einklappen';

  @override
  String get commandPalette => 'Befehlspalette';

  @override
  String get commandPaletteOrgMembers => 'Organization members';

  @override
  String get commandPaletteBrowseTeam => 'Browse team';

  @override
  String get commandPaletteBrowseTeamDesc => 'View all organization members';

  @override
  String get commandsMentionSection => 'Befehle';

  @override
  String get comment => 'Kommentar';

  @override
  String get commentOnFile => 'Diese Datei kommentieren';

  @override
  String get commentOnThisFile => 'Diese Datei kommentieren';

  @override
  String get commentSelected => 'Auswahl kommentieren';

  @override
  String get commented => 'Kommentiert';

  @override
  String get commits => 'Commits';

  @override
  String commitsShowingLatest(int loaded, int total) {
    return 'Zeige die letzten $loaded von $total Commits';
  }

  @override
  String get prCloneProgressCloningTitle => 'Repository wird geklont';

  @override
  String prCloneProgressCloningSubtitle(int fileCount) {
    return 'Dieser PR ändert $fileCount Dateien und überschreitet das API-Limit von GitHub. Das Repository wird lokal geklont…';
  }

  @override
  String get prCloneProgressCloningSubtitleNoCount =>
      'Dieser PR überschreitet das Datei-Limit der GitHub-API. Das Repository wird lokal geklont…';

  @override
  String get prCloneProgressFetchingTitle => 'Refs werden abgerufen';

  @override
  String get prCloneProgressFetchingSubtitle =>
      'Basis-Branch und PR-Ref werden abgerufen…';

  @override
  String get prCloneProgressComputingTitle => 'Diff wird berechnet';

  @override
  String get prCloneProgressComputingSubtitle =>
      'git diff wird lokal ausgeführt…';

  @override
  String get prCloneProgressErrorTitle => 'Diff konnte nicht geladen werden';

  @override
  String get prCloneProgressErrorSubtitle =>
      'Beim Klonen oder Berechnen des Diffs ist ein Fehler aufgetreten.';

  @override
  String prCloneProgressElapsed(String elapsed) {
    return 'Läuft noch… $elapsed vergangen';
  }

  @override
  String confidenceLabel(int percent) {
    return 'Konfidenz: $percent%';
  }

  @override
  String get configureAgentIdentities =>
      'Agent-Identitäten, Prompts, Fähigkeiten konfigurieren und Läufe anzeigen.';

  @override
  String get configureDefaultRunners =>
      'Konfiguriere, welcher Adapter und welches Modell für neue Konversationen und Titelerstellung verwendet werden.';

  @override
  String get configuredLabel => 'Konfiguriert.';

  @override
  String get confirmedBy => 'Bestätigt von';

  @override
  String get consensus => 'Konsens';

  @override
  String get contentBlockingDescription =>
      'Werbung, Tracker und Cookie-Banner blockieren';

  @override
  String get contentHint => 'Was gespeichert werden soll';

  @override
  String get contentLabel => 'Inhalt';

  @override
  String get contentMarkdown => 'Inhalt (Markdown)';

  @override
  String get contextWindowSize => 'Kontextfenstergröße';

  @override
  String get continueLabel => 'Weiter';

  @override
  String get conversationMode => 'Konversationsmodus';

  @override
  String get convertToGroup => 'Zu Gruppe konvertieren?';

  @override
  String get convertToGroupBody =>
      'Das Hinzufügen eines weiteren Agenten verwandelt dies in eine Gruppenkonversation.';

  @override
  String cookieRulesCount(int count) {
    return '$count Cookie-Regeln';
  }

  @override
  String get copied => 'Kopiert!';

  @override
  String get copy => 'Kopieren';

  @override
  String get copyBaseBranchTooltip => 'Namen des Ziel-Branch kopieren';

  @override
  String get copyHeadBranchTooltip => 'Namen des Quell-Branch kopieren';

  @override
  String get couldNotCheckGhCli => 'gh CLI konnte nicht überprüft werden.';

  @override
  String couldNotListDevices(String error) {
    return 'Geräte konnten nicht aufgelistet werden: $error';
  }

  @override
  String get create => 'Erstellen';

  @override
  String get createFirstAgent =>
      'Erstelle deinen ersten Agenten, um loszulegen.';

  @override
  String get createOrSelectWorkspace =>
      'Erstelle oder wähle einen Arbeitsbereich, bevor du Repositorys hinzufügst.';

  @override
  String get createPr => 'PR erstellen';

  @override
  String get createPullRequest => 'Pull Request erstellen';

  @override
  String get createdByMe => 'Von mir erstellt';

  @override
  String createdLabel(String date) {
    return 'Erstellt: $date';
  }

  @override
  String get currentParticipants => 'Aktuelle Teilnehmer';

  @override
  String get customCapabilitiesDescription =>
      'Benutzerdefinierte Fähigkeiten für diesen Agenten';

  @override
  String get customSystemPrompt =>
      'Benutzerdefinierter System-Prompt für diesen Agenten...';

  @override
  String daysAgo(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'vor $count Tagen',
      one: 'vor 1 Tag',
    );
    return '$_temp0';
  }

  @override
  String get deactivate => 'Deaktivieren';

  @override
  String get defaultCapabilities => 'Standardfähigkeiten · neue Konversationen';

  @override
  String get defaultChat => 'Standard-Chat';

  @override
  String defaultPort(int port) {
    return 'Standard: $port.';
  }

  @override
  String defaultPortHint(int port) {
    return 'Standard: $port.';
  }

  @override
  String get defaultRunners => 'Standard-Runner';

  @override
  String get delete => 'Löschen';

  @override
  String get deleteAgent => 'Agent löschen';

  @override
  String deleteAgentConfirm(String name) {
    return '\"$name\" löschen? Dies kann nicht rückgängig gemacht werden.';
  }

  @override
  String get deleteChannel => 'Kanal löschen';

  @override
  String deleteConfirmName(String name) {
    return '\"$name\" löschen?';
  }

  @override
  String get deleteConversation => 'Konversation löschen';

  @override
  String get deleteConversationConfirm =>
      'Diese Konversation löschen? Alle Nachrichten gehen verloren.';

  @override
  String get deleteFact => 'Fakt löschen';

  @override
  String get deleteFeedBody =>
      'Dies entfernt den Feed und alle seine zwischengespeicherten Artikel. Lesezeichen von Artikeln dieses Feeds werden ebenfalls entfernt.';

  @override
  String deleteFeedConfirm(String name) {
    return '\"$name\" löschen?';
  }

  @override
  String deleteNamedConversation(String name) {
    return '\"$name\" löschen? Alle Nachrichten gehen verloren.';
  }

  @override
  String get deletePolicy => 'Richtlinie löschen';

  @override
  String get deletePolicyConfirm =>
      'Diese Richtlinie löschen? Dies kann nicht rückgängig gemacht werden.';

  @override
  String deleteTopicConfirm(String topic) {
    return '\"$topic\" löschen? Dies kann nicht rückgängig gemacht werden.';
  }

  @override
  String get deleteWorkspace => 'Arbeitsbereich löschen';

  @override
  String get deny => 'Verweigern';

  @override
  String get descriptionLabel => 'Beschreibung';

  @override
  String get detailsLabel => 'Details';

  @override
  String detectedBackend(String label) {
    return 'Erkannt: $label';
  }

  @override
  String detectedRunners(int count) {
    return 'Erkannte Runner ($count)';
  }

  @override
  String get detectingAdapters => 'Adapter erkennen…';

  @override
  String get detectingGhCli => 'gh CLI erkennen…';

  @override
  String get detectingInputDevices => 'Eingabegeräte werden erkannt…';

  @override
  String detectionFailed(String error) {
    return 'Erkennung fehlgeschlagen: $error';
  }

  @override
  String diffFailed(String message) {
    return 'Diff fehlgeschlagen: $message';
  }

  @override
  String get diffWorkerPool => 'Worker-Pool';

  @override
  String get directMessage => 'Direktnachricht';

  @override
  String get directMessages => 'Direktnachrichten';

  @override
  String get disabled => 'Deaktiviert';

  @override
  String get discover => 'Entdecken';

  @override
  String get discoverAgents => 'Agenten entdecken';

  @override
  String get discoverAgentsDescription =>
      'Die Agentenentdeckung durchsucht Arbeitsbereichspfade nach AGENTS.md- und TEAM.md-Dateien und parst sie in das Agentenregister.\n\nKonfiguriere zuerst einen Arbeitsbereich und verwende dann diese Funktion, um Agenten automatisch zu füllen.';

  @override
  String get dismissed => 'Verworfen';

  @override
  String get domainHint => 'z.B. api-performance';

  @override
  String get domainLabel => 'Domäne';

  @override
  String get download => 'Herunterladen';

  @override
  String get downloadingLabel => 'Lade herunter';

  @override
  String downloadingModel(int pct) {
    return 'Modell wird heruntergeladen… $pct%';
  }

  @override
  String get draft => 'Entwurf';

  @override
  String get draftLabel => 'Entwurf';

  @override
  String get earnTiersDescription =>
      'Verdiene Stufen durch die Nutzung des Control Center';

  @override
  String get edit => 'Bearbeiten';

  @override
  String get editFact => 'Fakt bearbeiten';

  @override
  String get editPolicy => 'Richtlinie bearbeiten';

  @override
  String get editSuggestedCodeHint => 'Vorgeschlagenen Code bearbeiten…';

  @override
  String get editSuggestion => 'Vorschlag bearbeiten';

  @override
  String get editTheSuggestedCodeHint => 'Den vorgeschlagenen Code bearbeiten…';

  @override
  String get egArchitect => 'z.B. Architekt';

  @override
  String get egControlCenter => 'z.B. control-center';

  @override
  String get egPlatform => 'z.B. macOS';

  @override
  String get egSamuelAlev => 'z.B. SamuelAlev';

  @override
  String get egSoftwareArchitect => 'z.B. Software-Architekt';

  @override
  String get egTheVerge => 'z.B. The Verge';

  @override
  String get egTokenLimit => 'z.B. 128000';

  @override
  String embeddingInstallFailed(String error) {
    return 'Installation fehlgeschlagen: $error';
  }

  @override
  String get embeddingInstalled =>
      'Lokales Embedding-Modell installiert. Hybride Suche ist aktiviert.';

  @override
  String get embeddingModel => 'Embedding-Modell (ONNX)';

  @override
  String get embeddingNotInstalled =>
      'Nicht installiert. Suche greift auf reine Schlüsselwortsuche zurück, bis aktiviert.';

  @override
  String get embeddingRedownloadBody =>
      'Die vorhandenen Modelldateien werden gelöscht und erneut heruntergeladen. Die semantische Suche steht bis zum Abschluss des Downloads nicht zur Verfügung.';

  @override
  String get embeddingRemoveBody =>
      'Die semantische Suche wird deaktiviert, bis du sie neu installierst. Du kannst sie jederzeit wieder installieren.';

  @override
  String get speakerDiarization => 'Sprecher-Diarisierung';

  @override
  String get diarizationModel => 'Diarisierungsmodell';

  @override
  String get diarizationInstalled =>
      'Installiert — benennt einzelne Sprecher in Meeting-Transkripten';

  @override
  String get diarizationNotInstalled =>
      'Nicht installiert — Meeting-Sprecher werden nicht getrennt';

  @override
  String diarizationInstallFailed(String error) {
    return 'Installation fehlgeschlagen: $error';
  }

  @override
  String get redownloadDiarizationModel =>
      'Diarisierungsmodell erneut herunterladen';

  @override
  String get diarizationRedownloadBody =>
      'Dadurch werden die aktuellen Diarisierungsmodelle entfernt und erneut heruntergeladen.';

  @override
  String get removeDiarizationModel => 'Diarisierungsmodell entfernen';

  @override
  String get diarizationRemoveBody =>
      'Dadurch werden die Diarisierungsmodelle auf dem Gerät gelöscht. Bereits erstellte Meeting-Transkripte sind nicht betroffen.';

  @override
  String get onboardingDiarizationTitle => 'Sprecher-Diarisierung (optional)';

  @override
  String get onboardingDiarizationSubtitle =>
      'Herunterladen, um einzelne Sprecher (Person 1, Person 2…) in Meeting-Notizen zu kennzeichnen. Du kannst dies später in den Einstellungen hinzufügen.';

  @override
  String get enableMcpServer => 'MCP-Server aktivieren';

  @override
  String get enableNotifications => 'Benachrichtigungen aktivieren';

  @override
  String get enableSandboxing => 'Sandboxing aktivieren';

  @override
  String get enabled => 'Aktiviert';

  @override
  String enterToken(String name) {
    return '$name-Token eingeben';
  }

  @override
  String get enterTokenToAuth =>
      'Token eingeben, um Authentifizierung zu erzwingen';

  @override
  String errorCreatingAgent(String error) {
    return 'Fehler beim Erstellen des Agenten: $error';
  }

  @override
  String errorDeletingAgent(String error) {
    return 'Fehler beim Löschen des Agenten: $error';
  }

  @override
  String get errorLoadingAgents => 'Fehler beim Laden der Agenten';

  @override
  String errorWithDetail(String error) {
    return 'Fehler: $error';
  }

  @override
  String get errored => 'Fehlerhaft';

  @override
  String get erroredLabel => 'Fehlerhaft';

  @override
  String get exitSelection => 'Auswahl verlassen';

  @override
  String get expand => 'Ausklappen';

  @override
  String get extractingLabel => 'Extrahiere';

  @override
  String extractingModel(int pct) {
    return 'Modell wird extrahiert… $pct%';
  }

  @override
  String get fact => 'Fakt';

  @override
  String factCount(int count) {
    return '$count Fakt';
  }

  @override
  String factCountPlural(int count) {
    return '$count Fakten';
  }

  @override
  String get facts => 'Fakten';

  @override
  String factsPoliciesCount(int factCount, int policyCount) {
    return '$factCount Fakten · $policyCount Richtlinien';
  }

  @override
  String get failed => 'Fehlgeschlagen';

  @override
  String failedToDispatch(String error) {
    return 'Versand fehlgeschlagen: $error';
  }

  @override
  String get failedToLoad => 'Laden fehlgeschlagen';

  @override
  String failedToLoadAgents(String error) {
    return 'Agenten konnten nicht geladen werden: $error';
  }

  @override
  String failedToLoadFeeds(String error) {
    return 'Feeds konnten nicht geladen werden: $error';
  }

  @override
  String get failedToLoadGifs => 'GIFs konnten nicht geladen werden';

  @override
  String failedToLoadLogs(String error) {
    return 'Protokolle konnten nicht geladen werden: $error';
  }

  @override
  String get failedToLoadRepos => 'Repositorys konnten nicht geladen werden';

  @override
  String get failedToLoadWorkspaces =>
      'Arbeitsbereiche konnten nicht geladen werden';

  @override
  String failedToStartAiReview(String error) {
    return 'KI-Review konnte nicht gestartet werden: $error';
  }

  @override
  String get failedToStartMicTest =>
      'Mikrofontest konnte nicht gestartet werden.';

  @override
  String failedToSubmitReview(String error) {
    return 'Review konnte nicht gesendet werden: $error';
  }

  @override
  String failedToUpload(String name, String error) {
    return 'Upload von $name fehlgeschlagen: $error';
  }

  @override
  String failedWithError(String error) {
    return 'Fehlgeschlagen: $error';
  }

  @override
  String get failure => 'Fehlgeschlagen';

  @override
  String get feedAlreadyExists => 'Ein Feed mit dieser URL existiert bereits.';

  @override
  String get feedUrl => 'Feed-URL';

  @override
  String get feedUrlExample => 'z.B. https://example.com/feed.xml';

  @override
  String get feedUrlExists => 'Ein Feed mit dieser URL existiert bereits.';

  @override
  String get feedUrlLabel => 'Feed-URL';

  @override
  String feedsCount(int count) {
    return 'Feeds ($count)';
  }

  @override
  String get feedsLabel => 'Feeds';

  @override
  String get filesChanged => 'Dateien geändert';

  @override
  String filesCount(int count) {
    return '$count Datei(en)';
  }

  @override
  String get filesMentionSection => 'Dateien';

  @override
  String get filterAgents => 'Agenten filtern...';

  @override
  String get filterAgentsPlaceholder => 'Agenten filtern…';

  @override
  String get filterFilesHint => 'Dateien filtern…';

  @override
  String get filterLists => 'Filterlisten';

  @override
  String get filterSkillsPlaceholder => 'Fähigkeiten filtern…';

  @override
  String get finish => 'Abschließen';

  @override
  String get firstReviewBadge => 'Erstes Review';

  @override
  String get fix => 'Korrektur';

  @override
  String get fixSelected => 'Auswahl korrigieren';

  @override
  String get flawlessBadge => 'Makellos';

  @override
  String get forks => 'Forks';

  @override
  String get forward => 'Weiterleiten';

  @override
  String get gatesGithubPatPush =>
      'Steuert GitHub PAT-Injektion. Erforderlich, damit der Agent pushen kann.';

  @override
  String get general => 'Allgemein';

  @override
  String get generalSettingsDescription =>
      'Erscheinungsbild, Typografie, Integrationen und MCP-Server.';

  @override
  String get ghCliAuthButPatOverrideBody =>
      'GitHub CLI ist authentifiziert und bereit, aber ein persönlicher Zugriffstoken ist unten eingestellt und wird stattdessen verwendet. Lösche den PAT, um gh CLI-Authentifizierung zu nutzen.';

  @override
  String get ghCliInstalledAuth =>
      'Installiert. Führe `gh auth login` aus und tippe dann auf Aktualisieren.';

  @override
  String get ghCliNotInstalled =>
      'gh CLI nicht installiert — installiere von cli.github.com.';

  @override
  String get ghCliNotInstalledLabel => 'gh CLI nicht installiert';

  @override
  String get githubCli => 'GitHub CLI';

  @override
  String get githubCliIntegration => 'GitHub CLI-Integration';

  @override
  String get githubCliReady => 'GitHub CLI ist authentifiziert und bereit.';

  @override
  String get githubLink => 'GitHub-Link';

  @override
  String get githubPersonalAccessToken => 'GitHub persönliches Zugriffstoken';

  @override
  String get githubStatusAllOperational => 'Alle Systeme betriebsbereit';

  @override
  String get githubStatusComponents => 'Komponenten';

  @override
  String get githubStatusFetchFailed =>
      'githubstatus.com konnte nicht erreicht werden';

  @override
  String get githubStatusIncidents => 'Aktive Vorfälle';

  @override
  String get githubStatusOpenInBrowser => 'githubstatus.com öffnen';

  @override
  String get githubStatusRefresh => 'Aktualisieren';

  @override
  String get githubStatusTitle => 'GitHub-Status';

  @override
  String githubStatusUpdated(String time) {
    return 'Aktualisiert $time';
  }

  @override
  String lastChecked(String time) {
    return 'Geprüft $time';
  }

  @override
  String get lastCheckedRecently => 'Kürzlich geprüft';

  @override
  String get githubToken => 'GitHub-Token';

  @override
  String get giveAgentsAMemory => 'Agenten ein Gedächtnis geben.';

  @override
  String get giveYourWorkAHome => 'Gib deiner Arbeit ein Zuhause.';

  @override
  String get goBack => 'Zurückgehen';

  @override
  String get goForward => 'Vorwärtsgehen';

  @override
  String get googleFonts => 'Google Fonts';

  @override
  String get groupLabel => 'Gruppe';

  @override
  String get groupName => 'Gruppenname';

  @override
  String get groups => 'Gruppen';

  @override
  String get hideContainerTerminal => 'Container-Terminal ausblenden';

  @override
  String get high => 'Hoch';

  @override
  String get hotStreakBadge => 'Heiße Serie';

  @override
  String hoursAgo(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'vor $count Stunden',
      one: 'vor 1 Stunde',
    );
    return '$_temp0';
  }

  @override
  String get idleStatus => 'Inaktiv';

  @override
  String get images => 'Bilder';

  @override
  String get inFlightLabel => 'In Bearbeitung';

  @override
  String get inactive => 'Inaktiv';

  @override
  String get install => 'Installieren';

  @override
  String get installGhCliBody =>
      'Installiere gh von https://cli.github.com/ und führe `gh auth login` aus, dann auf Aktualisieren tippen.';

  @override
  String get installRequired => 'Installation erforderlich';

  @override
  String get installedNotSignedIn => 'Installiert - nicht angemeldet';

  @override
  String installedVersion(String version) {
    return 'Installiert $version';
  }

  @override
  String get integrations => 'Integrationen';

  @override
  String get invite => 'Einladen';

  @override
  String get inviteAgent => 'Agenten einladen';

  @override
  String get isolateAgentExecution => 'Agentenausführung isolieren.';

  @override
  String jobCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'n',
      one: '',
    );
    return '$count Aufgabe$_temp0';
  }

  @override
  String get justNow => 'gerade eben';

  @override
  String get keepMessages => 'Nachrichten behalten';

  @override
  String get keepSandboxing => 'Sandboxing beibehalten';

  @override
  String get keybindingAdapters => 'Adapter';

  @override
  String get keybindingAddARepositoryDescription => 'Ein Repository hinzufügen';

  @override
  String get keybindingAddRepository => 'Repository hinzufügen';

  @override
  String get keybindingAgents => 'Agenten';

  @override
  String get keybindingApprove => 'Genehmigen';

  @override
  String get keybindingApproveThePeerReviewDescription =>
      'Peer-Review genehmigen';

  @override
  String get keybindingBookmarkOrUnbookmarkTheSelectedArticleDescription =>
      'Ausgewählten Artikel bookmarken oder entbookmarken';

  @override
  String get keybindingCommandPalette => 'Befehlspalette';

  @override
  String get keybindingConversationTab => 'Konversation-Tab';

  @override
  String get keybindingCreateANewAgentDescription => 'Neuen Agenten erstellen';

  @override
  String get keybindingCreateANewGroupChannelDescription =>
      'Neuen Gruppenkanal erstellen';

  @override
  String get keybindingCreateANewWorkspaceDescription =>
      'Neuen Arbeitsbereich erstellen';

  @override
  String get keybindingDeleteAgent => 'Agenten löschen';

  @override
  String get keybindingDeleteChannel => 'Kanal löschen';

  @override
  String get keybindingDeleteTheSelectedAgentDescription =>
      'Ausgewählten Agenten löschen';

  @override
  String get keybindingDeleteTheSelectedChannelDescription =>
      'Ausgewählten Kanal löschen';

  @override
  String get keybindingDeleteTheSelectedWorkspaceDescription =>
      'Ausgewählten Arbeitsbereich löschen';

  @override
  String get keybindingDeleteWorkspace => 'Arbeitsbereich löschen';

  @override
  String get keybindingFilesChangedTab => 'Geänderte Dateien-Tab';

  @override
  String get keybindingFocusSearch => 'Suche fokussieren';

  @override
  String get keybindingFocusThePullRequestSearchFieldDescription =>
      'Das Pull-Request-Suchfeld fokussieren';

  @override
  String get keybindingGeneral => 'Allgemein';

  @override
  String get keybindingGoToAgents => 'Zu den Agenten gehen';

  @override
  String get keybindingGoToAnalytics => 'Zur Analyse gehen';

  @override
  String get keybindingGoToDashboard => 'Zur Übersicht gehen';

  @override
  String get keybindingGoToMemory => 'Zum Speicher gehen';

  @override
  String get keybindingGoToNewsfeed => 'Zum Newsfeed gehen';

  @override
  String get keybindingGoToPipelines => 'Zu Pipelines gehen';

  @override
  String get keybindingGoToPullRequests => 'Zu den Pull Requests gehen';

  @override
  String get keybindingGoToTickets => 'Zu Tickets gehen';

  @override
  String get keybindingKeybindings => 'Tastenkürzel';

  @override
  String get keybindingNavigateToTheAgentsRegistryDescription =>
      'Zum Agentenregister navigieren';

  @override
  String get keybindingNavigateToTheAnalyticsDashboardDescription =>
      'Zum Analyse-Dashboard navigieren';

  @override
  String get keybindingNavigateToTheGlobalDashboardDescription =>
      'Zum globalen Dashboard navigieren';

  @override
  String get keybindingNavigateToTheMemoryDescription =>
      'Zur Wissensdatenbank navigieren';

  @override
  String get keybindingNavigateToTheNewsfeedDescription =>
      'Zum Newsfeed navigieren';

  @override
  String get keybindingNavigateToThePipelinesListDescription =>
      'Zur Pipeline-Liste navigieren';

  @override
  String get keybindingNavigateToThePullRequestListDescription =>
      'Zur Pull-Request-Liste navigieren';

  @override
  String get keybindingNavigateToTheTicketsBoardDescription =>
      'Zur Ticket-Tafel navigieren';

  @override
  String get keybindingNewAgent => 'Neuer Agent';

  @override
  String get keybindingNewDirectMessage => 'Neue Direktnachricht';

  @override
  String get keybindingNewGroup => 'Neue Gruppe';

  @override
  String get keybindingNewWorkspace => 'Neuer Arbeitsbereich';

  @override
  String get keybindingNextArticle => 'Nächster Artikel';

  @override
  String get keybindingNextChannel => 'Nächster Kanal';

  @override
  String get keybindingNextPr => 'Nächste PR';

  @override
  String get keybindingNextWorkspace => 'Nächster Arbeitsbereich';

  @override
  String get keybindingOpenArticle => 'Artikel öffnen';

  @override
  String
  get keybindingOpenOrCloseTheWorkspaceSwitcherPopupInTheSidebarDescription =>
      'Arbeitsbereich-Umschalt-Popup in der Seitenleiste öffnen oder schließen';

  @override
  String get keybindingOpenPr => 'PR öffnen';

  @override
  String get keybindingOpenSettings => 'Einstellungen öffnen';

  @override
  String get keybindingOpenTheAdaptersSettingsPageDescription =>
      'Adapter-Einstellungsseite öffnen';

  @override
  String get keybindingOpenTheAgentsSettingsPageDescription =>
      'Agenten-Einstellungsseite öffnen';

  @override
  String get keybindingOpenTheApplicationSettingsDescription =>
      'Anwendungseinstellungen öffnen';

  @override
  String get keybindingOpenTheCommandPaletteDescription =>
      'Befehlspalette öffnen';

  @override
  String get keybindingOpenTheGeneralSettingsPageDescription =>
      'Allgemeine Einstellungsseite öffnen';

  @override
  String get keybindingOpenTheKeybindingsSettingsPageDescription =>
      'Tastenkürzel-Einstellungsseite öffnen';

  @override
  String get keybindingOpenTheRepositoriesSettingsPageDescription =>
      'Repository-Einstellungsseite öffnen';

  @override
  String get keybindingOpenTheSelectedArticleDescription =>
      'Ausgewählten Artikel öffnen';

  @override
  String get keybindingOpenTheSelectedPullRequestDescription =>
      'Ausgewählte Pull Request öffnen';

  @override
  String get keybindingOpenTheSelectedWorkspaceDescription =>
      'Ausgewählten Arbeitsbereich öffnen';

  @override
  String get keybindingOpenTheSkillsSettingsPageDescription =>
      'Fähigkeiten-Einstellungsseite öffnen';

  @override
  String get keybindingOpenWorkspace => 'Arbeitsbereich öffnen';

  @override
  String get keybindingPreviousArticle => 'Vorheriger Artikel';

  @override
  String get keybindingPreviousChannel => 'Vorheriger Kanal';

  @override
  String get keybindingPreviousPr => 'Vorherige PR';

  @override
  String get keybindingPreviousWorkspace => 'Vorheriger Arbeitsbereich';

  @override
  String get keybindingRefresh => 'Aktualisieren';

  @override
  String get keybindingRefreshAllFeedsDescription => 'Alle Feeds aktualisieren';

  @override
  String get keybindingRefreshAnalyticsDataDescription =>
      'Analysedaten aktualisieren';

  @override
  String get keybindingRefreshDashboardDataDescription =>
      'Dashboard-Daten aktualisieren';

  @override
  String get keybindingRefreshThePullRequestListDescription =>
      'Pull-Request-Liste aktualisieren';

  @override
  String get keybindingRemoveRepository => 'Repository entfernen';

  @override
  String get keybindingRemoveTheSelectedRepositoryDescription =>
      'Ausgewähltes Repository entfernen';

  @override
  String get keybindingRepositories => 'Repositorys';

  @override
  String get keybindingRequestChanges => 'Änderungen anfordern';

  @override
  String get keybindingRequestChangesOnThePeerReviewDescription =>
      'Änderungen am Peer-Review anfordern';

  @override
  String get keybindingRescanForAdaptersDescription =>
      'Nach Adaptern neu scannen';

  @override
  String get keybindingSearchInDiff => 'In Diff suchen';

  @override
  String get keybindingSearchWithinTheDiffViewDescription =>
      'In der Diff-Ansicht suchen';

  @override
  String get keybindingToggleViewed => 'Gesehen umschalten';

  @override
  String get keybindingMarkTheFocusedFileAsViewedOrUnviewedDescription =>
      'Fokussierte Datei als gesehen oder ungesehen markieren';

  @override
  String get keybindingToggleCollapse => 'Zusammenklappen umschalten';

  @override
  String get keybindingCollapseOrExpandTheFocusedFileDescription =>
      'Fokussierte Datei zusammenklappen oder erweitern';

  @override
  String get keybindingSelectTheNextArticleDescription =>
      'Nächsten Artikel auswählen';

  @override
  String get keybindingSelectTheNextChannelDescription =>
      'Nächsten Kanal auswählen';

  @override
  String get keybindingSelectTheNextPullRequestDescription =>
      'Nächste Pull Request auswählen';

  @override
  String get keybindingSelectThePreviousArticleDescription =>
      'Vorherigen Artikel auswählen';

  @override
  String get keybindingSelectThePreviousChannelDescription =>
      'Vorherigen Kanal auswählen';

  @override
  String get keybindingSelectThePreviousPullRequestDescription =>
      'Vorherige Pull Request auswählen';

  @override
  String get keybindingSendMessage => 'Nachricht senden';

  @override
  String get keybindingSendTheCurrentMessageDescription =>
      'Aktuelle Nachricht senden';

  @override
  String get keybindingSkills => 'Fähigkeiten';

  @override
  String get keybindingStartANewDirectMessageDescription =>
      'Neue Direktnachricht starten';

  @override
  String get keybindingSwitchBetweenLightAndDarkModeDescription =>
      'Zwischen hellem und dunklem Modus wechseln';

  @override
  String get keybindingSwitchToTheConversationTabDescription =>
      'Zum Konversation-Tab wechseln';

  @override
  String get keybindingSwitchToTheEighthWorkspaceDescription =>
      'Zum achten Arbeitsbereich wechseln';

  @override
  String get keybindingSwitchToTheFifthWorkspaceDescription =>
      'Zum fünften Arbeitsbereich wechseln';

  @override
  String get keybindingSwitchToTheFilesChangedTabDescription =>
      'Zum geänderte Dateien-Tab wechseln';

  @override
  String get keybindingSwitchToTheFirstWorkspaceDescription =>
      'Zum ersten Arbeitsbereich wechseln';

  @override
  String get keybindingSwitchToTheFourthWorkspaceDescription =>
      'Zum vierten Arbeitsbereich wechseln';

  @override
  String get keybindingSwitchToTheNextWorkspaceDescription =>
      'Zum nächsten Arbeitsbereich wechseln';

  @override
  String get keybindingSwitchToTheNinthWorkspaceDescription =>
      'Zum neunten Arbeitsbereich wechseln';

  @override
  String get keybindingSwitchToThePreviousWorkspaceDescription =>
      'Zum vorherigen Arbeitsbereich wechseln';

  @override
  String get keybindingSwitchToTheSecondWorkspaceDescription =>
      'Zum zweiten Arbeitsbereich wechseln';

  @override
  String get keybindingSwitchToTheSeventhWorkspaceDescription =>
      'Zum siebten Arbeitsbereich wechseln';

  @override
  String get keybindingSwitchToTheSixthWorkspaceDescription =>
      'Zum sechsten Arbeitsbereich wechseln';

  @override
  String get keybindingSwitchToTheThirdWorkspaceDescription =>
      'Zum dritten Arbeitsbereich wechseln';

  @override
  String get keybindingToggleBookmark => 'Bookmark umschalten';

  @override
  String get keybindingToggleTheme => 'Theme umschalten';

  @override
  String get keybindingToggleWorkspaceSwitcher =>
      'Arbeitsbereich-Umschalter umschalten';

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
  String get keybindings => 'Tastaturkürzel';

  @override
  String get keybindingsDescription =>
      'Alle Tastaturkürzel. Kürzel sind fest und können nicht neu zugewiesen werden.';

  @override
  String get killRunning => 'Laufenden beenden';

  @override
  String get klipyNotConfigured => 'KLIPY_APP_KEY nicht konfiguriert';

  @override
  String get klipyNotConfiguredHint =>
      'Übergebe --dart-define=KLIPY_APP_KEY=...\\noder setze sie in der .env vor dem Starten.';

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
    return 'Letzte $count Monate';
  }

  @override
  String get latestLabel => 'Neueste';

  @override
  String get leaderboardLabel => 'BESTENLISTE';

  @override
  String get leaderboardLabelShort => 'Bestenliste';

  @override
  String get leaveACommentEllipsis => 'Kommentar hinterlassen…';

  @override
  String get legendLabel => 'Legende';

  @override
  String get lessLabel => 'Weniger';

  @override
  String get letsPluginTools => 'Lass uns deine Tools einbinden.';

  @override
  String get level => 'Stufe';

  @override
  String levelLabel(int level) {
    return 'Stufe $level';
  }

  @override
  String get liveDiff => 'Live-Diff';

  @override
  String get liveSync => 'Live-Sync';

  @override
  String get loadingAgents => 'Agenten laden…';

  @override
  String get loadingModels => 'Modelle laden…';

  @override
  String get lockedLabel => 'Gesperrt';

  @override
  String get logLevel => 'Log-Level';

  @override
  String get logs => 'Protokolle';

  @override
  String get low => 'Niedrig';

  @override
  String get maintenance => 'Wartung';

  @override
  String get manageParticipants => 'Teilnehmer verwalten';

  @override
  String get manageWorkspaces => 'Arbeitsbereiche verwalten';

  @override
  String get masterToggle => 'Hauptschalter';

  @override
  String get matchOsAppearance =>
      'An das Betriebssystem anpassen oder einen festen Modus wählen.';

  @override
  String get mcpActiveAccepting =>
      'MCP-Server ist aktiv und akzeptiert Verbindungen.';

  @override
  String get mcpAuthToken => 'MCP-Authentifizierungstoken';

  @override
  String get mcpAuthentication => 'Authentifizierung';

  @override
  String get mcpAutoStartDescription =>
      'Wenn deaktiviert, bleibt der Server gestoppt, bis du ihn startest.';

  @override
  String mcpDefaultPort(int port) {
    return 'Standard: $port';
  }

  @override
  String mcpListeningOn(int port) {
    return 'Lauscht auf 127.0.0.1:$port';
  }

  @override
  String mcpListeningOnPort(int port) {
    return 'Lauscht auf 127.0.0.1:$port.';
  }

  @override
  String get mcpNotRunning =>
      'Server läuft nicht. Starte ihn, um MCP-Verbindungen zu aktivieren.';

  @override
  String get mcpRestartPortChanges =>
      'Server muss neu gestartet werden, um Port-Änderungen zu übernehmen.';

  @override
  String get mcpServer => 'MCP-Server';

  @override
  String get mcpServerStopped => 'Server ist gestoppt';

  @override
  String get mcpStatus => 'Status';

  @override
  String get medium => 'Mittel';

  @override
  String get memoryDataHint =>
      'Fakten und Richtlinien erscheinen hier, während Agenten arbeiten.';

  @override
  String get memoryLabel => 'Speicher';

  @override
  String get merge => 'Merge';

  @override
  String get mergeMasterBadge => 'Merge-Meister';

  @override
  String get merged => 'Zusammengeführt';

  @override
  String get messagePlaceholder =>
      'Nachricht… (@ für Erwähnung, / für Befehle)';

  @override
  String get messagingLabel => 'Nachrichten';

  @override
  String get microphonePermissionDenied => 'Mikrofonberechtigung verweigert.';

  @override
  String minutesAgo(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'vor $count Minuten',
      one: 'vor 1 Minute',
    );
    return '$_temp0';
  }

  @override
  String get modelLabel => 'Modell';

  @override
  String get modified => 'Geändert';

  @override
  String monthsAgo(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'vor $count Monaten',
      one: 'vor 1 Monat',
    );
    return '$_temp0';
  }

  @override
  String get more => 'Mehr';

  @override
  String get moreLabel => 'Mehr';

  @override
  String get mozillaUserAgent => 'Mozilla/5.0 …';

  @override
  String get name => 'Name';

  @override
  String get nameAndTitleRequired => 'Name und Titel sind erforderlich.';

  @override
  String get nameAndUrlRequired => 'Name und URL sind erforderlich';

  @override
  String get nameLabel => 'Name';

  @override
  String nativeSandboxAvailable(String platform) {
    return 'Nativer Sandbox ist auf $platform verfügbar.';
  }

  @override
  String get nativeSandboxNeedsInstall =>
      'Installation für nativen Sandbox erforderlich';

  @override
  String get navAnalytics => 'Analyse';

  @override
  String get navDashboard => 'Übersicht';

  @override
  String get navSaved => 'Gespeichert';

  @override
  String get navSettings => 'Einstellungen';

  @override
  String get navigateLabel => 'Navigieren';

  @override
  String networkBlockCount(int count) {
    return '$count Netzwerkblocke';
  }

  @override
  String get neutral => 'Neutral';

  @override
  String get newAgent => 'Neuer Agent';

  @override
  String get newCommitsPushed =>
      'Neue Commits wurden gepusht — klicke, um den Diff neu zu laden';

  @override
  String get newFact => 'Neuer Fakt';

  @override
  String get newGroup => 'Neue Gruppe';

  @override
  String get newLabel => 'Neu';

  @override
  String get newMessage => 'Neue Nachricht';

  @override
  String get newPolicy => 'Neue Richtlinie';

  @override
  String get newPrToReview => 'Neuer PR zur Review';

  @override
  String get newsfeed => 'Newsfeed';

  @override
  String get newsfeedLabel => 'Newsfeed';

  @override
  String get newsfeedSettingsDescription =>
      'Abonnierte Feeds und Leser-Einstellungen verwalten.';

  @override
  String get newsfeedSettingsTitle => 'Newsfeed-Einstellungen';

  @override
  String get nextMatch => 'Nächste Übereinstimmung (↵)';

  @override
  String get noAccessGrants => 'Keine Zugriffsberechtigungen konfiguriert';

  @override
  String get noActiveWorkspace =>
      'Kein aktiver Arbeitsbereich oder Repository ausgewählt.';

  @override
  String get noActiveWorkspaceCreate => 'Kein aktiver Arbeitsbereich';

  @override
  String get noActiveWorkspaceGithub =>
      'Kein aktiver Arbeitsbereich mit einem GitHub-Repository.';

  @override
  String get noAgentAssigned => 'Kein Agent zugewiesen';

  @override
  String get noAgentProcessesRunning => 'Keine Agentenprozesse aktiv';

  @override
  String get noAgents => 'Keine Agenten';

  @override
  String get noAgentsConfigured => 'Keine Agenten konfiguriert';

  @override
  String get noAgentsDiscovered => 'Keine Agenten gefunden';

  @override
  String get noAgentsDiscoveredHint =>
      'Klicke auf \"Entdecken\", um AGENTS.md-Dateien zu suchen, oder \"Agent hinzufügen\", um einen manuell zu konfigurieren';

  @override
  String get noAgentsMatchSearch => 'Keine Agenten entsprechen deiner Suche';

  @override
  String get noAgentsRegisteredYet => 'Noch keine Agenten registriert';

  @override
  String get noArticlesYet => 'Noch keine Artikel';

  @override
  String get noArticlesYetBody => 'Die Artikel deiner Feeds erscheinen hier.';

  @override
  String get noData => 'Keine Daten';

  @override
  String get noDirectMessagesYet => 'Noch keine Direktnachrichten';

  @override
  String get noDomains => 'Noch keine Domains';

  @override
  String get noExecutionLogsYet => 'Noch keine Ausführungsprotokolle';

  @override
  String get noFacts => 'Noch keine Fakten';

  @override
  String get noFeedsYet => 'Noch keine Feeds';

  @override
  String get noFileAnchor =>
      'Kein Dateianker — Inline-Kommentar kann nicht gesendet werden.';

  @override
  String get noFileChangesInScope => 'Keine Dateiänderungen in diesem Bereich';

  @override
  String get noGifsFound => 'Keine GIFs gefunden';

  @override
  String get noGroupsYet => 'Noch keine Gruppen';

  @override
  String get noInputDevicesDetected =>
      'Keine Eingabegeräte erkannt — Verwendung des Systemstandards.';

  @override
  String get noMatchingFiles => 'Keine passenden Dateien';

  @override
  String get noMatchingGoogleFonts => 'Keine passenden Google Fonts.';

  @override
  String get noMemoryData => 'Noch keine Speicherdaten';

  @override
  String get noMessagesYet => 'Noch keine Nachrichten';

  @override
  String get noModelsAdvertised =>
      'Keine Modelle von diesem Adapter angekündigt.';

  @override
  String get noOpenPullRequests => 'Keine offenen Pull Requests';

  @override
  String get noPolicies => 'Noch keine Richtlinien';

  @override
  String get noReposInWorkspaceYet =>
      'Noch keine Repositorys in diesem Arbeitsbereich';

  @override
  String get noRunnersDetected =>
      'Noch keine Runner erkannt. Aktualisiere, um erneut zu suchen.';

  @override
  String get noSavedArticles => 'Noch keine gespeicherten Artikel';

  @override
  String get noSavedArticlesBody =>
      'Die Artikel, die du speicherst, erscheinen hier.';

  @override
  String noShortcutsMatch(String query) {
    return 'Keine Kürzel entsprechen \"$query\"';
  }

  @override
  String get noSystemFonts => 'Keine Systemschriften erkannt.';

  @override
  String get noTokenSet => 'Kein Token gesetzt — Zugriff ist uneingeschränkt.';

  @override
  String get noTokenSetUnrestricted =>
      'Kein Token gesetzt — Zugriff ist uneingeschränkt.';

  @override
  String get noTokenUnrestricted => 'Kein Token — Zugriff ist uneingeschränkt';

  @override
  String get noWorkingMemory => 'Noch keine Arbeitsgedächtnisnotizen.';

  @override
  String get noneAllRoles => 'Keine (alle Rollen)';

  @override
  String get notAvailable => 'Nicht verfügbar';

  @override
  String get notConfiguredLabel => 'Nicht konfiguriert.';

  @override
  String get notDetected => 'Nicht erkannt';

  @override
  String get notEarnedYet => 'Noch nicht verdient';

  @override
  String get notFoundLabel => 'Nicht gefunden';

  @override
  String get notYetSpawned => 'Noch nicht gestartet';

  @override
  String get notes => 'Notizen';

  @override
  String get notificationAgentFinished => 'Agent abgeschlossen';

  @override
  String get notificationExternalPr => 'Externe PRs';

  @override
  String get notificationNewMessages => 'Neue Nachrichten';

  @override
  String get notificationPrMerged => 'PR zusammengeführt';

  @override
  String get notificationPrPublished => 'PR veröffentlicht';

  @override
  String get notifications => 'Benachrichtigungen';

  @override
  String get notifyAgentRunCompleted =>
      'Benachrichtigen, wenn ein Agent einen Lauf abschließt.';

  @override
  String get notifyExternalPr =>
      'Benachrichtigen, wenn ein neuer PR durch Polling erkannt wird.';

  @override
  String get notifyNewMessages =>
      'Benachrichtigen bei neuen Agent-Nachrichten in anderen Kanälen.';

  @override
  String get notifyPrMerged =>
      'Benachrichtigen, wenn ein Pull Request zusammengeführt wird.';

  @override
  String get notifyPrPublished =>
      'Benachrichtigen, wenn ein Agent einen Pull Request veröffentlicht.';

  @override
  String get onboardingLinuxDescription =>
      'Control Center kann Linux-Container nutzen, um die Ausführung von Agenten zu isolieren.';

  @override
  String get onboardingMacosDescription =>
      'Control Center nutzt den nativen Sandbox auf macOS, um die Ausführung von Agenten zu isolieren.';

  @override
  String get onboardingUnsupportedDescription =>
      'Sandbox ist auf dieser Plattform nicht verfügbar. Die Ausführung von Agenten erfolgt ohne Isolierung.';

  @override
  String get openAction => 'Öffnen';

  @override
  String get openApplicationSettings => 'Anwendungseinstellungen öffnen';

  @override
  String get openArticlesBrowserFallback => 'Artikel im Browser öffnen';

  @override
  String get openArticlesInApp => 'Artikel in der App öffnen';

  @override
  String get openContainerTerminal => 'Container-Terminal öffnen';

  @override
  String get openFolder => 'Ordner öffnen';

  @override
  String get openInBrowser => 'Im Browser öffnen';

  @override
  String get openLabel => 'Offen';

  @override
  String get openOnGithub => 'Auf GitHub öffnen';

  @override
  String get openStatus => 'Offen';

  @override
  String get optionalPersonaDescription => 'Optionale Persona-Beschreibung';

  @override
  String get otherLabel => 'Sonstige';

  @override
  String get ownerOrganization => 'Besitzer / Organisation';

  @override
  String get p0 => 'P0';

  @override
  String get p1 => 'P1';

  @override
  String get p2 => 'P2';

  @override
  String get p3 => 'P3';

  @override
  String get parsingDiff => 'Diff wird analysiert…';

  @override
  String get passed => 'Bestanden';

  @override
  String get pasteTokenHere => 'Token hier einfügen';

  @override
  String get pasteValueHere => 'Wert hier einfügen';

  @override
  String get patNotNeededGhCli => 'Nicht erforderlich — gh CLI ist angemeldet.';

  @override
  String get patOverridesGhCli => 'Konfiguriert — überschreibt gh CLI.';

  @override
  String get pathLabel => 'Pfad';

  @override
  String get pendingApproval => 'Wartet auf deine Genehmigung';

  @override
  String get perfectionistBadge => 'Perfektionist';

  @override
  String get persona => 'Persona';

  @override
  String get personaColon => 'Persona:';

  @override
  String get personaOptional => 'Persona (optional)';

  @override
  String get personalAccessTokenOptional =>
      'Persönliches Zugriffstoken (optional)';

  @override
  String get planLabel => 'Plan';

  @override
  String get policies => 'Richtlinien';

  @override
  String get policiesHint =>
      'Richtlinien erscheinen hier, sobald Agenten Fakten befördern.';

  @override
  String get policy => 'Richtlinie';

  @override
  String get popular => 'Beliebt';

  @override
  String get port => 'Port';

  @override
  String get portLabel => 'Port';

  @override
  String get postingEllipsis => 'Veröffentlichen…';

  @override
  String get prCommits => 'Commits';

  @override
  String get prDescriptionPlaceholder => 'PR-Beschreibung in Markdown...';

  @override
  String get prDraftCreated => 'PR-Entwurf erstellt';

  @override
  String get prMachineBadge => 'PR-Maschine';

  @override
  String get prMergedBody => 'Ein Pull Request wurde zusammengeführt';

  @override
  String get prMoreActions => 'More actions';

  @override
  String get prTitle => 'PR-Titel';

  @override
  String get previewLabel => 'Vorschau';

  @override
  String get previousArticle => 'Vorheriger Artikel';

  @override
  String get previousChannel => 'Vorheriger Kanal';

  @override
  String get previousMatch => 'Vorherige Übereinstimmung (⇧↵)';

  @override
  String get previousPr => 'Vorherige PR';

  @override
  String get previousWorkspace => 'Vorheriger Arbeitsbereich';

  @override
  String get priorityReviews => 'Prioritäts-Reviews';

  @override
  String get priorityReviewsDescription =>
      'Prioritäts-Reviews und Repository-Übersicht.';

  @override
  String get progressLabel => 'Fortschritt';

  @override
  String get proposeToCreateDomain =>
      'Schlage einen Fakt oder eine Richtlinie vor, um eine zu erstellen.';

  @override
  String get prsCreated => 'PRs erstellt';

  @override
  String get prsCreatedLabel => 'PRs erstellt';

  @override
  String get prsMerged => 'PRs zusammengeführt';

  @override
  String get publishToGithub => 'Auf GitHub veröffentlichen';

  @override
  String get published => 'Veröffentlicht';

  @override
  String get pullRequestApproved => 'Pull Request genehmigt';

  @override
  String get pullRequests => 'Pull Requests';

  @override
  String get questionLabel => 'FRAGE';

  @override
  String get queued => 'In Warteschlange';

  @override
  String get react => 'Reagieren';

  @override
  String get readPrsIssuesMetadata =>
      'Erlaubt dem Agenten, PRs, Issues und Repository-Metadaten zu lesen.';

  @override
  String get readerPreferences => 'Leser-Einstellungen';

  @override
  String get reasoningEffort => 'Reasoning-Aufwand';

  @override
  String get recommendLabel => 'EMPFEHLUNG';

  @override
  String recordingFromDevice(String device) {
    return 'Aufnahme von $device.';
  }

  @override
  String get redownload => 'Erneut herunterladen';

  @override
  String get redownloadEmbeddingModel =>
      'Embedding-Modell erneut herunterladen?';

  @override
  String get redownloadVoiceModel => 'Sprachmodell erneut herunterladen?';

  @override
  String get refinePlan => 'Plan verfeinern';

  @override
  String get refiningPlan => 'Plan wird verfeinert…';

  @override
  String get refresh => 'Aktualisieren';

  @override
  String get refreshAll => 'Alle aktualisieren';

  @override
  String get refreshAllFeeds => 'Alle Feeds aktualisieren';

  @override
  String get refreshLabel => 'Aktualisieren';

  @override
  String get refreshPrData => 'PR-Daten aktualisieren';

  @override
  String get reject => 'Ablehnen';

  @override
  String get rejected => 'Abgelehnt';

  @override
  String get reload => 'Neu laden';

  @override
  String get remove => 'Entfernen';

  @override
  String get removeBookmark => 'Lesezeichen entfernen';

  @override
  String get removeEmbeddingModel => 'Embedding-Modell entfernen?';

  @override
  String get removeLogo => 'Logo entfernen';

  @override
  String get removeRepoFromWorkspace =>
      'Repository aus dem Arbeitsbereich entfernen?';

  @override
  String get removeRepository => 'Repository entfernen';

  @override
  String get removeRepositoryConfirm =>
      'Repository aus dem Arbeitsbereich entfernen?';

  @override
  String get removeVoiceModel => 'Sprachmodell entfernen?';

  @override
  String get removed => 'Entfernt';

  @override
  String get renamed => 'Umbenannt';

  @override
  String get reopen => 'Wieder öffnen';

  @override
  String get replyEllipsis => 'Antworten…';

  @override
  String repoRemovedFromWorkspace(String name) {
    return '$name wird aus diesem Arbeitsbereich entfernt. Die lokalen Dateien auf der Festplatte bleiben unberührt.';
  }

  @override
  String get reportsTo => 'Berichtet an';

  @override
  String get reportsToOptional => 'Berichtet an (optional)';

  @override
  String reposCount(int count) {
    return 'Repositorys ($count)';
  }

  @override
  String get reposDescription =>
      'Die lokalen Checkouts, die dieser Arbeitsbereich verwendet.';

  @override
  String get repositories => 'Repositorys';

  @override
  String get repositoriesSettings => 'Repository-Einstellungen';

  @override
  String get repositoryName => 'Repository-Name';

  @override
  String get requestChanges => 'Änderungen anfordern';

  @override
  String get requested => 'Angefordert';

  @override
  String get requestedChanges => 'Änderungen angefordert';

  @override
  String get requiredIfGhCliUnavailable =>
      'Erforderlich, wenn gh CLI nicht verfügbar ist';

  @override
  String requiredRoleLabel(String role) {
    return 'Erforderliche Rolle: $role';
  }

  @override
  String get requiredRoleOptional => 'Erforderliche Rolle (optional)';

  @override
  String get requirements => 'Anforderungen';

  @override
  String get reset => 'Zurücksetzen';

  @override
  String get resetAllSandboxes => 'Alle Sandboxes zurücksetzen';

  @override
  String get resolve => 'Lösen';

  @override
  String get resolved => 'Gelöst';

  @override
  String get restartServerToApply =>
      'Starte den Server neu, um die Änderungen anzuwenden.';

  @override
  String get restartShell => 'Shell neu starten';

  @override
  String get restartToApply =>
      'Starte den Server neu, um Änderungen zu übernehmen.';

  @override
  String get retry => 'Erneut versuchen';

  @override
  String get review => 'Review';

  @override
  String get reviewChanges => 'Änderungen reviewen';

  @override
  String get reviewedByMe => 'Von mir reviewed';

  @override
  String get reviewers => 'REVIEWER';

  @override
  String get reviewersActive => 'Aktive Reviewer';

  @override
  String get reviewsLabel => 'Reviews';

  @override
  String get roleLabel => 'Rolle';

  @override
  String get ruleHint => 'Die Regel der Richtlinie (Markdown wird unterstützt)';

  @override
  String get ruleLabel => 'Regel';

  @override
  String get runCompleted => 'Ausführung abgeschlossen';

  @override
  String get runGhAuthLoginBody =>
      'Führe `gh auth login` in deinem Terminal aus, dann auf Aktualisieren tippen.';

  @override
  String get running => 'Läuft';

  @override
  String get runningLabel => 'läuft';

  @override
  String get runningStatus => 'Läuft';

  @override
  String get runs => 'Läufe';

  @override
  String get runsAcrossAllAgents => 'Läufe über alle Agenten';

  @override
  String get runsLabel => 'Ausführungen';

  @override
  String get sandboxBackendNativeLabel => 'Native sandbox';

  @override
  String get sandboxBackendNoneLabel => 'No isolation';

  @override
  String get sandboxLinuxInstall =>
      'Nativer Sandbox auf Linux/WSL2 verwendet bubblewrap. Installiere mit:\\n\\n  sudo apt-get install bubblewrap socat ripgrep   # Debian/Ubuntu\\n  sudo dnf install bubblewrap socat ripgrep       # Fedora/RHEL\\n  sudo pacman -S bubblewrap socat ripgrep         # Arch';

  @override
  String get sandboxMacosBuiltIn =>
      'Nativer Sandbox ist in macOS integriert — verwendet Apple Seatbelt (`sandbox-exec`). Keine Installation erforderlich.';

  @override
  String get sandboxPermissions => 'Sandbox-Berechtigungen';

  @override
  String get sandboxUnsupported =>
      'Nativer Sandbox wird auf dieser Plattform noch nicht unterstützt. Fällt zurück auf \"Keine Isolierung\".';

  @override
  String get sandboxing => 'Sandboxing';

  @override
  String get sandboxingDescription =>
      'Führe Agenten in einem Sandbox auf Betriebssystemebene aus, damit sie nicht auf deinen Home-Ordner, SSH-Schlüssel oder nicht gewährte Token zugreifen können.';

  @override
  String get sandboxingDisabledDescription =>
      'Agenten werden direkt auf dem Host mit vollem Env ausgeführt — nicht empfohlen.';

  @override
  String sandboxingEnabledDescription(String backend) {
    return 'Alle Agentenaufrufe werden über $backend geleitet.';
  }

  @override
  String get save => 'Speichern';

  @override
  String get saveChanges => 'Änderungen speichern';

  @override
  String get savedArticlesDescription =>
      'Artikel, die du mit einem Lesezeichen versehen hast.';

  @override
  String get savedLabel => 'Gespeichert';

  @override
  String get savingChanges => 'Änderungen werden gespeichert…';

  @override
  String get savingEllipsis => 'Speichern…';

  @override
  String get scopeDiffToCommits =>
      'Diff auf Commits einschränken — Umschalt+Klick für Bereich';

  @override
  String get searchAgents => 'Agenten suchen';

  @override
  String get searchAuthors => 'Autoren suchen…';

  @override
  String get searchPullRequestsHint => 'Suchen… z. B. author:@user';

  @override
  String get noPrsMatchSearch => 'Keine passenden Pull Requests';

  @override
  String get noPrsMatchSearchHint =>
      'Keine offenen PRs entsprechen deiner Suche. Andere Begriffe versuchen oder Suche löschen.';

  @override
  String get searchAuthorsPlaceholder => 'Autoren suchen…';

  @override
  String get searchFactsHint => 'Fakten suchen...';

  @override
  String get searchFonts => 'Schriften suchen…';

  @override
  String get searchGifs => 'GIFs suchen';

  @override
  String get searchGifsHint => 'GIFs suchen...';

  @override
  String get searchInDiff => 'Im Diff suchen';

  @override
  String get searchInDiffHint => 'Im Diff suchen…';

  @override
  String get searchOrTypeModel => 'Suchen oder Modellnamen eingeben…';

  @override
  String get searchPlaceholder => 'Suchen…';

  @override
  String get searchShortcuts => 'Kürzel suchen…';

  @override
  String get searching => 'Suchen…';

  @override
  String secondsAgo(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'vor $count Sekunden',
      one: 'vor 1 Sekunde',
    );
    return '$_temp0';
  }

  @override
  String get selectAdapter => 'Adapter auswählen';

  @override
  String get selectAdapterFirst => 'Zuerst einen Adapter auswählen';

  @override
  String get selectAgentToReportTo => 'Agent für Berichterstattung auswählen…';

  @override
  String get selectAnAgent => 'Agenten auswählen';

  @override
  String get selectConversation => 'Konversation auswählen';

  @override
  String get selectEffortLevel => 'Aufwandsstufe auswählen';

  @override
  String get selectLabel => 'Auswählen';

  @override
  String get selectRunner => 'Runner auswählen';

  @override
  String get semanticSearch => 'Semantische Suche';

  @override
  String get send => 'Senden';

  @override
  String get sendFirstMessage => 'Sende die erste Nachricht';

  @override
  String get sendMessage => 'Nachricht senden';

  @override
  String sentFindingsToAgent(int count) {
    return '$count Ergebnis(se) an Agent gesendet.';
  }

  @override
  String get serverRunning => 'Server läuft';

  @override
  String get serverStopped => 'Server gestoppt';

  @override
  String setGithubLinkDescription(String name) {
    return 'Setze den GitHub-Besitzer und Repository-Namen für $name. Dies wird verwendet, um PR- und Issue-Referenzen wie #123 in Markdown-Inhalten aufzulösen.';
  }

  @override
  String get setLabel => 'Setzen';

  @override
  String get setToken => 'Token setzen';

  @override
  String get settingsGeneralDescription =>
      'Erscheinungsbild, Typografie, Integrationen und MCP-Server.';

  @override
  String get settingsLabel => 'Einstellungen';

  @override
  String get settingsLanguage => 'Sprache';

  @override
  String get settingsLanguageDescription => 'Wähle die App-Sprache.';

  @override
  String get sharedSecretToken => 'Gemeinsamer geheimer Token';

  @override
  String get sharpshooterBadge => 'Scharfschütze';

  @override
  String get shortTask => 'Kurze Aufgabe';

  @override
  String get showNativeNotifications =>
      'Native macOS-Benachrichtigungen für Ereignisse anzeigen.';

  @override
  String get showSuperseded => 'Ersetzte anzeigen';

  @override
  String get signInWithGhAuth =>
      'Mit gh auth login anmelden oder Token unter Einstellungen > API-Schlüssel hinzufügen';

  @override
  String get signedIn => 'Angemeldet.';

  @override
  String signedInAs(String username) {
    return 'Angemeldet als $username.';
  }

  @override
  String get skillEditor => 'Fähigkeiten-Editor';

  @override
  String get skillNameRequired => 'Fähigkeitsname ist erforderlich.';

  @override
  String skillSaved(String name) {
    return 'Fähigkeit \"$name\" gespeichert.';
  }

  @override
  String get skills => 'Fähigkeiten';

  @override
  String get skillsColon => 'Fähigkeiten:';

  @override
  String get skillsCommaSeparated => 'Fähigkeiten (durch Komma getrennt)';

  @override
  String get skillsLabel => 'FÄHIGKEITEN';

  @override
  String get skipAcceptRisk => 'Überspringen — Ich akzeptiere das Risiko';

  @override
  String get skipForNow => 'Vorerst überspringen';

  @override
  String get skipSandboxing => 'Sandboxing überspringen';

  @override
  String get skipSandboxingDialogContent =>
      'Bist du sicher, dass du das Sandboxing überspringen möchtest? Dies erlaubt Agenten, Code auf deinem System ohne Isolierung auszuführen.';

  @override
  String get somethingWentWrong => 'Etwas ist schiefgelaufen';

  @override
  String sourceCount(int count) {
    return '$count Quelle';
  }

  @override
  String sourceCountPlural(int count) {
    return '$count Quellen';
  }

  @override
  String get sourceFacts => 'Quellfakten:';

  @override
  String get splitDiff => 'Diff nebeneinander';

  @override
  String get startDmWithAgent => 'Direktnachricht mit Agenten starten';

  @override
  String get startFresh => 'Neu anfangen';

  @override
  String get startLabel => 'Starten';

  @override
  String get startOnAppLaunch => 'Beim App-Start starten';

  @override
  String get startServerToAccept =>
      'Starte den Server, um MCP-Verbindungen zu akzeptieren.';

  @override
  String get stats => 'Statistiken';

  @override
  String get statusLabel => 'Status';

  @override
  String stepConnect(int number) {
    return 'Schritt $number · Verbinden';
  }

  @override
  String get stop => 'Stoppen';

  @override
  String get stopped => 'Gestoppt';

  @override
  String get streaks => 'Serien';

  @override
  String get streaksLabel => 'Serien';

  @override
  String get strictIdentityCheck => 'Strenge Identitätsprüfung';

  @override
  String get success => 'Erfolg';

  @override
  String get successLabel => 'Erfolg';

  @override
  String get successLabelShort => 'Erfolg';

  @override
  String get successRate => 'Erfolgsquote';

  @override
  String get suggestAChange => 'Änderung vorschlagen';

  @override
  String get suggestAChangeEllipsis => 'Änderung vorschlagen…';

  @override
  String get suggestLabel => 'VORSCHLAG';

  @override
  String get superseded => 'Ersetzt';

  @override
  String get synced => 'Synchronisiert';

  @override
  String get systemDefault => 'Systemstandard';

  @override
  String get systemFonts => 'Systemschriften';

  @override
  String get systemPrompt => 'System-Prompt';

  @override
  String get systemPromptLabel => 'System-Prompt';

  @override
  String get talkToControlCenter => 'Sprich mit Control Center.';

  @override
  String get tapBadgeDescription =>
      'Tippe auf ein Badge, um zu sehen, wie du aufsteigst';

  @override
  String get tapBadgeToLevelUp =>
      'Tippe auf ein Badge, um zu sehen, wie du aufsteigst';

  @override
  String get taskMentionSection => 'Aufgabe';

  @override
  String get testLabel => 'Testen';

  @override
  String get theme => 'Thema';

  @override
  String get themeDark => 'Dunkel';

  @override
  String get themeLight => 'Hell';

  @override
  String get themeSystem => 'System';

  @override
  String get thisCannotBeUndone => 'Dies kann nicht rückgängig gemacht werden.';

  @override
  String get thisConversation => 'diese Konversation';

  @override
  String get threadLabel => 'Thread';

  @override
  String get throughput => 'Durchsatz';

  @override
  String get ticketLabel => 'TICKET';

  @override
  String tierLabel(String tier) {
    return 'Stufe $tier';
  }

  @override
  String get titleDescription => 'Beschreibung';

  @override
  String get titleLabel => 'Titel';

  @override
  String get todayLabel => 'Heute';

  @override
  String get toggleBookmark => 'Lesezeichen umschalten';

  @override
  String get toggleTheme => 'Thema umschalten';

  @override
  String get toggleWorkspaceSwitcher => 'Arbeitsbereich-Umschalter umschalten';

  @override
  String get tokenConfigured =>
      'Konfiguriert — Clients müssen diesen Token vorweisen.';

  @override
  String get tokenConfiguredClients =>
      'Konfiguriert — Clients müssen dieses Token vorweisen.';

  @override
  String tokenName(String name) {
    return '$name-Token';
  }

  @override
  String get topPerformerLabel => 'TOP PERFORMER';

  @override
  String get topPerformersDescription =>
      'Top-Performer, Durchsatz und Arbeitsbereich-Gesundheit.';

  @override
  String get topic => 'Thema';

  @override
  String get topicHint => 'z.B. Tech Stack, Design System';

  @override
  String get totalRuns => 'Läufe gesamt';

  @override
  String get totalRunsLabel => 'Läufe gesamt';

  @override
  String trackingParamsCount(int count) {
    return '$count Tracking-Parameter';
  }

  @override
  String get typeCommandOrSearch => 'Befehl eingeben oder suchen…';

  @override
  String get typography => 'Typografie';

  @override
  String get unavailable => 'Nicht verfügbar';

  @override
  String get unexpectedError => 'Ein unerwarteter Fehler ist aufgetreten.';

  @override
  String get unifiedDiff => 'Vereinigter Diff';

  @override
  String get unknownAuthor => 'Unbekannt';

  @override
  String get unnamedAgent => 'Unbenannter Agent';

  @override
  String get updateKey => 'Schlüssel aktualisieren';

  @override
  String get updateLabel => 'Aktualisieren';

  @override
  String get updateToken => 'Token aktualisieren';

  @override
  String updatedDaysAgo(int count) {
    return 'Vor $count Tagen aktualisiert';
  }

  @override
  String updatedHoursAgo(int count) {
    return 'Vor $count Stunden aktualisiert';
  }

  @override
  String get updatedJustNow => 'Gerade aktualisiert';

  @override
  String updatedMinutesAgo(int count) {
    return 'Vor $count Minuten aktualisiert';
  }

  @override
  String get useSandbox => 'Sandbox verwenden';

  @override
  String get useWorkspaceDefault => 'Arbeitsbereichsstandard verwenden';

  @override
  String get userAgent => 'User-Agent';

  @override
  String get userAgentDescription =>
      'Leer lassen, um den Standard-User-Agent der App zu verwenden. Einige Seiten blockieren Nicht-Browser-User-Agents.';

  @override
  String get usingSystemDefaultMicrophone =>
      'Verwendung des Standardmikrofons des Systems.';

  @override
  String get viewAll => 'Alle anzeigen';

  @override
  String get viewLabel => 'Ansicht';

  @override
  String get viewLog => 'Log anzeigen';

  @override
  String get viewLogs => 'Logs anzeigen';

  @override
  String voiceInstallFailed(String error) {
    return 'Installation fehlgeschlagen: $error';
  }

  @override
  String get voiceModelNotInstalled =>
      'Nicht installiert. Lädt ca. 200 MB einmal herunter; läuft vollständig auf dem Gerät.';

  @override
  String get voiceModelNotInstalledLabel => 'Sprachmodell nicht installiert.';

  @override
  String get voiceRedownloadBody =>
      'Die vorhandenen Modelldateien werden gelöscht und das ca. 200 MB große Archiv erneut heruntergeladen. Die Sprachtranskription steht bis zum Abschluss des Downloads nicht zur Verfügung.';

  @override
  String get voiceRemoveBody =>
      'Die Sprachtranskription wird deaktiviert, bis du sie erneut installierst. Du kannst sie jederzeit erneut installieren.';

  @override
  String get voiceTranscription => 'Sprachtranskription';

  @override
  String get weakIsolationDescription =>
      'Schwache Isolierung — nur Namespace-Grenze, keine Kernel-Grenze.';

  @override
  String get whenOffNoDefaultRoute =>
      'Wenn deaktiviert, startet die Sandbox ohne Standardroute.';

  @override
  String get whenOffServerStaysStopped =>
      'Wenn deaktiviert, bleibt der Server gestoppt, bis du ihn startest.';

  @override
  String get whisperBaseEn => 'Whisper base.en (sherpa-onnx)';

  @override
  String get whisperInstalled =>
      'Whisper base.en installiert. Wird vom Mikrofon-Button im Composer verwendet.';

  @override
  String workerLabel(int index) {
    return 'Worker $index';
  }

  @override
  String workersCount(int count) {
    return '$count Worker';
  }

  @override
  String get workingMemory => 'Arbeitsspeicher';

  @override
  String get workspaceName => 'Name des Arbeitsbereichs';

  @override
  String get workspaceNotFound => 'Arbeitsbereich nicht gefunden';

  @override
  String get workspaceNotesScratchpad => 'Arbeitsbereich-Notizen & Notizblock';

  @override
  String get workspacePulse => 'ARBEITSBEREICH-PULS';

  @override
  String get workspaceScopedSkills =>
      'Arbeitsbereich-bezogene Fähigkeitsdateien, die Agenten zugeordnet sind.';

  @override
  String workspaceTitle(String name) {
    return 'Arbeitsbereich: $name';
  }

  @override
  String get workspaces => 'Arbeitsbereiche';

  @override
  String get writeLabel => 'Schreiben';

  @override
  String get writePrivateNotes =>
      'Private Notizen, Beobachtungen, Pläne schreiben...';

  @override
  String get writeSkillContent =>
      'Schreibe deinen Fähigkeitsinhalt hier (Markdown)…';

  @override
  String get xp => 'XP';

  @override
  String yearsAgo(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'vor $count Jahren',
      one: 'vor 1 Jahr',
    );
    return '$_temp0';
  }

  @override
  String get yesterday => 'gestern';

  @override
  String get yourAchievements => 'DEINE LEISTUNGEN';

  @override
  String get focusModeStart => 'Fokus-Sitzung starten';

  @override
  String get focusModeConfigTitle => 'Fokus-Sitzung starten';

  @override
  String get focusModeGoalLabel => 'Ziel';

  @override
  String get focusModeGoalHint => 'Woran arbeitest du?';

  @override
  String get focusModeDurationLabel => 'Dauer';

  @override
  String get focusModeBlockNotifications => 'Benachrichtigungen blockieren';

  @override
  String get focusModeStartButton => 'Starten';

  @override
  String get focusModeEndSession => 'Sitzung beenden';

  @override
  String get focusModeExpand => 'App erweitern';

  @override
  String get focusModeFloat => 'In Leiste minimieren';

  @override
  String get focusModeActiveTooltip => 'Fokus-Modus aktiv — zum Beenden tippen';

  @override
  String get dismiss => 'Ablehnen';

  @override
  String get acceptAndResolve => 'Übernehmen und auflösen';

  @override
  String reviewFatigueWarning(int minutes) {
    return 'Es sieht so aus, als ob du viele Reviews hintereinander machst. Mach eine Pause!';
  }

  @override
  String get notificationSound => 'Benachrichtigungston';

  @override
  String get notificationSoundDescription =>
      'Ton, der abgespielt wird, wenn eine Benachrichtigung angezeigt wird.';

  @override
  String get notificationSoundNone => 'Keiner';

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
  String get notificationVolume => 'Lautstärke';

  @override
  String get viewProfile => 'Profil ansehen';

  @override
  String get clearAllFilters => '× Alle löschen';

  @override
  String acrossNRepos(num count) {
    final intl.NumberFormat countNumberFormat = intl.NumberFormat.compact(
      locale: localeName,
    );
    final String countString = countNumberFormat.format(count);

    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'In $countString Repos',
      one: 'In 1 Repo',
    );
    return '$_temp0';
  }

  @override
  String get pullRequestsLabel => 'PRs';

  @override
  String noPrsByUserInWorkspace(String login) {
    return 'Keine PRs von @$login in diesem Arbeitsbereich';
  }

  @override
  String get usersLabel => 'Benutzer';

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
  String get checksFailing => 'Prüfungen fehlgeschlagen';

  @override
  String get reviewsPending => 'Some reviews are pending';

  @override
  String get confirm => 'Confirm';

  @override
  String get trustedSitesSectionTitle => 'Vertrauenswürdige Sites';

  @override
  String get trustedSitesEmpty =>
      'Keine vertrauenswürdigen Sites. Fügen Sie eine Domain hinzu, um die Blockierung dort zu deaktivieren.';

  @override
  String get addTrustedSite => 'Vertrauenswürdige Site hinzufügen';

  @override
  String get removeTrustedSite => 'Entfernen';

  @override
  String get disableBlockingForThisSite =>
      'Blockierung auf dieser Site deaktivieren';

  @override
  String get enableBlockingForThisSite =>
      'Blockierung auf dieser Site aktivieren';

  @override
  String get enterDomainHint => 'z. B. beispiel.com';

  @override
  String get invalidDomain =>
      'Geben Sie eine gültige Domain ein (z. B. beispiel.com)';

  @override
  String get pageLoadTimedOut =>
      'Seitenladezeit überschritten. Neu laden oder im Browser öffnen.';

  @override
  String get pipelinesScreenTitle => 'Pipelines';

  @override
  String get pipelinesScreenSubtitle =>
      'Declarative multi-step agent workflows';

  @override
  String get pipelinesRunHello => 'Run hello pipeline';

  @override
  String get pipelinesRunPipeline => 'Pipeline ausführen';

  @override
  String get pipelineRunLauncherTitle => 'Pipeline ausführen';

  @override
  String get pipelineRunSubtitle =>
      'Wähle eine Pipeline und fülle ihre Eingaben aus, um eine Ausführung zu starten.';

  @override
  String get pipelineRunNoInputsBadge => 'Keine Eingaben';

  @override
  String pipelineRunInputsCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count Eingaben',
      one: '1 Eingabe',
    );
    return '$_temp0';
  }

  @override
  String get pipelineRunNoInputs => 'Diese Pipeline benötigt keine Eingaben.';

  @override
  String get pipelineRunSubmit => 'Pipeline ausführen';

  @override
  String get pipelineRunCouldNotStart =>
      'Ausführung konnte nicht gestartet werden.';

  @override
  String pipelineRunStarted(String name) {
    return '$name gestartet';
  }

  @override
  String get pipelineRunEmptyTitle => 'Keine Pipelines zum Ausführen bereit';

  @override
  String get pipelineRunEmptyHint =>
      'Aktiviere eine Pipeline und schalte die manuelle Ausführung in ihrem Editor ein, um sie hier zu starten.';

  @override
  String get pipelineRunManageTemplates => 'Pipelines verwalten';

  @override
  String get pipelineRunSettingsTitle => 'Manuelle Ausführung';

  @override
  String get pipelineRunSettingsAllow => 'Manuelle Ausführung zulassen';

  @override
  String get pipelineRunSettingsAllowHelp =>
      'Diese Pipeline auf der Ausführungsseite anzeigen, damit sie manuell gestartet werden kann.';

  @override
  String get pipelineRunSettingsInputsTitle => 'Eingaben';

  @override
  String get pipelineRunSettingsAddInput => 'Eingabe hinzufügen';

  @override
  String get pipelineRunSettingsNoInputs => 'Noch keine Eingaben.';

  @override
  String get pipelineInputEditTitle => 'Eingabefeld';

  @override
  String get pipelineInputKeyLabel => 'Schlüssel';

  @override
  String get pipelineInputKeyHelp =>
      'Statusschlüssel, unter dem der Wert gespeichert wird (z. B. repoFullName).';

  @override
  String get pipelineInputLabelLabel => 'Bezeichnung';

  @override
  String get pipelineInputTypeLabel => 'Typ';

  @override
  String get pipelineInputOptionsLabel => 'Optionen (durch Kommas getrennt)';

  @override
  String get pipelineInputDefaultLabel => 'Standardwert';

  @override
  String get pipelineInputPlaceholderLabel => 'Platzhalter';

  @override
  String get pipelineInputHelpLabel => 'Hilfetext';

  @override
  String get pipelineInputRequiredLabel => 'Erforderlich';

  @override
  String get pipelineInputTypeText => 'Text';

  @override
  String get pipelineInputTypeMultiline => 'Mehrzeiliger Text';

  @override
  String get pipelineInputTypeNumber => 'Zahl';

  @override
  String get pipelineInputTypeBoolean => 'Schalter';

  @override
  String get pipelineInputTypeSelect => 'Auswahl';

  @override
  String get pipelinesEmpty => 'No pipeline runs yet';

  @override
  String get pipelinesEmptyHint =>
      'Klicke auf „Pipeline ausführen“, um eine zu starten.';

  @override
  String get pipelinesSelectRun => 'Select a pipeline run to view steps';

  @override
  String get pipelinesNoSteps => 'No steps recorded yet';

  @override
  String get pipelinesNoActiveWorkspace =>
      'Wähle einen Arbeitsbereich, um seine Pipelines anzuzeigen';

  @override
  String pipelinesLoadError(String error) {
    return 'Pipelines konnten nicht geladen werden: $error';
  }

  @override
  String pipelinesRunFailed(String error) {
    return 'Pipeline konnte nicht gestartet werden: $error';
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
    return '$completed von $total Schritten';
  }

  @override
  String get pipelineStepStarted => 'Gestartet';

  @override
  String get pipelineStepFinished => 'Abgeschlossen';

  @override
  String get pipelineStepDurationLabel => 'Dauer';

  @override
  String get pipelineStepBranch => 'Branch';

  @override
  String get pipelineStepError => 'Fehler';

  @override
  String get pipelineStepInput => 'Eingabe';

  @override
  String get pipelineStepOutput => 'Ausgabe';

  @override
  String get pipelineStepNotExecuted => 'Noch nicht ausgeführt';

  @override
  String get pipelineRunViewTimeline => 'Zeitverlauf';

  @override
  String get pipelineRunViewGraph => 'Diagramm';

  @override
  String pipelineRunFailedAtStep(String step) {
    return 'Fehlgeschlagen bei $step';
  }

  @override
  String get pipelineRunTriggerManual => 'Manuell';

  @override
  String get pipelineRunTriggerAuto => 'Automatisch';

  @override
  String get pipelineStepSkippedReason => 'Übersprungen';

  @override
  String get pipelineRunFilterAll => 'Alle';

  @override
  String get pipelineRunFilterEmpty =>
      'Keine Ausführungen entsprechen diesem Filter';

  @override
  String get relativeJustNow => 'gerade eben';

  @override
  String relativeMinutesAgo(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'vor $count Min.',
      one: 'vor 1 Min.',
    );
    return '$_temp0';
  }

  @override
  String relativeHoursAgo(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'vor $count Stunden',
      one: 'vor 1 Stunde',
    );
    return '$_temp0';
  }

  @override
  String relativeDaysAgo(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'vor $count Tagen',
      one: 'vor 1 Tag',
    );
    return '$_temp0';
  }

  @override
  String get automationsTitle => 'Automatisierungen';

  @override
  String get automationsSubtitle =>
      'Pipelines automatisch starten, wenn Domänenereignisse ausgelöst werden';

  @override
  String get automationsNoTriggers =>
      'Keine Auslöser für dieses Ereignis konfiguriert.';

  @override
  String get automationsAddTrigger => 'Auslöser hinzufügen';

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
  String get tasksNoTasks => 'Keine Tickets';

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
  String get pipelineTemplatesNav => 'Pipeline-Vorlagen';

  @override
  String get pipelineTemplatesTitle => 'Pipeline-Vorlagen';

  @override
  String get pipelineTemplatesSubtitle =>
      'Drag-and-Drop-Editor für die Pipelines, die deine Agenten orchestrieren.';

  @override
  String get pipelineTemplatesNew => 'Neue Vorlage';

  @override
  String get pipelineTemplatesEmpty =>
      'Noch keine Pipeline-Vorlagen. Erstelle eine, um zu beginnen.';

  @override
  String get pipelineTemplateIdLabel => 'Vorlagen-ID';

  @override
  String get pipelineTemplateBuiltInBadge => 'Integriert';

  @override
  String get pipelineTemplateDeleteConfirmTitle => 'Vorlage löschen?';

  @override
  String pipelineTemplateDeleteConfirmBody(String name) {
    return 'Pipeline-Vorlage $name löschen? Das kann nicht rückgängig gemacht werden.';
  }

  @override
  String get pipelineTemplateSaved => 'Pipeline-Vorlage gespeichert';

  @override
  String get pipelineTemplateEditorTitle => 'Pipeline bearbeiten';

  @override
  String get pipelineTemplateEditorSubtitle =>
      'Ziehe Knotentypen aus der Seitenleiste auf die Leinwand und verbinde sie.';

  @override
  String get unsavedChanges => 'Nicht gespeicherte Änderungen';

  @override
  String get nodeLibraryTitle => 'Knotenbibliothek';

  @override
  String get nodeLibraryHint =>
      'Ziehe einen Eintrag auf die Leinwand, um einen Knoten hinzuzufügen.';

  @override
  String get editorDragHint =>
      'Aus der Bibliothek ziehen, Knoten anklicken zum Bearbeiten';

  @override
  String get editorEmptyCanvas =>
      'Ziehe einen Knoten aus der Bibliothek, um zu beginnen.';

  @override
  String get nodeConfigTitle => 'Knoten-Konfiguration';

  @override
  String get nodeConfigKind => 'Art';

  @override
  String get nodeConfigLabel => 'Bezeichnung';

  @override
  String get nodeConfigAgent => 'Agent';

  @override
  String get nodeConfigAgentHint => 'Agent auswählen…';

  @override
  String get nodeConfigInputKeys => 'Eingabeschlüssel (kommagetrennt)';

  @override
  String get nodeConfigInputKeysHelp =>
      'State-Schlüssel, die dieser Knoten konsumiert. Werden für die Platzhalter-Substitution im Prompt verwendet.';

  @override
  String get nodeConfigOutputKey => 'Ausgabeschlüssel';

  @override
  String get nodeConfigPrompt => 'Prompt-Vorlage';

  @override
  String get nodeConfigPromptHelp =>
      'Verwende Platzhalter in doppelten geschweiften Klammern, um Werte aus dem State zur Laufzeit einzusetzen.';

  @override
  String get nodeConfigScript => 'Bash-Skript';

  @override
  String get nodeConfigScriptHelp =>
      'Wird mit bash -c ausgeführt. GITHUB_TOKEN ist gesetzt. Platzhalter werden vor der Ausführung ersetzt.';

  @override
  String get nodeConfigTriggers => 'Ausgelöst durch';

  @override
  String get nodeConfigNoUpstream => 'Keine anderen Knoten zum Verbinden.';

  @override
  String get nodeConfigRouteKeys => 'Routing-Schlüssel';

  @override
  String nodeConfigRouteKeyFrom(String source) {
    return 'Routing-Schlüssel von $source';
  }

  @override
  String get conditionSectionTitle => 'Bedingung';

  @override
  String get conditionMode => 'Modus';

  @override
  String get conditionModeFilesAny => 'Datei(en) vorhanden — beliebige';

  @override
  String get conditionModeFilesAll => 'Dateien vorhanden — alle';

  @override
  String get conditionModeComparison => 'Vergleich';

  @override
  String get conditionModeSwitch => 'Verzweigung';

  @override
  String get conditionFilePaths => 'Dateipfade';

  @override
  String get conditionFilePathsAnyHelp =>
      'Ein Pfad pro Zeile, relativ zum Basisverzeichnis. Gibt true zurück, wenn einer existiert.';

  @override
  String get conditionFilePathsAllHelp =>
      'Ein Pfad pro Zeile, relativ zum Basisverzeichnis. Gibt true nur zurück, wenn alle existieren.';

  @override
  String get conditionBaseKey => 'Schlüssel des Basisverzeichnisses';

  @override
  String get conditionBaseKeyHelp =>
      'Status-Schlüssel mit dem Verzeichnis, gegen das Pfade aufgelöst werden (Standard repoLocalPath).';

  @override
  String get conditionRecursive => 'Unterverzeichnisse durchsuchen';

  @override
  String get conditionNegate => 'Umkehren: true, wenn nicht vorhanden';

  @override
  String get conditionLeft => 'Linker Wert';

  @override
  String get conditionOperator => 'Operator';

  @override
  String get conditionRight => 'Rechter Wert';

  @override
  String get conditionSwitchKey => 'Nach Status-Schlüssel verzweigen';

  @override
  String get conditionCases => 'Fälle (durch Komma getrennt)';

  @override
  String get conditionCasesHelp =>
      'Routing-Schlüssel, die der Reihe nach mit dem Wert verglichen werden.';

  @override
  String get conditionDefaultCase => 'Standardfall';

  @override
  String get triggerPanelTitle => 'Auslöser';

  @override
  String get triggerPanelHelp => 'Was diese Pipeline startet.';

  @override
  String get triggerManualHelp =>
      'Auf der Ausführungsseite anzeigen und manuell starten.';

  @override
  String get triggerSectionAutomatic => 'Automatische Auslöser';

  @override
  String get triggerAddButton => 'Auslöser hinzufügen';

  @override
  String get triggerNoneYet => 'Noch keine automatischen Auslöser.';

  @override
  String get triggerAddDialogTitle => 'Auslöser hinzufügen';

  @override
  String get triggerKindLabel => 'Auslösertyp';

  @override
  String get triggerKindEvent => 'Bei einem Ereignis';

  @override
  String get triggerKindSchedule => 'Nach Zeitplan';

  @override
  String get triggerIntervalLabel => 'Ausführen alle (Sekunden)';

  @override
  String get triggerEventFieldLabel => 'Ereignis';

  @override
  String get triggerNoMoreEvents =>
      'Alle verfügbaren Ereignisse sind bereits eingerichtet.';

  @override
  String get triggerMatchStatusLabel => 'Nur wenn der Status ist';

  @override
  String get triggerSummaryNone => 'Keine Auslöser';

  @override
  String triggerEverySeconds(int seconds) {
    return 'Alle ${seconds}s';
  }

  @override
  String get triggerEventManual => 'Manueller Lauf';

  @override
  String get triggerEventSchedule => 'Zeitplan';

  @override
  String get triggerEventPrStatusChanged => 'PR-Status geändert';

  @override
  String get triggerEventExternalPr => 'Externe PR geöffnet';

  @override
  String get triggerEventPrPublished => 'PR veröffentlicht';

  @override
  String get triggerEventPrMerged => 'PR zusammengeführt';

  @override
  String get triggerEventRepoAdded => 'Repository hinzugefügt';

  @override
  String get triggerEventMessageReceived => 'Nachricht empfangen';

  @override
  String get triggerEventTicketCompleted => 'Aufgabe abgeschlossen';

  @override
  String get triggerEventTicketFailed => 'Aufgabe fehlgeschlagen';

  @override
  String get triggerEventBudgetCrossed => 'Budgetschwelle überschritten';

  @override
  String get automationsManagedHint =>
      'Auslöser werden pro Pipeline in deren Editor konfiguriert. Hier ein- oder ausschalten.';

  @override
  String get automationsEditInPipeline => 'In Pipeline bearbeiten';

  @override
  String get nodeLibrarySearchHint => 'Knoten suchen';

  @override
  String get nodeLibraryNoMatches => 'Keine passenden Knoten';

  @override
  String get nodeCategoryFlow => 'Ablauf und Logik';

  @override
  String get nodeCategoryPr => 'PR-Review';

  @override
  String get nodeCategoryAgents => 'Agenten';

  @override
  String get nodeCategoryMessaging => 'Nachrichten';

  @override
  String get nodeCategoryCode => 'Code';

  @override
  String get nodeCategoryDemo => 'Demo';

  @override
  String get triggerDisabledTag => 'aus';

  @override
  String get pipelineInputTypeRepo => 'Repository';

  @override
  String get pipelineRunNoRepos =>
      'Noch keine Repositorys in diesem Workspace.';

  @override
  String get allowTicketingApi => 'Ticketing-API-Aufrufe zulassen';

  @override
  String get ticketingApiKey => 'Ticketing-API-Schlüssel';

  @override
  String get ticketingApiKeySubtitle =>
      'Fügt den API-Schlüssel des Ticketing-Anbieters in die Sandbox ein.';

  @override
  String get ticketingProvider => 'Ticketing-Anbieter';

  @override
  String get connectGitHubAndTicketing =>
      'Verbinde GitHub, damit Control Center deine Pull Requests, Issues und Reviews lesen kann. Optional einen Ticketing-Anbieter verbinden. Nichts verlässt diesen Rechner.';

  @override
  String get triggerEventTicketAssigned => 'Ticket zugewiesen';

  @override
  String get navTickets => 'Tickets';

  @override
  String get ticketsTitle => 'Tickets';

  @override
  String get newTicket => 'Neues Ticket';

  @override
  String get noTicketsYet => 'Noch keine Tickets';

  @override
  String get assignTicket => 'Ticket zuweisen';

  @override
  String get addCollaborator => 'Mitarbeiter hinzufügen';

  @override
  String get noCollaborators => 'Noch keine Mitarbeiter';

  @override
  String get linkedPullRequests => 'Verknüpfte Pull Requests';

  @override
  String get noLinkedPullRequests => 'Noch keine verknüpften Pull Requests';

  @override
  String get ticketActivity => 'Aktivität';

  @override
  String get ticketDispatchHint =>
      '@erwähne einen Agenten, um ihn zu beauftragen…';

  @override
  String get stopAgent => 'Agent stoppen';

  @override
  String get removeQueuedMessage => 'Eingereihte Nachricht entfernen';

  @override
  String get ticketProperties => 'Eigenschaften';

  @override
  String get ticketTabIssue => 'Ticket';

  @override
  String get ticketTabActivity => 'Aktivität';

  @override
  String get ticketTabChanges => 'Änderungen';

  @override
  String get ticketTabTerminal => 'Terminal';

  @override
  String get ticketSelectPrompt =>
      'Wähle ein Ticket, um seine Details anzuzeigen';

  @override
  String get ticketNoChanges =>
      'Noch keine Änderungen in den verknüpften Repositorys';

  @override
  String get ticketTerminalNoAgent =>
      'Weise einen Agenten zu, um ein Terminal zu öffnen';

  @override
  String get unassigned => 'Nicht zugewiesen';

  @override
  String get ticketStatusBacklog => 'Backlog';

  @override
  String get ticketStatusOpen => 'Zu erledigen';

  @override
  String get ticketStatusInProgress => 'In Bearbeitung';

  @override
  String get ticketStatusInReview => 'In Prüfung';

  @override
  String get ticketStatusDone => 'Erledigt';

  @override
  String get ticketStatusBlocked => 'Blockiert';

  @override
  String get ticketStatusFailed => 'Fehlgeschlagen';

  @override
  String get ticketStatusCancelled => 'Abgebrochen';

  @override
  String get notificationTicketAssigned => 'Ticket zugewiesen';

  @override
  String get notificationTicketStatusChanged => 'Ticket-Status geändert';

  @override
  String get notificationTicketCollaboratorAdded => 'Mitarbeiter hinzugefügt';

  @override
  String get priority => 'Priorität';

  @override
  String get status => 'Status';

  @override
  String get assignee => 'Zugewiesen an';

  @override
  String get ticketDescription => 'Beschreibung';

  @override
  String get ticketPriorityNone => 'Keine';

  @override
  String get ticketPriorityUrgent => 'Dringend';

  @override
  String get ticketPriorityHigh => 'Hoch';

  @override
  String get ticketPriorityMedium => 'Mittel';

  @override
  String get ticketPriorityLow => 'Niedrig';

  @override
  String get ticketViewList => 'Liste';

  @override
  String get ticketViewBoard => 'Board';

  @override
  String get ticketTitlePlaceholder => 'Titel des Tickets';

  @override
  String get ticketDescriptionPlaceholder => 'Beschreibung hinzufügen…';

  @override
  String get createMore => 'Weitere erstellen';

  @override
  String selectedCount(int count) {
    return '$count ausgewählt';
  }

  @override
  String get clearSelection => 'Auswahl aufheben';

  @override
  String get bulkDeleteTitle => 'Tickets löschen';

  @override
  String bulkDeleteMessage(int count) {
    return '$count ausgewählte Tickets löschen? Das kann nicht rückgängig gemacht werden.';
  }

  @override
  String get assignTo => 'Zuweisen an…';

  @override
  String get sectionMembers => 'Mitglieder';

  @override
  String get sectionAgents => 'Agenten';

  @override
  String get sidebarGroupWork => 'Arbeit';

  @override
  String get sidebarGroupTeam => 'Team';

  @override
  String get notificationsTitle => 'Benachrichtigungen';

  @override
  String get notificationsTooltip => 'Benachrichtigungen';

  @override
  String get notificationsEmpty => 'Alles erledigt';

  @override
  String get markAllRead => 'Alle als gelesen markieren';

  @override
  String get toggleThemeLabel => 'Design wechseln';

  @override
  String get teamsNav => 'Teams';

  @override
  String get dashboardGreeting => 'Grüezi';

  @override
  String get dashboardSubtitle => 'Das machen deine Agenten gerade.';

  @override
  String get recentActivityTitle => 'Letzte Aktivität';

  @override
  String get noRecentActivity => 'Noch keine aktuelle Aktivität';

  @override
  String get noRecentActivitySubtitle =>
      'Agent-Ausführungen, Pull Requests und Nachrichten erscheinen hier.';

  @override
  String get noWorkspace => 'Kein Arbeitsbereich';

  @override
  String get allAgentsIdle => 'Alle Agenten inaktiv';

  @override
  String get statWorkspaces => 'Arbeitsbereiche';

  @override
  String get statAgents => 'Agenten';

  @override
  String get statRunning => 'Aktiv';

  @override
  String get activeAgentsTitle => 'Aktive Agenten';

  @override
  String get noAgentProcessesSubtitle =>
      'Agentenaktivität erscheint hier, sobald ein Lauf startet.';

  @override
  String agentIdShort(String id) {
    return 'ID $id';
  }

  @override
  String runningProcessesLabel(int count) {
    return 'Aktiv · $count';
  }

  @override
  String get noneLabel => 'Keine';

  @override
  String get sidebarGroupKnowledge => 'Wissen';

  @override
  String get navMemory => 'Gedächtnis';

  @override
  String get memoryTabFacts => 'Fakten';

  @override
  String get memoryTabPolicies => 'Richtlinien';

  @override
  String get memoryTabGraph => 'Wissensgraph';

  @override
  String get memoryNoWorkspace =>
      'Wähle einen Arbeitsbereich, um sein Gedächtnis anzuzeigen.';

  @override
  String get topStory => 'Top-Story';

  @override
  String get searchArticles => 'Artikel suchen';

  @override
  String get filterAll => 'Alle';

  @override
  String get filterUnread => 'Ungelesen';

  @override
  String get filterSaved => 'Gespeichert';

  @override
  String get saveArticle => 'Artikel speichern';

  @override
  String get removeFromSaved => 'Aus Gespeicherten entfernen';

  @override
  String get filterBySource => 'Nach Quelle filtern';

  @override
  String get viewAsList => 'Listenansicht';

  @override
  String get viewAsGrid => 'Rasteransicht';

  @override
  String get noMatchingArticles => 'Keine passenden Artikel';

  @override
  String get noMatchingArticlesBody =>
      'Versuche eine andere Suche oder einen anderen Quellenfilter.';

  @override
  String get allCaughtUp => 'Alles erledigt';

  @override
  String get allCaughtUpBody =>
      'Keine ungelesenen Artikel — schau später wieder vorbei.';

  @override
  String get openArticlesInAppDescription =>
      'Links im integrierten Reader statt im Standardbrowser öffnen.';

  @override
  String get blockAdsTrackersDescription =>
      'Werbung, Tracker und Cookie-Banner aus Artikeln entfernen, die du im Reader öffnest.';

  @override
  String get agentQuestionHeader => 'Frage an dich';

  @override
  String get agentQuestionAnsweredLabel => 'Beantwortet';

  @override
  String get agentQuestionSubmit => 'Antwort senden';

  @override
  String get agentQuestionFreeformHint => 'Gib deine Antwort ein…';

  @override
  String get agentQuestionAnswerLabel => 'Deine Antwort';

  @override
  String get reviewRequested => 'Review angefragt';

  @override
  String get loadMorePrs => 'Mehr laden';

  @override
  String get loadingMorePrs => 'Wird geladen…';

  @override
  String get noPrsMatchFilters =>
      'Keine Pull Requests entsprechen den Filtern in diesem Repository';

  @override
  String get connectGitHubToLoadPrs =>
      'GitHub verbinden, um Pull Requests zu laden';

  @override
  String get noRepositoriesConfigured => 'Keine Repositories konfiguriert';

  @override
  String get noAuthors => 'Keine Autoren';

  @override
  String get noAuthorMatches => 'Keine Treffer';

  @override
  String openedAgo(String age) {
    return 'Geöffnet $age';
  }

  @override
  String updatedAgo(String age) {
    return 'Aktualisiert $age';
  }

  @override
  String get checksPassing => 'Prüfungen bestanden';

  @override
  String get checksRunning => 'Prüfungen laufen';

  @override
  String get needsYourReview => 'Benötigt deine Review';

  @override
  String diffSummary(int additions, int deletions) {
    return '+$additions −$deletions Zeilen';
  }

  @override
  String get checks => 'Prüfungen';

  @override
  String get noReviewersAssigned => 'Keine Prüfer zugewiesen';

  @override
  String get noAssignees => 'Keine Zuständigen';

  @override
  String get noChecksYet => 'Noch keine Prüfungen ausgeführt';

  @override
  String checksFailingCount(int count) {
    return '$count fehlgeschlagen';
  }

  @override
  String get showMore => 'Mehr anzeigen';

  @override
  String get showLess => 'Weniger anzeigen';

  @override
  String get backToPullRequests => 'Zurück zu den Pull Requests';

  @override
  String get pullRequestNotFound => 'Pull Request nicht gefunden';

  @override
  String get pullRequestNotFoundBody =>
      'Sie wurde möglicherweise zusammengeführt, geschlossen oder verschoben.';

  @override
  String get couldntLoadPullRequest =>
      'Diese Pull Request konnte nicht geladen werden';

  @override
  String get showDetails => 'Details anzeigen';

  @override
  String loadingPullRequestNumber(int number) {
    return 'Pull Request #$number wird geladen…';
  }

  @override
  String get noDescriptionProvided => 'Keine Beschreibung angegeben.';

  @override
  String get factsHint =>
      'Fakten erscheinen hier, sobald deine Agenten dazulernen.';

  @override
  String get noFactsMatch => 'Keine Fakten entsprechen deiner Suche';

  @override
  String get memoryLoadError => 'Speicher konnte nicht geladen werden';

  @override
  String get sortRecent => 'Neueste';

  @override
  String get sortConfidence => 'Konfidenz';

  @override
  String get confidenceTooltip =>
      'Wie sicher sich Agenten sind, dass dieser Fakt stimmt, von 0 bis 100 %.';

  @override
  String get supersededTooltip => 'Ein neuerer Fakt hat diesen ersetzt.';

  @override
  String get domain => 'Domäne';

  @override
  String get fitToView => 'An Ansicht anpassen';

  @override
  String get project => 'Projekt';

  @override
  String get projects => 'Projekte';

  @override
  String get newProject => 'Neues Projekt';

  @override
  String get editProject => 'Projekt bearbeiten';

  @override
  String get deleteProject => 'Projekt löschen';

  @override
  String get noProject => 'Kein Projekt';

  @override
  String get allTickets => 'Alle Tickets';

  @override
  String get projectNamePlaceholder => 'Projektname';

  @override
  String get projectDescriptionPlaceholder => 'Beschreibung (optional)';

  @override
  String get projectColorLabel => 'Farbe';

  @override
  String get noProjectsYet => 'Noch keine Projekte';

  @override
  String get projectTicketsEmpty => 'Noch keine Tickets in diesem Projekt';

  @override
  String get createProject => 'Projekt erstellen';

  @override
  String projectProgress(int done, int total) {
    return '$done von $total erledigt';
  }

  @override
  String deleteProjectConfirm(String name) {
    return '„$name“ löschen? Die Tickets bleiben erhalten und werden aus dem Projekt entfernt.';
  }

  @override
  String get projectStatusActive => 'Aktiv';

  @override
  String get projectStatusCompleted => 'Abgeschlossen';

  @override
  String get projectStatusArchived => 'Archiviert';

  @override
  String get markProjectCompleted => 'Als abgeschlossen markieren';

  @override
  String get markProjectActive => 'Als aktiv markieren';

  @override
  String get archiveProject => 'Archivieren';

  @override
  String get restoreProject => 'Wiederherstellen';

  @override
  String get relations => 'Beziehungen';

  @override
  String get relateTo => 'Verknüpfen mit';

  @override
  String get relationSubIssueOf => 'Unteraufgabe von…';

  @override
  String get relationParentOf => 'Übergeordnet zu…';

  @override
  String get relationBlockedBy => 'Blockiert von…';

  @override
  String get relationBlocking => 'Blockiert…';

  @override
  String get relationRelatedTo => 'Verwandt mit…';

  @override
  String get relationDuplicateOf => 'Duplikat von…';

  @override
  String get relationGroupParent => 'Übergeordnet';

  @override
  String get relationGroupSubIssues => 'Unteraufgaben';

  @override
  String get relationGroupBlockedBy => 'Blockiert von';

  @override
  String get relationGroupBlocking => 'Blockiert';

  @override
  String get relationGroupRelated => 'Verwandt';

  @override
  String get relationGroupDuplicateOf => 'Duplikat von';

  @override
  String get relationGroupDuplicatedBy => 'Dupliziert von';

  @override
  String get copyId => 'ID kopieren';

  @override
  String get ticketIdCopied => 'Ticket-ID kopiert';

  @override
  String get selectTicket => 'Ticket auswählen';

  @override
  String get searchTicketsHint => 'Tickets suchen…';

  @override
  String get noMatchingTickets => 'Keine passenden Tickets';

  @override
  String get addToProject => 'Zum Projekt hinzufügen';

  @override
  String get activeFleet => 'Aktive Flotte';

  @override
  String agentsCountLabel(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count Agenten',
      one: '1 Agent',
    );
    return '$_temp0';
  }

  @override
  String get blockedStatus => 'Blockiert';

  @override
  String get failedStatus => 'Fehlgeschlagen';

  @override
  String get neverRunStatus => 'Nie ausgeführt';

  @override
  String get noActiveRun => 'Kein aktiver Lauf';

  @override
  String get allPullRequests => 'Alle Pull Requests';

  @override
  String get clearAll => 'Alle löschen';

  @override
  String get needsYouNow => 'Braucht dich jetzt';

  @override
  String get pipelinesSectionTitle => 'Pipelines';

  @override
  String get allRuns => 'Alle Läufe';

  @override
  String get triage => 'Sichten';

  @override
  String agentsRunningCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count Agenten aktiv',
      one: '1 Agent aktiv',
    );
    return '$_temp0';
  }

  @override
  String blockedCountLabel(int count) {
    return '$count blockiert';
  }

  @override
  String needsYouCountLabel(int count) {
    return '$count für dich';
  }

  @override
  String reviewSummary(int prs, int repos) {
    String _temp0 = intl.Intl.pluralLogic(
      prs,
      locale: localeName,
      other: '$prs PRs warten',
      one: '1 PR wartet',
    );
    String _temp1 = intl.Intl.pluralLogic(
      repos,
      locale: localeName,
      other: '$repos Repositorys',
      one: '1 Repository',
    );
    return '$_temp0 auf deine Review in $_temp1';
  }

  @override
  String reviewsAwaitingYou(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count Reviews',
      one: '1 Review',
    );
    return '$_temp0 warten auf dich';
  }

  @override
  String reviewsOverTwoDays(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count älter als 2 Tage',
      one: '1 älter als 2 Tage',
    );
    return '$_temp0';
  }

  @override
  String agentBlockedTitle(String name) {
    return '$name ist blockiert';
  }

  @override
  String get agentBlockedSubtitle => 'Wartet auf deine Bestätigung';

  @override
  String get pipelineFailedTitle => 'Pipeline fehlgeschlagen';

  @override
  String prStaleTitle(String number) {
    return 'PR $number veraltet';
  }

  @override
  String get prStaleSubtitle => 'Keine aktuelle Aktivität';

  @override
  String get reviewRequestedBadge => 'Review angefragt';

  @override
  String get draftBadge => 'Entwurf';

  @override
  String get staleLabel => 'Veraltet';

  @override
  String stepsProgress(int done, int total) {
    return '$done von $total Schritten';
  }

  @override
  String get allCaughtUpSubtitle =>
      'Derzeit brauchen dich keine Reviews, Blockaden oder Fehler.';

  @override
  String dashboardGreetingNamed(String name) {
    return 'Grüezi, $name';
  }

  @override
  String workspaceEyebrow(String name) {
    return '$name-Workspace';
  }

  @override
  String get pipelineTriggerNode => 'Trigger';

  @override
  String get priorityReviewsTooltip =>
      'Offene PRs, die deine Review anfragen und seit mehr als 24 Stunden warten.';

  @override
  String get workspaceSettings => 'Workspace-Einstellungen';

  @override
  String get manageWorkspacesSubtitle =>
      'Benenne einen Workspace um und ändere seine Markierung — wähle links einen aus, um ihn zu bearbeiten.';

  @override
  String workspaceCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count Workspaces',
      one: '1 Workspace',
      zero: 'Keine Workspaces',
    );
    return '$_temp0';
  }

  @override
  String workspaceReposAgents(int repos, int agents) {
    String _temp0 = intl.Intl.pluralLogic(
      repos,
      locale: localeName,
      other: '$repos Repos',
      one: '1 Repo',
      zero: 'Keine Repos',
    );
    String _temp1 = intl.Intl.pluralLogic(
      agents,
      locale: localeName,
      other: '$agents Agenten',
      one: '1 Agent',
      zero: '0 Agenten',
    );
    return '$_temp0 · $_temp1';
  }

  @override
  String get identity => 'Identität';

  @override
  String get uploadImage => 'Bild hochladen';

  @override
  String get workspaceLogoHint =>
      'PNG, JPG oder GIF bis zu 2 MB. Andernfalls verwenden wir den Anfangsbuchstaben des Workspace.';

  @override
  String get workspaceNameFieldHelp =>
      'Wird im Umschalter, im Brotkrümelpfad und auf jedem Bildschirm angezeigt.';

  @override
  String get dangerZone => 'Gefahrenzone';

  @override
  String get deleteThisWorkspace => 'Diesen Workspace löschen';

  @override
  String deleteWorkspaceLongDescription(String name) {
    return 'Entfernt $name, seine Repository-Verbindungen, Agenten und den Speicher dauerhaft. Dies kann nicht rückgängig gemacht werden.';
  }

  @override
  String get discard => 'Verwerfen';

  @override
  String discardChangesQuestion(String name) {
    return 'Nicht gespeicherte Änderungen an $name verwerfen?';
  }

  @override
  String get workspaceUpdated => 'Workspace aktualisiert';

  @override
  String get editTitle => 'Titel bearbeiten';

  @override
  String get editDescription => 'Beschreibung bearbeiten';

  @override
  String get addDescription => 'Beschreibung hinzufügen';

  @override
  String get prTitlePlaceholder => 'Titel';

  @override
  String get prBodyPlaceholder => 'Beschreibung hinzufügen';

  @override
  String get write => 'Schreiben';

  @override
  String get diff => 'Diff';

  @override
  String get preview => 'Vorschau';

  @override
  String get prTemplateLabel => 'Vorlage';

  @override
  String get prTemplateDefault => 'Standard';

  @override
  String get addReviewers => 'Reviewer hinzufügen';

  @override
  String get addAssignees => 'Zuständige hinzufügen';

  @override
  String get searchUsers => 'Personen suchen…';

  @override
  String get searchReviewers => 'Personen und Teams suchen…';

  @override
  String get usersSectionLabel => 'Personen';

  @override
  String get teamsSectionLabel => 'Teams';

  @override
  String get noMatchingUsers => 'Keine passenden Personen';

  @override
  String get noMatchingReviewers => 'Keine Treffer';

  @override
  String addCount(int count) {
    return 'Hinzufügen ($count)';
  }

  @override
  String get requiredByCodeOwners => 'Von Code-Eigentümern erforderlich';

  @override
  String reviewedOnBehalfOf(String login) {
    return 'über $login';
  }

  @override
  String get team => 'Team';

  @override
  String get markdownBold => 'Fett';

  @override
  String get markdownItalic => 'Kursiv';

  @override
  String get markdownHeading => 'Überschrift';

  @override
  String get markdownBulletList => 'Aufzählung';

  @override
  String get markdownChecklist => 'Checkliste';

  @override
  String get markdownCode => 'Code';

  @override
  String get markdownLink => 'Link';

  @override
  String get markdownQuote => 'Zitat';

  @override
  String failedToUpdateTitle(String error) {
    return 'Titel konnte nicht aktualisiert werden: $error';
  }

  @override
  String failedToUpdateDescription(String error) {
    return 'Beschreibung konnte nicht aktualisiert werden: $error';
  }

  @override
  String failedToUpdateReviewers(String error) {
    return 'Reviewer konnten nicht aktualisiert werden: $error';
  }

  @override
  String failedToUpdateAssignees(String error) {
    return 'Zuständige konnten nicht aktualisiert werden: $error';
  }

  @override
  String get discardChangesConfirm => 'Änderungen verwerfen?';

  @override
  String get newPr => 'Neue PR';

  @override
  String get openPullRequest => 'Pull Request öffnen';

  @override
  String get composePrSubtitle =>
      'Aus einem gepushten Branch — ohne Agenten oder Tickets';

  @override
  String get createAsDraft => 'Als Entwurf erstellen';

  @override
  String get composePrNoRepo => 'Kein GitHub-Repository ausgewählt';

  @override
  String get composePrNoRepoHint =>
      'Wähle einen Arbeitsbereich mit einem mit GitHub verknüpften Repository, um eine Pull Request zu öffnen.';

  @override
  String get composePrPickBranches =>
      'Wähle einen Basis- und einen Vergleichsbranch, um die Änderungen anzuzeigen.';

  @override
  String get composePrNothingToCompare =>
      'Es gibt keine Änderungen zwischen diesen Branches.';

  @override
  String get repository => 'Repository';

  @override
  String get baseBranchLabel => 'Basis';

  @override
  String get compareBranchLabel => 'Vergleichen';

  @override
  String get selectBranch => 'Branch auswählen';

  @override
  String get navMeetings => 'Besprechungen';

  @override
  String get meetingsNoWorkspace =>
      'Wähle einen Arbeitsbereich, um Besprechungen zu sehen.';

  @override
  String get meetingsEmpty =>
      'Noch keine Besprechungen. Starte eine Aufnahme, um eine zu erfassen.';

  @override
  String get meetingsStartRecording => 'Aufnahme starten';

  @override
  String get meetingsStopRecording => 'Aufnahme stoppen';

  @override
  String get meetingsProcessing => 'Zusammenfassung läuft…';

  @override
  String get meetingEnhancedNotes => 'Erweiterte Notizen';

  @override
  String get meetingYourNotes => 'Deine Notizen';

  @override
  String get meetingNotesHint =>
      'Notiere kurze Notizen – der Agent erweitert sie nach der Besprechung.';

  @override
  String get meetingTranscriptTitle => 'Transkript';

  @override
  String get meetingNoTranscriptYet =>
      'Das Transkript erscheint hier, während gesprochen wird.';

  @override
  String get meetingSpeakerMe => 'Du';

  @override
  String get meetingSpeakerThem => 'Andere';

  @override
  String get meetingStatusRecording => 'Aufnahme';

  @override
  String get meetingStatusProcessing => 'Verarbeitung';

  @override
  String get meetingStatusDone => 'Fertig';

  @override
  String get meetingStatusFailed => 'Fehlgeschlagen';

  @override
  String get keybindingGoToMeetings => 'Zu Besprechungen';

  @override
  String get keybindingNavigateToTheMeetingsDescription =>
      'Zur Besprechungsliste navigieren';

  @override
  String get meetingsOverlineKnowledge => 'Wissen';

  @override
  String get meetingsOverlineEngine => 'Auf dem Gerät · Whisper base.en';

  @override
  String get meetingsSubtitle =>
      'Lokale Aufnahme deiner Besprechungen. Wir greifen das Besprechungsaudio und dein Mikrofon ab, transkribieren auf dem Gerät und lassen einen Agenten deine knappen Notizen in Entscheidungen und Aufgaben verwandeln — kein Bot tritt dem Anruf je bei.';

  @override
  String get meetingsRecordMeeting => 'Besprechung aufnehmen';

  @override
  String meetingsProcessingNow(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count werden gerade verarbeitet',
      one: '1 wird gerade verarbeitet',
    );
    return '$_temp0';
  }

  @override
  String get meetingsStatThisWeek => 'Diese Woche';

  @override
  String get meetingsStatThisWeekUnit => 'Besprechungen erfasst';

  @override
  String get meetingsStatRecorded => 'Aufgenommen';

  @override
  String get meetingsStatRecordedUnit => 'lokal transkribiert';

  @override
  String get meetingsStatOpen => 'Offen';

  @override
  String get meetingsStatOpenUnit => 'ausstehende Aufgaben';

  @override
  String get meetingsStatLogged => 'Protokolliert';

  @override
  String get meetingsStatLoggedUnit => 'extrahierte Entscheidungen';

  @override
  String get meetingsCaptureTitle =>
      'Treiberlose Systemaudio-Aufnahme ist scharf geschaltet.';

  @override
  String get meetingsCaptureBody =>
      'Control Center greift die Lautsprecherausgabe der App ab, in der du gerade bist — Slack Huddle, Meet, Zoom, Tuple — plus dein Mikrofon, und dekodiert beide Streams auf diesem Gerät.';

  @override
  String get meetingsCapturePermission => 'Berechtigung erteilt';

  @override
  String get meetingsCaptureOnDevice => '100 % auf dem Gerät';

  @override
  String get meetingsCaptureNoBot => 'Kein Bot tritt bei';

  @override
  String get meetingsScopeAll => 'Alle Besprechungen';

  @override
  String get meetingsFilterAll => 'Alle';

  @override
  String get meetingsFilterDone => 'Erledigt';

  @override
  String get meetingsFilterProcessing => 'In Bearbeitung';

  @override
  String get meetingsSearchHint => 'Nach Titel, Person, App filtern…';

  @override
  String get meetingsBucketToday => 'Heute';

  @override
  String get meetingsBucketYesterday => 'Gestern';

  @override
  String get meetingsBucketEarlierThisWeek => 'Früher diese Woche';

  @override
  String get meetingsBucketLastWeek => 'Letzte Woche';

  @override
  String get meetingsBucketOlder => 'Älter';

  @override
  String meetingsDecisionsCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count Entscheidungen',
      one: '1 Entscheidung',
    );
    return '$_temp0';
  }

  @override
  String meetingsActionItemsProgress(int done, int total) {
    return '$done / $total Aufgaben';
  }

  @override
  String get meetingsEnhancedPill => 'angereichert';

  @override
  String get meetingsTranscribing => 'transkribieren und zusammenfassen…';

  @override
  String get meetingsOpenAction => 'Öffnen';

  @override
  String get meetingsStopProcessing => 'Stoppen';

  @override
  String get meetingsStillTranscribing =>
      'Wird noch transkribiert — die Zusammenfassung erscheint, sobald sie fertig ist.';

  @override
  String get meetingsNoMatch => 'Keine Besprechung passt';

  @override
  String get meetingsNoMatchHint =>
      'Versuche einen anderen Filter oder Suchbegriff.';

  @override
  String get meetingBackAllMeetings => 'Alle Besprechungen';

  @override
  String meetingPeopleCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count Personen',
      one: '1 Person',
    );
    return '$_temp0';
  }

  @override
  String get meetingReRunSummary => 'Zusammenfassung neu erstellen';

  @override
  String get meetingExport => 'Exportieren';

  @override
  String get meetingAugmentingBanner =>
      'Notizen werden aus dem Transkript angereichert — Entscheidungen und Aufgaben werden extrahiert…';

  @override
  String get meetingTabNotes => 'Notizen';

  @override
  String get meetingTabTranscript => 'Transkript';

  @override
  String get meetingTabActionItems => 'Aufgaben';

  @override
  String get meetingTabDecisions => 'Entscheidungen';

  @override
  String get meetingNotesEnhancedToggle => 'Angereichert';

  @override
  String get meetingNotesYoursToggle => 'Deine Notizen';

  @override
  String get meetingEnhancedByAgent =>
      'Vom Agenten angereichert · aus dem Transkript';

  @override
  String get meetingEnhancedPending =>
      'Der Agent arbeitet noch an dieser Zusammenfassung.';

  @override
  String get meetingNotesEmpty => 'Noch keine angereicherten Notizen.';

  @override
  String get meetingNotesSavedLocally => 'Lokal gespeichert';

  @override
  String get meetingNotesSaving => 'Speichern…';

  @override
  String get meetingViewFullTranscript => 'Vollständiges Transkript ansehen';

  @override
  String get meetingTranscriptSearchHint => 'Im Transkript suchen…';

  @override
  String get meetingSpeakerEveryone => 'Alle';

  @override
  String get meetingSpeakerOthers => 'Andere';

  @override
  String get meetingTranscriptEmpty => 'Noch kein Transkript.';

  @override
  String get meetingActionItemsEmpty => 'Keine Aufgaben extrahiert.';

  @override
  String get meetingActionItemFrom => 'aus dieser Besprechung';

  @override
  String get meetingCreateTicket => 'Ticket erstellen';

  @override
  String meetingTicketCreated(String key) {
    return 'Ticket $key erstellt und zugewiesen.';
  }

  @override
  String get meetingTicketFailed => 'Ticket konnte nicht erstellt werden.';

  @override
  String get meetingDecisionsEmpty => 'Keine Entscheidungen protokolliert.';

  @override
  String get meetingReRunStarted =>
      'Zusammenfassung wird auf dem Transkript neu erstellt…';

  @override
  String get meetingReRunDone => 'Zusammenfassung aktualisiert.';

  @override
  String get meetingReRunNoTranscript =>
      'Es gibt noch kein Transkript zum Zusammenfassen.';

  @override
  String get meetingExportCopied =>
      'Notizen als Markdown in die Zwischenablage kopiert.';

  @override
  String get meetingExportNothing => 'Es gibt noch nichts zu exportieren.';

  @override
  String get meetingsRecordingCrumb => 'Aufnahme…';

  @override
  String get meetingRecordTitleHint => 'Besprechungstitel';

  @override
  String get meetingRecordTappingLabel => 'Abgriff:';

  @override
  String get meetingRecordMic => 'Mikro';

  @override
  String get meetingRecordSystemAudio => 'Systemaudio';

  @override
  String get meetingRecordPause => 'Pause';

  @override
  String get meetingRecordResume => 'Fortsetzen';

  @override
  String get meetingRecordStop => 'Stoppen und zusammenfassen';

  @override
  String get meetingRecordYourNotes => 'Deine Notizen';

  @override
  String get meetingRecordNotesTagline =>
      'notiere knapp — der Agent füllt den Rest';

  @override
  String get meetingRecordNotesPlaceholder =>
      'Schreib mit, während du zuhörst. Ein paar Fragmente genügen — nach dem Stopp erweitert der Agent sie anhand des Transkripts.';

  @override
  String get meetingRecordLiveTranscript => 'Live-Transkript';

  @override
  String get meetingRecordDecoding => 'Dekodierung auf dem Gerät';

  @override
  String get meetingRecordListening =>
      'Höre zu… Sprache erscheint hier in ein, zwei Sekunden, gekennzeichnet als Du / Andere.';

  @override
  String get meetingRecordPausedHint =>
      'Pausiert — Audio wird ignoriert, bis du fortsetzt.';

  @override
  String get meetingRecordNotActive => 'Keine aktive Aufnahme.';

  @override
  String get meetingHudRecording => 'Aufnahme';

  @override
  String get meetingHudPaused => 'pausiert';

  @override
  String get meetingHudOpen => 'Öffnen';

  @override
  String get meetingHudStop => 'Stoppen';
}
