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
  String get copyCommand => 'Kopier kommando';

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
  String get newSpaceFolder => 'Ny mappe';

  @override
  String get folderName => 'Mappenavn';

  @override
  String get renameSpaceFolder => 'Gi mappen nytt navn';

  @override
  String get deleteSpaceFolder => 'Slett mappe';

  @override
  String get moveSpaceToFolder => 'Flytt til mappe';

  @override
  String get removeSpaceFromFolder => 'Fjern fra mappe';

  @override
  String get spaceFolderActions => 'Mappehandlinger';

  @override
  String get deleteFolderWithSpacesWarning =>
      'Hvis du sletter områder permanent, fjernes meldingene og arbeidskatalogene deres for alle. Dette kan ikke angres.';

  @override
  String get deleteSpacesInFolder => 'Slett områdene i denne mappen permanent';

  @override
  String get deleteFolderAndSpaces => 'Slett mappe og områder';

  @override
  String get keepSpacesInFolder =>
      'Ellers blir områdene liggende utenfor mapper.';

  @override
  String get create => 'Opprett';

  @override
  String get otherSpaces => 'Andre områder';

  @override
  String get folderUpdateFailed => 'Kunne ikke oppdatere mappene';

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

  @override
  String get mobileConversations => 'Samtaler';

  @override
  String get mobileNewConversation => 'Ny samtale';

  @override
  String get mobileConversationName => 'Samtalenavn';

  @override
  String get mobileRename => 'Gi nytt navn';

  @override
  String get mobileManageSpace => 'Administrer område';

  @override
  String get mobileArchived => 'Arkivert';

  @override
  String get mobileSearchMessages => 'Søk i alle meldinger i dette området';

  @override
  String get mobileSearch => 'Søk';

  @override
  String get mobileNoResults => 'Ingen resultater';

  @override
  String get mobileReopen => 'Åpne på nytt';

  @override
  String get mobileArchive => 'Arkiver';

  @override
  String get mobileProgress => 'Fremdrift og kontekst';

  @override
  String get mobileReadFailed => 'Kunne ikke merke samtalen som lest';

  @override
  String get mobileSendFailed =>
      'Meldingen ble ikke sendt. Utkastet ditt er fortsatt her.';

  @override
  String get sentAttachmentUnavailable => 'Vedlegg utilgjengelig';

  @override
  String get sentAttachmentLoadFailed => 'Kunne ikke laste inn vedlegg';

  @override
  String get mobileActionFailed => 'Handling mislyktes';

  @override
  String get mobileRemove => 'Fjern';

  @override
  String get mobileLinkedMessage => 'Lenket melding';

  @override
  String get mobileOlderMessages => 'Eldre meldinger';

  @override
  String get mobileMessageActions => 'Meldingshandlinger';

  @override
  String get mobileOpenThread => 'Åpne tråd';

  @override
  String get mobileCopyLink => 'Kopier lenke';

  @override
  String get mobileStopRun => 'Stopp kjøring';

  @override
  String get mobileStopRunConfirm =>
      'Stoppe denne agentkjøringen? Arbeid som allerede er fullført, beholdes.';

  @override
  String get mobileControlUnsupported =>
      'Kjøringen er fullført eller støtter ikke denne handlingen.';

  @override
  String get mobilePauseRequested => 'Pause er bedt om ved neste turskifte';

  @override
  String get mobileResumed => 'Kjøringen er gjenopptatt';

  @override
  String get mobileStopRequested => 'Stopp er bedt om';

  @override
  String get mobileQueuedMessages => 'Kølagte meldinger';

  @override
  String get mobilePauseRun => 'Sett på pause ved neste tur';

  @override
  String get mobileResumeRun => 'Fortsett';

  @override
  String get mobileEditQueued => 'Rediger kølagt melding';

  @override
  String get mobileSteerNow => 'Styr nå';

  @override
  String get mobileMoveUp => 'Flytt opp';

  @override
  String get mobileMoveDown => 'Flytt ned';

  @override
  String get mobileQueueChanged =>
      'Køen er endret, eller kjøringen kan ikke styres underveis. Oppdater og prøv igjen.';

  @override
  String get mobileActivity => 'Aktivitet';

  @override
  String get mobilePermissions => 'Tillatelser og revisjonslogg';

  @override
  String get mobilePlans => 'Planer';

  @override
  String get mobileGoals => 'Overvåkede mål';

  @override
  String get mobileCredentials => 'Tilkoblinger og tilgangsopplysninger';

  @override
  String get mobileWorkspaceUnavailable =>
      'Arbeidsområdet er utilgjengelig, eller du har ikke lenger tilgang.';

  @override
  String get mobilePrReviewThreads => 'Gjennomgangstråder';

  @override
  String get mobilePrThreadsLoadFailed => 'Kunne ikke laste gjennomgangstråder';

  @override
  String get mobilePrNoReviewThreads => 'Ingen gjennomgangstråder i koden ennå';

  @override
  String get mobilePrCommentPermissionDenied =>
      'Du har ikke tillatelse til å kommentere i dette arkivet.';

  @override
  String get mobilePrPermissionChecking => 'Sjekker kommentartillatelser …';

  @override
  String get mobilePrPermissionLoadFailed =>
      'Kunne ikke sjekke kommentartillatelser. Prøv igjen for å kommentere.';

  @override
  String mobilePrThreadLine(String side, String line) {
    return '$side linje $line';
  }

  @override
  String get mobilePrOriginalSide => 'Opprinnelig';

  @override
  String get mobilePrSelectCommentLine => 'Velg en linje å kommentere';

  @override
  String get mobilePrUpdatedSide => 'Oppdatert';

  @override
  String get mobilePrThreadResolved => 'Løst';

  @override
  String get mobilePrReplyHint => 'Skriv et svar …';

  @override
  String get mobilePrCommentRequired => 'Skriv en kommentar før du publiserer.';

  @override
  String get mobilePrReply => 'Svar';

  @override
  String get mobilePrReopenThread => 'Åpne tråden igjen';

  @override
  String get mobilePrResolveThread => 'Løs tråden';

  @override
  String get mobilePrResolvePermissionDenied =>
      'Bare forfatteren av pull requesten eller noen med skrivetilgang kan løse denne tråden.';

  @override
  String mobilePrCommentOnLine(String side, String line) {
    return 'Kommenter på $side linje $line';
  }

  @override
  String get mobilePrInlineCommentHint => 'Skriv en kommentar i koden …';

  @override
  String get mobilePrPostInlineComment => 'Publiser kommentar';

  @override
  String get mobilePrCommentUnavailable =>
      'Kommentarer i koden er ikke tilgjengelige for denne pull requesten.';

  @override
  String get mobilePrPatchUnavailable =>
      'Kodeverten leverte ingen tekstbasert endringsoversikt for denne filen.';

  @override
  String get mobilePrNoPatchForFile =>
      'Endringsoversikten for denne filen er ikke tilgjengelig.';

  @override
  String get mobileTicketNew => 'Ny sak';

  @override
  String get mobileTicketCreate => 'Opprett sak';

  @override
  String get mobileTicketEdit => 'Rediger sak';

  @override
  String get mobileTicketTitle => 'Tittel';

  @override
  String get mobileTicketTitleRequired =>
      'Skriv inn en tittel for å lagre saken.';

  @override
  String get mobileTicketDescription => 'Beskrivelse';

  @override
  String get mobileTicketMarkdownHint => 'Legg til detaljer i Markdown';

  @override
  String get mobileTicketPriority => 'Prioritet';

  @override
  String get mobileTicketPriorityNone => 'Ingen prioritet';

  @override
  String get mobileTicketPriorityUrgent => 'Haster';

  @override
  String get mobileTicketPriorityHigh => 'Høy';

  @override
  String get mobileTicketPriorityMedium => 'Middels';

  @override
  String get mobileTicketPriorityLow => 'Lav';

  @override
  String get mobileTicketLabels => 'Etiketter';

  @override
  String get mobileTicketLabelsHint => 'Én etikett per linje';

  @override
  String get mobileTicketLabelsHelp => 'Skriv hver etikett på en egen linje.';

  @override
  String mobileTicketWorkspaceProvider(String provider) {
    return 'Registrert i $provider';
  }

  @override
  String get mobileTicketProviderLocal => 'Control Center';

  @override
  String get mobileTicketUnassigned => 'Ikke tildelt';

  @override
  String get mobileTicketAssignedFilter => 'Tildelt';

  @override
  String get mobileTicketAgentsLoadFailed => 'Kunne ikke laste agenter';

  @override
  String get mobileTicketSearch => 'Søk i saker';

  @override
  String get mobileTicketSearchHint =>
      'Tittel, nøkkel, beskrivelse, etikett eller ansvarlig';

  @override
  String get mobileTicketClearSearch => 'Tøm sakssøk';

  @override
  String get mobileTicketNoMatches => 'Ingen treff blant sakene';

  @override
  String get mobileTicketAdjustFilters =>
      'Prøv et annet søk eller endre filtrene.';

  @override
  String get mobileTicketClearFilters => 'Fjern filtre';

  @override
  String get mobileTicketNotFound => 'Fant ikke saken';

  @override
  String get mobileTicketNotFoundDescription =>
      'Saken kan være slettet eller flyttet ut av dette arbeidsområdet.';

  @override
  String get mobileTicketWorkspaceChanged =>
      'Arbeidsområdet er endret. Gå tilbake til det gjeldende arbeidsområdet før du lagrer.';

  @override
  String get mobileTicketOpenLinkedSpace => 'Åpne tilknyttet område';

  @override
  String get mobileTicketReadOnly =>
      'Du må være medlem av arbeidsområdet for å endre saker.';

  @override
  String get permissionTitle => 'Tillatelser';

  @override
  String get permissionWorkspaceFailed => 'Kunne ikke laste arbeidsområdet';

  @override
  String get permissionNoWorkspace =>
      'Velg et arbeidsområde for å se tillatelser.';

  @override
  String get permissionLoading => 'Laster tillatelser …';

  @override
  String get permissionScopeDescription =>
      'Se hvordan hver handling avgjøres på dette nivået. Regler for arbeidsområdet kan arves av agenter og områder.';

  @override
  String get permissionScope => 'Regelomfang';

  @override
  String get permissionWorkspaceScope => 'Arbeidsområde';

  @override
  String get permissionAgentScope => 'Agent';

  @override
  String get permissionSpaceScope => 'Område';

  @override
  String get permissionAgentContext => 'Agent som handler i dette området';

  @override
  String get permissionNoAgentContext => 'Ingen agent valgt';

  @override
  String get permissionTargetsFailed =>
      'Kunne ikke laste mål for regelomfanget';

  @override
  String get permissionNoTargets =>
      'Ingen mål er tilgjengelige på dette nivået.';

  @override
  String get permissionRoleFailed =>
      'Kunne ikke bekrefte rollen din i arbeidsområdet';

  @override
  String get permissionMemberRequired =>
      'Du må være medlem av arbeidsområdet for å se reglene.';

  @override
  String get permissionRulesFailed => 'Kunne ikke laste reglene';

  @override
  String get permissionAuditAdminOnly =>
      'Autorisasjonshistorikk er bare tilgjengelig for administratorer av arbeidsområdet.';

  @override
  String get permissionAllow => 'Tillat';

  @override
  String get permissionAsk => 'Spør først';

  @override
  String get permissionDeny => 'Nekt';

  @override
  String get permissionFileDelete => 'Slett filer';

  @override
  String get permissionFileWriteOutsideWorktree => 'Skriv utenfor arbeidstreet';

  @override
  String get permissionGitCommit => 'Opprett commit';

  @override
  String get permissionGitPush => 'Push committer';

  @override
  String get permissionPrCreate => 'Opprett pull requests';

  @override
  String get permissionPrPublish => 'Publiser pull requests';

  @override
  String get permissionVendorSyncWrite =>
      'Skriv til et eksternt oppfølgingssystem';

  @override
  String get permissionNetworkEgress => 'Få tilgang til nettverket';

  @override
  String get permissionSecretAccess => 'Få tilgang til hemmeligheter';

  @override
  String get permissionPackageInstall => 'Installer pakker';

  @override
  String get permissionProcessSpawn => 'Start prosesser';

  @override
  String get permissionWorkspaceMutation => 'Endre arbeidsområdet';

  @override
  String get permissionEnclosureControl => 'Kontroller det isolerte miljøet';

  @override
  String get permissionChangeFailed => 'Kunne ikke endre regelen';

  @override
  String get permissionEffectiveDescription =>
      'Gjelder på dette nivået uten handlingsargumenter. Betingede tillatelser nedenfor gjelder bare forespørsler som oppfyller vilkårene. Serveren tar den endelige avgjørelsen.';

  @override
  String get permissionSpaceAgentNote =>
      'Ingen agent valgt. Agentspesifikke regler vises ikke før du velger en agent ovenfor.';

  @override
  String get permissionScopedGrants => 'Regler på dette nivået';

  @override
  String get permissionModePreset => 'Modusforhåndsvalg';

  @override
  String get permissionBuiltInDefault => 'Innebygd standard';

  @override
  String get permissionRemembered => 'Lagret godkjenning';

  @override
  String get permissionSource => 'Kilde';

  @override
  String permissionSetAtThisScope(String source) {
    return '$source · angitt her';
  }

  @override
  String permissionInheritedFrom(String source) {
    return '$source · arvet';
  }

  @override
  String permissionExpiresAt(String date) {
    return 'Utløper $date';
  }

  @override
  String get permissionSetHere => 'Angi en regel her';

  @override
  String get permissionRevokeBeforeEdit =>
      'Tilbakekall den avgrensede eller lagrede regelen før du angir en generell regel for denne handlingen.';

  @override
  String get permissionConfirmRevoke => 'Bekreft tilbakekalling';

  @override
  String get permissionRevokeRule => 'Tilbakekall regel';

  @override
  String permissionCommandPrefix(String prefix) {
    return 'Kommandoprefiks: $prefix';
  }

  @override
  String get permissionNoExpiry => 'Utløper ikke';

  @override
  String get permissionExpired => 'Utløpt';

  @override
  String get permissionExplicitRule => 'Eksplisitt regel';

  @override
  String get permissionEnforcementAdvisory =>
      'Veiledende: «Spør først»-regler loggføres uten å spørre';

  @override
  String get permissionEnforcementSoft =>
      'Myk håndheving: overstyring krever autorisasjon';

  @override
  String get permissionEnforcementHard =>
      'Streng håndheving: kan ikke overstyres';

  @override
  String permissionPaths(String paths) {
    return 'Filstier: $paths';
  }

  @override
  String permissionRefs(String refs) {
    return 'Git-referanser: $refs';
  }

  @override
  String permissionHosts(String hosts) {
    return 'Verter: $hosts';
  }

  @override
  String permissionCommands(String commands) {
    return 'Kommandoer: $commands';
  }

  @override
  String permissionMaxCount(String count) {
    return 'Maksimalt antall: $count';
  }

  @override
  String permissionMaxCents(String cents) {
    return 'Maksimalt antall cent: $cents';
  }

  @override
  String get permissionAuditHeading => 'Autorisasjonshistorikk';

  @override
  String get permissionAuditDescription =>
      'Nylige avgjørelser registrert av serveren. Bare administratorer kan se loggen eller kontrollere hashkjeden.';

  @override
  String permissionOnBehalfOf(String user) {
    return 'på vegne av $user';
  }

  @override
  String get permissionPrompted => 'Menneskelig godkjenning forespurt';

  @override
  String get permissionVerifyChain => 'Kontroller loggkjeden';

  @override
  String get permissionVerifyFailed => 'Kunne ikke kontrollere loggkjeden';

  @override
  String permissionChainIntact(String count) {
    return 'Kjeden er intakt · $count oppføringer kontrollert';
  }

  @override
  String permissionChainBroken(String sequence, String reason) {
    return 'Kjeden er brutt ved oppføring $sequence: $reason';
  }

  @override
  String get permissionAuditEmpty =>
      'Ingen autorisasjonsavgjørelser er registrert ennå.';

  @override
  String get permissionAuditFailed =>
      'Kunne ikke laste autorisasjonshistorikken';

  @override
  String get mobilePlansLoadFailed => 'Kunne ikke laste planer';

  @override
  String get mobilePlansEmpty => 'Ingen planer ennå';

  @override
  String get mobilePlansEmptyDescription =>
      'Planer sendt inn av agenter vises her for gjennomgang.';

  @override
  String get mobilePlanTitle => 'Plan';

  @override
  String get mobilePlanMissing =>
      'Denne planen er ikke lenger tilgjengelig i dette arbeidsområdet.';

  @override
  String mobilePlanStepCount(int count) {
    return '$count trinn';
  }

  @override
  String get mobilePlanDraft => 'Utkast';

  @override
  String get mobilePlanProposed => 'Venter på gjennomgang';

  @override
  String get mobilePlanApproved => 'Godkjent';

  @override
  String get mobilePlanRejected => 'Avvist';

  @override
  String get mobilePlanSuperseded => 'Erstattet';

  @override
  String get mobilePlanExecuting => 'Kjører';

  @override
  String get mobilePlanSynthesizing => 'Syntetiserer';

  @override
  String get mobilePlanCompleted => 'Fullført';

  @override
  String get mobilePlanFailed => 'Mislyktes';

  @override
  String get mobilePlanCancelled => 'Avbrutt';

  @override
  String mobilePlanRevision(String revision) {
    return 'Revisjon $revision';
  }

  @override
  String get mobilePlanSteps => 'Trinn';

  @override
  String get mobilePlanNoSteps => 'Ingen trinn ble sendt inn for denne planen.';

  @override
  String get mobilePlanAssumptions => 'Avklaringer';

  @override
  String mobilePlanDependsOn(String keys) {
    return 'Avhenger av $keys';
  }

  @override
  String mobilePlanStepCost(String cost) {
    return 'Anslått til opptil $cost';
  }

  @override
  String get mobilePlanSelect => 'Velg';

  @override
  String get mobilePlanSelected => 'Valgt';

  @override
  String get mobilePlanEstimate => 'Beregn kostnad';

  @override
  String get mobilePlanEstimateRequired =>
      'Beregn kostnaden før du godkjenner kjøring.';

  @override
  String mobilePlanEstimatedCost(String low, String high) {
    return 'Anslått kostnad: $low–$high';
  }

  @override
  String get mobilePlanCostUnknown => 'ikke tilgjengelig';

  @override
  String get mobilePlanNoHardCap => 'ingen øvre grense';

  @override
  String get mobilePlanExceedsBudget =>
      'Kostnadsanslaget overstiger budsjettet. Se gjennom før du godkjenner.';

  @override
  String get mobilePlanPartialEstimate =>
      'Anslaget gjelder hele planen. Valgte trinn kan koste mindre.';

  @override
  String get mobilePlanConfirmAll => 'Starte hele planen?';

  @override
  String get mobilePlanConfirmSelected => 'Starte valgte trinn?';

  @override
  String mobilePlanExecutionConfirmation(String cost, String cap) {
    return 'Godkjenning starter kjøringen og kan medføre kostnader. Høyeste anslåtte kostnad: $cost. Kostnadsgrense: $cap.';
  }

  @override
  String get mobilePlanApproveAll => 'Godkjenn alle og kjør';

  @override
  String get mobilePlanApproveSelected => 'Godkjenn valgte og kjør';

  @override
  String get mobilePlanWiden => 'Godkjenn flere trinn';

  @override
  String mobilePlanWidenConfirm(String count, String cap) {
    return 'Frigi $count trinn til kjøring? De kan medføre kostnader. Gjeldende kostnadsgrense for kjøringen: $cap.';
  }

  @override
  String get mobilePlanChanged =>
      'Planen ble endret under gjennomgangen. Åpne den nyeste revisjonen og beregn kostnaden på nytt.';

  @override
  String get mobilePlanReject => 'Avvis plan';

  @override
  String get mobilePlanRejectConfirm =>
      'Avvise denne planen? Den vil ikke bli kjørt.';

  @override
  String get mobilePlanStop => 'Stopp kjøring';

  @override
  String get mobilePlanStopConfirm =>
      'Stoppe kjøringen av denne planen? Fullført arbeid blir ikke angret.';

  @override
  String mobilePlanRunId(String runId) {
    return 'Kjøring: $runId';
  }

  @override
  String get mobilePlanExecutionPending =>
      'Godkjenning mottatt. Venter på kjøringsoppføringen …';

  @override
  String mobilePlanProgress(String completed, String total) {
    return '$completed av $total trinn fullført';
  }

  @override
  String get mobilePlanOpenConversation => 'Åpne samtale';

  @override
  String get mobileGoalsTitle => 'Overvåkede mål';

  @override
  String get mobileGoalsLoadFailed => 'Kunne ikke laste overvåkede mål';

  @override
  String get mobileGoalsEmpty => 'Ingen overvåkede mål ennå';

  @override
  String get mobileGoalsEmptyDescription =>
      'Start et mål i et område, eller send /goal i en samtale.';

  @override
  String get mobileGoalMissing =>
      'Dette målet er ikke lenger tilgjengelig i dette arbeidsområdet.';

  @override
  String get mobileGoalActive => 'Aktiv';

  @override
  String get mobileGoalPaused => 'På pause';

  @override
  String get mobileGoalCompleted => 'Fullført';

  @override
  String get mobileGoalFailed => 'Mislyktes';

  @override
  String get mobileGoalCancelled => 'Avbrutt';

  @override
  String get mobileGoalBudgetExhausted => 'Budsjettet er brukt opp';

  @override
  String get mobileGoalGoal => 'Mål';

  @override
  String get mobileGoalLoop => 'Løkke';

  @override
  String mobileGoalKind(String kind) {
    return 'Type: $kind';
  }

  @override
  String mobileGoalRuns(String count) {
    return '$count kjøringer';
  }

  @override
  String get mobileGoalNoRunLimit => 'ubegrenset';

  @override
  String mobileGoalProgress(
    String runs,
    String maxRuns,
    String spent,
    String cap,
  ) {
    return 'Kjøringer: $runs / $maxRuns · Brukt: $spent / $cap';
  }

  @override
  String mobileGoalDeadline(String date) {
    return 'Frist: $date';
  }

  @override
  String mobileGoalFailures(String count) {
    return 'Mislykkede kjøringer på rad: $count';
  }

  @override
  String get mobileGoalSummary => 'Oppsummering av fullføring';

  @override
  String get mobileGoalFailedDescription =>
      'Overvåkeren stoppet etter gjentatte mislykkede kjøringer. Se samtalen for detaljer.';

  @override
  String get mobileGoalBudgetWall =>
      'Fristen eller grensen for antall kjøringer er nådd. Målet kan ikke fortsettes ved å øke kostnadsgrensen.';

  @override
  String get mobileGoalPause => 'Sett mål på pause';

  @override
  String get mobileGoalResume => 'Fortsett mål';

  @override
  String get mobileGoalStop => 'Avbryt mål';

  @override
  String get mobileGoalStopConfirm =>
      'Avbryte dette overvåkede målet permanent? Det kan ikke fortsettes.';

  @override
  String get mobileGoalRaiseBudget => 'Øk budsjettet og fortsett';

  @override
  String mobileGoalRaiseTo(String amount) {
    return 'Øk budsjettet til $amount og fortsett';
  }

  @override
  String mobileGoalRaiseConfirm(String oldCap, String newCap) {
    return 'Øke kostnadsgrensen for dette målet fra $oldCap til $newCap og fortsette å bruke penger?';
  }

  @override
  String get mobileGoalOpenConversation => 'Åpne målsamtalen';

  @override
  String get mobileGoalCreate => 'Start overvåket mål';

  @override
  String get mobileGoalChooseSpace => 'Kjør i område';

  @override
  String get mobileGoalNoSpaces => 'Opprett et område før du starter et mål.';

  @override
  String get mobileGoalChooseAgent => 'Kjør med agent';

  @override
  String get mobileGoalNoAgents =>
      'Legg til en aktiv agent før du starter et mål.';

  @override
  String mobileGoalSelectedAgent(String name) {
    return '$name valgt';
  }

  @override
  String get mobileGoalObjectiveHint =>
      'Hvilket resultat skal agenten jobbe mot?';

  @override
  String get mobileGoalBudgetUsd => 'Kostnadsgrense (USD)';

  @override
  String get mobileGoalCreateInvalid =>
      'Velg et område og en agent, angi et mål og sett en kostnadsgrense i USD som er større enn null.';

  @override
  String mobileGoalCreateConfirm(String cap) {
    return 'Starte et overvåket mål med en maksimal kostnad på $cap? Agenten kan starte umiddelbart.';
  }

  @override
  String get mobileGoalUnavailable =>
      'Tilkoblingen til serveren er ikke klar. Prøv igjen når tilkoblingen er gjenopprettet.';

  @override
  String get mobileGoalConversationMissing =>
      'Den valgte samtalen er ikke lenger tilgjengelig i dette arbeidsområdet.';

  @override
  String get mobileGoalCreateSent =>
      'Målet er startet. Overvåkerens status vises i denne listen.';

  @override
  String get mobileGoalStartRefused =>
      'Ingen målkjøring ble startet. Se samtalen for overvåkerens begrunnelse.';

  @override
  String mobileGoalSelectedSpace(String name) {
    return '$name valgt';
  }

  @override
  String get requestUnavailable =>
      'Denne forespørselen er ikke lenger tilgjengelig i det aktive arbeidsområdet.';

  @override
  String get requestAlreadyResolved => 'Denne forespørselen er allerede løst.';

  @override
  String get inboxCredentialsBlocked =>
      'Tilgangsopplysninger blokkerer kjøringer';

  @override
  String get inboxSyncFailures => 'Mislykket synkronisering med leverandører';

  @override
  String get inboxConfigureCredentials => 'Konfigurer tilgangsopplysninger';

  @override
  String get openTicket => 'Åpne sak';

  @override
  String get activityTitle => 'Aktivitet';

  @override
  String get activityClearAll => 'Fjern all aktivitet';

  @override
  String get activityClearConfirm =>
      'Dette skjuler all aktivitet som hittil er registrert for deg, på alle enheter. Ny aktivitet vises fortsatt.';

  @override
  String get activityMarkAllRead => 'Merk alle som lest';

  @override
  String get activityMarkAllConfirm =>
      'Merke all aktivitet i dette arbeidsområdet som lest på alle enhetene dine?';

  @override
  String get activityMarkRead => 'Merk som lest';

  @override
  String get activityMarkUnread => 'Merk som ulest';

  @override
  String get activityDismiss => 'Avvis';

  @override
  String get activityResolved => 'Løst';

  @override
  String get activityOpen => 'Åpen';

  @override
  String get activityEmpty => 'Ingen aktivitet ennå';

  @override
  String get activityLoadFailed => 'Kunne ikke laste aktivitet';

  @override
  String get activityAgentWaiting => 'Agenten trenger innspill';

  @override
  String get activityAgentBlocked => 'Agenthandling blokkert';

  @override
  String get activityMessage => 'Ny melding';

  @override
  String get activityPullRequest => 'Oppdatering av pull request';

  @override
  String get activityTicket => 'Sak oppdatert';

  @override
  String get activityMeeting => 'Møte oppdatert';

  @override
  String get activityCalendar => 'Kalendertilkobling';

  @override
  String get activityRig => 'Stasjon oppdatert';

  @override
  String get activityEvent => 'Oppdater';

  @override
  String get activityPrReady => 'Pull request klar til sammenslåing';

  @override
  String get activityPrBlocked => 'Sammenslåing av pull request blokkert';

  @override
  String get activityPrApproved => 'Pull request godkjent';

  @override
  String get activityPrChanges => 'Endringer forespurt';

  @override
  String get activityPrChecksFailed => 'Kontroller for pull request mislyktes';

  @override
  String get activityPrChecksRecovered =>
      'Kontroller for pull request fungerer igjen';

  @override
  String get activityPrComment => 'Kommentar til pull request';

  @override
  String get activityPrPublished => 'Pull request publisert';

  @override
  String get activityPrMerged => 'Pull request sammenslått';

  @override
  String get activityPrMentioned => 'Nevnt i en pull request';

  @override
  String get activityPrReviewRequested => 'Gjennomgang forespurt';

  @override
  String get activityPrReviewStale => 'Gjennomgangen må oppdateres';

  @override
  String get activityTicketAssigned => 'Sak tildelt';

  @override
  String get activityTicketChanged => 'Sakstatus endret';

  @override
  String get activityMeetingSoon => 'Møte starter snart';

  @override
  String get activityCalendarExpired => 'Kalendertilkoblingen er utløpt';

  @override
  String get activityRigControl => 'Kontroll over stasjonen endret';

  @override
  String get activityRigClosed => 'Stasjon stoppet';

  @override
  String get mobileSpacesSearch => 'Søk i områder';

  @override
  String get mobileSpacesArchived => 'Arkivert';

  @override
  String get mobileSpacesActive => 'Aktiv';

  @override
  String get mobileSpacesNew => 'Nytt område';

  @override
  String get mobileSpacesManage => 'Administrer område';

  @override
  String get mobileSpacesName => 'Områdenavn';

  @override
  String get mobileSpacesAgents => 'Agenter';

  @override
  String get mobileSpacesMembers => 'Personer';

  @override
  String get mobileSpacesRepos => 'Arkiv';

  @override
  String get mobileSpacesAllRepos => 'Alle tilknyttede arkiver';

  @override
  String get mobileSpacesNoRepos => 'Ingen arkiver';

  @override
  String get mobileSpacesBaseBranch => 'Basisgren (valgfritt)';

  @override
  String get mobileSpacesDefaultBranch => 'Standardgren';

  @override
  String get mobileSpacesMode => 'Modus';

  @override
  String get mobileSpacesModeChat => 'Chat';

  @override
  String get mobileSpacesModeReview => 'Gjennomgang (skrivebeskyttet)';

  @override
  String get mobileSpacesModePlan => 'Plan (skrivebeskyttet)';

  @override
  String get mobileSpacesModeOrchestrate => 'Orkestrer';

  @override
  String get mobileSpacesAutonomy => 'Overstyr autonomi';

  @override
  String get mobileSpacesAutonomyInherited => 'Arvet';

  @override
  String get mobileSpacesAutonomyPropose => 'Bare foreslå';

  @override
  String get mobileSpacesAutonomyApproval => 'Handle med godkjenning';

  @override
  String get mobileSpacesAutonomyFreely => 'Handle fritt';

  @override
  String get mobileSpacesAutonomyNotice =>
      'En overstyring kan ikke omgå forespørsler om godkjenning eller avslag i handlingsreglene. Bare administratorer for arbeidsområdet kan endre den.';

  @override
  String get mobileSpacesArchive => 'Arkiver område';

  @override
  String get mobileSpacesReopen => 'Åpne området på nytt';

  @override
  String get mobileSpacesSave => 'Lagre endringer';

  @override
  String get mobileSpacesCreate => 'Opprett område';

  @override
  String get mobileSpacesOperationFailed => 'Kunne ikke oppdatere området';

  @override
  String get mobileSpacesMissing => 'Fant ikke området i dette arbeidsområdet';

  @override
  String get mobileSpacesEmptyName => 'Skriv inn et områdenavn';

  @override
  String get mobileSpacesNoMatches => 'Ingen områder funnet';

  @override
  String get mobileSpacesUnread => 'Ulest agentsvar';

  @override
  String get mobileSpacesNeedsInput => 'Trenger svar fra deg';

  @override
  String get mobileSpacesRunning => 'Agenten kjører';

  @override
  String get mobileSpacesNoAgents => 'Ingen agenter i dette arbeidsområdet';

  @override
  String get mobileSpacesNoMembers => 'Ingen andre personer i arbeidsområdet';

  @override
  String get mobileSpacesRepoError => 'Kunne ikke laste inn arkiver';

  @override
  String get mobileSpacesRetry => 'Prøv på nytt';

  @override
  String get mobileSpacesBranchUnavailable =>
      'Velg eller skriv inn en basisgren når du oppretter et område. Basisgrenen kan ikke endres senere.';

  @override
  String get mobileSpacesArchivedEmpty => 'Ingen arkiverte områder';

  @override
  String get mobileSpacesAllRepoWarning =>
      'Nye arkiver som knyttes til arbeidsområdet, blir også inkludert i dette området.';

  @override
  String get mobileSpacesCreatedRetry =>
      'Området er opprettet. Prøv å legge til personer på nytt, eller åpne siden for administrasjon.';

  @override
  String get progressTitle => 'Fremdrift';

  @override
  String get progressConversation => 'Samtale';

  @override
  String get progressLoadFailed => 'Kunne ikke laste inn fremdrift';

  @override
  String get progressUnavailable => 'Samtalen er utilgjengelig';

  @override
  String get progressUnavailableDescription =>
      'Denne samtalen er ikke i det aktive arbeidsområdet og området. Gå tilbake til området den tilhører for å fortsette.';

  @override
  String get progressSaveFailed => 'Kunne ikke oppdatere fremdrift';

  @override
  String get progressGoal => 'Mål';

  @override
  String get progressNoGoal => 'Ingen mål satt';

  @override
  String get progressSetGoal => 'Sett mål';

  @override
  String get progressEditGoal => 'Rediger mål';

  @override
  String get progressClearGoal => 'Fjern mål';

  @override
  String get progressGoalRequired => 'Skriv inn et mål før du lagrer.';

  @override
  String get progressTodos => 'Oppgaver';

  @override
  String get transcriptToolTodos => 'Oppgaver';

  @override
  String get transcriptToolSearchMemory => 'Søk i minnet';

  @override
  String get transcriptToolRenderMedia => 'Vis medier';

  @override
  String get progressNoTodos => 'Ingen oppgaver ennå';

  @override
  String get progressNewTodo => 'Ny oppgave';

  @override
  String get progressAddTodo => 'Legg til oppgave';

  @override
  String get progressEditTodo => 'Rediger oppgave';

  @override
  String get progressTodoRequired => 'Skriv inn en oppgave før du lagrer.';

  @override
  String get progressTodoNoLongerExists =>
      'Oppgaven er fjernet. Last inn listen på nytt og prøv igjen.';

  @override
  String get progressWorkspaceChanged =>
      'Det aktive arbeidsområdet er endret. Gå tilbake til denne samtalen og prøv igjen.';

  @override
  String progressRemoveTodo(String name) {
    return 'Fjern oppgaven $name';
  }

  @override
  String get progressPending => 'Venter';

  @override
  String get progressInProgress => 'Pågår';

  @override
  String get progressCompleted => 'Fullført';

  @override
  String get progressMoveUp => 'Flytt oppgaven opp';

  @override
  String get progressMoveDown => 'Flytt oppgaven ned';

  @override
  String get progressRunTree => 'Agentkjøringer';

  @override
  String get progressNoRuns => 'Ingen kjøringer i denne samtalen ennå';

  @override
  String get progressRunning => 'Kjører';

  @override
  String get progressFailed => 'Mislyktes';

  @override
  String get progressUnknown => 'Ukjent';

  @override
  String get progressHealthy => 'Aktiv';

  @override
  String get progressBlocked => 'Blokkert';

  @override
  String get progressLooping => 'Går i løkke';

  @override
  String get progressStalled => 'Står fast';

  @override
  String get progressDead => 'Stoppet uventet';

  @override
  String get progressQuiet => 'Ingen utdata ennå';

  @override
  String get progressCostReported => 'Kostnad oppgitt av leverandøren';

  @override
  String get progressCostNotional =>
      'Veiledende abonnementspris, ikke en faktura';

  @override
  String get progressCostMixed => 'Kostnader fra ulike kilder';

  @override
  String get progressCostEstimated => 'Anslått kostnad';

  @override
  String progressDurationSeconds(String seconds) {
    return '${seconds}s';
  }

  @override
  String progressRunDetails(String model, String duration, String cost) {
    return 'Modell: $model · Tid: $duration · Kostnad: $cost';
  }

  @override
  String progressStartedAt(String time) {
    return 'Startet $time';
  }

  @override
  String progressLiveness(String state) {
    return 'Tilstand: $state';
  }

  @override
  String progressRunTokens(String input, String output) {
    return 'Inndata: $input · Utdata: $output tokener';
  }

  @override
  String get progressOutputPreviewLimited =>
      'Bare de første 6 000 tegnene i strukturert utdata vises.';

  @override
  String progressRetryOf(String runId) {
    return 'Nytt forsøk på kjøring $runId';
  }

  @override
  String get progressContext => 'Kontekst og grenser';

  @override
  String get progressNoAgent => 'Ingen agent å undersøke';

  @override
  String progressContextReading(String used, String window) {
    return '$used / $window tokener';
  }

  @override
  String get progressMeasured =>
      'Kontekst oppgitt av leverandøren ved siste kall';

  @override
  String get progressEstimated =>
      'Anslått fra lagret samtale og vedvarende kontekst';

  @override
  String get progressContextUnknown => 'Kontekstbruk er ikke oppgitt ennå';

  @override
  String progressContextPercent(String percent) {
    return '$percent % av kontekstvinduet';
  }

  @override
  String progressMonthlyBudget(String amount) {
    return 'Angitt månedsgrense for agenten: $amount';
  }

  @override
  String progressConversationTokens(String tokens) {
    return 'Lagret aktiv samtale: anslagsvis $tokens tokener';
  }

  @override
  String progressInspectionFor(String agent, String model) {
    return 'Vedvarende kontekst for $agent · $model';
  }

  @override
  String get progressContextSystem => 'Systemprompt';

  @override
  String get progressContextRules => 'Regler';

  @override
  String get progressContextSkills => 'Ferdigheter';

  @override
  String get progressContextTools => 'Verktøydefinisjoner';

  @override
  String get progressContextMcp => 'MCP-verktøy';

  @override
  String get progressContextDeferred => 'Utsatte verktøy';

  @override
  String get progressContextSubagents => 'Underagenter';

  @override
  String get progressContextRunner => 'Ekstern kjører';

  @override
  String get progressContextMemory => 'Minne';

  @override
  String get progressContextHistory => 'Samtalehistorikk';

  @override
  String progressContextSegment(String label, String tokens) {
    return '$label · $tokens tokener';
  }

  @override
  String progressContextPart(String title, String tokens) {
    return '$title · $tokens tokener';
  }

  @override
  String get progressOutputs => 'Nylige utdata';

  @override
  String get progressNoOutputs => 'Ingen nylige utdata fra agenter';

  @override
  String get progressStructuredOutputsAbove =>
      'Strukturerte utdata vises i agentkjøringene over.';

  @override
  String get progressRecentOutputsOnly =>
      'Bare nylige meldinger vises. Åpne samtalen for å se eldre arbeid.';

  @override
  String get progressPlan => 'Plan';

  @override
  String get progressArtifact => 'Artefakt';

  @override
  String get progressResult => 'Resultat';

  @override
  String get progressHideArtifact => 'Skjul artefakt';

  @override
  String get progressReadArtifact => 'Les artefakt';

  @override
  String get progressArtifactUnavailable =>
      'Artefakten er ikke lenger tilgjengelig';

  @override
  String get progressArtifactPreviewLimited =>
      'Viser en begrenset forhåndsvisning av artefakten.';

  @override
  String get progressDiagramSource => 'Diagramkilde';

  @override
  String progressOpenAttachment(String name) {
    return 'Åpne $name';
  }

  @override
  String get progressOpenPlan => 'Åpne plan';

  @override
  String progressOpenDiff(String label) {
    return 'Se gjennom endrede filer: $label';
  }

  @override
  String get progressViewMessage => 'Vis melding';

  @override
  String get pushTitle => 'Bakgrunnsvarsler';

  @override
  String get pushIntro =>
      'Få et privat varsel når noe trenger oppmerksomheten din, også når appen er lukket. Detaljene blir værende i den krypterte tilkoblingen.';

  @override
  String get pushLoading => 'Sjekker varslingsinnstillinger …';

  @override
  String get pushError =>
      'Kunne ikke oppdatere varsler. Sjekk tilkoblingen og prøv på nytt.';

  @override
  String get pushEnable => 'Slå på varslinger';

  @override
  String get pushDisable => 'Slå av varslinger';

  @override
  String get pushQuiet => 'Sett varsler på pause på denne enheten';

  @override
  String get pushCategories => 'Varsle meg om';

  @override
  String get pushCategoryAgents => 'Agenter';

  @override
  String get pushCategoryMessages => 'Meldinger';

  @override
  String get pushCategoryPullRequests => 'Pull requests';

  @override
  String get pushCategoryTickets => 'Saker';

  @override
  String get pushCategoryCalendar => 'Kalender';

  @override
  String get pushCategoryMachines => 'Maskiner';

  @override
  String get pushSecureOrigin => 'Varslinger krever HTTPS.';

  @override
  String get pushInstallIos =>
      'På iPhone eller iPad må du legge appen til på Hjem-skjermen og åpne den derfra for å slå på varslinger.';

  @override
  String get pushUnsupported =>
      'Denne nettleseren støtter ikke bakgrunnsvarsler.';

  @override
  String get pushDenied =>
      'Nettleseren melder at varslinger er blokkert. Kontroller tillatelsen for dette nettstedet og varslingsinnstillingene i nettleseren eller på enheten, og oppdater siden.';

  @override
  String get pushOsHint =>
      'Nettleseren trenger også tillatelse til å vise varsler i enhetens systeminnstillinger.';

  @override
  String get pushServiceUnavailable =>
      'Nettleserens push-tjeneste avviste abonnementet. Enkelte nettlesere, som Brave, slår den av som standard: se etter et valg for push-meldinger i nettleserens personverninnstillinger, og prøv igjen.';

  @override
  String get pushWorkerUnavailable =>
      'Varslingstjenesten kunne ikke starte i denne nettleseren. Last inn siden på nytt og prøv igjen.';

  @override
  String get pushResubscribe => 'Koble til varslinger på nytt';

  @override
  String get pushStatusEnabled => 'Varslinger er på for denne enheten.';

  @override
  String get pushStatusDisabled => 'Varslinger er av for denne enheten.';

  @override
  String get credentialsTitle => 'Tilkoblinger og tilgangsopplysninger';

  @override
  String get credentialsIntro =>
      'Koble til kontoene som kjøringer og integrasjoner bruker. Hemmeligheter lagres på serveren din, ikke på denne telefonen.';

  @override
  String get credentialsModelProviders => 'Modellleverandører';

  @override
  String get credentialsOwnerOnly =>
      'Bare servereieren kan legge til eller fjerne tilgangsopplysninger for modellleverandører og logge inn hos dem. Disse nøklene deles mellom arbeidsområder.';

  @override
  String get credentialsContactOwner =>
      'Be servereieren koble til leverandøren som den blokkerte kjøringen trenger.';

  @override
  String get credentialsClaudeCode => 'Claude Code';

  @override
  String get credentialsClaudeHostOnly =>
      'Claude Code logger inn via kommandolinjen på verten. Be servereieren fullføre eller fornye kontopåloggingen i terminalen på verten. Det kan ikke gjøres fra denne telefonen.';

  @override
  String get credentialsYourForgeAccounts => 'Dine kontoer hos kodeverter';

  @override
  String get credentialsYourTicketingAccount => 'Din konto for saksbehandling';

  @override
  String get credentialsLocalTicketsNoLogin =>
      'Lokale saker krever ikke pålogging. Koble til Linear her hvis arbeidsområdet ditt bruker Linear.';

  @override
  String get credentialsMembershipRequired =>
      'Bli med i et arbeidsområde for å administrere tilgangsopplysninger for kodeverter eller saksbehandling. Be en administrator for arbeidsområdet om tilgang.';

  @override
  String get credentialsSwitchWorkspace =>
      'Denne lenken peker til et annet arbeidsområde. Bytt til det arbeidsområdet før du endrer tilgangsopplysninger.';

  @override
  String get credentialsReturnToInbox =>
      'Gå tilbake til innboksen for å prøve den blokkerte kjøringen på nytt når tilgangsopplysningene er koblet til. Verten sjekker også parkerte kjøringer automatisk.';

  @override
  String get credentialsLoadFailed =>
      'Kunne ikke laste tilkoblinger. Sjekk servertilkoblingen og prøv igjen.';

  @override
  String get credentialsOperationFailed =>
      'Kunne ikke endre denne tilkoblingen. Sjekk servertilkoblingen, tilgangen din og tilgangsopplysningene, og prøv igjen.';

  @override
  String get credentialsConnected => 'Tilkoblet';

  @override
  String get credentialsNotConnected => 'Ikke tilkoblet';

  @override
  String credentialsSignedInAs(String username) {
    return 'Logget inn som $username';
  }

  @override
  String get credentialsAccount => 'Tilkoblet konto';

  @override
  String get credentialsStoredKey => 'Lagret nøkkel';

  @override
  String get credentialsActive => 'Aktiv';

  @override
  String get credentialsRemove => 'Fjern';

  @override
  String get credentialsRemoveConfirm =>
      'Fjerne de lagrede tilgangsopplysningene dine? Du må kanskje logge inn på nytt.';

  @override
  String get credentialsApiKey => 'API-nøkkel';

  @override
  String get credentialsApiKeyHint => 'Lim inn en API-nøkkel fra leverandøren';

  @override
  String get credentialsBrowserLogin => 'Logg inn med nettleseren';

  @override
  String get credentialsSignInAgain => 'Logg inn på nytt';

  @override
  String get credentialsWaitingForLogin =>
      'Venter på autorisasjon i nettleseren …';

  @override
  String get credentialsLoginTimedOut =>
      'Påloggingen utløp. Start et nytt påloggingsforsøk.';

  @override
  String get credentialsCopyCode => 'Kopier kode';

  @override
  String get credentialsDeviceCodeHint =>
      'Bekreft denne koden på leverandørens side. La skjermen stå åpen mens serveren fullfører påloggingen.';

  @override
  String get credentialsPasteRedirect =>
      'Autorisasjonskode eller omdirigeringsadresse';

  @override
  String get credentialsPasteRedirectHint =>
      'Lim inn koden eller hele omdirigeringsadressen fra leverandøren';

  @override
  String get credentialsCompleteLogin => 'Fullfør pålogging';

  @override
  String get credentialsRedirectUnavailable =>
      'Serverens nettleser-tilbakekall kan ikke nås sikkert fra en telefon. Be servereieren konfigurere et offentlig HTTPS-tilbakekall, eller legg til et token i stedet.';

  @override
  String get credentialsUpdateToken => 'Oppdater token';

  @override
  String get credentialsAddToken => 'Legg til token';

  @override
  String get credentialsPersonalToken => 'Personlig tilgangstoken';

  @override
  String get credentialsPersonalTokenHint =>
      'Lim inn et personlig tilgangstoken';

  @override
  String get credentialsHostManaged =>
      'Denne tilkoblingen kommer fra serverappen eller miljøet. Bare servereieren kan endre den der, men du kan fortsatt legge til ditt eget token.';

  @override
  String get credentialsStopWatching => 'Slutt å følge med';

  @override
  String get transcriptClaudeSignInExpiredTitle =>
      'Innloggingen til Claude Code har utløpt';

  @override
  String get transcriptClaudeSignInExpiredBody =>
      'Kjøringen stoppet fordi kontoen ikke lenger autentiseres. Logg inn på nytt, og prøv turen igjen.';

  @override
  String get transcriptSignInExpiredTitle =>
      'Innloggingen til leverandøren har utløpt';

  @override
  String get transcriptSignInExpiredBody =>
      'Kjøringen stoppet fordi leverandørens legitimasjon ikke lenger virker. Koble den til på nytt under Innstillinger → Leverandører, og prøv turen igjen.';
}
