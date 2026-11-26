// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Swedish (`sv`).
class AppLocalizationsSv extends AppLocalizations {
  AppLocalizationsSv([String locale = 'sv']) : super(locale);

  @override
  String get appTitle => 'Control Center';

  @override
  String get back => 'Tillbaka';

  @override
  String get cancel => 'Avbryt';

  @override
  String get retry => 'Försök igen';

  @override
  String get tryAgain => 'Försök igen';

  @override
  String get settings => 'Inställningar';

  @override
  String get refresh => 'Uppdatera';

  @override
  String get approve => 'Godkänn';

  @override
  String get deny => 'Neka';

  @override
  String get continueLabel => 'Fortsätt';

  @override
  String get agentQuestionHeader => 'Fråga till dig';

  @override
  String get agentQuestionAnsweredLabel => 'Besvarad';

  @override
  String get agentQuestionSkip => 'Hoppa över';

  @override
  String get agentQuestionSkippedLabel => 'Överhoppad';

  @override
  String get agentQuestionFreeformHint => 'Skriv ditt svar…';

  @override
  String get agentApprovalRequired => 'Godkännande krävs';

  @override
  String get copyCommand => 'Kopiera kommando';

  @override
  String get approveAndRemember => 'Godkänn i 8 timmar';

  @override
  String get decline => 'Avböj';

  @override
  String get confirm => 'Bekräfta';

  @override
  String get send => 'Skicka';

  @override
  String get close => 'Stäng';

  @override
  String get expand => 'Visa mer';

  @override
  String get zoomIn => 'Zooma in';

  @override
  String get zoomOut => 'Zooma ut';

  @override
  String get resetZoom => 'Återställ zoom';

  @override
  String get scanQrPrompt =>
      'Skanna QR-koden från Control Center för att parkoppla den här telefonen.';

  @override
  String get scanQrHelp =>
      'Öppna kameran och rikta den mot QR-koden som visas i Control Center. Den här telefonen ansluter direkt över en privat länk.';

  @override
  String get connectingToMac => 'Ansluter till Control Center…';

  @override
  String get connectingDetail => 'Upprättar en säker, direkt länk.';

  @override
  String get identityChangedTitle => 'Serverns identitet har ändrats';

  @override
  String get identityChangedBody =>
      'Den här servern matchar inte längre identiteten som sparades när du parkopplade. Det kan betyda att servern har installerats om — eller att något fångar upp anslutningen. För säkerhets skull ansluter den här enheten inte. Ta bort parkopplingen och skanna sedan en ny QR-kod från Control Center för att parkoppla igen.';

  @override
  String get removePairing => 'Ta bort parkoppling';

  @override
  String get couldntConnect => 'Kunde inte ansluta';

  @override
  String get pendingPairingTitle => 'Anslut till den här servern?';

  @override
  String get pendingPairingBody =>
      'En länk bad Control Center att parkoppla med den här servern. Fortsätt bara om du startade det själv.';

  @override
  String get connect => 'Anslut';

  @override
  String get failureNotPaired =>
      'Inte parkopplad — skanna QR-koden från Control Center';

  @override
  String get failureUnreachable =>
      'Kunde inte nå servern på någon väg — kontrollera att den körs, eller prova samma nätverk';

  @override
  String get failureIdentityChanged =>
      'Serverns identitet har ändrats — om den installerats om, parkoppla den här enheten igen';

  @override
  String get failureAuthRejected =>
      'Servern avvisade den här enheten — parkoppla den igen från Control Center';

  @override
  String get failureUnknown =>
      'Kunde inte ansluta — tryck för att försöka igen';

  @override
  String get statusConnected => 'Ansluten';

  @override
  String get statusConnecting => 'Ansluter';

  @override
  String get statusOffline => 'Offline';

  @override
  String get statusIdentityMismatch => 'Identitetsfel';

  @override
  String get statusNotPaired => 'Inte parkopplad';

  @override
  String get statusConfirmPairing => 'Bekräfta parkoppling';

  @override
  String get connectionFailed => 'Anslutningen misslyckades';

  @override
  String get identityMismatchBanner =>
      'Serverns identitet har ändrats — anslutningen stoppades. Parkoppla den här enheten igen för att fortsätta.';

  @override
  String get tabInbox => 'Inkorg';

  @override
  String get tabTickets => 'Ärenden';

  @override
  String get tabChat => 'Chatt';

  @override
  String get tabPrs => 'PRs';

  @override
  String get tabCalendar => 'Kalender';

  @override
  String get tabNews => 'Nyheter';

  @override
  String tabWaitingCount(String label, int count) {
    return '$label, $count väntar';
  }

  @override
  String get updateAvailable => 'En ny Control Center är tillgänglig';

  @override
  String get appearance => 'Utseende';

  @override
  String get language => 'Språk';

  @override
  String get device => 'Enhet';

  @override
  String get themeSystem => 'System';

  @override
  String get themeLight => 'Ljust';

  @override
  String get themeDark => 'Mörkt';

  @override
  String get languageSystem => 'System';

  @override
  String get disconnectTapAgain =>
      'Tryck igen för att koppla från den här enheten från Control Center';

  @override
  String get disconnectDevice => 'Koppla från den här enheten';

  @override
  String get disconnect => 'Koppla från';

  @override
  String get chooseWorkspace => 'Välj arbetsyta';

  @override
  String get workspaces => 'Arbetsytor';

  @override
  String get workspacesLoadFailed => 'Kunde inte läsa in arbetsytor';

  @override
  String get noWorkspacesYet => 'Inga arbetsytor ännu';

  @override
  String selectWorkspace(String name) {
    return 'Välj $name';
  }

  @override
  String get inboxLoadFailed => 'Kunde inte läsa in inkorgen';

  @override
  String get allCaughtUp => 'Du är ikapp';

  @override
  String get inboxNothingWaiting =>
      'Inget är blockerat och ingen pull request väntar på dig.';

  @override
  String get blocked => 'Blockerad';

  @override
  String get sectionNeedsYourReview => 'Behöver din granskning';

  @override
  String get sectionReturnedToYou => 'Åter till dig';

  @override
  String get sectionApprovedAndReady => 'Godkända och redo';

  @override
  String get sectionYourDrafts => 'Dina utkast';

  @override
  String get sectionWaitingForReviewers => 'Väntar på granskare';

  @override
  String get sectionMergingAndMerged => 'Sammanslås och nyligen sammanslagna';

  @override
  String get sectionWaitingForAuthor => 'Väntar på författare';

  @override
  String waitingAgo(String ago) {
    return 'väntar $ago';
  }

  @override
  String get openConversation => 'Öppna samtalet';

  @override
  String get calendarLoadFailed => 'Kunde inte läsa in kalendern';

  @override
  String get nothingScheduled => 'Inget inbokat';

  @override
  String get calendarEmptyDescription =>
      'Händelser från dina anslutna kalendrar visas här.';

  @override
  String get agenda => 'Agenda';

  @override
  String get syncCalendarsNow => 'Synka kalendrar nu';

  @override
  String get event => 'Händelse';

  @override
  String get eventNotFound => 'Händelsen hittades inte';

  @override
  String get eventNotFoundDescription =>
      'Den kan ligga utanför agendafönstret, eller ha tagits bort uppströms.';

  @override
  String get joinMeeting => 'Anslut till mötet';

  @override
  String attendeesCount(int count) {
    return 'Deltagare ($count)';
  }

  @override
  String get details => 'Detaljer';

  @override
  String get allDay => 'Heldag';

  @override
  String get happeningNow => 'Pågår nu';

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
  String get attendeeAccepted => 'accepterat';

  @override
  String get attendeeDeclined => 'avböjt';

  @override
  String get attendeeMaybe => 'kanske';

  @override
  String get attendeeNoReply => 'inget svar';

  @override
  String get organizer => 'organisatör';

  @override
  String get calendarNoAccounts =>
      'Ingen kalender är ansluten för den här arbetsytan. Anslut en från desktopappen — inloggningen lagrar tokenet på servern.';

  @override
  String get calendarReauthNeeded =>
      'Ett kalenderkonto måste anslutas igen — det du ser nedan kan vara inaktuellt. Anslut det igen från desktopappen.';

  @override
  String get spacesLoadFailed => 'Kunde inte läsa in ytor';

  @override
  String get noSpaces => 'Inga ytor';

  @override
  String get spacesEmptyDescription => 'Ytor i den här arbetsytan visas här.';

  @override
  String get newSpaceFolder => 'Ny mapp';

  @override
  String get folderName => 'Mappnamn';

  @override
  String get renameSpaceFolder => 'Byt namn på mapp';

  @override
  String get deleteSpaceFolder => 'Ta bort mapp';

  @override
  String get moveSpaceToFolder => 'Flytta till mapp';

  @override
  String get removeSpaceFromFolder => 'Ta bort från mapp';

  @override
  String get spaceFolderActions => 'Mappåtgärder';

  @override
  String get deleteFolderWithSpacesWarning =>
      'Om du tar bort utrymmen permanent försvinner deras meddelanden och arbetskataloger för alla. Det går inte att ångra.';

  @override
  String get deleteSpacesInFolder =>
      'Ta bort utrymmena i den här mappen permanent';

  @override
  String get deleteFolderAndSpaces => 'Ta bort mapp och utrymmen';

  @override
  String get keepSpacesInFolder => 'Annars blir utrymmena kvar utanför mappar.';

  @override
  String get create => 'Skapa';

  @override
  String get otherSpaces => 'Andra utrymmen';

  @override
  String get folderUpdateFailed => 'Det gick inte att uppdatera mapparna';

  @override
  String get thread => 'Tråd';

  @override
  String get agentWorking => 'Agenten arbetar';

  @override
  String get messagesLoadFailed => 'Kunde inte läsa in meddelanden';

  @override
  String get noMessagesYet => 'Inga meddelanden ännu';

  @override
  String get noMessagesDescription =>
      'Skicka ett meddelande för att starta samtalet.';

  @override
  String get agentResponding => 'Agenten svarar';

  @override
  String get agentFinished => 'Agenten är klar';

  @override
  String attachmentsTooLarge(int count, String names) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$names är för stora för att skickas härifrån.',
      one: '$names är för stor för att skickas härifrån.',
    );
    return '$_temp0';
  }

  @override
  String get teammate => 'Kollega';

  @override
  String get systemSender => 'System';

  @override
  String get agent => 'Agent';

  @override
  String get attachFile => 'Bifoga en fil';

  @override
  String get messageHint => 'Meddelande';

  @override
  String removeAttachment(String name) {
    return 'Ta bort $name';
  }

  @override
  String get articlesLoadFailed => 'Kunde inte läsa in artiklar';

  @override
  String get noArticles => 'Inga artiklar';

  @override
  String get articlesEmptyDescription =>
      'Nya artiklar visas här när flöden uppdateras.';

  @override
  String get unread => 'Olästa';

  @override
  String get allFeeds => 'Alla flöden';

  @override
  String get save => 'Spara';

  @override
  String get unsave => 'Ta bort sparad';

  @override
  String get readFullArticle => 'Läs hela artikeln';

  @override
  String get ticketsLoadFailed => 'Kunde inte läsa in ärenden';

  @override
  String get noTickets => 'Inga ärenden';

  @override
  String get ticketsEmptyDescription =>
      'Ärenden i den här arbetsytan visas här.';

  @override
  String get all => 'Alla';

  @override
  String get ticket => 'Ärende';

  @override
  String get ticketLoadFailed => 'Kunde inte läsa in ärendet';

  @override
  String assignedTo(String name) {
    return 'Tilldelad $name';
  }

  @override
  String get openInBrowser => 'Öppna i webbläsaren';

  @override
  String get status => 'Status';

  @override
  String get assign => 'Tilldela';

  @override
  String get reassign => 'Tilldela om';

  @override
  String get noAgents => 'Inga agenter';

  @override
  String get noAgentsDescription =>
      'Tilldela en agent från den här arbetsytan.';

  @override
  String get statusOpen => 'Öppen';

  @override
  String get statusInProgress => 'Pågår';

  @override
  String get statusBlocked => 'Blockerad';

  @override
  String get statusInReview => 'Under granskning';

  @override
  String get statusDone => 'Klar';

  @override
  String get statusBacklog => 'Backlog';

  @override
  String get lensNeedsMe => 'Behöver mig';

  @override
  String get lensMine => 'Mina';

  @override
  String get prsLoadFailed => 'Kunde inte läsa in pull requests';

  @override
  String get noOpenPullRequests => 'Inga öppna pull requests';

  @override
  String get nothingWaitingOnReview => 'Inget väntar på din granskning';

  @override
  String get noOwnOpenPullRequests => 'Du har inga öppna pull requests';

  @override
  String get nothingBlocked => 'Inget är blockerat';

  @override
  String get prsEmptyDescription =>
      'Pull requests från den här arbetsytans repon visas här.';

  @override
  String get refreshPullRequests => 'Uppdatera pull requests';

  @override
  String get noForgeConnected =>
      'Ingen forge är ansluten på servern, så inga pull requests kan hämtas. Anslut en från desktopappen.';

  @override
  String get draft => 'Utkast';

  @override
  String get merged => 'Sammanslagen';

  @override
  String get closed => 'Stängd';

  @override
  String get open => 'Öppen';

  @override
  String get approved => 'Godkänd';

  @override
  String get changesRequested => 'Ändringar begärda';

  @override
  String get reviewRequired => 'Granskning krävs';

  @override
  String get checksPassing => 'Kontroller går igenom';

  @override
  String get checksFailing => 'Kontroller misslyckas';

  @override
  String get checksRunning => 'Kontroller körs';

  @override
  String prSemanticLabel(String title, String status) {
    return '$title, $status';
  }

  @override
  String get pullRequest => 'Pull request';

  @override
  String get prLoadFailed => 'Kunde inte läsa in den här pull requesten';

  @override
  String get openOnForge => 'Öppna på forge';

  @override
  String get requestChangesNeedsComment =>
      'Lägg till en kommentar som förklarar vad som behöver ändras.';

  @override
  String get conversation => 'Samtal';

  @override
  String get files => 'Filer';

  @override
  String get checks => 'Kontroller';

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
  String get reviewers => 'Granskare';

  @override
  String get noDescriptionNoComments =>
      'Ingen beskrivning och inga kommentarer ännu.';

  @override
  String get noChangedFiles => 'Inga ändrade filer.';

  @override
  String get noChecksReported =>
      'Inga kontroller rapporterade för head-commit.';

  @override
  String get reviewCommentHint => 'Lämna en granskningskommentar…';

  @override
  String get comment => 'Kommentar';

  @override
  String get commentPosted => 'Kommentaren publicerades';

  @override
  String get request => 'Begär';

  @override
  String get squashAndMerge => 'Squasha och slå samman';

  @override
  String noActionsAvailable(String status) {
    return '$status — inga åtgärder tillgängliga.';
  }

  @override
  String get reviewApproved => 'godkände';

  @override
  String get reviewRequestedChanges => 'begärde ändringar';

  @override
  String get reviewCommented => 'granskade';

  @override
  String get reviewPending => 'väntar';

  @override
  String get unknownAuthor => 'okänd';

  @override
  String hideDiffFor(String file) {
    return 'Dölj diffen för $file';
  }

  @override
  String showDiffFor(String file) {
    return 'Visa diffen för $file';
  }

  @override
  String get checkRunning => 'körs';

  @override
  String get checkPassed => 'godkänd';

  @override
  String get checkFailed => 'misslyckades';

  @override
  String get checkCancelled => 'avbruten';

  @override
  String get checkSkipped => 'hoppades över';

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
      'Ingen textdiff för den här filen — den är binär, eller för stor för att forge ska returnera en.';

  @override
  String showRemainingLines(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Visa de återstående $count raderna',
      one: 'Visa den återstående raden',
    );
    return '$_temp0';
  }

  @override
  String unchangedLines(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count oförändrade rader',
      one: '1 oförändrad rad',
    );
    return '$_temp0';
  }

  @override
  String get jumpToLatest => 'Hoppa till senaste';

  @override
  String get streaming => 'Strömmar';

  @override
  String get working => 'Arbetar';

  @override
  String get input => 'Indata';

  @override
  String get output => 'Utdata';

  @override
  String get now => 'nu';

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
  String get today => 'Idag';

  @override
  String get tomorrow => 'Imorgon';

  @override
  String get yesterday => 'Igår';

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
  String get mobileConversations => 'Samtal';

  @override
  String get mobileNewConversation => 'Nytt samtal';

  @override
  String get mobileConversationName => 'Samtalsnamn';

  @override
  String get mobileRename => 'Byt namn';

  @override
  String get mobileManageSpace => 'Hantera yta';

  @override
  String get mobileArchived => 'Arkiverat';

  @override
  String get mobileSearchMessages => 'Sök i alla meddelanden på ytan';

  @override
  String get mobileSearch => 'Sök';

  @override
  String get mobileNoResults => 'Inga resultat';

  @override
  String get mobileReopen => 'Öppna igen';

  @override
  String get mobileArchive => 'Arkivera';

  @override
  String get mobileProgress => 'Förlopp och kontext';

  @override
  String get mobileReadFailed => 'Kunde inte markera samtalet som läst';

  @override
  String get mobileSendFailed =>
      'Meddelandet skickades inte. Ditt utkast finns kvar.';

  @override
  String get sentAttachmentUnavailable => 'Bilagan är inte tillgänglig';

  @override
  String get sentAttachmentLoadFailed => 'Kunde inte läsa in bilagan';

  @override
  String get mobileActionFailed => 'Åtgärden misslyckades';

  @override
  String get mobileRemove => 'Ta bort';

  @override
  String get mobileLinkedMessage => 'Länkat meddelande';

  @override
  String get mobileOlderMessages => 'Äldre meddelanden';

  @override
  String get mobileMessageActions => 'Meddelandeåtgärder';

  @override
  String get mobileOpenThread => 'Öppna tråd';

  @override
  String get mobileCopyLink => 'Kopiera länk';

  @override
  String get mobileStopRun => 'Stoppa körning';

  @override
  String get mobileStopRunConfirm =>
      'Stoppa agentkörningen? Redan slutfört arbete sparas.';

  @override
  String get mobileControlUnsupported =>
      'Körningen är avslutad eller stöder inte den här åtgärden.';

  @override
  String get mobilePauseRequested => 'Paus begärd efter aktuell tur';

  @override
  String get mobileResumed => 'Körningen har återupptagits';

  @override
  String get mobileStopRequested => 'Stopp begärt';

  @override
  String get mobileQueuedMessages => 'Köade meddelanden';

  @override
  String get mobilePauseRun => 'Pausa efter aktuell tur';

  @override
  String get mobileResumeRun => 'Återuppta';

  @override
  String get mobileEditQueued => 'Redigera köat meddelande';

  @override
  String get mobileSteerNow => 'Styr nu';

  @override
  String get mobileMoveUp => 'Flytta upp';

  @override
  String get mobileMoveDown => 'Flytta ner';

  @override
  String get mobileQueueChanged =>
      'Kön har ändrats eller så kan körningen inte ta emot styrning i realtid. Uppdatera och försök igen.';

  @override
  String get mobileActivity => 'Aktivitet';

  @override
  String get mobilePermissions => 'Behörigheter och granskningslogg';

  @override
  String get mobilePlans => 'Planer';

  @override
  String get mobileGoals => 'Övervakade mål';

  @override
  String get mobileCredentials => 'Anslutningar och inloggningsuppgifter';

  @override
  String get mobileWorkspaceUnavailable =>
      'Arbetsytan är inte tillgänglig eller så har du inte längre åtkomst.';

  @override
  String get mobilePrReviewThreads => 'Granskningstrådar';

  @override
  String get mobilePrThreadsLoadFailed =>
      'Kunde inte läsa in granskningstrådar';

  @override
  String get mobilePrNoReviewThreads =>
      'Inga granskningstrådar för enskilda rader ännu';

  @override
  String get mobilePrCommentPermissionDenied =>
      'Du har inte behörighet att kommentera i det här arkivet.';

  @override
  String get mobilePrPermissionChecking => 'Kontrollerar kommentarsbehörighet…';

  @override
  String get mobilePrPermissionLoadFailed =>
      'Kunde inte kontrollera kommentarsbehörighet. Försök igen för att kommentera.';

  @override
  String mobilePrThreadLine(String side, String line) {
    return '$side, rad $line';
  }

  @override
  String get mobilePrOriginalSide => 'Ursprunglig';

  @override
  String get mobilePrSelectCommentLine => 'Välj en rad att kommentera';

  @override
  String get mobilePrUpdatedSide => 'Uppdaterad';

  @override
  String get mobilePrThreadResolved => 'Löst';

  @override
  String get mobilePrReplyHint => 'Skriv ett svar…';

  @override
  String get mobilePrCommentRequired =>
      'Skriv en kommentar innan du publicerar.';

  @override
  String get mobilePrReply => 'Svara';

  @override
  String get mobilePrReopenThread => 'Öppna tråden igen';

  @override
  String get mobilePrResolveThread => 'Lös tråden';

  @override
  String get mobilePrResolvePermissionDenied =>
      'Bara den som skapade pull requesten eller någon med skrivbehörighet kan lösa tråden.';

  @override
  String mobilePrCommentOnLine(String side, String line) {
    return 'Kommentera $side, rad $line';
  }

  @override
  String get mobilePrInlineCommentHint => 'Skriv en radkommentar…';

  @override
  String get mobilePrPostInlineComment => 'Publicera kommentar';

  @override
  String get mobilePrCommentUnavailable =>
      'Radkommentarer är inte tillgängliga för den här pull requesten.';

  @override
  String get mobilePrPatchUnavailable =>
      'Kodplattformen tillhandahöll ingen textpatch för filen.';

  @override
  String get mobilePrNoPatchForFile => 'Patchen för filen är inte tillgänglig.';

  @override
  String get mobileTicketNew => 'Nytt ärende';

  @override
  String get mobileTicketCreate => 'Skapa ärende';

  @override
  String get mobileTicketEdit => 'Redigera ärende';

  @override
  String get mobileTicketTitle => 'Titel';

  @override
  String get mobileTicketTitleRequired =>
      'Ange en titel för att spara ärendet.';

  @override
  String get mobileTicketDescription => 'Beskrivning';

  @override
  String get mobileTicketMarkdownHint => 'Lägg till detaljer i Markdown';

  @override
  String get mobileTicketPriority => 'Prioritet';

  @override
  String get mobileTicketPriorityNone => 'Ingen prioritet';

  @override
  String get mobileTicketPriorityUrgent => 'Brådskande';

  @override
  String get mobileTicketPriorityHigh => 'Hög';

  @override
  String get mobileTicketPriorityMedium => 'Medel';

  @override
  String get mobileTicketPriorityLow => 'Låg';

  @override
  String get mobileTicketLabels => 'Etiketter';

  @override
  String get mobileTicketLabelsHint => 'En etikett per rad';

  @override
  String get mobileTicketLabelsHelp => 'Ange varje etikett på en egen rad.';

  @override
  String mobileTicketWorkspaceProvider(String provider) {
    return 'Registrerat i $provider';
  }

  @override
  String get mobileTicketProviderLocal => 'Control Center';

  @override
  String get mobileTicketUnassigned => 'Ej tilldelad';

  @override
  String get mobileTicketAssignedFilter => 'Tilldelade';

  @override
  String get mobileTicketAgentsLoadFailed => 'Kunde inte läsa in agenter';

  @override
  String get mobileTicketSearch => 'Sök ärenden';

  @override
  String get mobileTicketSearchHint =>
      'Titel, nyckel, beskrivning, etikett eller ansvarig';

  @override
  String get mobileTicketClearSearch => 'Rensa ärendesökning';

  @override
  String get mobileTicketNoMatches => 'Inga matchande ärenden';

  @override
  String get mobileTicketAdjustFilters =>
      'Prova en annan sökning eller ändra filtren.';

  @override
  String get mobileTicketClearFilters => 'Rensa filter';

  @override
  String get mobileTicketNotFound => 'Ärendet hittades inte';

  @override
  String get mobileTicketNotFoundDescription =>
      'Ärendet kan ha tagits bort eller flyttats från arbetsytan.';

  @override
  String get mobileTicketWorkspaceChanged =>
      'Arbetsytan har ändrats. Återgå till den aktuella arbetsytan innan du sparar.';

  @override
  String get mobileTicketOpenLinkedSpace => 'Öppna länkad yta';

  @override
  String get mobileTicketReadOnly =>
      'Du måste ha medlemsrollen i arbetsytan för att ändra ärenden.';

  @override
  String get permissionTitle => 'Behörigheter';

  @override
  String get permissionWorkspaceFailed => 'Kunde inte läsa in arbetsytan';

  @override
  String get permissionNoWorkspace =>
      'Välj en arbetsyta för att granska behörigheter.';

  @override
  String get permissionLoading => 'Läser in behörigheter…';

  @override
  String get permissionScopeDescription =>
      'Se hur varje åtgärd bedöms på den här nivån. Arbetsytans regler kan ärvas av agenter och ytor.';

  @override
  String get permissionScope => 'Regelnivå';

  @override
  String get permissionWorkspaceScope => 'Arbetsyta';

  @override
  String get permissionAgentScope => 'Agent';

  @override
  String get permissionSpaceScope => 'Yta';

  @override
  String get permissionAgentContext => 'Agent som agerar på ytan';

  @override
  String get permissionNoAgentContext => 'Ingen agent vald';

  @override
  String get permissionTargetsFailed => 'Kunde inte läsa in objekt för nivån';

  @override
  String get permissionNoTargets =>
      'Inga objekt är tillgängliga på den här nivån.';

  @override
  String get permissionRoleFailed =>
      'Kunde inte bekräfta din roll i arbetsytan';

  @override
  String get permissionMemberRequired =>
      'Du måste ha medlemsrollen i arbetsytan för att se behörighetsregler.';

  @override
  String get permissionRulesFailed => 'Kunde inte läsa in behörighetsregler';

  @override
  String get permissionAuditAdminOnly =>
      'Behörighetshistoriken är bara tillgänglig för arbetsytans administratörer.';

  @override
  String get permissionAllow => 'Tillåt';

  @override
  String get permissionAsk => 'Fråga först';

  @override
  String get permissionDeny => 'Neka';

  @override
  String get permissionFileDelete => 'Ta bort filer';

  @override
  String get permissionFileWriteOutsideWorktree => 'Skriv utanför arbetsträdet';

  @override
  String get permissionGitCommit => 'Skapa commits';

  @override
  String get permissionGitPush => 'Pusha commits';

  @override
  String get permissionPrCreate => 'Skapa pull requests';

  @override
  String get permissionPrPublish => 'Uppdatera eller slå ihop pull requests';

  @override
  String get permissionVendorSyncWrite => 'Skriv till ett externt ärendesystem';

  @override
  String get permissionNetworkEgress => 'Använd nätverket';

  @override
  String get permissionSecretAccess => 'Läs hemligheter';

  @override
  String get permissionPackageInstall => 'Installera paket';

  @override
  String get permissionProcessSpawn => 'Starta processer';

  @override
  String get permissionWorkspaceMutation => 'Ändra arbetsyta';

  @override
  String get permissionEnclosureControl => 'Styr en avskild miljö (station)';

  @override
  String get permissionChangeFailed => 'Kunde inte ändra regeln';

  @override
  String get permissionEffectiveDescription =>
      'Gäller på den här nivån utan åtgärdsargument. Villkorade behörigheter nedan gäller bara matchande förfrågningar. Servern fattar det slutliga beslutet.';

  @override
  String get permissionSpaceAgentNote =>
      'Ingen agent vald. Agentspecifika regler visas först när du väljer en agent ovan.';

  @override
  String get permissionScopedGrants => 'Regler på den här nivån';

  @override
  String get permissionModePreset => 'Lägesförinställning';

  @override
  String get permissionBuiltInDefault => 'Inbyggd standard';

  @override
  String get permissionRemembered => 'Stående godkännande';

  @override
  String get permissionSource => 'Källa';

  @override
  String permissionSetAtThisScope(String source) {
    return '$source · angiven här';
  }

  @override
  String permissionInheritedFrom(String source) {
    return '$source · ärvd';
  }

  @override
  String permissionExpiresAt(String date) {
    return 'Går ut $date';
  }

  @override
  String get permissionSetHere => 'Ange en regel här';

  @override
  String get permissionConfirmRevoke => 'Bekräfta återkallande';

  @override
  String get permissionRevokeRule => 'Återkalla regel';

  @override
  String permissionCommandPrefix(String prefix) {
    return 'Kommandoprefix: $prefix';
  }

  @override
  String get permissionNoExpiry => 'Ingen utgångstid';

  @override
  String get permissionExpired => 'Utgången';

  @override
  String get permissionExplicitRule => 'Uttrycklig regel';

  @override
  String get permissionEnforcementAdvisory =>
      'Rådgivande: Fråga först-regler loggas utan att någon fråga visas';

  @override
  String get permissionEnforcementSoft =>
      'Mjuk tillämpning: undantag kräver godkännande';

  @override
  String get permissionEnforcementHard =>
      'Strikt tillämpning: kan inte åsidosättas';

  @override
  String permissionPaths(String paths) {
    return 'Sökvägar: $paths';
  }

  @override
  String permissionRefs(String refs) {
    return 'Git-referenser: $refs';
  }

  @override
  String permissionHosts(String hosts) {
    return 'Värdar: $hosts';
  }

  @override
  String permissionCommands(String commands) {
    return 'Kommandon: $commands';
  }

  @override
  String permissionTools(String tools) {
    return 'Verktyg: $tools';
  }

  @override
  String get permissionNotInEffect =>
      'Inte i kraft medan den här åtgärden är nekad';

  @override
  String permissionMaxCount(String count) {
    return 'Högsta antal: $count';
  }

  @override
  String permissionMaxCents(String cents) {
    return 'Högsta belopp i cent: $cents';
  }

  @override
  String get permissionAuditHeading => 'Behörighetshistorik';

  @override
  String get permissionAuditDescription =>
      'Senaste besluten som registrerats av servern. Endast administratörer kan granska loggen eller verifiera dess hashkedja.';

  @override
  String permissionOnBehalfOf(String user) {
    return 'för $user';
  }

  @override
  String get permissionPrompted => 'Mänskligt godkännande begärt';

  @override
  String get permissionVerifyChain => 'Verifiera loggkedjan';

  @override
  String get permissionVerifyFailed => 'Kunde inte verifiera loggkedjan';

  @override
  String permissionChainIntact(String count) {
    return 'Kedjan är intakt · $count poster kontrollerade';
  }

  @override
  String permissionChainBroken(String sequence, String reason) {
    return 'Kedjan är bruten vid post $sequence: $reason';
  }

  @override
  String get permissionAuditEmpty =>
      'Inga behörighetsbeslut har registrerats ännu.';

  @override
  String get permissionAuditFailed =>
      'Kunde inte läsa in behörighetshistoriken';

  @override
  String get mobilePlansLoadFailed => 'Kunde inte läsa in planer';

  @override
  String get mobilePlansEmpty => 'Inga planer ännu';

  @override
  String get mobilePlansEmptyDescription =>
      'Planer som agenter skickar in visas här för granskning.';

  @override
  String get mobilePlanTitle => 'Plan';

  @override
  String get mobilePlanMissing =>
      'Den här planen är inte längre tillgänglig i den här arbetsytan.';

  @override
  String mobilePlanStepCount(int count) {
    return '$count steg';
  }

  @override
  String get mobilePlanDraft => 'Utkast';

  @override
  String get mobilePlanProposed => 'Väntar på granskning';

  @override
  String get mobilePlanApproved => 'Godkänd';

  @override
  String get mobilePlanRejected => 'Avvisad';

  @override
  String get mobilePlanSuperseded => 'Ersatt';

  @override
  String get mobilePlanExecuting => 'Körs';

  @override
  String get mobilePlanSynthesizing => 'Syntetiserar';

  @override
  String get mobilePlanCompleted => 'Slutförd';

  @override
  String get mobilePlanFailed => 'Misslyckades';

  @override
  String get mobilePlanCancelled => 'Avbruten';

  @override
  String mobilePlanRevision(String revision) {
    return 'Revision $revision';
  }

  @override
  String get mobilePlanSteps => 'Steg';

  @override
  String get mobilePlanNoSteps =>
      'Inga steg har skickats in för den här planen.';

  @override
  String get mobilePlanAssumptions => 'Förtydliganden';

  @override
  String mobilePlanDependsOn(String keys) {
    return 'Beror på $keys';
  }

  @override
  String mobilePlanStepCost(String cost) {
    return 'Beräknas kosta högst $cost';
  }

  @override
  String get mobilePlanSelect => 'Välj';

  @override
  String get mobilePlanSelected => 'Vald';

  @override
  String get mobilePlanEstimate => 'Beräkna kostnad';

  @override
  String get mobilePlanEstimateRequired =>
      'Beräkna planens kostnad innan du godkänner körningen.';

  @override
  String mobilePlanEstimatedCost(String low, String high) {
    return 'Beräknad kostnad: $low–$high';
  }

  @override
  String get mobilePlanCostUnknown => 'inte tillgänglig';

  @override
  String get mobilePlanNoHardCap => 'inget fast tak';

  @override
  String get mobilePlanExceedsBudget =>
      'Den beräknade kostnaden överskrider den inställda budgeten. Granska innan du godkänner.';

  @override
  String get mobilePlanPartialEstimate =>
      'Kostnadsberäkningen gäller hela planen. Valda steg kan kosta mindre.';

  @override
  String get mobilePlanConfirmAll => 'Starta hela planen?';

  @override
  String get mobilePlanConfirmSelected => 'Starta valda steg?';

  @override
  String mobilePlanExecutionConfirmation(String cost, String cap) {
    return 'Godkännandet startar körningen och kan medföra kostnader. Beräknad övre kostnad: $cost. Budgettak: $cap.';
  }

  @override
  String get mobilePlanApproveAll => 'Godkänn alla och kör';

  @override
  String get mobilePlanApproveSelected => 'Godkänn valda och kör';

  @override
  String get mobilePlanWiden => 'Godkänn fler steg';

  @override
  String mobilePlanWidenConfirm(String count, String cap) {
    return 'Tillåt körning av ytterligare $count steg? De kan medföra kostnader. Befintligt kostnadstak för körningen: $cap.';
  }

  @override
  String get mobilePlanChanged =>
      'Planen ändrades under granskningen. Öppna den senaste revisionen och beräkna kostnaden igen.';

  @override
  String get mobilePlanReject => 'Avvisa plan';

  @override
  String get mobilePlanRejectConfirm =>
      'Avvisa den här planen? Den kommer inte att köras.';

  @override
  String get mobilePlanStop => 'Stoppa körning';

  @override
  String get mobilePlanStopConfirm =>
      'Stoppa körningen av den här planen? Redan slutfört arbete ångras inte.';

  @override
  String mobilePlanRunId(String runId) {
    return 'Körning: $runId';
  }

  @override
  String get mobilePlanExecutionPending =>
      'Godkännandet har tagits emot. Väntar på att körningen registreras…';

  @override
  String mobilePlanProgress(String completed, String total) {
    return '$completed av $total körningssteg slutförda';
  }

  @override
  String get mobilePlanOpenConversation => 'Öppna samtal';

  @override
  String get mobileGoalsTitle => 'Övervakade mål';

  @override
  String get mobileGoalsLoadFailed => 'Kunde inte läsa in övervakade mål';

  @override
  String get mobileGoalsEmpty => 'Inga övervakade mål ännu';

  @override
  String get mobileGoalsEmptyDescription =>
      'Starta ett i en yta eller skicka /goal i ett samtal.';

  @override
  String get mobileGoalMissing =>
      'Det här målet är inte längre tillgängligt i den här arbetsytan.';

  @override
  String get mobileGoalActive => 'Aktiv';

  @override
  String get mobileGoalPaused => 'Pausat';

  @override
  String get mobileGoalCompleted => 'Slutförd';

  @override
  String get mobileGoalFailed => 'Misslyckades';

  @override
  String get mobileGoalCancelled => 'Avbruten';

  @override
  String get mobileGoalBudgetExhausted => 'Budgetgränsen nådd';

  @override
  String mobileGoalFailures(String count) {
    return 'Misslyckade körningar i rad: $count';
  }

  @override
  String get mobileGoalFailedDescription =>
      'Övervakaren stoppade efter upprepade misslyckade körningar. Se samtalet för mer information.';

  @override
  String get mobileGoalPause => 'Pausa mål';

  @override
  String get mobileGoalResume => 'Återuppta mål';

  @override
  String get mobileGoalStop => 'Avbryt mål';

  @override
  String get mobileGoalStopConfirm =>
      'Avbryt det här övervakade målet permanent? Det kan inte återupptas.';

  @override
  String get mobileGoalRaiseBudget => 'Höj budgeten och återuppta';

  @override
  String mobileGoalRaiseTo(String amount) {
    return 'Höj budgeten till $amount och återuppta';
  }

  @override
  String mobileGoalRaiseConfirm(String oldCap, String newCap) {
    return 'Höj målets kostnadstak från $oldCap till $newCap och tillåt fortsatta kostnader?';
  }

  @override
  String get mobileGoalOpenConversation => 'Öppna målets samtal';

  @override
  String get mobileGoalCreate => 'Starta övervakat mål';

  @override
  String get mobileGoalChooseSpace => 'Kör i yta';

  @override
  String get mobileGoalNoSpaces => 'Skapa en yta innan du startar ett mål.';

  @override
  String get mobileGoalChooseAgent => 'Kör med agent';

  @override
  String get mobileGoalNoAgents =>
      'Lägg till en aktiv agent innan du startar ett mål.';

  @override
  String mobileGoalSelectedAgent(String name) {
    return '$name har valts';
  }

  @override
  String get mobileGoalObjectiveHint =>
      'Vilket resultat ska agenten sträva efter?';

  @override
  String get mobileGoalBudgetUsd => 'Kostnadstak (USD)';

  @override
  String get mobileGoalCreateInvalid =>
      'Välj en yta och en agent, ange en målsättning och sätt ett positivt kostnadstak i USD.';

  @override
  String mobileGoalCreateConfirm(String cap) {
    return 'Starta ett övervakat mål med en högsta kostnad på $cap? Agenten kan börja direkt.';
  }

  @override
  String get mobileGoalUnavailable =>
      'Serveranslutningen är inte redo. Försök igen efter att anslutningen har återställts.';

  @override
  String get mobileGoalConversationMissing =>
      'Det valda samtalet är inte längre tillgängligt i den här arbetsytan.';

  @override
  String get mobileGoalCreateSent =>
      'Målet har startats. Övervakarens status visas i den här listan.';

  @override
  String get mobileGoalStartRefused =>
      'Ingen målkörning startades. Se samtalet för övervakarens motivering.';

  @override
  String mobileGoalSelectedSpace(String name) {
    return '$name har valts';
  }

  @override
  String get requestUnavailable =>
      'Den här begäran är inte längre tillgänglig i den aktiva arbetsytan.';

  @override
  String get requestAlreadyResolved => 'Den här begäran har redan hanterats.';

  @override
  String get inboxCredentialsBlocked =>
      'Inloggningsuppgifter blockerar körningar';

  @override
  String get inboxSyncFailures => 'Misslyckade leverantörssynkroniseringar';

  @override
  String get inboxConfigureCredentials => 'Konfigurera inloggningsuppgifter';

  @override
  String get openTicket => 'Öppna ärende';

  @override
  String get activityTitle => 'Aktivitet';

  @override
  String get activityClearAll => 'Rensa aktivitet';

  @override
  String get activityClearConfirm =>
      'Detta döljer all aktivitet som hittills registrerats för dig på alla dina enheter. Ny aktivitet visas fortfarande.';

  @override
  String get activityMarkAllRead => 'Markera alla som lästa';

  @override
  String get activityMarkAllConfirm =>
      'Markera all aktivitet i den här arbetsytan som läst på alla dina enheter?';

  @override
  String get activityMarkRead => 'Markera som läst';

  @override
  String get activityMarkUnread => 'Markera som oläst';

  @override
  String get activityDismiss => 'Stäng';

  @override
  String get activityResolved => 'Löst';

  @override
  String get activityOpen => 'Öppen';

  @override
  String get activityEmpty => 'Ingen aktivitet ännu';

  @override
  String get activityLoadFailed => 'Kunde inte läsa in aktivitet';

  @override
  String get activityAgentWaiting => 'Agenten behöver svar';

  @override
  String get activityAgentBlocked => 'Agentens åtgärd blockerad';

  @override
  String get activityMessage => 'Nytt meddelande';

  @override
  String get activityPullRequest => 'Uppdatering av pull request';

  @override
  String get activityRig => 'Stationsuppdatering';

  @override
  String get activityEvent => 'Uppdatera';

  @override
  String get activityPrReady => 'Pull request redo att slås samman';

  @override
  String get activityPrBlocked => 'Sammanslagning av pull request blockerad';

  @override
  String get activityPrApproved => 'Pull request godkänd';

  @override
  String get activityPrChanges => 'Ändringar begärda';

  @override
  String get activityPrChecksFailed =>
      'Kontroller av pull request misslyckades';

  @override
  String get activityPrChecksRecovered =>
      'Kontroller av pull request fungerar igen';

  @override
  String get activityPrComment => 'Kommentar på pull request';

  @override
  String get activityPrPublished => 'Pull request publicerad';

  @override
  String get activityPrMerged => 'Pull request sammanslagen';

  @override
  String get activityPrMentioned => 'Omnämnd i en pull request';

  @override
  String get activityPrReviewRequested => 'Granskning begärd';

  @override
  String get activityPrReviewStale => 'Granskningen behöver uppdateras';

  @override
  String get activityTicketAssigned => 'Ärende tilldelat';

  @override
  String get activityTicketChanged => 'Ärendestatus ändrad';

  @override
  String get activityMeetingSoon => 'Mötet börjar snart';

  @override
  String get activityCalendarExpired => 'Kalenderanslutningen har gått ut';

  @override
  String get activityRigControl => 'Stationens styrning har ändrats';

  @override
  String get activityRigClosed => 'Stationen har stoppats';

  @override
  String get mobileSpacesSearch => 'Sök ytor';

  @override
  String get mobileSpacesArchived => 'Arkiverat';

  @override
  String get mobileSpacesActive => 'Aktiv';

  @override
  String get mobileSpacesNew => 'Ny yta';

  @override
  String get mobileSpacesManage => 'Hantera yta';

  @override
  String get mobileSpacesName => 'Ytnamn';

  @override
  String get mobileSpacesAgents => 'Agenter';

  @override
  String get mobileSpacesMembers => 'Personer';

  @override
  String get mobileSpacesRepos => 'Arkiv';

  @override
  String get mobileSpacesAllRepos => 'Alla länkade arkiv';

  @override
  String get mobileSpacesNoRepos => 'Inga arkiv';

  @override
  String get mobileSpacesBaseBranch => 'Basgren (valfritt)';

  @override
  String get mobileSpacesDefaultBranch => 'Standardgren';

  @override
  String get mobileSpacesMode => 'Läge';

  @override
  String get mobileSpacesModeChat => 'Chatt';

  @override
  String get mobileSpacesModeReview => 'Granska (skrivskyddat)';

  @override
  String get mobileSpacesModePlan => 'Planera (skrivskyddat)';

  @override
  String get mobileSpacesModeOrchestrate => 'Orkestrera';

  @override
  String get mobileSpacesAutonomy => 'Åsidosätt autonomi';

  @override
  String get mobileSpacesAutonomyInherited => 'Ärvt';

  @override
  String get mobileSpacesAutonomyPropose => 'Bara föreslå';

  @override
  String get mobileSpacesAutonomyApproval => 'Agera med godkännande';

  @override
  String get mobileSpacesAutonomyFreely => 'Agera fritt';

  @override
  String get mobileSpacesAutonomyNotice =>
      'Ett åsidosättande kan inte kringgå åtgärdspolicyns godkännandekrav eller nekanden. Endast arbetsytans administratörer kan ändra det.';

  @override
  String get mobileSpacesArchive => 'Arkivera yta';

  @override
  String get mobileSpacesReopen => 'Öppna ytan igen';

  @override
  String get mobileSpacesSave => 'Spara ändringar';

  @override
  String get mobileSpacesCreate => 'Skapa yta';

  @override
  String get mobileSpacesOperationFailed => 'Det gick inte att uppdatera ytan';

  @override
  String get mobileSpacesMissing => 'Ytan hittades inte i den här arbetsytan';

  @override
  String get mobileSpacesEmptyName => 'Ange ett ytnamn';

  @override
  String get mobileSpacesNoMatches => 'Inga matchande ytor';

  @override
  String get mobileSpacesUnread => 'Oläst agentsvar';

  @override
  String get mobileSpacesNeedsInput => 'Behöver din återkoppling';

  @override
  String get mobileSpacesRunning => 'Agenten körs';

  @override
  String get mobileSpacesNoAgents => 'Inga agenter i den här arbetsytan';

  @override
  String get mobileSpacesNoMembers => 'Inga andra medlemmar i arbetsytan';

  @override
  String get mobileSpacesRepoError => 'Det gick inte att läsa in arkiven';

  @override
  String get mobileSpacesRetry => 'Försök igen';

  @override
  String get mobileSpacesBranchUnavailable =>
      'Välj eller ange en basgren när du skapar en yta. Basgrenen kan inte ändras för befintliga ytor.';

  @override
  String get mobileSpacesArchivedEmpty => 'Inga arkiverade ytor';

  @override
  String get mobileSpacesAllRepoWarning =>
      'Arkiv som länkas till arbetsytan framöver kommer också att ingå i den här ytan.';

  @override
  String get mobileSpacesCreatedRetry =>
      'Ytan har skapats. Försök lägga till personer igen eller öppna ytans hanteringssida.';

  @override
  String get progressTitle => 'Förlopp';

  @override
  String get progressConversation => 'Samtal';

  @override
  String get progressLoadFailed => 'Det gick inte att läsa in förloppet';

  @override
  String get progressUnavailable => 'Samtalet är inte tillgängligt';

  @override
  String get progressUnavailableDescription =>
      'Det här samtalet finns inte i den aktiva arbetsytan och ytan. Gå tillbaka till samtalets yta för att fortsätta.';

  @override
  String get progressSaveFailed => 'Det gick inte att uppdatera förloppet';

  @override
  String get progressGoal => 'Mål';

  @override
  String get progressNoGoal => 'Inget arbetsmål angivet';

  @override
  String get progressSetGoal => 'Sätt mål';

  @override
  String get progressEditGoal => 'Redigera mål';

  @override
  String get progressClearGoal => 'Rensa mål';

  @override
  String get progressGoalRequired => 'Ange ett mål innan du sparar.';

  @override
  String get progressTodos => 'Uppgifter';

  @override
  String get transcriptToolTodos => 'Uppgifter';

  @override
  String get transcriptToolSearchMemory => 'Sök i minnet';

  @override
  String get transcriptToolRenderMedia => 'Visa media';

  @override
  String get progressNoTodos => 'Inga uppgifter ännu';

  @override
  String get progressNewTodo => 'Ny uppgift';

  @override
  String get progressAddTodo => 'Lägg till uppgift';

  @override
  String get progressEditTodo => 'Redigera uppgift';

  @override
  String get progressTodoRequired => 'Ange en uppgift innan du sparar.';

  @override
  String get progressTodoNoLongerExists =>
      'Uppgiften har tagits bort. Läs in listan igen och försök på nytt.';

  @override
  String get progressWorkspaceChanged =>
      'Den aktiva arbetsytan har ändrats. Gå tillbaka till det här samtalet och försök igen.';

  @override
  String progressRemoveTodo(String name) {
    return 'Ta bort uppgiften $name';
  }

  @override
  String get progressPending => 'Väntar';

  @override
  String get progressInProgress => 'Pågår';

  @override
  String get progressCompleted => 'Slutförd';

  @override
  String get progressMoveUp => 'Flytta upp uppgiften';

  @override
  String get progressMoveDown => 'Flytta ner uppgiften';

  @override
  String get progressRunTree => 'Agentkörningar';

  @override
  String get progressNoRuns => 'Inga körningar i det här samtalet ännu';

  @override
  String get progressRunning => 'Körs';

  @override
  String get progressFailed => 'Misslyckades';

  @override
  String get progressUnknown => 'Okänd';

  @override
  String get progressHealthy => 'Aktiv';

  @override
  String get progressBlocked => 'Blockerad';

  @override
  String get progressLooping => 'Fast i en loop';

  @override
  String get progressStalled => 'Har stannat av';

  @override
  String get progressDead => 'Stoppades oväntat';

  @override
  String get progressQuiet => 'Inga utdata ännu';

  @override
  String get progressCostReported => 'Avgift rapporterad av leverantören';

  @override
  String get progressCostNotional =>
      'Teoretiskt listpris för abonnemanget, inte en faktura';

  @override
  String get progressCostMixed => 'Blandade kostnadskällor';

  @override
  String get progressCostEstimated => 'Uppskattad kostnad';

  @override
  String progressDurationSeconds(String seconds) {
    return '$seconds s';
  }

  @override
  String progressRunDetails(String model, String duration, String cost) {
    return 'Modell: $model · Tid: $duration · Kostnad: $cost';
  }

  @override
  String progressStartedAt(String time) {
    return 'Startad $time';
  }

  @override
  String progressLiveness(String state) {
    return 'Hälsa: $state';
  }

  @override
  String progressRunTokens(String input, String output) {
    return 'Indata: $input · Utdata: $output token';
  }

  @override
  String get progressOutputPreviewLimited =>
      'Endast de första 6 000 tecknen i strukturerade utdata visas.';

  @override
  String progressRetryOf(String runId) {
    return 'Nytt försök av körning $runId';
  }

  @override
  String get progressContext => 'Kontext och gränser';

  @override
  String get progressNoAgent => 'Ingen agent att inspektera';

  @override
  String progressContextReading(String used, String window) {
    return '$used / $window token';
  }

  @override
  String get progressMeasured =>
      'Kontext rapporterad av leverantören vid det senaste anropet';

  @override
  String get progressEstimated =>
      'Uppskattat utifrån det lagrade samtalet och beständig kontext';

  @override
  String get progressContextUnknown =>
      'Kontextanvändningen har inte rapporterats ännu';

  @override
  String progressContextPercent(String percent) {
    return '$percent% av kontextfönstret';
  }

  @override
  String progressMonthlyBudget(String amount) {
    return 'Inställd månadsgräns för agenten: $amount';
  }

  @override
  String progressConversationTokens(String tokens) {
    return 'Lagrat pågående samtal: uppskattningsvis $tokens token';
  }

  @override
  String progressInspectionFor(String agent, String model) {
    return 'Beständig kontext för $agent · $model';
  }

  @override
  String get progressContextSystem => 'Systemprompt';

  @override
  String get progressContextRules => 'Regler';

  @override
  String get progressContextSkills => 'Färdigheter';

  @override
  String get progressContextTools => 'Verktygsdefinitioner';

  @override
  String get progressContextMcp => 'MCP-verktyg';

  @override
  String get progressContextDeferred => 'Uppskjutna verktyg';

  @override
  String get progressContextSubagents => 'Subagenter';

  @override
  String get progressContextRunner => 'Extern körare';

  @override
  String get progressContextMemory => 'Minne';

  @override
  String get progressContextHistory => 'Samtalshistorik';

  @override
  String progressContextSegment(String label, String tokens) {
    return '$label · $tokens token';
  }

  @override
  String progressContextPart(String title, String tokens) {
    return '$title · $tokens token';
  }

  @override
  String get progressOutputs => 'Senaste utdata';

  @override
  String get progressNoOutputs => 'Inga utdata från agenten på sistone';

  @override
  String get progressStructuredOutputsAbove =>
      'Strukturerade utdata från körningar visas i agentkörningarna ovan.';

  @override
  String get progressRecentOutputsOnly =>
      'Endast de senaste meddelandena visas. Öppna samtalet för att se tidigare arbete.';

  @override
  String get progressPlan => 'Plan';

  @override
  String get progressArtifact => 'Artefakt';

  @override
  String get progressResult => 'Resultat';

  @override
  String get progressHideArtifact => 'Dölj artefakt';

  @override
  String get progressReadArtifact => 'Läs artefakt';

  @override
  String get progressArtifactUnavailable =>
      'Artefakten är inte längre tillgänglig';

  @override
  String get progressArtifactPreviewLimited =>
      'En begränsad förhandsvisning av artefakten visas.';

  @override
  String get progressDiagramSource => 'Diagramkälla';

  @override
  String progressOpenAttachment(String name) {
    return 'Öppna $name';
  }

  @override
  String get progressOpenPlan => 'Öppna plan';

  @override
  String progressOpenDiff(String label) {
    return 'Granska ändrade filer: $label';
  }

  @override
  String get progressViewMessage => 'Visa meddelande';

  @override
  String get pushTitle => 'Bakgrundsaviseringar';

  @override
  String get pushIntro =>
      'Få en privat avisering när något behöver din uppmärksamhet, även när appen är stängd. Detaljerna stannar inom din krypterade anslutning.';

  @override
  String get pushLoading => 'Kontrollerar aviseringsinställningar…';

  @override
  String get pushError =>
      'Det gick inte att uppdatera aviseringarna. Kontrollera anslutningen och försök igen.';

  @override
  String get pushEnable => 'Aktivera aviseringar';

  @override
  String get pushDisable => 'Stäng av aviseringar';

  @override
  String get pushQuiet => 'Pausa aviseringar på den här enheten';

  @override
  String get pushCategories => 'Avisera mig om';

  @override
  String get pushCategoryAgents => 'Agenter';

  @override
  String get pushCategoryMessages => 'Meddelanden';

  @override
  String get pushCategoryPullRequests => 'Pull requests';

  @override
  String get pushCategoryTickets => 'Ärenden';

  @override
  String get pushCategoryCalendar => 'Kalender';

  @override
  String get pushCategoryMachines => 'Datorer';

  @override
  String get pushSecureOrigin => 'Aviseringar kräver HTTPS.';

  @override
  String get pushInstallIos =>
      'På iPhone eller iPad lägger du till appen på hemskärmen och öppnar den där för att aktivera aviseringar.';

  @override
  String get pushUnsupported =>
      'Den här webbläsaren stöder inte bakgrundsaviseringar.';

  @override
  String get pushDenied =>
      'Webbläsaren rapporterar att aviseringar är blockerade. Kontrollera webbplatsens behörighet och aviseringsinställningarna i webbläsaren eller på enheten, och uppdatera sedan sidan.';

  @override
  String get pushOsHint =>
      'Webbläsaren behöver också behörighet att visa aviseringar i enhetens systeminställningar.';

  @override
  String get pushServiceUnavailable =>
      'Webbläsarens pushtjänst avvisade prenumerationen. Vissa webbläsare, som Brave, stänger av den som standard: leta efter ett alternativ för pushmeddelanden i webbläsarens sekretessinställningar och försök igen.';

  @override
  String get pushWorkerUnavailable =>
      'Aviseringstjänsten kunde inte starta i den här webbläsaren. Läs in sidan igen och försök på nytt.';

  @override
  String get pushResubscribe => 'Återanslut aviseringar';

  @override
  String get pushStatusEnabled => 'Aviseringar är på för den här enheten.';

  @override
  String get pushStatusDisabled => 'Aviseringar är av för den här enheten.';

  @override
  String get credentialsTitle => 'Anslutningar och inloggningsuppgifter';

  @override
  String get credentialsIntro =>
      'Anslut kontona som dina körningar och integrationer använder. Hemligheter lagras på din server, inte på den här telefonen.';

  @override
  String get credentialsModelProviders => 'Modellleverantörer';

  @override
  String get credentialsOwnerOnly =>
      'Bara serverägaren kan lägga till, logga in på eller ta bort inloggningsuppgifter för modellleverantörer. Nycklarna delas mellan arbetsytor.';

  @override
  String get credentialsContactOwner =>
      'Be serverägaren ansluta leverantören som den blockerade körningen behöver.';

  @override
  String get credentialsClaudeCode => 'Claude Code';

  @override
  String get credentialsClaudeHostOnly =>
      'Claude Code loggar in via CLI på värddatorn. Be serverägaren logga in eller förnya inloggningen i värddatorns terminal. Det går inte från den här telefonen.';

  @override
  String get credentialsYourForgeAccounts => 'Dina konton på kodplattformar';

  @override
  String get credentialsYourTicketingAccount => 'Ditt ärendekonto';

  @override
  String get credentialsLocalTicketsNoLogin =>
      'Lokala ärenden kräver ingen inloggning. Anslut Linear här om din arbetsyta använder Linear.';

  @override
  String get credentialsMembershipRequired =>
      'Gå med i en arbetsyta för att hantera inloggningsuppgifter för kodplattformar eller ärendesystem. Be en administratör om åtkomst.';

  @override
  String get credentialsSwitchWorkspace =>
      'Länken pekar på en annan arbetsyta. Byt till den arbetsytan innan du ändrar inloggningsuppgifter.';

  @override
  String get credentialsReturnToInbox =>
      'Gå tillbaka till Inkorgen och försök köra igen när inloggningsuppgifterna har anslutits. Värddatorn kontrollerar också pausade körningar automatiskt.';

  @override
  String get credentialsLoadFailed =>
      'Kunde inte läsa in anslutningar. Kontrollera serveranslutningen och försök igen.';

  @override
  String get credentialsOperationFailed =>
      'Kunde inte ändra anslutningen. Kontrollera serveranslutningen, din åtkomst och inloggningsuppgifterna och försök igen.';

  @override
  String get credentialsConnected => 'Ansluten';

  @override
  String get credentialsNotConnected => 'Inte ansluten';

  @override
  String credentialsSignedInAs(String username) {
    return 'Inloggad som $username';
  }

  @override
  String get credentialsAccount => 'Anslutet konto';

  @override
  String get credentialsStoredKey => 'Sparad nyckel';

  @override
  String get credentialsActive => 'Aktiv';

  @override
  String get credentialsRemove => 'Ta bort';

  @override
  String get credentialsRemoveConfirm =>
      'Ta bort dina sparade inloggningsuppgifter? Du kan behöva logga in igen.';

  @override
  String get credentialsApiKey => 'API-nyckel';

  @override
  String get credentialsApiKeyHint =>
      'Klistra in en API-nyckel från leverantören';

  @override
  String get credentialsBrowserLogin => 'Logga in via webbläsaren';

  @override
  String get credentialsSignInAgain => 'Logga in igen';

  @override
  String get credentialsWaitingForLogin =>
      'Väntar på godkännande i din webbläsare…';

  @override
  String get credentialsConnectCodePrompt => 'Bekräftelsekod';

  @override
  String get credentialsConnectCodeMalformed =>
      'Det ser inte ut som en inloggningskod. Koder har 8 bokstäver och siffror.';

  @override
  String get credentialsSignInInvalidCode =>
      'Koden hör inte till den här inloggningen. Kontrollera den och försök igen.';

  @override
  String get credentialsSignInTooManyCodes =>
      'För många felaktiga koder. Starta inloggningen igen.';

  @override
  String get credentialsSignInRetryLater =>
      'Inloggningstjänsten svarar inte just nu. Vänta en minut och försök igen.';

  @override
  String get credentialsSignInRefused =>
      'Inloggningen nekades. Starta den igen och godkänn alla begärda behörigheter.';

  @override
  String get credentialsSignInNotSaved =>
      'Inloggningen fungerade, men servern kunde inte spara den. Försök igen.';

  @override
  String credentialsSignInUnavailable(String provider) {
    return 'Inloggning på $provider är inte konfigurerad på den här servern än.';
  }

  @override
  String get credentialsSignInPhoneUnreachable =>
      'Serverns återanropsadress för inloggning går inte att nå säkert från en telefon. Logga in från skrivbordsappen eller be serverns ägare att konfigurera en offentlig HTTPS-adress.';

  @override
  String get credentialsLoginTimedOut =>
      'Inloggningsförsöket har gått ut. Starta ett nytt försök.';

  @override
  String get credentialsCopyCode => 'Kopiera kod';

  @override
  String get credentialsDeviceCodeHint =>
      'Bekräfta koden på leverantörens sida. Låt den här skärmen vara öppen medan servern slutför inloggningen.';

  @override
  String get credentialsPasteRedirect =>
      'Auktoriseringskod eller omdirigeringsadress';

  @override
  String get credentialsPasteRedirectHint =>
      'Klistra in koden eller den fullständiga omdirigeringsadressen från leverantören';

  @override
  String get credentialsCompleteLogin => 'Slutför inloggningen';

  @override
  String get credentialsUpdateToken => 'Uppdatera token';

  @override
  String get credentialsAddToken => 'Lägg till token';

  @override
  String get credentialsPersonalToken => 'Personlig åtkomsttoken';

  @override
  String get credentialsPersonalTokenHint =>
      'Klistra in en personlig åtkomsttoken';

  @override
  String get credentialsStopWatching => 'Sluta bevaka';

  @override
  String get transcriptClaudeSignInExpiredTitle =>
      'Inloggningen till Claude Code har gått ut';

  @override
  String get transcriptClaudeSignInExpiredBody =>
      'Körningen stoppades eftersom kontot inte längre autentiseras. Logga in igen och försök sedan med turen igen.';

  @override
  String get transcriptSignInExpiredTitle =>
      'Inloggningen till leverantören har gått ut';

  @override
  String get transcriptSignInExpiredBody =>
      'Körningen stoppades eftersom leverantörens inloggningsuppgifter inte längre fungerar. Anslut den igen under Inställningar → Leverantörer och försök sedan med turen igen.';

  @override
  String get permissionHostExecution => 'Kör kommandon på värden';

  @override
  String credentialsSignInLapsed(String provider) {
    return 'Din inloggning på $provider har gått ut. Logga in igen.';
  }

  @override
  String get credentialsSignInPaused =>
      'Pausad: arbetsytans inloggningstjänst har ändrats. Den fungerar igen när tjänsten är tillbaka.';

  @override
  String credentialsProviderUnreachable(String provider) {
    return 'Det går inte att nå $provider just nu. Försöker igen.';
  }

  @override
  String get credentialsScopeWorkspace => 'Bara den här arbetsytan';

  @override
  String get credentialsScopeAllWorkspaces => 'Alla arbetsytor';

  @override
  String get credentialsRemoveConfirmWorkspace =>
      'Ta bort dina sparade inloggningsuppgifter från den här arbetsytan? Andra arbetsytor behåller sina.';

  @override
  String get credentialsRemoveConfirmAllWorkspaces =>
      'Ta bort dina sparade inloggningsuppgifter från alla arbetsytor som delar dem?';

  @override
  String get credentialsSignInServerRestarted =>
      'Servern startades om. Börja inloggningen igen.';

  @override
  String repoAccessInstallApp(String owner, String names) {
    return 'Installera GitHub App på $owner så att automatiseringen når $names. Tryck för att öppna GitHub.';
  }

  @override
  String repoAccessAskAdminInstall(String owner, String names) {
    return 'GitHub App är inte installerad på $owner, så automatiseringen når inte $names. Be en administratör för arbetsytan att installera den.';
  }

  @override
  String repoAccessAddToApp(String names) {
    return 'Lägg till $names bland GitHub Appens arkiv. Tryck för att öppna GitHub.';
  }

  @override
  String repoAccessAskAdminAdd(String names) {
    return 'GitHub App ser inte $names ännu. Be en administratör för arbetsytan att lägga till dem bland dess arkiv.';
  }

  @override
  String repoAccessSuspended(String names) {
    return 'GitHub App-installationen är avstängd. Automatiseringen för $names är pausad tills en ägare av kontot återupptar installationen på GitHub.';
  }

  @override
  String repoAccessOwnerCannotSee(String names) {
    return 'Personen som ansvarar för arbetsytans automatisering kan inte längre se $names, så inget körs där för deras räkning.';
  }

  @override
  String repoAccessOwnerNotSignedIn(String names) {
    return 'Personen som ansvarar för arbetsytans automatisering är inte inloggad på forgen, så automatiseringen för $names väntar tills de loggar in.';
  }

  @override
  String repoAccessRetrying(String names) {
    return 'Kunde inte kontrollera åtkomsten till $names. Försöker igen.';
  }

  @override
  String hiddenReposSignIn(int count, String forge) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other:
          'Logga in på $forge för att se pull requests från $count arkiv till',
      one: 'Logga in på $forge för att se pull requests från 1 arkiv till',
    );
    return '$_temp0';
  }

  @override
  String hiddenReposNoForgeAccess(int count, String forge) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count arkiv är dolda eftersom ditt $forge-konto inte kan se dem',
      one: '1 arkiv är dolt eftersom ditt $forge-konto inte kan se det',
    );
    return '$_temp0';
  }

  @override
  String hiddenReposNoGrant(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other:
          '$count arkiv är dolda eftersom du saknar åtkomst till dem i den här arbetsytan',
      one:
          '1 arkiv är dolt eftersom du saknar åtkomst till det i den här arbetsytan',
    );
    return '$_temp0';
  }

  @override
  String hiddenReposChecking(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Kontrollerar din åtkomst till $count arkiv till…',
      one: 'Kontrollerar din åtkomst till 1 arkiv till…',
    );
    return '$_temp0';
  }

  @override
  String get credentialsAtlassianEmail => 'E-post för Atlassian-kontot';

  @override
  String get credentialsAtlassianEmailInvalid =>
      'Ange e-postadressen för ditt Atlassian-konto.';

  @override
  String get credentialsBitbucketApiToken => 'API-token';

  @override
  String repoAccessAutomationTokenMissing(String names) {
    return 'Ingen automatiseringstoken kan läsa $names, så bakgrundsarbetet där är pausat. En administratör kan lägga till en under Inställningar → Repositoryn.';
  }

  @override
  String get credentialsSignInConfirmInBrowser =>
      'Bekräfta i webbläsaren och ange sedan koden den visar i fältet nedan.';

  @override
  String get credentialsSignInAccountAlreadyBound =>
      'Det här kontot är redan anslutet till en annan person på den här servern. Logga in med ett annat konto.';

  @override
  String credentialsTokenUnreachable(String provider) {
    return '$provider kunde inte nås för att kontrollera token. Försök igen om en stund.';
  }

  @override
  String credentialsTokenRejected(String provider) {
    return '$provider godkänner inte token. Kontrollera att du kopierat hela den och att den inte har återkallats.';
  }

  @override
  String credentialsTokenWrongKind(String provider) {
    return 'Det här är ingen personlig token. Klistra in en personlig åtkomsttoken från ditt eget $provider-konto, inte en token för ett projekt, en grupp, en arbetsyta eller en bot.';
  }

  @override
  String credentialsTokenNarrowScope(String scope) {
    return 'Token saknar behörigheten $scope, som granskning och kommentarer kräver. Skapa en som har den.';
  }

  @override
  String get credentialsTokenExpired =>
      'Token har gått ut. Skapa en ny och klistra in den här.';

  @override
  String get credentialsSignInRateLimited =>
      'För många förfrågningar just nu. Vänta en stund och försök igen.';

  @override
  String get credentialsSignInCancelled =>
      'Inloggningen avbröts eller nekades. Starta den igen när du är redo.';

  @override
  String get credentialsSignInNoLongerOpen =>
      'Den här inloggningen är inte längre öppen: den avbröts, användes eller ersattes. Starta den igen.';

  @override
  String get noWorkspacesYetHint =>
      'En arbetsytadministratör måste bjuda in dig, eller så kan serverägaren skapa en arbetsyta åt dig.';

  @override
  String repoAccessReplaced(String repos, String forge) {
    return '$repos pekar nu på ett annat arkiv på $forge. Koppla om det från skrivbordsappen eller webbappen för att fortsätta använda det.';
  }

  @override
  String repoAccessAskAdminRelink(String repos, String forge) {
    return '$repos pekar nu på ett annat arkiv på $forge. En arbetsytadministratör måste koppla om det innan det kan användas igen.';
  }

  @override
  String get runSandboxUnavailableTitle =>
      'Agenter behöver en sandlåda på den här servern';

  @override
  String get runSandboxUnavailable =>
      'Den här servern har ingen sandlåda, så bara dess ägare kan köra agenter här. Ägaren kan installera sandlådan eller stänga av sandlådan för alla.';

  @override
  String get scriptToolCalls => 'Verktygsanrop';

  @override
  String scriptCallCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count anrop',
      one: '1 anrop',
    );
    return '$_temp0';
  }

  @override
  String scriptCallsRunning(int count) {
    return '$count körs';
  }

  @override
  String scriptCallsOk(int count) {
    return '$count ok';
  }

  @override
  String scriptCallsFailed(int count) {
    return '$count misslyckades';
  }

  @override
  String scriptCallsDenied(int count) {
    return '$count nekade';
  }

  @override
  String scriptCallsCancelled(int count) {
    return '$count avbrutna';
  }

  @override
  String scriptCallsQueued(int count) {
    return '$count i kö';
  }

  @override
  String scriptCallsSkipped(int count) {
    return '$count hoppade över';
  }

  @override
  String get scriptStepQueued => 'I kö';

  @override
  String get scriptStepSkipped => 'Hoppad över';

  @override
  String get scriptGroupLoop => 'Loop';

  @override
  String get scriptGroupEach => 'För varje';

  @override
  String get scriptGroupParallel => 'Parallellt';

  @override
  String get scriptGroupFunction => 'Funktion';

  @override
  String scriptCallsHidden(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Visa ytterligare $count anrop',
      one: 'Visa ytterligare 1 anrop',
    );
    return '$_temp0';
  }

  @override
  String get scriptCallsUnplaced => 'Anrop som inte placerats i skriptet';

  @override
  String get scriptToolComputed => 'Verktyg';

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
      other: '$count rader',
      one: '1 rad',
    );
    return '$_temp0';
  }

  @override
  String get scriptStateRunning => 'Körs';

  @override
  String get scriptStateCompleted => 'Slutförd';

  @override
  String get scriptStateFailed => 'Misslyckades';

  @override
  String get scriptStateTimedOut => 'Tiden gick ut';

  @override
  String get scriptStateCancelled => 'Avbruten';

  @override
  String get scriptStateMemoryExceeded => 'Slut på minne';

  @override
  String get scriptStateOutputExceeded => 'För mycket utdata';

  @override
  String get scriptStateSandboxError => 'Fel i sandlådan';

  @override
  String get scriptStateRefused => 'Nekad';

  @override
  String get scriptOriginLine => 'Från ett skript som agenten kör';

  @override
  String get codeModeTitle => 'Kodläge';

  @override
  String get codeModeAvailable => 'Tillgänglig';

  @override
  String get codeModeUnavailable => 'Otillgänglig';

  @override
  String codeModeUnavailableNote(String reason) {
    return 'Den här servern kan inte köra skript, så agenter här anropar sina verktyg ett i taget. Servern säger: $reason';
  }

  @override
  String get codeModeNoReason => 'ingen anledning angavs.';

  @override
  String get workKindUnknown =>
      'Av en orsak som den här versionen inte känner igen:';

  @override
  String get workRefusalUnknown => 'Servern nekade det här:';

  @override
  String workActionFailed(String error) {
    return 'Det fungerade inte: $error';
  }

  @override
  String get wakeKindStopped =>
      'Parkerad eftersom en person stoppade körningen.';

  @override
  String get wakeKindAttempts => 'Leveransen misslyckades tre gånger.';

  @override
  String get wakeKindAgentDeleted => 'Agenten finns inte längre.';

  @override
  String get wakeKindAgentNotDispatchable => 'Agenten är pensionerad.';

  @override
  String get wakeKindAgentPaused => 'Agenten är pausad.';

  @override
  String get wakeKindPersonRemoved =>
      'Personen den agerar för har lämnat arbetsytan.';

  @override
  String get wakeKindBudgetBlocked => 'En budget blockerar en körning.';

  @override
  String get wakeKindTakeOver => 'En person har tagit över arbetskopian.';

  @override
  String get wakeKindRateCapConversation =>
      'Det här samtalet har startat 30 körningar från väckningar den senaste timmen.';

  @override
  String get wakeKindRateCapWorkspace =>
      'Den här arbetsytan har startat 300 körningar från väckningar den senaste timmen.';

  @override
  String get wakeKindLiveRunNoInput =>
      'Agentens pågående körning här tar inte emot indata.';

  @override
  String get wakeKindLiveRunOtherOptions =>
      'Agentens pågående körning här körs på ett annat sätt, så den här startar en egen körning efter den.';

  @override
  String get wakeKindLiveRunOtherPerson =>
      'Agentens pågående körning här agerar för någon annan, så den här startar en egen körning efter den.';

  @override
  String get wakeKindDispatchRefused => 'Körningen kunde inte starta.';

  @override
  String get wakeKindSandboxUnavailable =>
      'Ingen sandlåda är tillgänglig för en skrivskyddad körning.';

  @override
  String get wakeKindReadOnlyUnavailable =>
      'Agentens backend kan inte hålla en körning skrivskyddad.';

  @override
  String get wakeKindServerStopped =>
      'En omstart av servern stoppade körningen.';

  @override
  String get wakeKindServerRestarted =>
      'Servern startade om under en persons körning.';

  @override
  String get wakeKindGuardFailed => 'En kontroll före leverans misslyckades.';

  @override
  String get wakeKindLimit =>
      'Väntar på att leverantörens användningsgräns ska återställas.';

  @override
  String get wakeKindLimitRunLive =>
      'Väntar på att körningen vid användningsgränsen ska avslutas.';

  @override
  String get wakeKindWakeMissed => 'Missades medan servern var nere.';

  @override
  String get wakeKindPipelineRunEnded => 'Dess pipelinekörning avslutades.';

  @override
  String get wakeKindGoalEnded => 'Dess mål avslutades.';

  @override
  String get wakeKindGoalBudgetExhausted => 'Dess mål använde sin budget.';

  @override
  String get wakeKindGoalReviewStale =>
      'Målet ändrades sedan granskningen begärdes.';

  @override
  String get wakeKindGoalPaused => 'Dess mål är pausat.';

  @override
  String get wakeKindGoalHeld => 'Dess mål är parkerat.';

  @override
  String get wakeKindGoalStopped => 'Dess mål stoppades.';

  @override
  String get wakeKindAskSettled => 'Frågan den svarar på är redan avgjord.';

  @override
  String get wakeKindRuleEnded => 'Dess schema avslutades.';

  @override
  String get wakeRefusalNotYours =>
      'Den här väckningen agerar för en annan person. Bara de kan leverera eller återuppta den.';

  @override
  String get wakeRefusalSettled => 'Den här väckningen har redan avslutats.';

  @override
  String get goalRefusalAlreadyActive =>
      'Den här agenten har redan ett aktivt mål.';

  @override
  String get goalRefusalNotInReview => 'Målet väntar inte på granskning.';

  @override
  String get goalRefusalEvidenceIncomplete =>
      'Målets underlag är ofullständigt.';

  @override
  String get goalRefusalClaimPending =>
      'Ett påstående om att det är klart kontrolleras fortfarande.';

  @override
  String get goalRefusalNotActiveSegment => 'Målet har inget segment igång.';

  @override
  String get goalRefusalNotYours =>
      'Bara personen som startade målet kan göra det.';

  @override
  String get goalRefusalNotPaused => 'Pausa målet först.';

  @override
  String get goalRefusalContractInvalid => 'Målets kontrakt kan inte läsas.';

  @override
  String get goalRefusalCheckerUnknown => 'Ingen agent har det namnet.';

  @override
  String get goalRefusalCheckerAmbiguous => 'Mer än en agent har det namnet.';

  @override
  String get goalRefusalCheckerIsGoalAgent =>
      'Granskaren måste vara en annan agent än den som utför arbetet.';

  @override
  String get goalRefusalCommandInvalid => 'Det här målet kan inte läsas:';

  @override
  String get wakeRuleRefusalIntervalTooShort =>
      'Intervallet är för kort. Välj minst en minut.';

  @override
  String get wakeRuleRefusalTooSoon => 'Tiden är för nära. Välj en senare.';

  @override
  String get wakeRuleRefusalLineageEnded =>
      'Den här kedjan av väckningar har använt sina körningar eller sin tid.';

  @override
  String get wakeRuleRefusalWatchTargetUnreadable =>
      'Du kan inte läsa det här bevakningen skulle gälla.';

  @override
  String get wakeRuleRefusalExpiryRequired =>
      'Ge den ett slutdatum eller ett antal körningar.';

  @override
  String get wakeRuleRefusalLimitReached =>
      'Det här samtalet eller den här agenten har redan så många scheman som det får ha.';

  @override
  String get wakeRuleRefusalInvalidWhen => 'Tiden kan inte läsas.';

  @override
  String get wakeRuleRefusalNoteTooLong => 'Anteckningen är för lång.';

  @override
  String get wakeRuleRefusalExpiryTooLong =>
      'Slutdatumet ligger för långt bort.';

  @override
  String get wakeRuleRefusalLimitOutOfRange =>
      'En gräns för körningar, dagar eller budget ligger utanför intervallet.';

  @override
  String get wakeRuleRefusalNextOutsideLoop =>
      'Bara en loop kan välja sin egen nästa tid.';

  @override
  String get wakeRuleRefusalWatchRefused => 'Det här kan inte bevakas.';

  @override
  String get wakeRuleRefusalRuleEnded => 'Schemat har redan avslutats.';

  @override
  String get wakeRuleRefusalNotYours => 'Schemat tillhör någon annan.';

  @override
  String get wakeRuleEndFired => 'Den kördes en gång.';

  @override
  String get wakeRuleEndExpired => 'Den nådde sitt slutdatum.';

  @override
  String get wakeRuleEndRunCap => 'Den använde sina körningar.';

  @override
  String get wakeRuleEndCostCap => 'Den nådde sin kostnadsgräns.';

  @override
  String get wakeRuleEndGoalEnded => 'Dess mål avslutades.';

  @override
  String get wakeRuleEndCancelled => 'Den avbröts.';

  @override
  String get wakeRuleEndMemberRemoved => 'Dess person har lämnat arbetsytan.';

  @override
  String get wakeRuleEndInvalidRow =>
      'Dess sparade inställningar kunde inte läsas.';

  @override
  String goalHoldWorking(int segment) {
    final intl.NumberFormat segmentNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String segmentString = segmentNumberFormat.format(segment);

    return 'Arbetar med segment $segmentString. Ingen behöver göra något.';
  }

  @override
  String get goalHoldWaiting =>
      'Väntar på arbete den är skyldig. Den fortsätter av sig själv.';

  @override
  String goalHoldWaitingUntil(String time) {
    return 'Väntar på arbete den är skyldig. Den fortsätter av sig själv senast $time.';
  }

  @override
  String get goalHoldVerifying =>
      'Den säger att den är klar. Servern kör dess kontroller, sedan avgör en granskare.';

  @override
  String get goalHoldLimit =>
      'Pausad vid leverantörens användningsgräns. Den återupptas av sig själv efter återställningen.';

  @override
  String goalHoldLimitUntil(String time) {
    return 'Pausad vid leverantörens användningsgräns. Den återupptas av sig själv $time.';
  }

  @override
  String get goalHoldPerson =>
      'Väntar på att en person svarar i samtalet. Den fortsätter när någon har svarat.';

  @override
  String get goalHoldByPerson =>
      'Pausad av en person. Den förblir pausad tills någon återupptar den.';

  @override
  String get goalHoldNeedsReview =>
      'Väntar på granskning: den kan inte fortsätta av sig själv. Godkänn den som klar, återuppta den eller avbryt den.';

  @override
  String get goalHoldBudget =>
      'Den använde sin budget. Höj budgeten för att låta den fortsätta.';

  @override
  String goalHoldLimitParks(int count, int max) {
    final intl.NumberFormat countNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String countString = countNumberFormat.format(count);
    final intl.NumberFormat maxNumberFormat = intl.NumberFormat.decimalPattern(
      localeName,
    );
    final String maxString = maxNumberFormat.format(max);

    return 'Pauser vid användningsgränser: $countString av $maxString';
  }

  @override
  String get goalHoldDetailStalled =>
      'Inga framsteg under dess senaste segment.';

  @override
  String get goalHoldDetailStalledWaiting =>
      'Den väntade i 24 timmar på samma arbete utan framsteg.';

  @override
  String get goalHoldDetailVerificationFailed =>
      'Den senaste kontrollen misslyckades.';

  @override
  String get goalHoldDetailCannotVerify =>
      'Granskaren kunde inte avgöra om det är klart.';

  @override
  String get goalHoldDetailSandboxUnavailable =>
      'Ingen sandlåda är tillgänglig för att köra dess kontroller.';

  @override
  String get goalHoldDetailCheckerUnavailable =>
      'Dess granskningsagent är inte tillgänglig. Välj en annan granskare och återuppta sedan.';

  @override
  String get goalHoldDetailCheckBroken => 'Den här kontrollen kan inte köras:';

  @override
  String get goalHoldDetailWakeSkipped => 'Dess väckning levererades inte.';

  @override
  String get goalHoldDetailClaimPending =>
      'Dess påstående att det är klart väntar på en kontroll.';

  @override
  String get goalHoldDetailUnanswered =>
      'En fråga eller godkännandebegäran till en person har inte fått något svar.';

  @override
  String get goalHoldDetailLimitParks =>
      'Den nådde användningsgränser för ofta. Titta igenom det och återuppta sedan.';

  @override
  String get goalHoldDetailInput => 'Väntar på ett svar i samtalet.';

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

    return 'Segment $runString av $maxString';
  }

  @override
  String goalSegmentsNoCap(int run) {
    final intl.NumberFormat runNumberFormat = intl.NumberFormat.decimalPattern(
      localeName,
    );
    final String runString = runNumberFormat.format(run);

    return 'Segment $runString, ingen gräns';
  }

  @override
  String goalMoney(String spent, String cap) {
    return 'Använt $spent av $cap';
  }

  @override
  String goalDeadline(String time) {
    return 'Deadline $time';
  }

  @override
  String get goalPipelineStep => 'Ett pipelinesteg driver det här målet.';

  @override
  String get goalSummaryHeading => 'Senaste sammanfattning';

  @override
  String get goalDoneMeans => 'Klart innebär';

  @override
  String get goalChecks => 'Kontroller';

  @override
  String get goalBoundaries => 'Gränser';

  @override
  String get goalStopWhen => 'Stoppa och fråga när';

  @override
  String get goalNoMachineCheck =>
      'Ingen maskinkontroll. En granskare bedömer utifrån det den kan läsa.';

  @override
  String get goalCheckEnvironment => 'Miljöuppgift';

  @override
  String goalLastCheck(int round, String time) {
    final intl.NumberFormat roundNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String roundString = roundNumberFormat.format(round);

    return 'Senaste kontroll, omgång $roundString, $time';
  }

  @override
  String get goalClaim => 'Vad den påstod';

  @override
  String get goalCheckPassed => 'Godkänd';

  @override
  String goalCheckFailed(int code) {
    return 'Misslyckades, slutkod $code';
  }

  @override
  String get goalCheckTimedOut => 'Tiden gick ut';

  @override
  String get goalCheckNotRerun => 'Körs inte om: inget har ändrats';

  @override
  String get goalCheckBroken => 'Kan inte köras';

  @override
  String get goalCriterionMet => 'Uppfylld';

  @override
  String get goalCriterionUnmet => 'Inte uppfylld';

  @override
  String get goalCriterionCannotTell => 'Kan inte avgöra';

  @override
  String get goalVerdictPass => 'Beslut: klart';

  @override
  String get goalVerdictFail => 'Beslut: inte klart';

  @override
  String get goalVerdictCannotVerify => 'Beslut: kunde inte avgöra';

  @override
  String get goalConcerns => 'Invändningar';

  @override
  String goalVerifiedBy(String agent) {
    return 'Verifierad av $agent';
  }

  @override
  String get goalVerifiedBySelf =>
      'Verifierad av sig själv (ingen separat granskare)';

  @override
  String get goalClosedByPerson => 'Stängd av en person utan godkänd kontroll';

  @override
  String get goalApprove => 'Godkänn slutförande';

  @override
  String get goalApproveTitle => 'Stäng det här målet som klart?';

  @override
  String get goalApproveBody =>
      'Ingen kontroll bekräftade det. Du stänger det på ditt eget ord, och målet noterar att en person stängde det overifierat.';

  @override
  String get goalApproveConfirm => 'Stäng som klart';

  @override
  String get goalResumeNotYours =>
      'Att återuppta det eller höja dess budget tillhör den som startade det.';

  @override
  String get goalChooseChecker => 'Välj en annan granskare';

  @override
  String goalCheckerSet(String agent) {
    return '$agent kontrollerar det nu. Återuppta för att verifiera igen.';
  }

  @override
  String get goalSchedules => 'Scheman';

  @override
  String get goalRepeat => 'Upprepa';

  @override
  String get goalCreateChecks => 'Kontroller (valfritt)';

  @override
  String get goalCreateCheckHint =>
      'Ett kommando som lyckas när arbetet är klart';

  @override
  String get goalCreateAddCheck => 'Lägg till kontroll';

  @override
  String get goalCreateRemoveCheck => 'Ta bort kontroll';

  @override
  String get goalCreateSegmentCap => 'Segmentgräns (valfritt)';

  @override
  String get goalCreateSegmentInvalid =>
      'Segmentgränsen är ett heltal, minst 1.';

  @override
  String get scheduleCreateTitle => 'Upprepa en uppmaning';

  @override
  String get scheduleCadence => 'Hur ofta';

  @override
  String get scheduleEveryMinutes => 'Var N:e minut';

  @override
  String get scheduleEveryHours => 'Var N:e timme';

  @override
  String get scheduleSelfPaced => 'Agenten väljer';

  @override
  String get scheduleSelfPacedHint =>
      'Agenten väljer fördröjningen efter varje körning, mellan 1 minut och 1 timme.';

  @override
  String get scheduleInterval => 'Intervall';

  @override
  String get scheduleNote => 'Vad ska varje körning göra?';

  @override
  String get scheduleCostCap => 'Kostnadsgräns i USD (valfritt)';

  @override
  String get scheduleExpiryDays => 'Slutar efter N dagar (valfritt)';

  @override
  String get scheduleCreateInvalid =>
      'Välj en yta och en agent, skriv vad varje körning ska göra och ange heltal på minst 1.';

  @override
  String get scheduleCreateButton => 'Starta schema';

  @override
  String get scheduleCreateConfirmTitle => 'Starta det här schemat?';

  @override
  String scheduleCreateConfirmEveryMinutes(int count) {
    final intl.NumberFormat countNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String countString = countNumberFormat.format(count);

    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Den körs var $countString:e minut, från och med nu.',
      one: 'Den körs varje minut, från och med nu.',
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
      other: 'Den körs var $countString:e timme, från och med nu.',
      one: 'Den körs varje timme, från och med nu.',
    );
    return '$_temp0';
  }

  @override
  String get scheduleCreateConfirmSelfPaced =>
      'Den körs nu, sedan väljer agenten när den ska köras igen.';

  @override
  String get scheduleCreated => 'Schemat startade. Det finns under Scheman.';

  @override
  String get schedulesTitle => 'Scheman';

  @override
  String get schedulesLoadFailed => 'Det gick inte att läsa in scheman';

  @override
  String get schedulesEmpty => 'Inga scheman eller bevakningar';

  @override
  String get schedulesEmptyDescription =>
      'Upprepa en uppmaning från målskärmen, eller skicka /loop eller /schedule i ett samtal.';

  @override
  String get scheduleMissing =>
      'Schemat finns inte längre i den här arbetsytan.';

  @override
  String scheduleEvery(String interval) {
    return 'Var $interval';
  }

  @override
  String get scheduleSelfPacedLoop => 'Loop i agentens takt';

  @override
  String get scheduleCron => 'Cron-schema';

  @override
  String scheduleOnce(String time) {
    return 'En gång $time';
  }

  @override
  String scheduleWatch(String event) {
    return 'Bevakning: $event';
  }

  @override
  String get scheduleWatchPrChecks => 'pull request-kontroller';

  @override
  String get scheduleWatchPrReview => 'granskningar av pull requests';

  @override
  String get scheduleWatchPrMerged => 'sammanslagning av pull request';

  @override
  String get scheduleWatchEnvironment => 'miljö';

  @override
  String get scheduleWatchTicket => 'ärende';

  @override
  String get scheduleWatchPipelineRun => 'pipelinekörning';

  @override
  String get scheduleStatusActive => 'Aktiv';

  @override
  String get scheduleStatusPaused => 'Pausad';

  @override
  String get scheduleStatusEnded => 'Avslutat';

  @override
  String scheduleWakes(String agent) {
    return 'Väcker $agent';
  }

  @override
  String scheduleNext(String time) {
    return 'Nästa körning $time';
  }

  @override
  String scheduleLast(String time) {
    return 'Senaste körning $time';
  }

  @override
  String scheduleRuns(int count) {
    final intl.NumberFormat countNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String countString = countNumberFormat.format(count);

    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$countString körningar',
      one: '1 körning',
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

    return '$countString av $maxString körningar';
  }

  @override
  String scheduleSkipped(int count) {
    final intl.NumberFormat countNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String countString = countNumberFormat.format(count);

    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$countString hoppade över',
      one: '1 hoppad över',
    );
    return '$_temp0';
  }

  @override
  String scheduleEnds(String time) {
    return 'Slutar $time';
  }

  @override
  String scheduleChain(int count, String time) {
    final intl.NumberFormat countNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String countString = countNumberFormat.format(count);

    return 'En del av en kedja: $countString körningar kvar, slutar $time';
  }

  @override
  String get scheduleNoteAgent => 'Agentens egen anteckning, med egna ord:';

  @override
  String get scheduleNotePerson => 'En persons anteckning:';

  @override
  String scheduleActsFor(String name) {
    return 'Agerar för $name';
  }

  @override
  String get scheduleActsForBot => 'Agerar för ingen person';

  @override
  String get scheduleGoalBound => 'Det slutar med sitt mål.';

  @override
  String get schedulePause => 'Pausa';

  @override
  String get scheduleResume => 'Återuppta';

  @override
  String get scheduleDelete => 'Ta bort';

  @override
  String get scheduleRemove => 'Ta bort';

  @override
  String get scheduleDeleteTitle => 'Ta bort det här schemat?';

  @override
  String get scheduleDeleteBody =>
      'Det slutar för gott. Det som det redan har gjort ångras inte.';

  @override
  String get scheduleRemoveTitle => 'Ta bort det här schemat?';

  @override
  String get scheduleRemoveBody => 'Det försvinner från listan.';

  @override
  String get scheduleResumeNotYours =>
      'Bara personen som schemat agerar för kan återuppta det.';

  @override
  String get scheduleResumeAdminOnly =>
      'Bara en arbetsytadministratör kan återuppta ett schema som ingen person äger.';

  @override
  String get scheduleOpenConversation => 'Öppna samtal';

  @override
  String get progressWaiting => 'Väntar';

  @override
  String get progressNothingWaiting => 'Inget väntar.';

  @override
  String get wakeOriginGoal => 'Mål';

  @override
  String get wakeOriginGoalCheck => 'Målkontroll';

  @override
  String get wakeOriginGoalReview => 'Målgranskning';

  @override
  String get wakeOriginSchedule => 'Schema';

  @override
  String get wakeOriginWatch => 'Bevakning';

  @override
  String get wakeOriginReply => 'Svar';

  @override
  String get wakeOriginMessage => 'Meddelande';

  @override
  String get wakeOriginWorkFinished => 'Klart arbete';

  @override
  String get wakeOriginLimitReset => 'Gränsen återställd';

  @override
  String get wakeOriginRecovery => 'Återställning';

  @override
  String get wakeOriginAssignment => 'Tilldelning';

  @override
  String get wakeOriginPipelineStep => 'Pipelinesteg';

  @override
  String get wakeOriginImprovementReview => 'Förbättringsgranskning';

  @override
  String wakeOriginReplyFrom(String agent) {
    return 'Svar från $agent';
  }

  @override
  String wakeOriginMessageFrom(String agent) {
    return 'Meddelande från $agent';
  }

  @override
  String wakeOriginWorkFinishedBy(String agent) {
    return 'Klart arbete från $agent';
  }

  @override
  String wakeFor(String agent) {
    return 'För $agent';
  }

  @override
  String wakeDue(String time) {
    return 'Förfaller $time';
  }

  @override
  String get wakeDueNow => 'Förfaller nu';

  @override
  String get wakeHeld => 'Parkerad';

  @override
  String wakeExpires(String time) {
    return 'Går ut $time';
  }

  @override
  String wakeAttempt(int attempt) {
    final intl.NumberFormat attemptNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String attemptString = attemptNumberFormat.format(attempt);

    return 'Försök $attemptString';
  }

  @override
  String get wakeCancel => 'Avbryt';

  @override
  String get wakeDeliverNow => 'Leverera nu';

  @override
  String get wakeResume => 'Återuppta';

  @override
  String get wakeDismiss => 'Avfärda';

  @override
  String get wakeResumeOnlyTheirs =>
      'Bara personen vars körning det här är kan återuppta den.';

  @override
  String get wakeRecovery =>
      'Servern startade om under den här körningen. Återuppta den för att fortsätta, eller avfärda den.';

  @override
  String limitParkTitle(String provider, String time) {
    return 'Pausad vid ${provider}s användningsgräns, som återställs $time. Körningen väntar på att återupptas i upp till 7 dagar efter återställningen.';
  }

  @override
  String limitParkTitleUnnamed(String time) {
    return 'Pausad vid leverantörens användningsgräns, som återställs $time. Körningen väntar på att återupptas i upp till 7 dagar efter återställningen.';
  }

  @override
  String get limitParkResumeNow => 'Återuppta nu';

  @override
  String get limitParkCancel => 'Avbryt';

  @override
  String limitParkResumed(String provider) {
    return 'Återupptogs efter ${provider}s användningsgräns.';
  }

  @override
  String limitParkGone(String provider) {
    return 'Väntar inte längre på ${provider}s användningsgräns.';
  }

  @override
  String get limitParkProviderUnknown => 'leverantören';

  @override
  String get mobileHeldMessages => 'Parkerade meddelanden';

  @override
  String get heldSteeringTitle =>
      'Parkerade eftersom körningen slutade innan den kunde ta emot dem. Skicka dina nu eller ta bort dem.';

  @override
  String get heldSteeringRelease => 'Skicka parkerade meddelanden';

  @override
  String get notifGoalCompleted => 'Mål klart';

  @override
  String get notifGoalFailed => 'Målet misslyckades';

  @override
  String get notifGoalCancelled => 'Målet avbröts';

  @override
  String get notifGoalBudgetExhausted => 'Målet använde sin budget';

  @override
  String get notifGoalNeedsReview => 'Ett mål väntar på din granskning';

  @override
  String get notifGoalNeedsPerson => 'Ett mål behöver dig';

  @override
  String get notifGoalOnHold => 'Ett mål är parkerat';

  @override
  String get notifWakeRuleEnded => 'Ett schema avslutades';

  @override
  String notifWaitingDigest(int count) {
    final intl.NumberFormat countNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String countString = countNumberFormat.format(count);

    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$countString saker väntar på dig',
      one: '1 sak väntar på dig',
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
      other: '$countString förbättringsförslag lades fram',
      one: 'Ett förbättringsförslag lades fram',
    );
    return '$_temp0';
  }

  @override
  String get notifPipelineRunHeld =>
      'En pipelinekörning är parkerad vid sin budget';

  @override
  String notifPipelineRunHeldBody(String spent, String cap) {
    return 'Använt $spent av $cap';
  }

  @override
  String get notifNeedsYou => 'Behöver dig';

  @override
  String get notifDigestGoalReview => 'Mål väntar på granskning';

  @override
  String get notifDigestGoalPerson => 'Målet behöver en person';

  @override
  String get notifDigestHeldWake => 'Parkerad väckning';

  @override
  String get notifDigestImprovement => 'Föreslagen förbättring';

  @override
  String get wakeKindRulePaused => 'Dess schema är pausat.';

  @override
  String get wakeKindRuleBusy =>
      'Agenten var upptagen, och det här schemat hoppar över en tid när den är det.';

  @override
  String get wakeKindRuleFolded =>
      'En senare händelse i samma bevakning tog dess plats.';

  @override
  String get wakeKindRuleSuperseded =>
      'En senare tid i dess schema ersatte den.';

  @override
  String get wakeKindRuleNotified =>
      'Dess schema skickar bara en avisering, så ingen körning startade.';

  @override
  String get wakeKindRuleLimitParked =>
      'Dess schema väntar på att leverantörens användningsgräns ska återställas.';

  @override
  String get improvementRefusalCooldown =>
      'En förbättringsgranskning körde i det här samtalet för en kort stund sedan. Försök igen senare.';

  @override
  String get improvementRefusalQueued =>
      'En förbättringsgranskning av det här samtalet väntar redan på att köras.';

  @override
  String get improvementRefusalAgentNotFound =>
      'Den agenten finns inte i den här arbetsytan.';

  @override
  String get steeringRefusalHeldByLimit =>
      'Meddelanden som parkerats vid en användningsgräns kan inte skickas för hand. De väntar på att den pausade körningen ska återupptas.';

  @override
  String limitParkCancelled(String provider) {
    return 'Väntan vid ${provider}s användningsgräns avbröts.';
  }

  @override
  String limitParkExpired(String provider) {
    return 'Väntan vid ${provider}s användningsgräns gick ut innan körningen återupptogs.';
  }

  @override
  String limitParkSkipped(String provider) {
    return 'Körningen återupptogs inte efter ${provider}s användningsgräns.';
  }

  @override
  String get heldSteeringLimitTitle =>
      'Parkerad medan körningen väntar på att användningsgränsen ska återställas. De skickas när personen den körs för återupptar den.';

  @override
  String heldSteeringLimitAt(String time) {
    return 'Parkerad tills användningsgränsen återställs $time. De skickas när personen den körs för återupptar den.';
  }

  @override
  String get heldSteeringOtherTitle =>
      'Parkerade av servern. Du kan ta bort dem.';

  @override
  String workRowWoke(int count, String agent) {
    final intl.NumberFormat countNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String countString = countNumberFormat.format(count);

    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Väckte $agent för $countString väntande poster',
      one: 'Väckte $agent',
    );
    return '$_temp0';
  }

  @override
  String workRowWakeMissed(String agent) {
    return 'En väckning för $agent missades medan servern var nere.';
  }

  @override
  String workRowWakeSkipped(String agent) {
    return 'En väckning för $agent levererades inte.';
  }

  @override
  String workRowScheduleCreated(String agent) {
    return 'Schema satt för $agent.';
  }

  @override
  String workRowScheduleEnded(String agent) {
    return '${agent}s schema avslutades.';
  }

  @override
  String workRowNoteFromAgent(String agent) {
    return 'Schemanotering från $agent:';
  }

  @override
  String get workRowNoteFromPerson => 'Schemanotering från en person:';

  @override
  String workRowCommandRefusedNamed(String command) {
    return 'Kommandot $command nekades.';
  }

  @override
  String get workRowCommandRefused => 'Ett kommando nekades.';

  @override
  String workRowCapRaised(String person, String from, String to) {
    return '$person höjde pipelinens utgiftsgräns från $from till $to.';
  }

  @override
  String workRowCapRaisedNoAmounts(String person) {
    return '$person höjde pipelinens utgiftsgräns.';
  }

  @override
  String get workRowApplyIncomplete =>
      'En godkänd ändring av den här färdigheten kunde inte slutföras, eftersom färdigheten ändrades under tiden. Förslaget återställdes.';

  @override
  String get workRowOpenSchedule => 'Öppna schema';

  @override
  String get heldSteeringOthersTitle =>
      'Parkerade eftersom körningen slutade innan den kunde ta emot dem. Bara den som skrev ett meddelande kan skicka det.';

  @override
  String get heldSteeringOnlyYours =>
      'Skickar bara dina meddelanden. De andra väntar på de personer som skrev dem.';

  @override
  String heldSteeringWrittenBy(String name) {
    return 'Skrivet av $name';
  }

  @override
  String get steeringRefusalNotYours =>
      'Bara den som skrev ett parkerat meddelande kan skicka det, och inget av dessa är dina.';

  @override
  String get steeringRefusalNeedsWrite =>
      'Du behöver skrivåtkomst till den här ytans arkiv för att styra en körning som agerar för någon annan.';

  @override
  String workRowSchedulePaused(String name, String agent) {
    return '$name pausade schemat för $agent.';
  }

  @override
  String get goalVerdictObjective => 'Målet som helhet';

  @override
  String get notifDigestRequest => 'Väntar på ditt svar';
}
