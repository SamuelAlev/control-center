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
}
