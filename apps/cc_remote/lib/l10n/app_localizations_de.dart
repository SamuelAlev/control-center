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
  String get inboxNoForgeAccount =>
      'Auf dem Server ist kein Forge-Konto verbunden, daher können Pull Requests dir noch nicht zugeordnet werden.';

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
  String attachmentsTooLargeRelay(int count, String names) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other:
          '$names sind zu groß, um von hier über das Relay gesendet zu werden.',
      one: '$names ist zu groß, um von hier über das Relay gesendet zu werden.',
    );
    return '$_temp0';
  }

  @override
  String get attachmentUploadFailed =>
      'Anhang konnte nicht hochgeladen werden. Erneut versuchen.';

  @override
  String attachmentsLeftOut(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other:
          '$count Anhänge konnten nicht hochgeladen werden und wurden weggelassen.',
      one: '1 Anhang konnte nicht hochgeladen werden und wurde weggelassen.',
    );
    return '$_temp0';
  }

  @override
  String get teammate => 'Teammitglied';

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
  String reposUnreadable(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count Repos konnten nicht gelesen werden.',
      one: '1 Repo konnte nicht gelesen werden.',
    );
    return '$_temp0';
  }

  @override
  String reposNotReadable(String names) {
    return 'Nicht lesbar: $names';
  }

  @override
  String get installationSuspendedTitle =>
      'GitHub App-Installation ist ausgesetzt';

  @override
  String installationSuspendedBody(String names) {
    return 'Für $names wird nur der zuletzt bekannte Stand angezeigt. Setze die Installation auf GitHub fort oder verbinde ein Token mit Zugriff.';
  }

  @override
  String installationSuspendedNotice(String names) {
    return 'GitHub App-Installation ist ausgesetzt. Für $names wird nur der zuletzt bekannte Stand angezeigt. Setze die Installation auf GitHub fort oder verbinde ein Token mit Zugriff.';
  }

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
  String get permissionPrPublish => 'Pull Requests veröffentlichen';

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
  String get permissionRemembered => 'Gespeicherte Genehmigung';

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
  String get permissionRevokeBeforeEdit =>
      'Vor dem Festlegen einer allgemeinen Regel für diese Aktion muss die bereichsspezifische oder gespeicherte Regel widerrufen werden.';

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
  String get mobileGoalGoal => 'Ziel';

  @override
  String get mobileGoalLoop => 'Schleife';

  @override
  String mobileGoalKind(String kind) {
    return 'Typ: $kind';
  }

  @override
  String mobileGoalRuns(String count) {
    return '$count Läufe';
  }

  @override
  String get mobileGoalNoRunLimit => 'unbegrenzt';

  @override
  String mobileGoalProgress(
    String runs,
    String maxRuns,
    String spent,
    String cap,
  ) {
    return 'Läufe: $runs / $maxRuns · Ausgegeben: $spent / $cap';
  }

  @override
  String mobileGoalDeadline(String date) {
    return 'Frist: $date';
  }

  @override
  String mobileGoalFailures(String count) {
    return 'Fehlgeschlagene Läufe in Folge: $count';
  }

  @override
  String get mobileGoalSummary => 'Abschlusszusammenfassung';

  @override
  String get mobileGoalFailedDescription =>
      'Die Überwachung wurde nach wiederholt fehlgeschlagenen Läufen gestoppt. Details sind in der Konversation zu finden.';

  @override
  String get mobileGoalBudgetWall =>
      'Die Frist oder die maximale Anzahl an Läufen wurde erreicht. Eine höhere Kostenobergrenze ermöglicht keine Fortsetzung dieses Ziels.';

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
  String get activityTicket => 'Ticket aktualisiert';

  @override
  String get activityMeeting => 'Meeting aktualisiert';

  @override
  String get activityCalendar => 'Kalenderverbindung';

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
  String get credentialsRedirectUnavailable =>
      'Der Browser-Rückruf dieses Servers ist vom Smartphone aus nicht sicher erreichbar. Bitten Sie den Serverbesitzer, eine öffentliche HTTPS-Rückrufadresse einzurichten, oder fügen Sie stattdessen ein Token hinzu.';

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
  String get credentialsHostManaged =>
      'Diese Verbindung stammt aus der Server-App oder der Serverumgebung. Nur der Serverbesitzer kann sie dort ändern. Sie können trotzdem Ihr eigenes Token hinzufügen.';

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
}
