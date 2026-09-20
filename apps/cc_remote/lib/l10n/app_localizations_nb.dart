// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Norwegian Bokmål (`nb`).
class AppLocalizationsNb extends AppLocalizations {
  AppLocalizationsNb([String locale = 'nb']) : super(locale);

  @override
  String get appTitle => 'Control Center';

  @override
  String get back => 'Tilbake';

  @override
  String get cancel => 'Avbryt';

  @override
  String get retry => 'Prøv på nytt';

  @override
  String get tryAgain => 'Prøv på nytt';

  @override
  String get settings => 'Innstillinger';

  @override
  String get refresh => 'Oppdater';

  @override
  String get approve => 'Godkjenn';

  @override
  String get deny => 'Nekt';

  @override
  String get continueLabel => 'Fortsett';

  @override
  String get agentQuestionHeader => 'Spørsmål til deg';

  @override
  String get agentQuestionAnsweredLabel => 'Besvart';

  @override
  String get agentQuestionSkip => 'Hopp over';

  @override
  String get agentQuestionSkippedLabel => 'Hoppet over';

  @override
  String get agentQuestionFreeformHint => 'Skriv svaret ditt…';

  @override
  String get agentApprovalRequired => 'Godkjenning kreves';

  @override
  String get approveAndRemember => 'Godkjenn i 8 timer';

  @override
  String get decline => 'Avslå';

  @override
  String get confirm => 'Bekreft';

  @override
  String get send => 'Send';

  @override
  String get close => 'Lukk';

  @override
  String get expand => 'Utvid';

  @override
  String get zoomIn => 'Zoom inn';

  @override
  String get zoomOut => 'Zoom ut';

  @override
  String get resetZoom => 'Tilbakestill zoom';

  @override
  String get scanQrPrompt =>
      'Skann QR-koden fra Control Center for å pare denne telefonen.';

  @override
  String get scanQrHelp =>
      'Åpne kameraet og pek det mot QR-koden som vises i Control Center. Denne telefonen kobler seg direkte over en privat lenke.';

  @override
  String get connectingToMac => 'Kobler til Control Center…';

  @override
  String get connectingDetail => 'Oppretter en sikker, direkte lenke.';

  @override
  String get identityChangedTitle => 'Serveridentiteten er endret';

  @override
  String get identityChangedBody =>
      'Denne serveren samsvarer ikke lenger med identiteten som ble lagret da du paret. Det kan bety at serveren ble installert på nytt — eller at noe avlytter tilkoblingen. For sikkerhets skyld kobler ikke denne enheten til. Fjern paringen, og skann deretter en ny QR-kode fra Control Center for å pare på nytt.';

  @override
  String get removePairing => 'Fjern paring';

  @override
  String get couldntConnect => 'Kunne ikke koble til';

  @override
  String get pendingPairingTitle => 'Koble til denne serveren?';

  @override
  String get pendingPairingBody =>
      'En lenke ba Control Center om å pare med denne serveren. Fortsett bare hvis du startet det selv.';

  @override
  String get connect => 'Koble til';

  @override
  String get failureNotPaired =>
      'Ikke paret — skann QR-koden fra Control Center';

  @override
  String get failureUnreachable =>
      'Nådde ikke serveren på noen sti — sjekk at den kjører, eller prøv samme nettverk';

  @override
  String get failureIdentityChanged =>
      'Serveridentiteten er endret — hvis den ble installert på nytt, par denne enheten på nytt';

  @override
  String get failureAuthRejected =>
      'Serveren avviste denne enheten — par den på nytt fra Control Center';

  @override
  String get failureUnknown =>
      'Kunne ikke koble til — trykk for å prøve på nytt';

  @override
  String get statusConnected => 'Tilkoblet';

  @override
  String get statusConnecting => 'Kobler til';

  @override
  String get statusOffline => 'Frakoblet';

  @override
  String get statusIdentityMismatch => 'Identitetsavvik';

  @override
  String get statusNotPaired => 'Ikke paret';

  @override
  String get statusConfirmPairing => 'Bekreft paring';

  @override
  String get connectionFailed => 'Tilkoblingen mislyktes';

  @override
  String get identityMismatchBanner =>
      'Serveridentiteten er endret — tilkoblingen ble stoppet. Par denne enheten på nytt for å fortsette.';

  @override
  String get tabInbox => 'Innboks';

  @override
  String get tabTickets => 'Saker';

  @override
  String get tabChat => 'Chat';

  @override
  String get tabPrs => 'PRs';

  @override
  String get tabCalendar => 'Kalender';

  @override
  String get tabNews => 'Nyheter';

  @override
  String tabWaitingCount(String label, int count) {
    return '$label, $count venter';
  }

  @override
  String get updateAvailable => 'En ny Control Center er tilgjengelig';

  @override
  String get appearance => 'Utseende';

  @override
  String get language => 'Språk';

  @override
  String get device => 'Enhet';

  @override
  String get themeSystem => 'System';

  @override
  String get themeLight => 'Lys';

  @override
  String get themeDark => 'Mørk';

  @override
  String get languageSystem => 'System';

  @override
  String get disconnectTapAgain =>
      'Trykk igjen for å koble denne enheten fra Control Center';

  @override
  String get disconnectDevice => 'Koble fra denne enheten';

  @override
  String get disconnect => 'Koble fra';

  @override
  String get chooseWorkspace => 'Velg arbeidsområde';

  @override
  String get workspaces => 'Arbeidsområder';

  @override
  String get workspacesLoadFailed => 'Kunne ikke laste arbeidsområder';

  @override
  String get noWorkspacesYet => 'Ingen arbeidsområder ennå';

  @override
  String selectWorkspace(String name) {
    return 'Velg $name';
  }

  @override
  String get inboxLoadFailed => 'Kunne ikke laste innboksen';

  @override
  String get allCaughtUp => 'Du er à jour';

  @override
  String get inboxNoForgeAccount =>
      'Ingen forge-konto er tilkoblet på serveren, så pull requests kan ikke tilskrives deg ennå.';

  @override
  String get inboxNothingWaiting =>
      'Ingenting er blokkert, og ingen pull request venter på deg.';

  @override
  String get blocked => 'Blokkert';

  @override
  String get sectionNeedsYourReview => 'Trenger gjennomgangen din';

  @override
  String get sectionReturnedToYou => 'Returnert til deg';

  @override
  String get sectionApprovedAndReady => 'Godkjent og klare';

  @override
  String get sectionYourDrafts => 'Dine utkast';

  @override
  String get sectionWaitingForReviewers => 'Venter på reviewere';

  @override
  String get sectionMergingAndMerged => 'Sammenslåing og nylig slått sammen';

  @override
  String get sectionWaitingForAuthor => 'Venter på forfatter';

  @override
  String waitingAgo(String ago) {
    return 'venter $ago';
  }

  @override
  String get openConversation => 'Åpne samtalen';

  @override
  String get calendarLoadFailed => 'Kunne ikke laste kalenderen';

  @override
  String get nothingScheduled => 'Ingenting planlagt';

  @override
  String get calendarEmptyDescription =>
      'Hendelser fra de tilkoblede kalenderne vises her.';

  @override
  String get agenda => 'Agenda';

  @override
  String get syncCalendarsNow => 'Synkroniser kalendere nå';

  @override
  String get event => 'Hendelse';

  @override
  String get eventNotFound => 'Hendelsen ble ikke funnet';

  @override
  String get eventNotFoundDescription =>
      'Den kan ligge utenfor agendavinduet, eller være fjernet oppstrøms.';

  @override
  String get joinMeeting => 'Bli med i møte';

  @override
  String get join => 'Bli med';

  @override
  String attendeesCount(int count) {
    return 'Deltakere ($count)';
  }

  @override
  String get details => 'Detaljer';

  @override
  String get allDay => 'Hele dagen';

  @override
  String get happeningNow => 'Pågår nå';

  @override
  String inDuration(String duration) {
    return 'Om $duration';
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
  String get attendeeAccepted => 'akseptert';

  @override
  String get attendeeDeclined => 'avslått';

  @override
  String get attendeeMaybe => 'kanskje';

  @override
  String get attendeeNoReply => 'ingen svar';

  @override
  String get organizer => 'arrangør';

  @override
  String get calendarNoAccounts =>
      'Ingen kalender er tilkoblet for dette arbeidsområdet. Koble til én fra skrivebordsappen — innloggingen lagrer tokenet på serveren.';

  @override
  String get calendarReauthNeeded =>
      'En kalenderkonto må kobles til på nytt — det du ser under kan være utdatert. Koble den til på nytt fra skrivebordsappen.';

  @override
  String get spacesLoadFailed => 'Kunne ikke laste områder';

  @override
  String get noSpaces => 'Ingen områder';

  @override
  String get spacesEmptyDescription =>
      'Områder i dette arbeidsområdet vises her.';

  @override
  String get thread => 'Tråd';

  @override
  String get agentWorking => 'Agenten jobber';

  @override
  String get messagesLoadFailed => 'Kunne ikke laste meldinger';

  @override
  String get noMessagesYet => 'Ingen meldinger ennå';

  @override
  String get noMessagesDescription => 'Send en melding for å starte samtalen.';

  @override
  String get agentResponding => 'Agenten svarer';

  @override
  String get agentFinished => 'Agent ferdig';

  @override
  String attachmentsTooLarge(int count, String names) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$names er for store til å sendes herfra.',
      one: '$names er for stor til å sendes herfra.',
    );
    return '$_temp0';
  }

  @override
  String attachmentsTooLargeRelay(int count, String names) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$names er for store til å sendes over reléen herfra.',
      one: '$names er for stor til å sendes over reléen herfra.',
    );
    return '$_temp0';
  }

  @override
  String get attachmentUploadFailed =>
      'Kunne ikke laste opp vedlegget. Prøv på nytt.';

  @override
  String attachmentsLeftOut(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count vedlegg kunne ikke lastes opp og ble utelatt.',
      one: '1 vedlegg kunne ikke lastes opp og ble utelatt.',
    );
    return '$_temp0';
  }

  @override
  String get teammate => 'Kollega';

  @override
  String get agent => 'Agent';

  @override
  String get attachFile => 'Legg ved en fil';

  @override
  String get messageHint => 'Melding';

  @override
  String removeAttachment(String name) {
    return 'Fjern $name';
  }

  @override
  String get articlesLoadFailed => 'Kunne ikke laste artikler';

  @override
  String get noArticles => 'Ingen artikler';

  @override
  String get articlesEmptyDescription =>
      'Nye artikler vises her etter hvert som strømmene oppdateres.';

  @override
  String get unread => 'Ulest';

  @override
  String get allFeeds => 'Alle strømmer';

  @override
  String get save => 'Lagre';

  @override
  String get unsave => 'Fjern lagring';

  @override
  String get readFullArticle => 'Les hele artikkelen';

  @override
  String get ticketsLoadFailed => 'Kunne ikke laste saker';

  @override
  String get noTickets => 'Ingen saker';

  @override
  String get ticketsEmptyDescription =>
      'Saker i dette arbeidsområdet vises her.';

  @override
  String get all => 'Alle';

  @override
  String get ticket => 'Sak';

  @override
  String get ticketLoadFailed => 'Kunne ikke laste saken';

  @override
  String assignedTo(String name) {
    return 'Tildelt $name';
  }

  @override
  String get openInBrowser => 'Åpne i nettleser';

  @override
  String get status => 'Status';

  @override
  String get assign => 'Tildel';

  @override
  String get reassign => 'Tildel på nytt';

  @override
  String get noAgents => 'Ingen agenter';

  @override
  String get noAgentsDescription => 'Tildel en agent fra dette arbeidsområdet.';

  @override
  String get statusOpen => 'Åpen';

  @override
  String get statusInProgress => 'Pågår';

  @override
  String get statusBlocked => 'Blokkert';

  @override
  String get statusInReview => 'Til gjennomgang';

  @override
  String get statusDone => 'Ferdig';

  @override
  String get statusBacklog => 'Backlog';

  @override
  String get lensNeedsMe => 'Trenger meg';

  @override
  String get lensMine => 'Mine';

  @override
  String get prsLoadFailed => 'Kunne ikke laste pull requests';

  @override
  String get noOpenPullRequests => 'Ingen åpne pull requests';

  @override
  String get nothingWaitingOnReview => 'Ingenting venter på gjennomgangen din';

  @override
  String get noOwnOpenPullRequests => 'Du har ingen åpne pull requests';

  @override
  String get nothingBlocked => 'Ingenting er blokkert';

  @override
  String get prsEmptyDescription =>
      'Pull requests fra repoene i dette arbeidsområdet vises her.';

  @override
  String get refreshPullRequests => 'Oppdater pull requests';

  @override
  String get noForgeConnected =>
      'Ingen forge er tilkoblet på serveren, så ingen pull requests kan hentes. Koble til én fra skrivebordsappen.';

  @override
  String reposUnreadable(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count repoer kunne ikke leses.',
      one: '1 repo kunne ikke leses.',
    );
    return '$_temp0';
  }

  @override
  String reposNotReadable(String names) {
    return 'Ikke lesbare: $names';
  }

  @override
  String get installationSuspendedTitle =>
      'GitHub App-installasjonen er suspendert';

  @override
  String installationSuspendedBody(String names) {
    return 'Viser sist kjente data for $names. Gjenoppta installasjonen på GitHub, eller koble til et token som har tilgang.';
  }

  @override
  String installationSuspendedNotice(String names) {
    return 'GitHub App-installasjonen er suspendert. Viser sist kjente data for $names. Gjenoppta installasjonen på GitHub, eller koble til et token som har tilgang.';
  }

  @override
  String get draft => 'Utkast';

  @override
  String get merged => 'Sammenslått';

  @override
  String get closed => 'Lukket';

  @override
  String get open => 'Åpen';

  @override
  String get approved => 'Godkjent';

  @override
  String get changesRequested => 'Endringer forespurt';

  @override
  String get reviewRequired => 'Gjennomgang kreves';

  @override
  String get checksPassing => 'Sjekker består';

  @override
  String get checksFailing => 'Sjekker feiler';

  @override
  String get checksRunning => 'Sjekker kjører';

  @override
  String prSemanticLabel(String title, String status) {
    return '$title, $status';
  }

  @override
  String get pullRequest => 'Pull request';

  @override
  String get prLoadFailed => 'Kunne ikke laste denne pull requesten';

  @override
  String get openOnForge => 'Åpne på forge';

  @override
  String get requestChangesNeedsComment =>
      'Legg til en kommentar som forklarer hva som må endres.';

  @override
  String get conversation => 'Samtale';

  @override
  String get files => 'Filer';

  @override
  String get checks => 'Sjekker';

  @override
  String labelWithCount(String label, int count) {
    return '$label ($count)';
  }

  @override
  String filesCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count filer',
      one: '1 fil',
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
  String get conflicts => 'Konflikter';

  @override
  String get reviewers => 'Reviewere';

  @override
  String get noDescriptionNoComments =>
      'Ingen beskrivelse og ingen kommentarer ennå.';

  @override
  String get noChangedFiles => 'Ingen endrede filer.';

  @override
  String get noChecksReported => 'Ingen sjekker rapportert for head-commiten.';

  @override
  String get reviewCommentHint => 'Legg igjen en review-kommentar…';

  @override
  String get comment => 'Kommentar';

  @override
  String get commentPosted => 'Kommentar publisert';

  @override
  String get request => 'Be om';

  @override
  String get squashAndMerge => 'Squash og slå sammen';

  @override
  String noActionsAvailable(String status) {
    return '$status — ingen handlinger tilgjengelig.';
  }

  @override
  String get reviewApproved => 'godkjente';

  @override
  String get reviewRequestedChanges => 'ba om endringer';

  @override
  String get reviewCommented => 'gjennomgikk';

  @override
  String get reviewPending => 'ventende';

  @override
  String get unknownAuthor => 'ukjent';

  @override
  String hideDiffFor(String file) {
    return 'Skjul diffen for $file';
  }

  @override
  String showDiffFor(String file) {
    return 'Vis diffen for $file';
  }

  @override
  String get checkRunning => 'kjører';

  @override
  String get checkPassed => 'bestått';

  @override
  String get checkFailed => 'mislyktes';

  @override
  String get checkCancelled => 'avbrutt';

  @override
  String get checkSkipped => 'hoppet over';

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
      'Ingen tekst-diff for denne filen — den er binær, eller for stor til at forge kan returnere én.';

  @override
  String showRemainingLines(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Vis de gjenværende $count linjene',
      one: 'Vis den gjenværende linjen',
    );
    return '$_temp0';
  }

  @override
  String unchangedLines(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count uendrede linjer',
      one: '1 uendret linje',
    );
    return '$_temp0';
  }

  @override
  String get jumpToLatest => 'Hopp til siste';

  @override
  String get streaming => 'Strømmer';

  @override
  String get working => 'Jobber';

  @override
  String get input => 'Inndata';

  @override
  String get output => 'Utdata';

  @override
  String get now => 'nå';

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
  String get today => 'I dag';

  @override
  String get tomorrow => 'I morgen';

  @override
  String get yesterday => 'I går';

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
