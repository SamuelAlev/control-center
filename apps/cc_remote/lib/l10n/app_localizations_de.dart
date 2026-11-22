// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for German (`de`).
class AppLocalizationsDe extends AppLocalizations {
  AppLocalizationsDe([String locale = 'de']) : super(locale);

  @override
  String get appTitle => 'Control Center';

  @override
  String get back => 'Zurück';

  @override
  String get cancel => 'Abbrechen';

  @override
  String get retry => 'Erneut versuchen';

  @override
  String get tryAgain => 'Erneut versuchen';

  @override
  String get settings => 'Einstellungen';

  @override
  String get refresh => 'Aktualisieren';

  @override
  String get approve => 'Genehmigen';

  @override
  String get deny => 'Verweigern';

  @override
  String get continueLabel => 'Weiter';

  @override
  String get agentQuestionHeader => 'Frage an dich';

  @override
  String get agentQuestionAnsweredLabel => 'Beantwortet';

  @override
  String get agentQuestionSkip => 'Überspringen';

  @override
  String get agentQuestionSkippedLabel => 'Übersprungen';

  @override
  String get agentQuestionFreeformHint => 'Gib deine Antwort ein…';

  @override
  String get agentApprovalRequired => 'Freigabe erforderlich';

  @override
  String get copyCommand => 'Befehl kopieren';

  @override
  String get approveAndRemember => '8 Stunden lang zulassen';

  @override
  String get decline => 'Ablehnen';

  @override
  String get confirm => 'Confirm';

  @override
  String get send => 'Senden';

  @override
  String get close => 'Schließen';

  @override
  String get expand => 'Ausklappen';

  @override
  String get zoomIn => 'Vergrößern';

  @override
  String get zoomOut => 'Verkleinern';

  @override
  String get resetZoom => 'Zoom zurücksetzen';

  @override
  String get scanQrPrompt =>
      'Scanne den QR-Code in Control Center, um dieses Handy zu koppeln.';

  @override
  String get scanQrHelp =>
      'Öffne die Kamera und richte sie auf den QR in Control Center. Dieses Handy verbindet sich direkt über eine private Verbindung.';

  @override
  String get connectingToMac =>
      'Verbindung mit Control Center wird hergestellt…';

  @override
  String get connectingDetail => 'Sichere, direkte Verbindung wird aufgebaut.';

  @override
  String get identityChangedTitle => 'Serveridentität hat sich geändert';

  @override
  String get identityChangedBody =>
      'Dieser Server stimmt nicht mehr mit der Identität überein, die beim Koppeln gespeichert wurde. Das kann bedeuten, dass der Server neu installiert wurde — oder dass etwas die Verbindung abfängt. Aus Sicherheitsgründen verbindet sich dieses Gerät nicht. Entferne die Kopplung und scanne dann einen neuen QR-Code in Control Center, um erneut zu koppeln.';

  @override
  String get removePairing => 'Kopplung entfernen';

  @override
  String get couldntConnect => 'Verbindung fehlgeschlagen';

  @override
  String get pendingPairingTitle => 'Mit diesem Server verbinden?';

  @override
  String get pendingPairingBody =>
      'Ein Link hat Control Center gebeten, sich mit diesem Server zu koppeln. Fahre nur fort, wenn du das selbst ausgelöst hast.';

  @override
  String get connect => 'Verbinden';

  @override
  String get failureNotPaired =>
      'Nicht gekoppelt — scanne den QR-Code in Control Center';

  @override
  String get failureUnreachable =>
      'Server über keinen Pfad erreichbar — prüfe, ob er läuft, oder versuche dasselbe Netzwerk';

  @override
  String get failureIdentityChanged =>
      'Die Serveridentität hat sich geändert — nach Neuinstallation dieses Gerät erneut koppeln';

  @override
  String get failureAuthRejected =>
      'Der Server hat dieses Gerät abgelehnt — kople es erneut von Control Center';

  @override
  String get failureUnknown =>
      'Verbindung fehlgeschlagen — tippen zum erneuten Versuch';

  @override
  String get statusConnected => 'Verbunden';

  @override
  String get statusConnecting => 'Verbinden';

  @override
  String get statusOffline => 'Offline';

  @override
  String get statusIdentityMismatch => 'Identitätsabweichung';

  @override
  String get statusNotPaired => 'Nicht gekoppelt';

  @override
  String get statusConfirmPairing => 'Kopplung bestätigen';

  @override
  String get connectionFailed => 'Verbindung fehlgeschlagen';

  @override
  String get identityMismatchBanner =>
      'Serveridentität hat sich geändert — Verbindung gestoppt. Kople dieses Gerät erneut, um fortzufahren.';

  @override
  String get tabInbox => 'Posteingang';

  @override
  String get tabTickets => 'Tickets';

  @override
  String get tabChat => 'Chat';

  @override
  String get tabPrs => 'PRs';

  @override
  String get tabCalendar => 'Kalender';

  @override
  String get tabNews => 'News';

  @override
  String tabWaitingCount(String label, int count) {
    return '$label, $count wartend';
  }

  @override
  String get updateAvailable => 'Ein neues Control Center ist verfügbar';

  @override
  String get appearance => 'Darstellung';

  @override
  String get language => 'Sprache';

  @override
  String get device => 'Gerät';

  @override
  String get themeSystem => 'System';

  @override
  String get themeLight => 'Hell';

  @override
  String get themeDark => 'Dunkel';

  @override
  String get languageSystem => 'System';

  @override
  String get disconnectTapAgain =>
      'Nochmal tippen, um dieses Gerät von Control Center zu trennen';

  @override
  String get disconnectDevice => 'Dieses Gerät trennen';

  @override
  String get disconnect => 'Trennen';

  @override
  String get chooseWorkspace => 'Workspace wählen';

  @override
  String get workspaces => 'Arbeitsbereiche';

  @override
  String get workspacesLoadFailed => 'Workspaces konnten nicht geladen werden';

  @override
  String get noWorkspacesYet => 'Noch keine Workspaces';

  @override
  String selectWorkspace(String name) {
    return '$name auswählen';
  }

  @override
  String get inboxLoadFailed => 'Posteingang konnte nicht geladen werden';

  @override
  String get allCaughtUp => 'Du bist auf dem neuesten Stand';

  @override
  String get inboxNothingWaiting =>
      'Nichts ist blockiert und kein Pull Request wartet auf dich.';

  @override
  String get blocked => 'Blockiert';

  @override
  String get sectionNeedsYourReview => 'Braucht dein Review';

  @override
  String get sectionReturnedToYou => 'An dich zurückgegeben';

  @override
  String get sectionApprovedAndReady => 'Freigegeben und bereit';

  @override
  String get sectionYourDrafts => 'Deine Entwürfe';

  @override
  String get sectionWaitingForReviewers => 'Wartet auf Reviewer';

  @override
  String get sectionMergingAndMerged => 'Wird gemergt und kürzlich gemergt';

  @override
  String get sectionWaitingForAuthor => 'Wartet auf Autor';

  @override
  String waitingAgo(String ago) {
    return 'wartet seit $ago';
  }

  @override
  String get openConversation => 'Unterhaltung öffnen';

  @override
  String get calendarLoadFailed => 'Kalender konnte nicht geladen werden';

  @override
  String get nothingScheduled => 'Nichts geplant';

  @override
  String get calendarEmptyDescription =>
      'Termine aus deinen verbundenen Kalendern erscheinen hier.';

  @override
  String get agenda => 'Agenda';

  @override
  String get syncCalendarsNow => 'Kalender jetzt synchronisieren';

  @override
  String get event => 'Termin';

  @override
  String get eventNotFound => 'Termin nicht gefunden';

  @override
  String get eventNotFoundDescription =>
      'Er liegt möglicherweise außerhalb des Agenda-Fensters oder wurde entfernt.';

  @override
  String get joinMeeting => 'Meeting beitreten';

  @override
  String get join => 'Beitreten';

  @override
  String attendeesCount(int count) {
    return 'Teilnehmer ($count)';
  }

  @override
  String get details => 'Details';

  @override
  String get allDay => 'Ganztägig';

  @override
  String get happeningNow => 'Läuft gerade';

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
  String get attendeeAccepted => 'zugesagt';

  @override
  String get attendeeDeclined => 'abgelehnt';

  @override
  String get attendeeMaybe => 'vielleicht';

  @override
  String get attendeeNoReply => 'keine Antwort';

  @override
  String get organizer => 'Organisator';

  @override
  String get calendarNoAccounts =>
      'Für diesen Workspace ist kein Kalender verbunden. Verbinde einen in der Desktop-App — die Anmeldung speichert das Token auf dem Server.';

  @override
  String get calendarReauthNeeded =>
      'Ein Kalenderkonto muss neu verbunden werden — die Anzeige unten kann veraltet sein. Verbinde es in der Desktop-App erneut.';

  @override
  String get spacesLoadFailed => 'Spaces konnten nicht geladen werden';

  @override
  String get noSpaces => 'Keine Spaces';

  @override
  String get spacesEmptyDescription =>
      'Spaces in diesem Workspace erscheinen hier.';

  @override
  String get newSpaceFolder => 'Neuer Ordner';

  @override
  String get folderName => 'Ordnername';

  @override
  String get renameSpaceFolder => 'Ordner umbenennen';

  @override
  String get deleteSpaceFolder => 'Ordner löschen';

  @override
  String get moveSpaceToFolder => 'Bereich in Ordner verschieben';

  @override
  String get removeSpaceFromFolder => 'Bereich aus Ordner entfernen';

  @override
  String get spaceFolderActions => 'Ordneraktionen';

  @override
  String get deleteFolderWithSpacesWarning =>
      'Wenn Bereiche dauerhaft gelöscht werden, werden ihre Nachrichten und Arbeitsverzeichnisse für alle entfernt. Dies kann nicht rückgängig gemacht werden.';

  @override
  String get deleteSpacesInFolder =>
      'Bereiche in diesem Ordner dauerhaft löschen';

  @override
  String get deleteFolderAndSpaces => 'Ordner und Bereiche löschen';

  @override
  String get keepSpacesInFolder =>
      'Andernfalls bleiben die Bereiche ohne Ordner.';

  @override
  String get create => 'Erstellen';

  @override
  String get otherSpaces => 'Weitere Bereiche';

  @override
  String get folderUpdateFailed => 'Ordner konnten nicht aktualisiert werden';

  @override
  String get thread => 'Thread';

  @override
  String get agentWorking => 'Agent arbeitet';

  @override
  String get messagesLoadFailed => 'Nachrichten konnten nicht geladen werden';

  @override
  String get noMessagesYet => 'Noch keine Nachrichten';

  @override
  String get noMessagesDescription =>
      'Sende eine Nachricht, um die Unterhaltung zu starten.';

  @override
  String get agentResponding => 'Agent antwortet';

  @override
  String get agentFinished => 'Agent fertig';

  @override
  String attachmentsTooLarge(int count, String names) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$names sind zu groß, um von hier gesendet zu werden.',
      one: '$names ist zu groß, um von hier gesendet zu werden.',
    );
    return '$_temp0';
  }

  @override
  String get teammate => 'Teammitglied';

  @override
  String get systemSender => 'System';

  @override
  String get agent => 'Agent';

  @override
  String get attachFile => 'Datei anhängen';

  @override
  String get messageHint => 'Nachricht';

  @override
  String removeAttachment(String name) {
    return '$name entfernen';
  }

  @override
  String get articlesLoadFailed => 'Artikel konnten nicht geladen werden';

  @override
  String get noArticles => 'Keine Artikel';

  @override
  String get articlesEmptyDescription =>
      'Neue Artikel erscheinen hier, sobald Feeds aktualisiert werden.';

  @override
  String get unread => 'Ungelesen';

  @override
  String get allFeeds => 'Alle Feeds';

  @override
  String get save => 'Speichern';

  @override
  String get unsave => 'Nicht mehr speichern';

  @override
  String get readFullArticle => 'Artikel vollständig lesen';

  @override
  String get ticketsLoadFailed => 'Tickets konnten nicht geladen werden';

  @override
  String get noTickets => 'Keine Tickets';

  @override
  String get ticketsEmptyDescription =>
      'Tickets in diesem Workspace erscheinen hier.';

  @override
  String get all => 'Alle';

  @override
  String get ticket => 'Ticket';

  @override
  String get ticketLoadFailed => 'Ticket konnte nicht geladen werden';

  @override
  String assignedTo(String name) {
    return 'Zugewiesen an $name';
  }

  @override
  String get openInBrowser => 'Im Browser öffnen';

  @override
  String get status => 'Status';

  @override
  String get assign => 'Zuweisen';

  @override
  String get reassign => 'Neu zuweisen';

  @override
  String get noAgents => 'Keine Agenten';

  @override
  String get noAgentsDescription =>
      'Weise einen Agenten aus diesem Workspace zu.';

  @override
  String get statusOpen => 'Offen';

  @override
  String get statusInProgress => 'In Bearbeitung';

  @override
  String get statusBlocked => 'Blockiert';

  @override
  String get statusInReview => 'In Prüfung';

  @override
  String get statusDone => 'Erledigt';

  @override
  String get statusBacklog => 'Backlog';

  @override
  String get lensNeedsMe => 'Für mich';

  @override
  String get lensMine => 'Meine';

  @override
  String get prsLoadFailed => 'Pull Requests konnten nicht geladen werden';

  @override
  String get noOpenPullRequests => 'Keine offenen Pull Requests';

  @override
  String get nothingWaitingOnReview => 'Nichts wartet auf dein Review';

  @override
  String get noOwnOpenPullRequests => 'Du hast keine offenen Pull Requests';

  @override
  String get nothingBlocked => 'Nichts blockiert';

  @override
  String get prsEmptyDescription =>
      'Pull Requests aus den Repos dieses Workspace erscheinen hier.';

  @override
  String get refreshPullRequests => 'Pull Requests aktualisieren';

  @override
  String get noForgeConnected =>
      'Auf dem Server ist keine Forge verbunden, daher können keine Pull Requests abgerufen werden. Verbinde eine in der Desktop-App.';

  @override
  String get draft => 'Entwurf';

  @override
  String get merged => 'Zusammengeführt';

  @override
  String get closed => 'Geschlossen';

  @override
  String get open => 'Offen';

  @override
  String get approved => 'Genehmigt';

  @override
  String get changesRequested => 'Änderungen angefordert';

  @override
  String get reviewRequired => 'Review erforderlich';

  @override
  String get checksPassing => 'Prüfungen bestanden';

  @override
  String get checksFailing => 'Prüfungen fehlgeschlagen';

  @override
  String get checksRunning => 'Prüfungen laufen';

  @override
  String prSemanticLabel(String title, String status) {
    return '$title, $status';
  }

  @override
  String get pullRequest => 'Pull Request';

  @override
  String get prLoadFailed => 'Dieser Pull Request konnte nicht geladen werden';

  @override
  String get openOnForge => 'Auf der Forge öffnen';

  @override
  String get requestChangesNeedsComment =>
      'Füge einen Kommentar hinzu, der die gewünschten Änderungen erklärt.';

  @override
  String get conversation => 'Unterhaltung';

  @override
  String get files => 'Dateien';

  @override
  String get checks => 'Prüfungen';

  @override
  String labelWithCount(String label, int count) {
    return '$label ($count)';
  }

  @override
  String filesCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count Dateien',
      one: '1 Datei',
    );
    return '$_temp0';
  }

  @override
  String commitsCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count Commits',
      one: '1 Commit',
    );
    return '$_temp0';
  }

  @override
  String get conflicts => 'Konflikte';

  @override
  String get reviewers => 'REVIEWER';

  @override
  String get noDescriptionNoComments =>
      'Noch keine Beschreibung und keine Kommentare.';

  @override
  String get noChangedFiles => 'Keine geänderten Dateien.';

  @override
  String get noChecksReported => 'Keine Checks für den Head-Commit gemeldet.';

  @override
  String get reviewCommentHint => 'Review-Kommentar hinterlassen…';

  @override
  String get comment => 'Kommentar';

  @override
  String get commentPosted => 'Kommentar veröffentlicht';

  @override
  String get request => 'Anfordern';

  @override
  String get squashAndMerge => 'Squash and merge';

  @override
  String noActionsAvailable(String status) {
    return '$status — keine Aktionen verfügbar.';
  }

  @override
  String get reviewApproved => 'genehmigt';

  @override
  String get reviewRequestedChanges => 'Änderungen angefordert';

  @override
  String get reviewCommented => 'kommentiert';

  @override
  String get reviewPending => 'ausstehend';

  @override
  String get unknownAuthor => 'unbekannt';

  @override
  String hideDiffFor(String file) {
    return 'Diff für $file ausblenden';
  }

  @override
  String showDiffFor(String file) {
    return 'Diff für $file anzeigen';
  }

  @override
  String get checkRunning => 'läuft';

  @override
  String get checkPassed => 'bestanden';

  @override
  String get checkFailed => 'fehlgeschlagen';

  @override
  String get checkCancelled => 'abgebrochen';

  @override
  String get checkSkipped => 'übersprungen';

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
      'Kein Text-Diff für diese Datei — sie ist binär oder zu groß, als dass die Forge eines liefern könnte.';

  @override
  String showRemainingLines(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Verbleibende $count Zeilen anzeigen',
      one: 'Verbleibende Zeile anzeigen',
    );
    return '$_temp0';
  }

  @override
  String unchangedLines(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count unveränderte Zeilen',
      one: '1 unveränderte Zeile',
    );
    return '$_temp0';
  }

  @override
  String get jumpToLatest => 'Zum neuesten springen';

  @override
  String get streaming => 'Wird übertragen';

  @override
  String get working => 'Arbeitet';

  @override
  String get input => 'Eingabe';

  @override
  String get output => 'Ausgabe';

  @override
  String get now => 'jetzt';

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
  String get today => 'Heute';

  @override
  String get tomorrow => 'Morgen';

  @override
  String get yesterday => 'gestern';

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
  String get mobileConversations => 'Konversationen';

  @override
  String get mobileNewConversation => 'Neue Konversation';

  @override
  String get mobileConversationName => 'Name der Unterhaltung';

  @override
  String get mobileRename => 'Umbenennen';

  @override
  String get mobileManageSpace => 'Bereich verwalten';

  @override
  String get mobileArchived => 'Archiviert';

  @override
  String get mobileSearchMessages =>
      'Alle Nachrichten in diesem Bereich durchsuchen';

  @override
  String get mobileSearch => 'Suchen';

  @override
  String get mobileNoResults => 'Keine Ergebnisse';

  @override
  String get mobileReopen => 'Erneut öffnen';

  @override
  String get mobileArchive => 'Archivieren';

  @override
  String get mobileProgress => 'Fortschritt und Kontext';

  @override
  String get mobileReadFailed =>
      'Diese Konversation konnte nicht als gelesen markiert werden.';

  @override
  String get mobileSendFailed =>
      'Nachricht nicht gesendet. Der Entwurf bleibt erhalten.';

  @override
  String get sentAttachmentUnavailable => 'Anhang nicht verfügbar';

  @override
  String get sentAttachmentLoadFailed => 'Anhang konnte nicht geladen werden';

  @override
  String get mobileActionFailed => 'Aktion fehlgeschlagen';

  @override
  String get mobileRemove => 'Entfernen';

  @override
  String get mobileLinkedMessage => 'Verknüpfte Nachricht';

  @override
  String get mobileOlderMessages => 'Ältere Nachrichten';

  @override
  String get mobileMessageActions => 'Nachrichtenaktionen';

  @override
  String get mobileOpenThread => 'Thread öffnen';

  @override
  String get mobileCopyLink => 'Link kopieren';

  @override
  String get mobileStopRun => 'Lauf stoppen';

  @override
  String get mobileStopRunConfirm =>
      'Diesen Agentenlauf stoppen? Bereits erledigte Arbeit bleibt erhalten.';

  @override
  String get mobileControlUnsupported =>
      'Dieser Lauf ist beendet oder unterstützt diese Aktion nicht.';

  @override
  String get mobilePauseRequested =>
      'Pause beim nächsten Rundenwechsel angefordert';

  @override
  String get mobileResumed => 'Lauf fortgesetzt';

  @override
  String get mobileStopRequested => 'Stopp angefordert';

  @override
  String get mobileQueuedMessages => 'Wartende Nachrichten';

  @override
  String get mobilePauseRun => 'Beim nächsten Rundenwechsel pausieren';

  @override
  String get mobileResumeRun => 'Fortsetzen';

  @override
  String get mobileEditQueued => 'Wartende Nachricht bearbeiten';

  @override
  String get mobileSteerNow => 'Jetzt eingreifen';

  @override
  String get mobileMoveUp => 'Nach oben';

  @override
  String get mobileMoveDown => 'Nach unten';

  @override
  String get mobileQueueChanged =>
      'Die Warteschlange hat sich geändert oder dieser Lauf unterstützt keine Live-Steuerung. Aktualisieren und erneut versuchen.';

  @override
  String get mobileActivity => 'Aktivität';

  @override
  String get mobilePermissions => 'Berechtigungen und Prüfprotokoll';

  @override
  String get mobilePlans => 'Pläne';

  @override
  String get mobileGoals => 'Überwachte Ziele';

  @override
  String get mobileCredentials => 'Verbindungen und Zugangsdaten';

  @override
  String get mobileWorkspaceUnavailable =>
      'Dieser Arbeitsbereich ist nicht verfügbar oder der Zugriff ist nicht mehr möglich.';

  @override
  String get mobilePrReviewThreads => 'Review-Threads';

  @override
  String get mobilePrThreadsLoadFailed =>
      'Review-Threads konnten nicht geladen werden';

  @override
  String get mobilePrNoReviewThreads => 'Noch keine Inline-Review-Threads';

  @override
  String get mobilePrCommentPermissionDenied =>
      'Keine Berechtigung zum Kommentieren in diesem Repository.';

  @override
  String get mobilePrPermissionChecking =>
      'Berechtigung zum Kommentieren wird geprüft…';

  @override
  String get mobilePrPermissionLoadFailed =>
      'Berechtigung zum Kommentieren konnte nicht geprüft werden. Zum Kommentieren erneut versuchen.';

  @override
  String mobilePrThreadLine(String side, String line) {
    return '$side, Zeile $line';
  }

  @override
  String get mobilePrOriginalSide => 'Original';

  @override
  String get mobilePrSelectCommentLine => 'Zeile zum Kommentieren auswählen';

  @override
  String get mobilePrUpdatedSide => 'Aktualisiert';

  @override
  String get mobilePrThreadResolved => 'Gelöst';

  @override
  String get mobilePrReplyHint => 'Antwort schreiben…';

  @override
  String get mobilePrCommentRequired =>
      'Vor dem Veröffentlichen einen Kommentar schreiben.';

  @override
  String get mobilePrReply => 'Antworten';

  @override
  String get mobilePrReopenThread => 'Thread wieder öffnen';

  @override
  String get mobilePrResolveThread => 'Thread lösen';

  @override
  String get mobilePrResolvePermissionDenied =>
      'Nur der Autor des Pull Requests oder Personen mit Schreibzugriff können diesen Thread lösen.';

  @override
  String mobilePrCommentOnLine(String side, String line) {
    return 'Kommentar zu $side, Zeile $line';
  }

  @override
  String get mobilePrInlineCommentHint => 'Inline-Kommentar schreiben…';

  @override
  String get mobilePrPostInlineComment => 'Kommentar veröffentlichen';

  @override
  String get mobilePrCommentUnavailable =>
      'Inline-Kommentare sind für diesen Pull Request nicht verfügbar.';

  @override
  String get mobilePrPatchUnavailable =>
      'Die Hosting-Plattform hat für diese Datei keinen Text-Patch bereitgestellt.';

  @override
  String get mobilePrNoPatchForFile =>
      'Der Patch für diese Datei ist nicht verfügbar.';

  @override
  String get mobileTicketNew => 'Neues Ticket';

  @override
  String get mobileTicketCreate => 'Ticket erstellen';

  @override
  String get mobileTicketEdit => 'Ticket bearbeiten';

  @override
  String get mobileTicketTitle => 'Titel';

  @override
  String get mobileTicketTitleRequired =>
      'Zum Speichern dieses Tickets einen Titel eingeben.';

  @override
  String get mobileTicketDescription => 'Beschreibung';

  @override
  String get mobileTicketMarkdownHint => 'Details in Markdown hinzufügen';

  @override
  String get mobileTicketPriority => 'Priorität';

  @override
  String get mobileTicketPriorityNone => 'Keine Priorität';

  @override
  String get mobileTicketPriorityUrgent => 'Dringend';

  @override
  String get mobileTicketPriorityHigh => 'Hoch';

  @override
  String get mobileTicketPriorityMedium => 'Mittel';

  @override
  String get mobileTicketPriorityLow => 'Niedrig';

  @override
  String get mobileTicketLabels => 'Labels';

  @override
  String get mobileTicketLabelsHint => 'Ein Label pro Zeile';

  @override
  String get mobileTicketLabelsHelp =>
      'Jedes Label in einer eigenen Zeile eingeben.';

  @override
  String mobileTicketWorkspaceProvider(String provider) {
    return 'Erfasst in $provider';
  }

  @override
  String get mobileTicketProviderLocal => 'Control Center';

  @override
  String get mobileTicketUnassigned => 'Nicht zugewiesen';

  @override
  String get mobileTicketAssignedFilter => 'Zugewiesen';

  @override
  String get mobileTicketAgentsLoadFailed =>
      'Agenten konnten nicht geladen werden';

  @override
  String get mobileTicketSearch => 'Tickets suchen';

  @override
  String get mobileTicketSearchHint =>
      'Titel, Schlüssel, Beschreibung, Label oder zugewiesene Person';

  @override
  String get mobileTicketClearSearch => 'Ticketsuche löschen';

  @override
  String get mobileTicketNoMatches => 'Keine passenden Tickets';

  @override
  String get mobileTicketAdjustFilters =>
      'Eine andere Suche versuchen oder die Filter ändern.';

  @override
  String get mobileTicketClearFilters => 'Filter löschen';

  @override
  String get mobileTicketNotFound => 'Ticket nicht gefunden';

  @override
  String get mobileTicketNotFoundDescription =>
      'Dieses Ticket wurde möglicherweise gelöscht oder in einen anderen Arbeitsbereich verschoben.';

  @override
  String get mobileTicketWorkspaceChanged =>
      'Der Arbeitsbereich hat sich geändert. Vor dem Speichern zum aktuellen Arbeitsbereich zurückkehren.';

  @override
  String get mobileTicketOpenLinkedSpace => 'Verknüpften Bereich öffnen';

  @override
  String get mobileTicketReadOnly =>
      'Zum Ändern von Tickets ist die Rolle „Mitglied“ im Arbeitsbereich erforderlich.';

  @override
  String get permissionTitle => 'Berechtigungen';

  @override
  String get permissionWorkspaceFailed =>
      'Arbeitsbereich konnte nicht geladen werden';

  @override
  String get permissionNoWorkspace =>
      'Einen Arbeitsbereich auswählen, um die Berechtigungen einzusehen.';

  @override
  String get permissionLoading => 'Berechtigungen werden geladen…';

  @override
  String get permissionScopeDescription =>
      'Einsehen, wie in diesem Geltungsbereich über einzelne Aktionen entschieden wird. Regeln des Arbeitsbereichs können an Agenten und Bereiche vererbt werden.';

  @override
  String get permissionScope => 'Geltungsbereich der Richtlinie';

  @override
  String get permissionWorkspaceScope => 'Arbeitsbereich';

  @override
  String get permissionAgentScope => 'Agent';

  @override
  String get permissionSpaceScope => 'Bereich';

  @override
  String get permissionAgentContext => 'In diesem Bereich agierender Agent';

  @override
  String get permissionNoAgentContext => 'Kein Agent ausgewählt';

  @override
  String get permissionTargetsFailed =>
      'Ziele des Geltungsbereichs konnten nicht geladen werden';

  @override
  String get permissionNoTargets =>
      'In diesem Geltungsbereich sind keine Ziele verfügbar.';

  @override
  String get permissionRoleFailed =>
      'Rolle im Arbeitsbereich konnte nicht bestätigt werden';

  @override
  String get permissionMemberRequired =>
      'Zum Einsehen der Richtlinienregeln ist die Rolle „Mitglied“ im Arbeitsbereich erforderlich.';

  @override
  String get permissionRulesFailed =>
      'Richtlinienregeln konnten nicht geladen werden';

  @override
  String get permissionAuditAdminOnly =>
      'Der Berechtigungsverlauf ist nur für Administratoren des Arbeitsbereichs verfügbar.';

  @override
  String get permissionAllow => 'Zulassen';

  @override
  String get permissionAsk => 'Zuerst fragen';

  @override
  String get permissionDeny => 'Verweigern';

  @override
  String get permissionFileDelete => 'Dateien löschen';

  @override
  String get permissionFileWriteOutsideWorktree =>
      'Außerhalb des Worktrees schreiben';

  @override
  String get permissionGitCommit => 'Änderungen committen';

  @override
  String get permissionGitPush => 'Commits pushen';

  @override
  String get permissionPrCreate => 'Pull Requests erstellen';

  @override
  String get permissionPrPublish =>
      'Pull Requests aktualisieren oder zusammenführen';

  @override
  String get permissionVendorSyncWrite =>
      'Schreibzugriff bei der Anbietersynchronisierung';

  @override
  String get permissionNetworkEgress => 'Auf das Netzwerk zugreifen';

  @override
  String get permissionSecretAccess => 'Auf Secrets zugreifen';

  @override
  String get permissionPackageInstall => 'Pakete installieren';

  @override
  String get permissionProcessSpawn => 'Prozesse starten';

  @override
  String get permissionWorkspaceMutation => 'Arbeitsbereich ändern';

  @override
  String get permissionEnclosureControl => 'Isolierte Umgebung steuern';

  @override
  String get permissionChangeFailed => 'Regel konnte nicht geändert werden';

  @override
  String get permissionEffectiveDescription =>
      'Effektive Berechtigungen für diesen Geltungsbereich ohne Aktionsargumente. Die folgenden bedingten Freigaben gelten nur für passende Anfragen; die endgültige Entscheidung trifft der Server.';

  @override
  String get permissionSpaceAgentNote =>
      'Kein Agent ausgewählt. Agentenspezifische Regeln werden erst angezeigt, wenn oben ein Agent ausgewählt wird.';

  @override
  String get permissionScopedGrants => 'Regeln für diesen Geltungsbereich';

  @override
  String get permissionModePreset => 'Modus-Voreinstellung';

  @override
  String get permissionBuiltInDefault => 'Standardwert';

  @override
  String get permissionRemembered => 'Dauerfreigabe';

  @override
  String get permissionSource => 'Quelltext';

  @override
  String permissionSetAtThisScope(String source) {
    return '$source · hier festgelegt';
  }

  @override
  String permissionInheritedFrom(String source) {
    return '$source · geerbt';
  }

  @override
  String permissionExpiresAt(String date) {
    return 'Läuft am $date ab';
  }

  @override
  String get permissionSetHere => 'Hier eine Regel festlegen';

  @override
  String get permissionConfirmRevoke => 'Widerruf bestätigen';

  @override
  String get permissionRevokeRule => 'Regel widerrufen';

  @override
  String permissionCommandPrefix(String prefix) {
    return 'Befehlspräfix: $prefix';
  }

  @override
  String get permissionNoExpiry => 'Kein Ablaufdatum';

  @override
  String get permissionExpired => 'Abgelaufen';

  @override
  String get permissionExplicitRule => 'Explizite Regel';

  @override
  String get permissionEnforcementAdvisory =>
      'Hinweismodus: Regeln mit „Zuerst fragen“ werden ohne Rückfrage protokolliert';

  @override
  String get permissionEnforcementSoft =>
      'Weiche Durchsetzung: Außerkraftsetzen erfordert Autorisierung';

  @override
  String get permissionEnforcementHard =>
      'Strikte Durchsetzung: Außerkraftsetzen nicht möglich';

  @override
  String permissionPaths(String paths) {
    return 'Pfade: $paths';
  }

  @override
  String permissionRefs(String refs) {
    return 'Git-Referenzen: $refs';
  }

  @override
  String permissionHosts(String hosts) {
    return 'Hosts: $hosts';
  }

  @override
  String permissionCommands(String commands) {
    return 'Befehle: $commands';
  }

  @override
  String permissionTools(String tools) {
    return 'Tools: $tools';
  }

  @override
  String get permissionNotInEffect =>
      'Ohne Wirkung, solange diese Aktion auf Verweigern steht';

  @override
  String permissionMaxCount(String count) {
    return 'Maximale Anzahl: $count';
  }

  @override
  String permissionMaxCents(String cents) {
    return 'Höchstbetrag in Cent: $cents';
  }

  @override
  String get permissionAuditHeading => 'Autorisierungsverlauf';

  @override
  String get permissionAuditDescription =>
      'Zuletzt vom Server protokollierte Entscheidungen. Nur Administratoren können das Protokoll einsehen oder seine Hash-Kette prüfen.';

  @override
  String permissionOnBehalfOf(String user) {
    return 'im Namen von $user';
  }

  @override
  String get permissionPrompted => 'Menschliche Genehmigung angefordert';

  @override
  String get permissionVerifyChain => 'Protokollkette prüfen';

  @override
  String get permissionVerifyFailed =>
      'Protokollkette konnte nicht geprüft werden';

  @override
  String permissionChainIntact(String count) {
    return 'Kette intakt · $count Einträge geprüft';
  }

  @override
  String permissionChainBroken(String sequence, String reason) {
    return 'Kette bei Eintrag $sequence unterbrochen: $reason';
  }

  @override
  String get permissionAuditEmpty =>
      'Noch keine Autorisierungsentscheidungen protokolliert.';

  @override
  String get permissionAuditFailed =>
      'Autorisierungsverlauf konnte nicht geladen werden';

  @override
  String get mobilePlansLoadFailed => 'Pläne konnten nicht geladen werden';

  @override
  String get mobilePlansEmpty => 'Noch keine Pläne';

  @override
  String get mobilePlansEmptyDescription =>
      'Von Agenten eingereichte Pläne erscheinen hier zur Prüfung.';

  @override
  String get mobilePlanTitle => 'Plan';

  @override
  String get mobilePlanMissing =>
      'Dieser Plan ist in diesem Arbeitsbereich nicht mehr verfügbar.';

  @override
  String mobilePlanStepCount(int count) {
    return '$count Schritte';
  }

  @override
  String get mobilePlanDraft => 'Entwurf';

  @override
  String get mobilePlanProposed => 'Prüfung ausstehend';

  @override
  String get mobilePlanApproved => 'Genehmigt';

  @override
  String get mobilePlanRejected => 'Abgelehnt';

  @override
  String get mobilePlanSuperseded => 'Ersetzt';

  @override
  String get mobilePlanExecuting => 'Läuft';

  @override
  String get mobilePlanSynthesizing => 'Synthese';

  @override
  String get mobilePlanCompleted => 'Completed';

  @override
  String get mobilePlanFailed => 'Fehlgeschlagen';

  @override
  String get mobilePlanCancelled => 'Cancelled';

  @override
  String mobilePlanRevision(String revision) {
    return 'Revision $revision';
  }

  @override
  String get mobilePlanSteps => 'Schritte';

  @override
  String get mobilePlanNoSteps =>
      'Für diesen Plan wurden keine Schritte eingereicht.';

  @override
  String get mobilePlanAssumptions => 'Klarstellungen';

  @override
  String mobilePlanDependsOn(String keys) {
    return 'Abhängig von $keys';
  }

  @override
  String mobilePlanStepCost(String cost) {
    return 'Voraussichtlich bis zu $cost';
  }

  @override
  String get mobilePlanSelect => 'Auswählen';

  @override
  String get mobilePlanSelected => 'Ausgewählt';

  @override
  String get mobilePlanEstimate => 'Kosten schätzen';

  @override
  String get mobilePlanEstimateRequired =>
      'Vor der Genehmigung der Ausführung müssen die Plankosten geschätzt werden.';

  @override
  String mobilePlanEstimatedCost(String low, String high) {
    return 'Geschätzte Kosten: $low–$high';
  }

  @override
  String get mobilePlanCostUnknown => 'nicht verfügbar';

  @override
  String get mobilePlanNoHardCap => 'keine feste Obergrenze';

  @override
  String get mobilePlanExceedsBudget =>
      'Die Schätzung überschreitet das festgelegte Budget. Vor der Genehmigung prüfen.';

  @override
  String get mobilePlanPartialEstimate =>
      'Diese Schätzung gilt für den gesamten Plan. Ausgewählte Schritte können weniger kosten.';

  @override
  String get mobilePlanConfirmAll => 'Gesamten Plan starten?';

  @override
  String get mobilePlanConfirmSelected => 'Ausgewählte Schritte starten?';

  @override
  String mobilePlanExecutionConfirmation(String cost, String cap) {
    return 'Die Genehmigung startet die Ausführung und kann Kosten verursachen. Obere Kostenschätzung: $cost. Budgetobergrenze: $cap.';
  }

  @override
  String get mobilePlanApproveAll => 'Alle genehmigen und ausführen';

  @override
  String get mobilePlanApproveSelected =>
      'Ausgewählte genehmigen und ausführen';

  @override
  String get mobilePlanWiden => 'Weitere Schritte genehmigen';

  @override
  String mobilePlanWidenConfirm(String count, String cap) {
    return '$count weitere Schritte zur Ausführung freigeben? Dabei können Kosten entstehen. Bisherige Kostenobergrenze für die Ausführung: $cap.';
  }

  @override
  String get mobilePlanChanged =>
      'Der Plan wurde während der Prüfung geändert. Die neueste Revision erneut öffnen und die Kosten neu schätzen.';

  @override
  String get mobilePlanReject => 'Plan ablehnen';

  @override
  String get mobilePlanRejectConfirm =>
      'Diesen Plan ablehnen? Er wird dann nicht ausgeführt.';

  @override
  String get mobilePlanStop => 'Ausführung stoppen';

  @override
  String get mobilePlanStopConfirm =>
      'Die Ausführung dieses Plans stoppen? Bereits abgeschlossene Arbeiten werden nicht rückgängig gemacht.';

  @override
  String mobilePlanRunId(String runId) {
    return 'Ausführungslauf: $runId';
  }

  @override
  String get mobilePlanExecutionPending =>
      'Genehmigung angenommen. Warten auf den Ausführungseintrag…';

  @override
  String mobilePlanProgress(String completed, String total) {
    return '$completed von $total Ausführungsschritten abgeschlossen';
  }

  @override
  String get mobilePlanOpenConversation => 'Konversation öffnen';

  @override
  String get mobileGoalsTitle => 'Überwachte Ziele';

  @override
  String get mobileGoalsLoadFailed =>
      'Überwachte Ziele konnten nicht geladen werden';

  @override
  String get mobileGoalsEmpty => 'Noch keine überwachten Ziele';

  @override
  String get mobileGoalsEmptyDescription =>
      'Ein überwachtes Ziel in einem Bereich starten oder /goal in einer Konversation senden.';

  @override
  String get mobileGoalMissing =>
      'Dieses Ziel ist in diesem Arbeitsbereich nicht mehr verfügbar.';

  @override
  String get mobileGoalActive => 'Aktiv';

  @override
  String get mobileGoalPaused => 'Pausiert';

  @override
  String get mobileGoalCompleted => 'Completed';

  @override
  String get mobileGoalFailed => 'Fehlgeschlagen';

  @override
  String get mobileGoalCancelled => 'Cancelled';

  @override
  String get mobileGoalBudgetExhausted => 'Budget erreicht';

  @override
  String mobileGoalFailures(String count) {
    return 'Fehlgeschlagene Läufe in Folge: $count';
  }

  @override
  String get mobileGoalFailedDescription =>
      'Die Überwachung wurde nach wiederholt fehlgeschlagenen Läufen gestoppt. Details sind in der Konversation zu finden.';

  @override
  String get mobileGoalPause => 'Ziel pausieren';

  @override
  String get mobileGoalResume => 'Ziel fortsetzen';

  @override
  String get mobileGoalStop => 'Ziel abbrechen';

  @override
  String get mobileGoalStopConfirm =>
      'Dieses überwachte Ziel endgültig abbrechen? Es kann danach nicht fortgesetzt werden.';

  @override
  String get mobileGoalRaiseBudget => 'Budget erhöhen und fortsetzen';

  @override
  String mobileGoalRaiseTo(String amount) {
    return 'Budget auf $amount erhöhen und fortsetzen';
  }

  @override
  String mobileGoalRaiseConfirm(String oldCap, String newCap) {
    return 'Die Kostenobergrenze dieses Ziels von $oldCap auf $newCap erhöhen und weitere Ausgaben zulassen?';
  }

  @override
  String get mobileGoalOpenConversation => 'Konversation zum Ziel öffnen';

  @override
  String get mobileGoalCreate => 'Überwachtes Ziel starten';

  @override
  String get mobileGoalChooseSpace => 'Im Bereich ausführen';

  @override
  String get mobileGoalNoSpaces =>
      'Vor dem Start eines Ziels einen Bereich erstellen.';

  @override
  String get mobileGoalChooseAgent => 'Mit Agenten ausführen';

  @override
  String get mobileGoalNoAgents =>
      'Vor dem Start eines Ziels einen aktiven Agenten hinzufügen.';

  @override
  String mobileGoalSelectedAgent(String name) {
    return '$name ausgewählt';
  }

  @override
  String get mobileGoalObjectiveHint =>
      'Welches Ergebnis soll der Agent anstreben?';

  @override
  String get mobileGoalBudgetUsd => 'Kostenobergrenze (USD)';

  @override
  String get mobileGoalCreateInvalid =>
      'Bereich und Agenten auswählen, eine Zielvorgabe eingeben und eine Kostenobergrenze über 0 USD festlegen.';

  @override
  String mobileGoalCreateConfirm(String cap) {
    return 'Überwachtes Ziel mit maximalen Kosten von $cap starten? Der Agent kann sofort beginnen.';
  }

  @override
  String get mobileGoalUnavailable =>
      'Die Serververbindung ist noch nicht bereit. Nach Wiederherstellung der Verbindung erneut versuchen.';

  @override
  String get mobileGoalConversationMissing =>
      'Die ausgewählte Unterhaltung ist in diesem Arbeitsbereich nicht mehr verfügbar.';

  @override
  String get mobileGoalCreateSent =>
      'Ziel gestartet. Der Supervisor-Status erscheint in dieser Liste.';

  @override
  String get mobileGoalStartRefused =>
      'Kein Ziellauf gestartet. Die Begründung des Supervisors steht in der Unterhaltung.';

  @override
  String mobileGoalSelectedSpace(String name) {
    return '$name ausgewählt';
  }

  @override
  String get requestUnavailable =>
      'Diese Anfrage ist im aktiven Arbeitsbereich nicht mehr verfügbar.';

  @override
  String get requestAlreadyResolved => 'Diese Anfrage wurde bereits erledigt.';

  @override
  String get inboxCredentialsBlocked => 'Zugangsdaten blockieren Läufe';

  @override
  String get inboxSyncFailures => 'Fehlgeschlagene Anbieter-Synchronisierungen';

  @override
  String get inboxConfigureCredentials => 'Zugangsdaten konfigurieren';

  @override
  String get openTicket => 'Ticket öffnen';

  @override
  String get activityTitle => 'Aktivität';

  @override
  String get activityClearAll => 'Aktivität löschen';

  @override
  String get activityClearConfirm =>
      'Alle bisherigen Aktivitäten werden auf allen Geräten ausgeblendet. Neue Aktivitäten erscheinen weiterhin.';

  @override
  String get activityMarkAllRead => 'Alle als gelesen markieren';

  @override
  String get activityMarkAllConfirm =>
      'Alle Aktivitäten in diesem Arbeitsbereich auf allen Geräten als gelesen markieren?';

  @override
  String get activityMarkRead => 'Als gelesen markieren';

  @override
  String get activityMarkUnread => 'Als ungelesen markieren';

  @override
  String get activityDismiss => 'Ablehnen';

  @override
  String get activityResolved => 'Gelöst';

  @override
  String get activityOpen => 'Offen';

  @override
  String get activityEmpty => 'Noch keine Aktivität';

  @override
  String get activityLoadFailed => 'Aktivität konnte nicht geladen werden';

  @override
  String get activityAgentWaiting => 'Agent benötigt eine Eingabe';

  @override
  String get activityAgentBlocked => 'Agentenaktion blockiert';

  @override
  String get activityMessage => 'Neue Nachricht';

  @override
  String get activityPullRequest => 'Pull Request aktualisiert';

  @override
  String get activityRig => 'Isolierte Umgebung aktualisiert';

  @override
  String get activityEvent => 'Aktualisieren';

  @override
  String get activityPrReady => 'Pull Request zum Zusammenführen bereit';

  @override
  String get activityPrBlocked => 'Zusammenführen des Pull Requests blockiert';

  @override
  String get activityPrApproved => 'Pull Request freigegeben';

  @override
  String get activityPrChanges => 'Änderungen angefordert';

  @override
  String get activityPrChecksFailed =>
      'Prüfungen des Pull Requests fehlgeschlagen';

  @override
  String get activityPrChecksRecovered =>
      'Prüfungen des Pull Requests wieder erfolgreich';

  @override
  String get activityPrComment => 'Kommentar zu einem Pull Request';

  @override
  String get activityPrPublished => 'Pull Request veröffentlicht';

  @override
  String get activityPrMerged => 'Pull request merged';

  @override
  String get activityPrMentioned => 'Erwähnung in einem Pull Request';

  @override
  String get activityPrReviewRequested => 'Review angefragt';

  @override
  String get activityPrReviewStale => 'Review muss aktualisiert werden';

  @override
  String get activityTicketAssigned => 'Ticket zugewiesen';

  @override
  String get activityTicketChanged => 'Ticket-Status geändert';

  @override
  String get activityMeetingSoon => 'Meeting beginnt bald';

  @override
  String get activityCalendarExpired => 'Kalenderverbindung abgelaufen';

  @override
  String get activityRigControl => 'Steuerung der isolierten Umgebung geändert';

  @override
  String get activityRigClosed => 'Isolierte Umgebung gestoppt';

  @override
  String get mobileSpacesSearch => 'Bereiche suchen';

  @override
  String get mobileSpacesArchived => 'Archiviert';

  @override
  String get mobileSpacesActive => 'Aktiv';

  @override
  String get mobileSpacesNew => 'Neuer Bereich';

  @override
  String get mobileSpacesManage => 'Bereich verwalten';

  @override
  String get mobileSpacesName => 'Name des Raums';

  @override
  String get mobileSpacesAgents => 'Agenten';

  @override
  String get mobileSpacesMembers => 'Personen';

  @override
  String get mobileSpacesRepos => 'Repositorys';

  @override
  String get mobileSpacesAllRepos => 'Alle verknüpften Repositorys';

  @override
  String get mobileSpacesNoRepos => 'Keine Repositorys';

  @override
  String get mobileSpacesBaseBranch => 'Basisbranch (optional)';

  @override
  String get mobileSpacesDefaultBranch => 'Standardbranch';

  @override
  String get mobileSpacesMode => 'Modus';

  @override
  String get mobileSpacesModeChat => 'Chat';

  @override
  String get mobileSpacesModeReview => 'Review (schreibgeschützt)';

  @override
  String get mobileSpacesModePlan => 'Plan (schreibgeschützt)';

  @override
  String get mobileSpacesModeOrchestrate => 'Orchestrieren';

  @override
  String get mobileSpacesAutonomy => 'Abweichende Autonomieeinstellung';

  @override
  String get mobileSpacesAutonomyInherited => 'Geerbt';

  @override
  String get mobileSpacesAutonomyPropose => 'Nur vorschlagen';

  @override
  String get mobileSpacesAutonomyApproval => 'Mit Genehmigung handeln';

  @override
  String get mobileSpacesAutonomyFreely => 'Frei handeln';

  @override
  String get mobileSpacesAutonomyNotice =>
      'Eine abweichende Einstellung kann Rückfragen oder Verbote der Aktionsrichtlinie nicht umgehen. Nur Arbeitsbereichsadministratoren können sie ändern.';

  @override
  String get mobileSpacesArchive => 'Bereich archivieren';

  @override
  String get mobileSpacesReopen => 'Bereich erneut öffnen';

  @override
  String get mobileSpacesSave => 'Änderungen speichern';

  @override
  String get mobileSpacesCreate => 'Bereich erstellen';

  @override
  String get mobileSpacesOperationFailed =>
      'Bereich konnte nicht aktualisiert werden';

  @override
  String get mobileSpacesMissing =>
      'Bereich in diesem Arbeitsbereich nicht gefunden';

  @override
  String get mobileSpacesEmptyName => 'Bereichsnamen eingeben';

  @override
  String get mobileSpacesNoMatches => 'Keine passenden Bereiche';

  @override
  String get mobileSpacesUnread => 'Ungelesene Agentenantwort';

  @override
  String get mobileSpacesNeedsInput => 'Eingabe erforderlich';

  @override
  String get mobileSpacesRunning => 'Agent läuft';

  @override
  String get mobileSpacesNoAgents => 'Keine Agenten in diesem Arbeitsbereich';

  @override
  String get mobileSpacesNoMembers =>
      'Keine weiteren Mitglieder im Arbeitsbereich';

  @override
  String get mobileSpacesRepoError =>
      'Repositorys konnten nicht geladen werden';

  @override
  String get mobileSpacesRetry => 'Erneut versuchen';

  @override
  String get mobileSpacesBranchUnavailable =>
      'Beim Erstellen eines Bereichs einen Basisbranch auswählen oder eingeben. Der Basisbranch bestehender Bereiche kann nicht geändert werden.';

  @override
  String get mobileSpacesArchivedEmpty => 'Keine archivierten Bereiche';

  @override
  String get mobileSpacesAllRepoWarning =>
      'Neu verknüpfte Repositorys des Arbeitsbereichs werden ebenfalls in diesen Bereich aufgenommen.';

  @override
  String get mobileSpacesCreatedRetry =>
      'Bereich erstellt. Das Hinzufügen von Personen erneut versuchen oder die Bereichsverwaltung öffnen.';

  @override
  String get progressTitle => 'Fortschritt';

  @override
  String get progressConversation => 'Konversation';

  @override
  String get progressLoadFailed => 'Fortschritt konnte nicht geladen werden';

  @override
  String get progressUnavailable => 'Konversation nicht verfügbar';

  @override
  String get progressUnavailableDescription =>
      'Diese Konversation gehört nicht zum aktiven Arbeitsbereich und Bereich. Zum zugehörigen Bereich zurückkehren, um fortzufahren.';

  @override
  String get progressSaveFailed =>
      'Fortschritt konnte nicht aktualisiert werden';

  @override
  String get progressGoal => 'Ziel';

  @override
  String get progressNoGoal => 'Kein Arbeitsziel festgelegt';

  @override
  String get progressSetGoal => 'Ziel setzen';

  @override
  String get progressEditGoal => 'Ziel bearbeiten';

  @override
  String get progressClearGoal => 'Ziel löschen';

  @override
  String get progressGoalRequired => 'Vor dem Speichern ein Ziel eingeben.';

  @override
  String get progressTodos => 'Aufgaben';

  @override
  String get transcriptToolTodos => 'Aufgaben';

  @override
  String get transcriptToolSearchMemory => 'Gedächtnis durchsuchen';

  @override
  String get transcriptToolRenderMedia => 'Medien rendern';

  @override
  String get progressNoTodos => 'Noch keine Aufgaben';

  @override
  String get progressNewTodo => 'Neue Aufgabe';

  @override
  String get progressAddTodo => 'Aufgabe hinzufügen';

  @override
  String get progressEditTodo => 'Aufgabe bearbeiten';

  @override
  String get progressTodoRequired => 'Vor dem Speichern eine Aufgabe eingeben.';

  @override
  String get progressTodoNoLongerExists =>
      'Diese Aufgabe wurde entfernt. Die Liste neu laden und erneut versuchen.';

  @override
  String get progressWorkspaceChanged =>
      'Der aktive Arbeitsbereich hat sich geändert. Zu dieser Konversation zurückkehren und erneut versuchen.';

  @override
  String progressRemoveTodo(String name) {
    return 'Aufgabe $name entfernen';
  }

  @override
  String get progressPending => 'Pending';

  @override
  String get progressInProgress => 'In Arbeit';

  @override
  String get progressCompleted => 'Completed';

  @override
  String get progressMoveUp => 'Aufgabe nach oben verschieben';

  @override
  String get progressMoveDown => 'Aufgabe nach unten verschieben';

  @override
  String get progressRunTree => 'Agentenläufe';

  @override
  String get progressNoRuns => 'Noch keine Läufe in dieser Konversation';

  @override
  String get progressRunning => 'Läuft';

  @override
  String get progressFailed => 'Fehlgeschlagen';

  @override
  String get progressUnknown => 'Unbekannt';

  @override
  String get progressHealthy => 'Aktiv';

  @override
  String get progressBlocked => 'Blockiert';

  @override
  String get progressLooping => 'In einer Schleife';

  @override
  String get progressStalled => 'Festgefahren';

  @override
  String get progressDead => 'Unerwartet gestoppt';

  @override
  String get progressQuiet => 'Noch keine Ausgabe';

  @override
  String get progressCostReported => 'Vom Anbieter gemeldete Kosten';

  @override
  String get progressCostNotional =>
      'Rechnerischer Abo-Listenpreis; keine Rechnung';

  @override
  String get progressCostMixed => 'Gemischte Kostenquellen';

  @override
  String get progressCostEstimated => 'Geschätzte Kosten';

  @override
  String progressDurationSeconds(String seconds) {
    return '$seconds s';
  }

  @override
  String progressRunDetails(String model, String duration, String cost) {
    return 'Modell: $model · Dauer: $duration · Kosten: $cost';
  }

  @override
  String progressStartedAt(String time) {
    return 'Gestartet $time';
  }

  @override
  String progressLiveness(String state) {
    return 'Status: $state';
  }

  @override
  String progressRunTokens(String input, String output) {
    return 'Eingabe: $input · Ausgabe: $output Tokens';
  }

  @override
  String get progressOutputPreviewLimited =>
      'Nur die ersten 6.000 Zeichen der strukturierten Ausgabe werden angezeigt.';

  @override
  String progressRetryOf(String runId) {
    return 'Wiederholung von Lauf $runId';
  }

  @override
  String get progressContext => 'Kontext und Limits';

  @override
  String get progressNoAgent => 'Kein Agent zur Prüfung vorhanden';

  @override
  String progressContextReading(String used, String window) {
    return '$used / $window Tokens';
  }

  @override
  String get progressMeasured =>
      'Vom Anbieter gemeldeter Kontext beim letzten Aufruf';

  @override
  String get progressEstimated =>
      'Anhand der gespeicherten Konversation und des dauerhaften Kontexts geschätzt';

  @override
  String get progressContextUnknown => 'Kontextnutzung noch nicht gemeldet';

  @override
  String progressContextPercent(String percent) {
    return '$percent% des Kontextfensters';
  }

  @override
  String progressMonthlyBudget(String amount) {
    return 'Festgelegtes monatliches Agentenlimit: $amount';
  }

  @override
  String progressConversationTokens(String tokens) {
    return 'Gespeicherte laufende Konversation: geschätzt $tokens Tokens';
  }

  @override
  String progressInspectionFor(String agent, String model) {
    return 'Dauerhafter Kontext für $agent · $model';
  }

  @override
  String get progressContextSystem => 'System-Prompt';

  @override
  String get progressContextRules => 'Regeln';

  @override
  String get progressContextSkills => 'Fähigkeiten';

  @override
  String get progressContextTools => 'Tool-Definitionen';

  @override
  String get progressContextMcp => 'MCP-Tools';

  @override
  String get progressContextDeferred => 'Zurückgestellte Tools';

  @override
  String get progressContextSubagents => 'Subagenten';

  @override
  String get progressContextRunner => 'Externe Ausführungsumgebung';

  @override
  String get progressContextMemory => 'Speicher';

  @override
  String get progressContextHistory => 'Konversationsverlauf';

  @override
  String progressContextSegment(String label, String tokens) {
    return '$label · $tokens Tokens';
  }

  @override
  String progressContextPart(String title, String tokens) {
    return '$title · $tokens Tokens';
  }

  @override
  String get progressOutputs => 'Letzte Ausgaben';

  @override
  String get progressNoOutputs => 'Keine aktuellen Agentenausgaben';

  @override
  String get progressStructuredOutputsAbove =>
      'Strukturierte Laufausgaben werden oben unter den Agentenläufen angezeigt.';

  @override
  String get progressRecentOutputsOnly =>
      'Nur die neuesten Nachrichten werden angezeigt. Ältere Inhalte sind in der Konversation verfügbar.';

  @override
  String get progressPlan => 'Plan';

  @override
  String get progressArtifact => 'Artefakt';

  @override
  String get progressResult => 'Ergebnis';

  @override
  String get progressHideArtifact => 'Artefakt ausblenden';

  @override
  String get progressReadArtifact => 'Artefakt lesen';

  @override
  String get progressArtifactUnavailable => 'Artefakt nicht mehr verfügbar';

  @override
  String get progressArtifactPreviewLimited =>
      'Eine eingeschränkte Vorschau dieses Artefakts wird angezeigt.';

  @override
  String get progressDiagramSource => 'Diagrammquelltext';

  @override
  String progressOpenAttachment(String name) {
    return '$name öffnen';
  }

  @override
  String get progressOpenPlan => 'Plan öffnen';

  @override
  String progressOpenDiff(String label) {
    return 'Geänderte Dateien prüfen: $label';
  }

  @override
  String get progressViewMessage => 'Nachricht anzeigen';

  @override
  String get pushTitle => 'Hintergrundbenachrichtigungen';

  @override
  String get pushIntro =>
      'Vertrauliche Benachrichtigungen erhalten, wenn etwas Aufmerksamkeit erfordert – auch bei geschlossener App. Details bleiben in der verschlüsselten Verbindung.';

  @override
  String get pushLoading => 'Benachrichtigungseinstellungen werden geprüft…';

  @override
  String get pushError =>
      'Benachrichtigungen konnten nicht aktualisiert werden. Verbindung prüfen und erneut versuchen.';

  @override
  String get pushEnable => 'Benachrichtigungen aktivieren';

  @override
  String get pushDisable => 'Benachrichtigungen deaktivieren';

  @override
  String get pushQuiet => 'Benachrichtigungen auf diesem Gerät pausieren';

  @override
  String get pushCategories => 'Benachrichtigungen zu';

  @override
  String get pushCategoryAgents => 'Agenten';

  @override
  String get pushCategoryMessages => 'Nachrichten';

  @override
  String get pushCategoryPullRequests => 'Pull Requests';

  @override
  String get pushCategoryTickets => 'Tickets';

  @override
  String get pushCategoryCalendar => 'Kalender';

  @override
  String get pushCategoryMachines => 'Computer';

  @override
  String get pushSecureOrigin => 'Benachrichtigungen erfordern HTTPS.';

  @override
  String get pushInstallIos =>
      'Auf dem iPhone oder iPad diese App zum Home-Bildschirm hinzufügen und von dort öffnen, um Benachrichtigungen zu aktivieren.';

  @override
  String get pushUnsupported =>
      'Dieser Browser unterstützt keine Hintergrundbenachrichtigungen.';

  @override
  String get pushDenied =>
      'Der Browser meldet, dass Benachrichtigungen blockiert sind. Berechtigung dieser Website und Benachrichtigungseinstellungen von Browser oder Gerät prüfen, dann aktualisieren.';

  @override
  String get pushOsHint =>
      'Dein Browser braucht außerdem in den Systemeinstellungen deines Geräts die Erlaubnis, Benachrichtigungen anzuzeigen.';

  @override
  String get pushServiceUnavailable =>
      'Der Push-Dienst des Browsers hat das Abonnement abgelehnt. Manche Browser, etwa Brave, schalten ihn standardmäßig aus: In den Datenschutzeinstellungen des Browsers nach einer Option für Push-Nachrichten suchen, dann erneut versuchen.';

  @override
  String get pushWorkerUnavailable =>
      'Der Benachrichtigungsdienst konnte in diesem Browser nicht starten. Seite neu laden und erneut versuchen.';

  @override
  String get pushResubscribe => 'Benachrichtigungen neu verbinden';

  @override
  String get pushStatusEnabled =>
      'Benachrichtigungen sind auf diesem Gerät aktiviert.';

  @override
  String get pushStatusDisabled =>
      'Benachrichtigungen sind auf diesem Gerät deaktiviert.';

  @override
  String get credentialsTitle => 'Verbindungen und Zugangsdaten';

  @override
  String get credentialsIntro =>
      'Verbinden Sie die Konten, die Ihre Läufe und Integrationen verwenden. Geheimnisse werden auf Ihrem Server gespeichert, nicht auf diesem Smartphone.';

  @override
  String get credentialsModelProviders => 'Modellanbieter';

  @override
  String get credentialsOwnerOnly =>
      'Nur der Serverbesitzer kann Zugangsdaten für Modellanbieter hinzufügen oder entfernen und die Anmeldung durchführen. Diese Schlüssel werden arbeitsbereichsübergreifend verwendet.';

  @override
  String get credentialsContactOwner =>
      'Bitten Sie den Serverbesitzer, den Anbieter zu verbinden, den der blockierte Lauf benötigt.';

  @override
  String get credentialsClaudeCode => 'Claude Code';

  @override
  String get credentialsClaudeHostOnly =>
      'Die Anmeldung bei Claude Code erfolgt über die CLI auf dem Host. Bitten Sie den Serverbesitzer, die Anmeldung im Host-Terminal abzuschließen oder zu erneuern. Auf diesem Smartphone ist das nicht möglich.';

  @override
  String get credentialsYourForgeAccounts => 'Ihre Konten bei Code-Plattformen';

  @override
  String get credentialsYourTicketingAccount => 'Ihr Ticket-System-Konto';

  @override
  String get credentialsLocalTicketsNoLogin =>
      'Für lokale Tickets ist keine Anmeldung nötig. Verbinden Sie Linear hier, falls Ihr Arbeitsbereich Linear verwendet.';

  @override
  String get credentialsMembershipRequired =>
      'Um Ihre Zugangsdaten für Code-Plattformen oder Tickets zu verwalten, müssen Sie Mitglied eines Arbeitsbereichs sein. Bitten Sie einen Administrator um Zugriff.';

  @override
  String get credentialsSwitchWorkspace =>
      'Dieser Link führt zu einem anderen Arbeitsbereich. Wechseln Sie dorthin, bevor Sie Zugangsdaten ändern.';

  @override
  String get credentialsReturnToInbox =>
      'Kehren Sie zum Posteingang zurück, um einen blockierten Lauf erneut zu versuchen, sobald die Zugangsdaten verbunden sind. Der Host prüft geparkte Läufe auch automatisch.';

  @override
  String get credentialsLoadFailed =>
      'Verbindungen konnten nicht geladen werden. Prüfen Sie die Serververbindung und versuchen Sie es erneut.';

  @override
  String get credentialsOperationFailed =>
      'Diese Verbindung konnte nicht geändert werden. Prüfen Sie die Serververbindung, Ihre Zugriffsrechte und die Zugangsdaten und versuchen Sie es erneut.';

  @override
  String get credentialsConnected => 'Verbunden';

  @override
  String get credentialsNotConnected => 'Nicht verbunden';

  @override
  String credentialsSignedInAs(String username) {
    return 'Angemeldet als $username';
  }

  @override
  String get credentialsAccount => 'Verbundenes Konto';

  @override
  String get credentialsStoredKey => 'Gespeicherter Schlüssel';

  @override
  String get credentialsActive => 'Aktiv';

  @override
  String get credentialsRemove => 'Entfernen';

  @override
  String get credentialsRemoveConfirm =>
      'Gespeicherte Zugangsdaten entfernen? Eventuell müssen Sie sich erneut anmelden.';

  @override
  String get credentialsApiKey => 'API-Schlüssel';

  @override
  String get credentialsApiKeyHint => 'API-Schlüssel eines Anbieters einfügen';

  @override
  String get credentialsBrowserLogin => 'Im Browser anmelden';

  @override
  String get credentialsSignInAgain => 'Erneut anmelden';

  @override
  String get credentialsWaitingForLogin =>
      'Warten auf die Autorisierung im Browser…';

  @override
  String get credentialsConnectCodePrompt => 'Bestätigungscode';

  @override
  String get credentialsConnectCodeMalformed =>
      'Das sieht nicht nach einem Anmeldecode aus. Codes bestehen aus 8 Buchstaben und Ziffern.';

  @override
  String get credentialsSignInInvalidCode =>
      'Dieser Code passt nicht zu dieser Anmeldung. Prüfen Sie ihn und versuchen Sie es erneut.';

  @override
  String get credentialsSignInTooManyCodes =>
      'Zu viele falsche Codes. Starten Sie die Anmeldung neu.';

  @override
  String get credentialsSignInRetryLater =>
      'Der Anmeldedienst antwortet gerade nicht. Warten Sie eine Minute und versuchen Sie es dann erneut.';

  @override
  String get credentialsSignInRefused =>
      'Die Anmeldung wurde abgelehnt. Starten Sie sie neu und genehmigen Sie alle angeforderten Berechtigungen.';

  @override
  String get credentialsSignInNotSaved =>
      'Die Anmeldung hat funktioniert, aber der Server konnte sie nicht speichern. Versuchen Sie es erneut.';

  @override
  String credentialsSignInUnavailable(String provider) {
    return 'Die Anmeldung bei $provider ist auf diesem Server noch nicht eingerichtet.';
  }

  @override
  String get credentialsSignInPhoneUnreachable =>
      'Die Anmelde-Rückrufadresse dieses Servers ist vom Smartphone aus nicht sicher erreichbar. Melden Sie sich in der Desktop-App an oder bitten Sie den Serverbesitzer, eine öffentliche HTTPS-Adresse einzurichten.';

  @override
  String get credentialsLoginTimedOut =>
      'Die Anmeldung ist abgelaufen. Starten Sie einen neuen Anmeldeversuch.';

  @override
  String get credentialsCopyCode => 'Code kopieren';

  @override
  String get credentialsDeviceCodeHint =>
      'Bestätigen Sie diesen Code auf der Seite des Anbieters. Lassen Sie diesen Bildschirm geöffnet, während der Server die Anmeldung abschließt.';

  @override
  String get credentialsPasteRedirect =>
      'Autorisierungscode oder Weiterleitungs-URL';

  @override
  String get credentialsPasteRedirectHint =>
      'Code oder vollständige Weiterleitungs-URL des Anbieters einfügen';

  @override
  String get credentialsCompleteLogin => 'Anmeldung abschließen';

  @override
  String get credentialsUpdateToken => 'Token aktualisieren';

  @override
  String get credentialsAddToken => 'Token hinzufügen';

  @override
  String get credentialsPersonalToken => 'Persönliches Zugriffstoken';

  @override
  String get credentialsPersonalTokenHint =>
      'Persönliches Zugriffstoken einfügen';

  @override
  String get credentialsStopWatching => 'Beobachtung beenden';

  @override
  String get transcriptClaudeSignInExpiredTitle =>
      'Claude-Code-Anmeldung abgelaufen';

  @override
  String get transcriptClaudeSignInExpiredBody =>
      'Der Lauf wurde beendet, weil sich sein Konto nicht mehr authentifiziert. Melde dich erneut an und wiederhole dann den Zug.';

  @override
  String get transcriptSignInExpiredTitle => 'Anbieter-Anmeldung abgelaufen';

  @override
  String get transcriptSignInExpiredBody =>
      'Der Lauf wurde beendet, weil die Zugangsdaten seines Anbieters nicht mehr funktionieren. Verbinde ihn unter Einstellungen → Anbieter neu und wiederhole dann den Zug.';

  @override
  String get permissionHostExecution => 'Befehle auf dem Host ausführen';

  @override
  String credentialsSignInLapsed(String provider) {
    return 'Deine Anmeldung bei $provider ist abgelaufen. Melde dich erneut an.';
  }

  @override
  String get credentialsSignInPaused =>
      'Pausiert: Der Anmeldedienst dieses Arbeitsbereichs hat sich geändert. Sie funktioniert wieder, sobald der Dienst zurück ist.';

  @override
  String credentialsProviderUnreachable(String provider) {
    return '$provider ist gerade nicht erreichbar. Neuer Versuch läuft.';
  }

  @override
  String get credentialsScopeWorkspace => 'Nur dieser Arbeitsbereich';

  @override
  String get credentialsScopeAllWorkspaces => 'Alle Arbeitsbereiche';

  @override
  String get credentialsRemoveConfirmWorkspace =>
      'Deine gespeicherten Zugangsdaten aus diesem Arbeitsbereich entfernen? Andere Arbeitsbereiche behalten ihre.';

  @override
  String get credentialsRemoveConfirmAllWorkspaces =>
      'Deine gespeicherten Zugangsdaten aus jedem Arbeitsbereich entfernen, der sie teilt?';

  @override
  String get credentialsSignInServerRestarted =>
      'Der Server wurde neu gestartet. Starte die Anmeldung erneut.';

  @override
  String repoAccessInstallApp(String owner, String names) {
    return 'Installiere die GitHub App auf $owner, damit die Automatisierung $names erreicht. Tippe, um GitHub zu öffnen.';
  }

  @override
  String repoAccessAskAdminInstall(String owner, String names) {
    return 'Die GitHub App ist auf $owner nicht installiert, daher erreicht die Automatisierung $names nicht. Bitte einen Admin des Arbeitsbereichs, sie zu installieren.';
  }

  @override
  String repoAccessAddToApp(String names) {
    return 'Füge $names zu den Repositorys der GitHub App hinzu. Tippe, um GitHub zu öffnen.';
  }

  @override
  String repoAccessAskAdminAdd(String names) {
    return 'Die GitHub App sieht $names noch nicht. Bitte einen Admin des Arbeitsbereichs, sie zu ihren Repositorys hinzuzufügen.';
  }

  @override
  String repoAccessSuspended(String names) {
    return 'GitHub App-Installation ausgesetzt. Die Automatisierung für $names ist pausiert, bis ein Owner des Kontos die Installation auf GitHub fortsetzt.';
  }

  @override
  String repoAccessOwnerCannotSee(String names) {
    return 'Die für die Automatisierung dieses Arbeitsbereichs verantwortliche Person sieht $names nicht mehr, daher läuft dort nichts in ihrem Namen.';
  }

  @override
  String repoAccessOwnerNotSignedIn(String names) {
    return 'Die für die Automatisierung dieses Arbeitsbereichs verantwortliche Person ist bei der Forge nicht angemeldet, daher wartet die Automatisierung für $names, bis sie sich anmeldet.';
  }

  @override
  String repoAccessRetrying(String names) {
    return 'Zugriff auf $names konnte nicht geprüft werden. Neuer Versuch läuft.';
  }

  @override
  String hiddenReposSignIn(int count, String forge) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other:
          'Melde dich bei $forge an, um Pull Requests aus $count weiteren Repositorys zu sehen',
      one:
          'Melde dich bei $forge an, um Pull Requests aus 1 weiteren Repository zu sehen',
    );
    return '$_temp0';
  }

  @override
  String hiddenReposNoForgeAccess(int count, String forge) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other:
          '$count Repositorys sind ausgeblendet, weil dein $forge-Konto sie nicht sieht',
      one:
          '1 Repository ist ausgeblendet, weil dein $forge-Konto es nicht sieht',
    );
    return '$_temp0';
  }

  @override
  String hiddenReposNoGrant(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other:
          '$count Repositorys sind ausgeblendet, weil du in diesem Arbeitsbereich keinen Zugriff darauf hast',
      one:
          '1 Repository ist ausgeblendet, weil du in diesem Arbeitsbereich keinen Zugriff darauf hast',
    );
    return '$_temp0';
  }

  @override
  String hiddenReposChecking(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Dein Zugriff auf $count weitere Repositorys wird geprüft…',
      one: 'Dein Zugriff auf 1 weiteres Repository wird geprüft…',
    );
    return '$_temp0';
  }

  @override
  String get credentialsAtlassianEmail => 'E-Mail des Atlassian-Kontos';

  @override
  String get credentialsAtlassianEmailInvalid =>
      'Gib die E-Mail-Adresse deines Atlassian-Kontos ein.';

  @override
  String get credentialsBitbucketApiToken => 'API-Token';

  @override
  String repoAccessAutomationTokenMissing(String names) {
    return 'Kein Automatisierungstoken kann $names lesen, daher ist die Hintergrundarbeit dort pausiert. Ein Admin kann eines unter Einstellungen → Repositorys hinzufügen.';
  }

  @override
  String get credentialsSignInConfirmInBrowser =>
      'Bestätige im Browser und gib dann den Code ein, den er anzeigt, in das Feld unten.';

  @override
  String get credentialsSignInAccountAlreadyBound =>
      'Dieses Konto ist bereits mit einer anderen Person auf diesem Server verbunden. Melde dich mit einem anderen Konto an.';

  @override
  String credentialsTokenUnreachable(String provider) {
    return '$provider konnte nicht erreicht werden, um dieses Token zu prüfen. Versuche es gleich noch einmal.';
  }

  @override
  String credentialsTokenRejected(String provider) {
    return '$provider akzeptiert dieses Token nicht. Prüfe, ob du alles kopiert hast und es nicht widerrufen wurde.';
  }

  @override
  String credentialsTokenWrongKind(String provider) {
    return 'Das ist kein persönliches Token. Füge ein persönliches Zugriffstoken aus deinem eigenen $provider-Konto ein, kein Projekt-, Gruppen-, Workspace- oder Bot-Token.';
  }

  @override
  String credentialsTokenNarrowScope(String scope) {
    return 'Diesem Token fehlt der Bereich $scope, den Reviews und Kommentare brauchen. Erstelle eins, das ihn hat.';
  }

  @override
  String get credentialsTokenExpired =>
      'Dieses Token ist abgelaufen. Erstelle ein neues und füge es hier ein.';

  @override
  String get credentialsSignInRateLimited =>
      'Gerade zu viele Anfragen. Warte kurz und versuche es dann erneut.';

  @override
  String get credentialsSignInCancelled =>
      'Die Anmeldung wurde abgebrochen oder abgelehnt. Starte sie erneut, wenn du bereit bist.';

  @override
  String get credentialsSignInNoLongerOpen =>
      'Diese Anmeldung ist nicht mehr offen: Sie wurde abgebrochen, verwendet oder ersetzt. Starte sie neu.';

  @override
  String get noWorkspacesYetHint =>
      'Ein Workspace-Admin muss dich einladen, oder der Serverinhaber kann einen Workspace für dich erstellen.';

  @override
  String repoAccessReplaced(String repos, String forge) {
    return '$repos zeigt jetzt auf ein anderes Repository auf $forge. Verknüpfe es über die Desktop- oder Web-App neu, um es weiter zu nutzen.';
  }

  @override
  String repoAccessAskAdminRelink(String repos, String forge) {
    return '$repos zeigt jetzt auf ein anderes Repository auf $forge. Ein Workspace-Admin muss es neu verknüpfen, bevor es wieder genutzt werden kann.';
  }

  @override
  String get runSandboxUnavailableTitle =>
      'Agenten brauchen eine Sandbox auf diesem Server';

  @override
  String get runSandboxUnavailable =>
      'Dieser Server hat keine Sandbox, daher kann hier nur der Serverinhaber Agenten ausführen. Der Inhaber kann die Sandbox installieren oder das Sandboxing für alle ausschalten.';

  @override
  String get scriptToolCalls => 'Werkzeugaufrufe';

  @override
  String scriptCallCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count Aufrufe',
      one: '1 Aufruf',
    );
    return '$_temp0';
  }

  @override
  String scriptCallsRunning(int count) {
    return '$count laufend';
  }

  @override
  String scriptCallsOk(int count) {
    return '$count ok';
  }

  @override
  String scriptCallsFailed(int count) {
    return '$count fehlgeschlagen';
  }

  @override
  String scriptCallsDenied(int count) {
    return '$count abgelehnt';
  }

  @override
  String scriptCallsCancelled(int count) {
    return '$count abgebrochen';
  }

  @override
  String scriptCallsQueued(int count) {
    return '$count in Warteschlange';
  }

  @override
  String scriptCallsSkipped(int count) {
    return '$count übersprungen';
  }

  @override
  String get scriptStepQueued => 'In Warteschlange';

  @override
  String get scriptStepSkipped => 'Übersprungen';

  @override
  String get scriptGroupLoop => 'Schleife';

  @override
  String get scriptGroupEach => 'Für jedes';

  @override
  String get scriptGroupParallel => 'Parallel';

  @override
  String get scriptGroupFunction => 'Funktion';

  @override
  String scriptCallsHidden(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count weitere Aufrufe anzeigen',
      one: '1 weiteren Aufruf anzeigen',
    );
    return '$_temp0';
  }

  @override
  String get scriptCallsUnplaced =>
      'Aufrufe, die im Skript nicht platziert sind';

  @override
  String get scriptToolComputed => 'Werkzeug';

  @override
  String scriptStepSemantics(String subject, String state) {
    return '$subject, $state';
  }

  @override
  String get scriptSourceLabel => 'Skript';

  @override
  String scriptSourceLines(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count Zeilen',
      one: '1 Zeile',
    );
    return '$_temp0';
  }

  @override
  String get scriptStateRunning => 'Läuft';

  @override
  String get scriptStateCompleted => 'Abgeschlossen';

  @override
  String get scriptStateFailed => 'Fehlgeschlagen';

  @override
  String get scriptStateTimedOut => 'Zeit abgelaufen';

  @override
  String get scriptStateCancelled => 'Abgebrochen';

  @override
  String get scriptStateMemoryExceeded => 'Speicherlimit erreicht';

  @override
  String get scriptStateOutputExceeded => 'Zu viel Ausgabe';

  @override
  String get scriptStateSandboxError => 'Sandbox-Fehler';

  @override
  String get scriptStateRefused => 'Abgelehnt';

  @override
  String get scriptOriginLine => 'Von einem Skript, das der Agent ausführt';

  @override
  String get codeModeTitle => 'Code-Modus';

  @override
  String get codeModeAvailable => 'Verfügbar';

  @override
  String get codeModeUnavailable => 'Nicht verfügbar';

  @override
  String codeModeUnavailableNote(String reason) {
    return 'Dieser Server kann keine Skripte ausführen, daher rufen Agenten hier ihre Werkzeuge einzeln auf. Der Server meldet: $reason';
  }

  @override
  String get codeModeNoReason => 'es wurde kein Grund angegeben.';

  @override
  String get workKindUnknown =>
      'Aus einem Grund, den diese Version nicht kennt:';

  @override
  String get workRefusalUnknown => 'Der Server hat dies abgelehnt:';

  @override
  String workActionFailed(String error) {
    return 'Das hat nicht geklappt: $error';
  }

  @override
  String get wakeKindStopped =>
      'Zurückgehalten, weil eine Person den Lauf gestoppt hat.';

  @override
  String get wakeKindAttempts => 'Die Zustellung ist dreimal fehlgeschlagen.';

  @override
  String get wakeKindAgentDeleted => 'Der Agent existiert nicht mehr.';

  @override
  String get wakeKindAgentNotDispatchable => 'Der Agent ist außer Dienst.';

  @override
  String get wakeKindAgentPaused => 'Der Agent ist pausiert.';

  @override
  String get wakeKindPersonRemoved =>
      'Die Person, für die er handelt, hat den Workspace verlassen.';

  @override
  String get wakeKindBudgetBlocked => 'Ein Budget blockiert einen Lauf.';

  @override
  String get wakeKindTakeOver => 'Eine Person hat den Worktree übernommen.';

  @override
  String get wakeKindRateCapConversation =>
      'Diese Konversation hat in der letzten Stunde 30 Läufe durch Weckrufe gestartet.';

  @override
  String get wakeKindRateCapWorkspace =>
      'Dieser Workspace hat in der letzten Stunde 300 Läufe durch Weckrufe gestartet.';

  @override
  String get wakeKindLiveRunNoInput =>
      'Der laufende Lauf des Agenten hier nimmt keine Eingaben an.';

  @override
  String get wakeKindLiveRunOtherOptions =>
      'Der laufende Lauf des Agenten hier arbeitet anders, daher startet dies danach einen eigenen Lauf.';

  @override
  String get wakeKindLiveRunOtherPerson =>
      'Der laufende Lauf des Agenten hier handelt für eine andere Person, daher startet dies danach einen eigenen Lauf.';

  @override
  String get wakeKindDispatchRefused => 'Der Lauf konnte nicht starten.';

  @override
  String get wakeKindSandboxUnavailable =>
      'Für einen Lauf im Nur-Lesen-Modus ist keine Sandbox verfügbar.';

  @override
  String get wakeKindReadOnlyUnavailable =>
      'Das Backend dieses Agenten kann einen Lauf nicht im Nur-Lesen-Modus halten.';

  @override
  String get wakeKindServerStopped =>
      'Ein Neustart des Servers hat den Lauf gestoppt.';

  @override
  String get wakeKindServerRestarted =>
      'Der Server wurde während eines Laufs einer Person neu gestartet.';

  @override
  String get wakeKindGuardFailed =>
      'Eine Prüfung vor der Zustellung ist fehlgeschlagen.';

  @override
  String get wakeKindLimit =>
      'Wartet, bis das Nutzungslimit des Anbieters zurückgesetzt ist.';

  @override
  String get wakeKindLimitRunLive =>
      'Wartet, bis der Lauf am Nutzungslimit endet.';

  @override
  String get wakeKindWakeMissed => 'Verpasst, während der Server nicht lief.';

  @override
  String get wakeKindPipelineRunEnded => 'Sein Pipeline-Run ist beendet.';

  @override
  String get wakeKindGoalEnded => 'Sein Ziel ist beendet.';

  @override
  String get wakeKindGoalBudgetExhausted =>
      'Sein Ziel hat sein Budget aufgebraucht.';

  @override
  String get wakeKindGoalReviewStale =>
      'Das Ziel hat sich seit der Anfrage für dieses Review geändert.';

  @override
  String get wakeKindGoalPaused => 'Sein Ziel ist pausiert.';

  @override
  String get wakeKindGoalHeld => 'Sein Ziel ist zurückgehalten.';

  @override
  String get wakeKindGoalStopped => 'Sein Ziel wurde gestoppt.';

  @override
  String get wakeKindAskSettled =>
      'Die Frage, die er beantwortet, ist bereits entschieden.';

  @override
  String get wakeKindRuleEnded => 'Sein Zeitplan ist beendet.';

  @override
  String get wakeRefusalNotYours =>
      'Dieser Weckruf handelt für eine andere Person. Nur sie kann ihn zustellen oder fortsetzen.';

  @override
  String get wakeRefusalSettled => 'Dieser Weckruf ist bereits erledigt.';

  @override
  String get goalRefusalAlreadyActive =>
      'Dieser Agent hat bereits ein aktives Ziel.';

  @override
  String get goalRefusalNotInReview =>
      'Dieses Ziel wartet nicht auf ein Review.';

  @override
  String get goalRefusalEvidenceIncomplete =>
      'Die Nachweise des Ziels sind unvollständig.';

  @override
  String get goalRefusalClaimPending =>
      'Eine Behauptung, dass es erledigt ist, wird noch geprüft.';

  @override
  String get goalRefusalNotActiveSegment =>
      'Für dieses Ziel läuft kein Abschnitt.';

  @override
  String get goalRefusalNotYours =>
      'Nur die Person, die dieses Ziel gestartet hat, kann das tun.';

  @override
  String get goalRefusalNotPaused => 'Pausiere das Ziel zuerst.';

  @override
  String get goalRefusalContractInvalid =>
      'Der Vertrag des Ziels kann nicht gelesen werden.';

  @override
  String get goalRefusalCheckerUnknown => 'Kein Agent hat diesen Namen.';

  @override
  String get goalRefusalCheckerAmbiguous =>
      'Mehr als ein Agent hat diesen Namen.';

  @override
  String get goalRefusalCheckerIsGoalAgent =>
      'Der Checker muss ein anderer Agent sein als der, der die Arbeit macht.';

  @override
  String get goalRefusalCommandInvalid =>
      'Dieses Ziel kann nicht gelesen werden:';

  @override
  String get wakeRuleRefusalIntervalTooShort =>
      'Das Intervall ist zu kurz. Wähle mindestens eine Minute.';

  @override
  String get wakeRuleRefusalTooSoon =>
      'Diese Zeit liegt zu nah. Wähle eine spätere.';

  @override
  String get wakeRuleRefusalLineageEnded =>
      'Diese Kette von Weckrufen hat ihre Läufe oder ihre Zeit aufgebraucht.';

  @override
  String get wakeRuleRefusalWatchTargetUnreadable =>
      'Was hier überwacht werden soll, kannst du nicht lesen.';

  @override
  String get wakeRuleRefusalExpiryRequired =>
      'Gib ein Enddatum oder eine Anzahl Läufe an.';

  @override
  String get wakeRuleRefusalLimitReached =>
      'Diese Konversation oder dieser Agent hat bereits so viele Zeitpläne, wie erlaubt sind.';

  @override
  String get wakeRuleRefusalInvalidWhen =>
      'Die Zeit kann nicht gelesen werden.';

  @override
  String get wakeRuleRefusalNoteTooLong => 'Die Notiz ist zu lang.';

  @override
  String get wakeRuleRefusalExpiryTooLong =>
      'Das Ende liegt zu weit in der Zukunft.';

  @override
  String get wakeRuleRefusalLimitOutOfRange =>
      'Ein Limit für Läufe, Tage oder Budget liegt außerhalb des zulässigen Bereichs.';

  @override
  String get wakeRuleRefusalNextOutsideLoop =>
      'Nur eine Schleife kann ihren nächsten Zeitpunkt selbst wählen.';

  @override
  String get wakeRuleRefusalWatchRefused => 'Das kann nicht überwacht werden.';

  @override
  String get wakeRuleRefusalRuleEnded => 'Dieser Zeitplan ist bereits beendet.';

  @override
  String get wakeRuleRefusalNotYours =>
      'Dieser Zeitplan gehört einer anderen Person.';

  @override
  String get wakeRuleEndFired => 'Er lief einmal.';

  @override
  String get wakeRuleEndExpired => 'Er hat sein Enddatum erreicht.';

  @override
  String get wakeRuleEndRunCap => 'Er hat seine Läufe aufgebraucht.';

  @override
  String get wakeRuleEndCostCap => 'Er hat seine Kostengrenze erreicht.';

  @override
  String get wakeRuleEndGoalEnded => 'Sein Ziel ist beendet.';

  @override
  String get wakeRuleEndCancelled => 'Er wurde abgebrochen.';

  @override
  String get wakeRuleEndMemberRemoved =>
      'Seine Person hat den Workspace verlassen.';

  @override
  String get wakeRuleEndInvalidRow =>
      'Seine gespeicherten Einstellungen konnten nicht gelesen werden.';

  @override
  String goalHoldWorking(int segment) {
    final intl.NumberFormat segmentNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String segmentString = segmentNumberFormat.format(segment);

    return 'Arbeitet an Abschnitt $segmentString. Niemand muss etwas tun.';
  }

  @override
  String get goalHoldWaiting =>
      'Wartet auf ausstehende Arbeit. Es geht von selbst weiter.';

  @override
  String goalHoldWaitingUntil(String time) {
    return 'Wartet auf ausstehende Arbeit. Es geht spätestens um $time von selbst weiter.';
  }

  @override
  String get goalHoldVerifying =>
      'Es sagt, es sei fertig. Der Server führt seine Prüfungen aus, dann entscheidet ein Reviewer.';

  @override
  String get goalHoldLimit =>
      'Pausiert am Nutzungslimit des Anbieters. Es wird nach dem Zurücksetzen von selbst fortgesetzt.';

  @override
  String goalHoldLimitUntil(String time) {
    return 'Pausiert am Nutzungslimit des Anbieters. Es wird um $time von selbst fortgesetzt.';
  }

  @override
  String get goalHoldPerson =>
      'Wartet darauf, dass eine Person in der Konversation antwortet. Es geht weiter, sobald jemand antwortet.';

  @override
  String get goalHoldByPerson =>
      'Von einer Person pausiert. Es bleibt pausiert, bis jemand es fortsetzt.';

  @override
  String get goalHoldNeedsReview =>
      'Wartet auf Review: Es kann nicht von selbst weitergehen. Genehmige es als erledigt, setze es fort oder brich es ab.';

  @override
  String get goalHoldBudget =>
      'Es hat sein Budget aufgebraucht. Erhöhe das Budget, damit es weitergehen kann.';

  @override
  String goalHoldLimitParks(int count, int max) {
    final intl.NumberFormat countNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String countString = countNumberFormat.format(count);
    final intl.NumberFormat maxNumberFormat = intl.NumberFormat.decimalPattern(
      localeName,
    );
    final String maxString = maxNumberFormat.format(max);

    return 'Pausen wegen des Nutzungslimits: $countString von $maxString';
  }

  @override
  String get goalHoldDetailStalled =>
      'Keine Fortschritte in seinen letzten Abschnitten.';

  @override
  String get goalHoldDetailStalledWaiting =>
      'Es hat 24 Stunden auf dieselbe Arbeit gewartet, ohne Fortschritt.';

  @override
  String get goalHoldDetailVerificationFailed =>
      'Die letzte Prüfung ist fehlgeschlagen.';

  @override
  String get goalHoldDetailCannotVerify =>
      'Der Checker konnte nicht beurteilen, ob es erledigt ist.';

  @override
  String get goalHoldDetailSandboxUnavailable =>
      'Für das Ausführen seiner Prüfungen ist keine Sandbox verfügbar.';

  @override
  String get goalHoldDetailCheckerUnavailable =>
      'Sein Checker-Agent ist nicht verfügbar. Wähle einen anderen Checker und setze dann fort.';

  @override
  String get goalHoldDetailCheckBroken =>
      'Diese Prüfung kann nicht ausgeführt werden:';

  @override
  String get goalHoldDetailWakeSkipped =>
      'Sein Weckruf wurde nicht zugestellt.';

  @override
  String get goalHoldDetailClaimPending =>
      'Seine Behauptung, dass es erledigt ist, wartet auf eine Prüfung.';

  @override
  String get goalHoldDetailUnanswered =>
      'Eine Frage oder Genehmigungsanfrage an eine Person blieb unbeantwortet.';

  @override
  String get goalHoldDetailLimitParks =>
      'Es hat die Nutzungslimits zu oft erreicht. Sieh es dir an und setze dann fort.';

  @override
  String get goalHoldDetailInput =>
      'Wartet auf eine Antwort in der Konversation.';

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

    return 'Abschnitt $runString von $maxString';
  }

  @override
  String goalSegmentsNoCap(int run) {
    final intl.NumberFormat runNumberFormat = intl.NumberFormat.decimalPattern(
      localeName,
    );
    final String runString = runNumberFormat.format(run);

    return 'Abschnitt $runString, ohne Obergrenze';
  }

  @override
  String goalMoney(String spent, String cap) {
    return '$spent von $cap ausgegeben';
  }

  @override
  String goalDeadline(String time) {
    return 'Frist $time';
  }

  @override
  String get goalPipelineStep => 'Ein Pipeline-Schritt verfolgt dieses Ziel.';

  @override
  String get goalSummaryHeading => 'Letzte Zusammenfassung';

  @override
  String get goalDoneMeans => 'Fertig heißt';

  @override
  String get goalChecks => 'Prüfungen';

  @override
  String get goalBoundaries => 'Grenzen';

  @override
  String get goalStopWhen => 'Anhalten und fragen, wenn';

  @override
  String get goalNoMachineCheck =>
      'Keine maschinelle Prüfung. Ein Reviewer urteilt anhand dessen, was er lesen kann.';

  @override
  String get goalCheckEnvironment => 'Environment-Aufgabe';

  @override
  String goalLastCheck(int round, String time) {
    final intl.NumberFormat roundNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String roundString = roundNumberFormat.format(round);

    return 'Letzte Prüfung, Runde $roundString, $time';
  }

  @override
  String get goalClaim => 'Was es behauptet hat';

  @override
  String get goalCheckPassed => 'Bestanden';

  @override
  String goalCheckFailed(int code) {
    return 'Fehlgeschlagen, Exit $code';
  }

  @override
  String get goalCheckTimedOut => 'Zeit abgelaufen';

  @override
  String get goalCheckNotRerun =>
      'Nicht erneut ausgeführt: nichts hat sich geändert';

  @override
  String get goalCheckBroken => 'Kann nicht ausgeführt werden';

  @override
  String get goalCriterionMet => 'Erfüllt';

  @override
  String get goalCriterionUnmet => 'Nicht erfüllt';

  @override
  String get goalCriterionCannotTell => 'Nicht beurteilbar';

  @override
  String get goalVerdictPass => 'Urteil: erledigt';

  @override
  String get goalVerdictFail => 'Urteil: nicht erledigt';

  @override
  String get goalVerdictCannotVerify => 'Urteil: nicht beurteilbar';

  @override
  String get goalConcerns => 'Bedenken';

  @override
  String goalVerifiedBy(String agent) {
    return 'Geprüft von $agent';
  }

  @override
  String get goalVerifiedBySelf => 'Selbst geprüft (kein eigener Checker)';

  @override
  String get goalClosedByPerson =>
      'Von einer Person ohne bestandene Prüfung abgeschlossen';

  @override
  String get goalApprove => 'Abschluss genehmigen';

  @override
  String get goalApproveTitle => 'Dieses Ziel als erledigt abschließen?';

  @override
  String get goalApproveBody =>
      'Keine Prüfung hat das bestätigt. Du schließt es auf eigene Verantwortung ab, und das Ziel hält fest, dass eine Person es ungeprüft abgeschlossen hat.';

  @override
  String get goalApproveConfirm => 'Als erledigt abschließen';

  @override
  String get goalResumeNotYours =>
      'Fortsetzen oder das Budget erhöhen darf nur, wer es gestartet hat.';

  @override
  String get goalChooseChecker => 'Anderen Checker wählen';

  @override
  String goalCheckerSet(String agent) {
    return '$agent prüft jetzt. Setze fort, um erneut zu prüfen.';
  }

  @override
  String get goalSchedules => 'Zeitpläne';

  @override
  String get goalRepeat => 'Wiederholen';

  @override
  String get goalCreateChecks => 'Prüfungen (optional)';

  @override
  String get goalCreateCheckHint =>
      'Ein Befehl, der besteht, wenn die Arbeit fertig ist';

  @override
  String get goalCreateAddCheck => 'Prüfung hinzufügen';

  @override
  String get goalCreateRemoveCheck => 'Prüfung entfernen';

  @override
  String get goalCreateSegmentCap => 'Obergrenze für Abschnitte (optional)';

  @override
  String get goalCreateSegmentInvalid =>
      'Die Obergrenze für Abschnitte ist eine ganze Zahl, mindestens 1.';

  @override
  String get scheduleCreateTitle => 'Einen Prompt wiederholen';

  @override
  String get scheduleCadence => 'Wie oft';

  @override
  String get scheduleEveryMinutes => 'Alle N Minuten';

  @override
  String get scheduleEveryHours => 'Alle N Stunden';

  @override
  String get scheduleSelfPaced => 'Selbstgetaktet';

  @override
  String get scheduleSelfPacedHint =>
      'Der Agent wählt nach jedem Lauf die Pause bis zum nächsten, zwischen 1 Minute und 1 Stunde.';

  @override
  String get scheduleInterval => 'Intervall';

  @override
  String get scheduleNote => 'Was soll jeder Lauf tun?';

  @override
  String get scheduleCostCap => 'Kostengrenze in USD (optional)';

  @override
  String get scheduleExpiryDays => 'Endet nach N Tagen (optional)';

  @override
  String get scheduleCreateInvalid =>
      'Wähle einen Bereich und einen Agenten, schreibe, was jeder Lauf tun soll, und gib ganze Zahlen ab 1 an.';

  @override
  String get scheduleCreateButton => 'Zeitplan starten';

  @override
  String get scheduleCreateConfirmTitle => 'Diesen Zeitplan starten?';

  @override
  String scheduleCreateConfirmEveryMinutes(int count) {
    final intl.NumberFormat countNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String countString = countNumberFormat.format(count);

    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Er läuft alle $countString Minuten, ab jetzt.',
      one: 'Er läuft jede Minute, ab jetzt.',
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
      other: 'Er läuft alle $countString Stunden, ab jetzt.',
      one: 'Er läuft jede Stunde, ab jetzt.',
    );
    return '$_temp0';
  }

  @override
  String get scheduleCreateConfirmSelfPaced =>
      'Er läuft jetzt, dann bestimmt der Agent, wann er erneut läuft.';

  @override
  String get scheduleCreated => 'Zeitplan gestartet. Er steht unter Zeitpläne.';

  @override
  String get schedulesTitle => 'Zeitpläne';

  @override
  String get schedulesLoadFailed => 'Zeitpläne konnten nicht geladen werden';

  @override
  String get schedulesEmpty => 'Keine Zeitpläne oder Überwachungen';

  @override
  String get schedulesEmptyDescription =>
      'Wiederhole einen Prompt aus dem Ziele-Bildschirm oder sende /loop oder /schedule in einer Konversation.';

  @override
  String get scheduleMissing =>
      'Dieser Zeitplan ist in diesem Workspace nicht mehr verfügbar.';

  @override
  String scheduleEvery(String interval) {
    return 'Alle $interval';
  }

  @override
  String get scheduleSelfPacedLoop => 'Selbstgetaktete Schleife';

  @override
  String get scheduleCron => 'Cron-Zeitplan';

  @override
  String scheduleOnce(String time) {
    return 'Einmal um $time';
  }

  @override
  String scheduleWatch(String event) {
    return 'Überwachung: $event';
  }

  @override
  String get scheduleWatchPrChecks => 'Prüfungen von Pull Requests';

  @override
  String get scheduleWatchPrReview => 'Reviews von Pull Requests';

  @override
  String get scheduleWatchPrMerged => 'Merge eines Pull Requests';

  @override
  String get scheduleWatchEnvironment => 'Environment';

  @override
  String get scheduleWatchTicket => 'Ticket';

  @override
  String get scheduleWatchPipelineRun => 'Pipeline-Run';

  @override
  String get scheduleStatusActive => 'Aktiv';

  @override
  String get scheduleStatusPaused => 'Pausiert';

  @override
  String get scheduleStatusEnded => 'Beendet';

  @override
  String scheduleWakes(String agent) {
    return 'Weckt $agent';
  }

  @override
  String scheduleNext(String time) {
    return 'Nächster Lauf $time';
  }

  @override
  String scheduleLast(String time) {
    return 'Letzter Lauf $time';
  }

  @override
  String scheduleRuns(int count) {
    final intl.NumberFormat countNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String countString = countNumberFormat.format(count);

    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$countString Läufe',
      one: '1 Lauf',
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

    return '$countString von $maxString Läufen';
  }

  @override
  String scheduleSkipped(int count) {
    final intl.NumberFormat countNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String countString = countNumberFormat.format(count);

    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$countString übersprungen',
      one: '1 übersprungen',
    );
    return '$_temp0';
  }

  @override
  String scheduleEnds(String time) {
    return 'Endet $time';
  }

  @override
  String scheduleChain(int count, String time) {
    final intl.NumberFormat countNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String countString = countNumberFormat.format(count);

    return 'Teil einer Kette: noch $countString Läufe, endet $time';
  }

  @override
  String get scheduleNoteAgent =>
      'Die eigene Notiz des Agenten, in seinen Worten:';

  @override
  String get scheduleNotePerson => 'Eine Notiz einer Person:';

  @override
  String scheduleActsFor(String name) {
    return 'Handelt für $name';
  }

  @override
  String get scheduleActsForBot => 'Handelt für keine Person';

  @override
  String get scheduleGoalBound => 'Er endet mit seinem Ziel.';

  @override
  String get schedulePause => 'Pausieren';

  @override
  String get scheduleResume => 'Fortsetzen';

  @override
  String get scheduleDelete => 'Löschen';

  @override
  String get scheduleRemove => 'Entfernen';

  @override
  String get scheduleDeleteTitle => 'Diesen Zeitplan löschen?';

  @override
  String get scheduleDeleteBody =>
      'Er hört endgültig auf. Was er schon getan hat, wird nicht rückgängig gemacht.';

  @override
  String get scheduleRemoveTitle => 'Diesen Zeitplan entfernen?';

  @override
  String get scheduleRemoveBody => 'Er verschwindet aus der Liste.';

  @override
  String get scheduleResumeNotYours =>
      'Nur die Person, für die dieser Zeitplan handelt, kann ihn fortsetzen.';

  @override
  String get scheduleResumeAdminOnly =>
      'Nur ein Workspace-Admin kann einen Zeitplan fortsetzen, der keiner Person gehört.';

  @override
  String get scheduleOpenConversation => 'Konversation öffnen';

  @override
  String get progressWaiting => 'Wartet';

  @override
  String get progressNothingWaiting => 'Nichts wartet.';

  @override
  String get wakeOriginGoal => 'Ziel';

  @override
  String get wakeOriginGoalCheck => 'Zielprüfung';

  @override
  String get wakeOriginGoalReview => 'Ziel-Review';

  @override
  String get wakeOriginSchedule => 'Zeitplan';

  @override
  String get wakeOriginWatch => 'Überwachung';

  @override
  String get wakeOriginReply => 'Antwort';

  @override
  String get wakeOriginMessage => 'Nachricht';

  @override
  String get wakeOriginWorkFinished => 'Fertige Arbeit';

  @override
  String get wakeOriginLimitReset => 'Limit zurückgesetzt';

  @override
  String get wakeOriginRecovery => 'Wiederherstellung';

  @override
  String get wakeOriginAssignment => 'Zuweisung';

  @override
  String get wakeOriginPipelineStep => 'Pipeline-Schritt';

  @override
  String get wakeOriginImprovementReview => 'Verbesserungs-Review';

  @override
  String wakeOriginReplyFrom(String agent) {
    return 'Antwort von $agent';
  }

  @override
  String wakeOriginMessageFrom(String agent) {
    return 'Nachricht von $agent';
  }

  @override
  String wakeOriginWorkFinishedBy(String agent) {
    return 'Fertige Arbeit von $agent';
  }

  @override
  String wakeFor(String agent) {
    return 'Für $agent';
  }

  @override
  String wakeDue(String time) {
    return 'Fällig $time';
  }

  @override
  String get wakeDueNow => 'Jetzt fällig';

  @override
  String get wakeHeld => 'Zurückgehalten';

  @override
  String wakeExpires(String time) {
    return 'Läuft ab $time';
  }

  @override
  String wakeAttempt(int attempt) {
    final intl.NumberFormat attemptNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String attemptString = attemptNumberFormat.format(attempt);

    return 'Versuch $attemptString';
  }

  @override
  String get wakeCancel => 'Abbrechen';

  @override
  String get wakeDeliverNow => 'Jetzt zustellen';

  @override
  String get wakeResume => 'Fortsetzen';

  @override
  String get wakeDismiss => 'Verwerfen';

  @override
  String get wakeResumeOnlyTheirs =>
      'Nur die Person, deren Lauf das ist, kann ihn fortsetzen.';

  @override
  String get wakeRecovery =>
      'Der Server wurde während dieses Laufs neu gestartet. Setze ihn fort oder verwirf ihn.';

  @override
  String limitParkTitle(String provider, String time) {
    return 'Pausiert wegen des Nutzungslimits von $provider, das um $time zurückgesetzt wird. Der Lauf wartet auf Fortsetzen, bis zu 7 Tage nach dem Zurücksetzen.';
  }

  @override
  String limitParkTitleUnnamed(String time) {
    return 'Pausiert wegen des Nutzungslimits des Anbieters, das um $time zurückgesetzt wird. Der Lauf wartet auf Fortsetzen, bis zu 7 Tage nach dem Zurücksetzen.';
  }

  @override
  String get limitParkResumeNow => 'Jetzt fortsetzen';

  @override
  String get limitParkCancel => 'Abbrechen';

  @override
  String limitParkResumed(String provider) {
    return 'Nach dem Nutzungslimit von $provider fortgesetzt.';
  }

  @override
  String limitParkGone(String provider) {
    return 'Wartet nicht mehr auf das Nutzungslimit von $provider.';
  }

  @override
  String get limitParkProviderUnknown => 'der Anbieter';

  @override
  String get mobileHeldMessages => 'Zurückgehaltene Nachrichten';

  @override
  String get heldSteeringTitle =>
      'Zurückgehalten, weil der Lauf endete, bevor er sie übernehmen konnte. Sende deine jetzt oder entferne sie.';

  @override
  String get heldSteeringRelease => 'Zurückgehaltene Nachrichten senden';

  @override
  String get notifGoalCompleted => 'Ziel erledigt';

  @override
  String get notifGoalFailed => 'Ziel fehlgeschlagen';

  @override
  String get notifGoalCancelled => 'Ziel abgebrochen';

  @override
  String get notifGoalBudgetExhausted => 'Ziel hat sein Budget aufgebraucht';

  @override
  String get notifGoalNeedsReview => 'Ein Ziel wartet auf dein Review';

  @override
  String get notifGoalNeedsPerson => 'Ein Ziel braucht dich';

  @override
  String get notifGoalOnHold => 'Ein Ziel ist zurückgehalten';

  @override
  String get notifWakeRuleEnded => 'Ein Zeitplan ist beendet';

  @override
  String notifWaitingDigest(int count) {
    final intl.NumberFormat countNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String countString = countNumberFormat.format(count);

    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$countString Sachen warten auf dich',
      one: '1 Sache wartet auf dich',
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
      other: '$countString Verbesserungen wurden vorgeschlagen',
      one: 'Eine Verbesserung wurde vorgeschlagen',
    );
    return '$_temp0';
  }

  @override
  String get notifPipelineRunHeld =>
      'Ein Pipeline-Run ist am Budget zurückgehalten';

  @override
  String notifPipelineRunHeldBody(String spent, String cap) {
    return '$spent von $cap ausgegeben';
  }

  @override
  String get notifNeedsYou => 'Braucht dich';

  @override
  String get notifDigestGoalReview => 'Ziel wartet auf Review';

  @override
  String get notifDigestGoalPerson => 'Ziel braucht eine Person';

  @override
  String get notifDigestHeldWake => 'Zurückgehaltener Weckruf';

  @override
  String get notifDigestImprovement => 'Vorgeschlagene Verbesserung';

  @override
  String get wakeKindRulePaused => 'Sein Zeitplan wurde pausiert.';

  @override
  String get wakeKindRuleBusy =>
      'Der Agent war beschäftigt, und dieser Zeitplan überspringt solche Zeitpunkte.';

  @override
  String get wakeKindRuleFolded =>
      'Ein späteres Ereignis derselben Überwachung hat seinen Platz eingenommen.';

  @override
  String get wakeKindRuleSuperseded =>
      'Ein späterer Zeitpunkt seines Zeitplans hat ihn ersetzt.';

  @override
  String get wakeKindRuleNotified =>
      'Sein Zeitplan sendet nur eine Benachrichtigung, daher wurde kein Lauf gestartet.';

  @override
  String get wakeKindRuleLimitParked =>
      'Sein Zeitplan wartet, bis das Nutzungslimit des Anbieters zurückgesetzt ist.';

  @override
  String get improvementRefusalCooldown =>
      'Ein Review dieser Konversation lief vor Kurzem. Versuche es später erneut.';

  @override
  String get improvementRefusalQueued =>
      'Ein Review dieser Konversation wartet bereits auf den Start.';

  @override
  String get improvementRefusalAgentNotFound =>
      'Dieser Agent gehört nicht zu diesem Workspace.';

  @override
  String get steeringRefusalHeldByLimit =>
      'Nachrichten am Nutzungslimit können nicht von Hand gesendet werden. Sie warten, bis der pausierte Lauf fortgesetzt wird.';

  @override
  String limitParkCancelled(String provider) {
    return 'Das Warten am Nutzungslimit von $provider wurde abgebrochen.';
  }

  @override
  String limitParkExpired(String provider) {
    return 'Das Warten am Nutzungslimit von $provider ist abgelaufen, bevor der Lauf fortgesetzt wurde.';
  }

  @override
  String limitParkSkipped(String provider) {
    return 'Der Lauf wurde nach dem Nutzungslimit von $provider nicht fortgesetzt.';
  }

  @override
  String get heldSteeringLimitTitle =>
      'Zurückgehalten, während der Lauf auf das Zurücksetzen des Nutzungslimits wartet. Sie werden gesendet, wenn die Person, für die er handelt, ihn fortsetzt.';

  @override
  String heldSteeringLimitAt(String time) {
    return 'Zurückgehalten bis zum Zurücksetzen des Nutzungslimits um $time. Sie werden gesendet, wenn die Person, für die er handelt, ihn fortsetzt.';
  }

  @override
  String get heldSteeringOtherTitle =>
      'Vom Server zurückgehalten. Du kannst sie entfernen.';

  @override
  String workRowWoke(int count, String agent) {
    final intl.NumberFormat countNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String countString = countNumberFormat.format(count);

    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$agent für $countString wartende Einträge geweckt',
      one: '$agent geweckt',
    );
    return '$_temp0';
  }

  @override
  String workRowWakeMissed(String agent) {
    return 'Ein Weckruf für $agent wurde verpasst, während der Server nicht lief.';
  }

  @override
  String workRowWakeSkipped(String agent) {
    return 'Ein Weckruf für $agent wurde nicht zugestellt.';
  }

  @override
  String workRowScheduleCreated(String agent) {
    return 'Zeitplan für $agent eingerichtet.';
  }

  @override
  String workRowScheduleEnded(String agent) {
    return 'Der Zeitplan von $agent ist beendet.';
  }

  @override
  String workRowNoteFromAgent(String agent) {
    return 'Notiz zum Zeitplan von $agent:';
  }

  @override
  String get workRowNoteFromPerson => 'Notiz zum Zeitplan von einer Person:';

  @override
  String workRowCommandRefusedNamed(String command) {
    return 'Der Befehl $command wurde abgelehnt.';
  }

  @override
  String get workRowCommandRefused => 'Ein Befehl wurde abgelehnt.';

  @override
  String workRowCapRaised(String person, String from, String to) {
    return '$person hat die Kostengrenze der Pipeline von $from auf $to erhöht.';
  }

  @override
  String workRowCapRaisedNoAmounts(String person) {
    return '$person hat die Kostengrenze der Pipeline erhöht.';
  }

  @override
  String get workRowApplyIncomplete =>
      'Eine akzeptierte Änderung an diesem Skill konnte nicht abgeschlossen werden, weil sich der Skill inzwischen geändert hat. Der Vorschlag wurde zurückgerollt.';

  @override
  String get workRowOpenSchedule => 'Zeitplan öffnen';

  @override
  String get heldSteeringOthersTitle =>
      'Zurückgehalten, weil der Lauf endete, bevor er sie übernehmen konnte. Nur die Person, die eine Nachricht geschrieben hat, kann sie senden.';

  @override
  String get heldSteeringOnlyYours =>
      'Sendet nur deine Nachrichten. Die anderen warten auf die Personen, die sie geschrieben haben.';

  @override
  String heldSteeringWrittenBy(String name) {
    return 'Geschrieben von $name';
  }

  @override
  String get steeringRefusalNotYours =>
      'Nur die Person, die eine zurückgehaltene Nachricht geschrieben hat, kann sie senden, und keine davon ist deine.';

  @override
  String get steeringRefusalNeedsWrite =>
      'Du brauchst Schreibzugriff auf die Repositorys dieses Bereichs, um einen Lauf zu steuern, der für eine andere Person handelt.';

  @override
  String workRowSchedulePaused(String name, String agent) {
    return '$name hat den Zeitplan für $agent pausiert.';
  }

  @override
  String get goalVerdictObjective => 'Die Zielsetzung als Ganzes';

  @override
  String get notifDigestRequest => 'Wartet auf deine Antwort';
}
