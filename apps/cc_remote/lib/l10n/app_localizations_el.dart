// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Modern Greek (`el`).
class AppLocalizationsEl extends AppLocalizations {
  AppLocalizationsEl([String locale = 'el']) : super(locale);

  @override
  String get appTitle => 'Control Center';

  @override
  String get back => 'Πίσω';

  @override
  String get cancel => 'Ακύρωση';

  @override
  String get retry => 'Επανάληψη';

  @override
  String get tryAgain => 'Δοκιμάστε ξανά';

  @override
  String get settings => 'Ρυθμίσεις';

  @override
  String get refresh => 'Ανανέωση';

  @override
  String get approve => 'Έγκριση';

  @override
  String get deny => 'Απόρριψη';

  @override
  String get continueLabel => 'Συνέχεια';

  @override
  String get agentQuestionHeader => 'Ερώτηση για εσάς';

  @override
  String get agentQuestionAnsweredLabel => 'Απαντήθηκε';

  @override
  String get agentQuestionSkip => 'Παράλειψη';

  @override
  String get agentQuestionSkippedLabel => 'Παραλείφθηκε';

  @override
  String get agentQuestionFreeformHint => 'Πληκτρολογήστε την απάντησή σας…';

  @override
  String get agentApprovalRequired => 'Απαιτείται έγκριση';

  @override
  String get approveAndRemember => 'Έγκριση για 8 ώρες';

  @override
  String get decline => 'Άρνηση';

  @override
  String get confirm => 'Επιβεβαίωση';

  @override
  String get send => 'Αποστολή';

  @override
  String get close => 'Κλείσιμο';

  @override
  String get expand => 'Ανάπτυξη';

  @override
  String get zoomIn => 'Μεγέθυνση';

  @override
  String get zoomOut => 'Σμίκρυνση';

  @override
  String get resetZoom => 'Επαναφορά μεγέθυνσης';

  @override
  String get scanQrPrompt =>
      'Σαρώστε τον κωδικό QR από το Control Center για να συζεύξετε αυτό το τηλέφωνο.';

  @override
  String get scanQrHelp =>
      'Ανοίξτε την κάμερα και στρέψτε την στον QR που εμφανίζεται στο Control Center. Αυτό το τηλέφωνο συνδέεται απευθείας μέσω ιδιωτικής σύνδεσης.';

  @override
  String get connectingToMac => 'Σύνδεση με το Control Center…';

  @override
  String get connectingDetail => 'Δημιουργία ασφαλούς, άμεσης σύνδεσης.';

  @override
  String get identityChangedTitle => 'Η ταυτότητα του διακομιστή άλλαξε';

  @override
  String get identityChangedBody =>
      'Αυτός ο διακομιστής δεν ταιριάζει πλέον με την ταυτότητα που αποθηκεύτηκε κατά τη σύζευξη. Μπορεί να σημαίνει ότι ο διακομιστής επανεγκαταστάθηκε — ή ότι κάτι παρεμβαίνει στη σύνδεση. Για ασφάλεια, αυτή η συσκευή δεν θα συνδεθεί. Αφαιρέστε τη σύζευξη και σαρώστε έναν νέο κωδικό QR από το Control Center για να συζεύξετε ξανά.';

  @override
  String get removePairing => 'Αφαίρεση σύζευξης';

  @override
  String get couldntConnect => 'Δεν ήταν δυνατή η σύνδεση';

  @override
  String get pendingPairingTitle => 'Σύνδεση σε αυτόν τον διακομιστή;';

  @override
  String get pendingPairingBody =>
      'Ένας σύνδεσμος ζήτησε από το Control Center να συζευχθεί με αυτόν τον διακομιστή. Συνεχίστε μόνο αν το ξεκινήσατε εσείς.';

  @override
  String get connect => 'Σύνδεση';

  @override
  String get failureNotPaired =>
      'Χωρίς σύζευξη — σαρώστε τον κωδικό QR από το Control Center';

  @override
  String get failureUnreachable =>
      'Δεν ήταν δυνατή η πρόσβαση στον διακομιστή από καμία διαδρομή — ελέγξτε ότι εκτελείται ή δοκιμάστε το ίδιο δίκτυο';

  @override
  String get failureIdentityChanged =>
      'Η ταυτότητα του διακομιστή άλλαξε — αν επανεγκαταστάθηκε, συζεύξτε ξανά αυτή τη συσκευή';

  @override
  String get failureAuthRejected =>
      'Ο διακομιστής απέρριψε αυτή τη συσκευή — συζεύξτε την ξανά από το Control Center';

  @override
  String get failureUnknown =>
      'Δεν ήταν δυνατή η σύνδεση — πατήστε για επανάληψη';

  @override
  String get statusConnected => 'Συνδεδεμένο';

  @override
  String get statusConnecting => 'Σύνδεση';

  @override
  String get statusOffline => 'Εκτός σύνδεσης';

  @override
  String get statusIdentityMismatch => 'Ασυμφωνία ταυτότητας';

  @override
  String get statusNotPaired => 'Χωρίς σύζευξη';

  @override
  String get statusConfirmPairing => 'Επιβεβαίωση σύζευξης';

  @override
  String get connectionFailed => 'Η σύνδεση απέτυχε';

  @override
  String get identityMismatchBanner =>
      'Η ταυτότητα του διακομιστή άλλαξε — η σύνδεση σταμάτησε. Συζεύξτε ξανά αυτή τη συσκευή για να συνεχίσετε.';

  @override
  String get tabInbox => 'Εισερχόμενα';

  @override
  String get tabTickets => 'Εισιτήρια';

  @override
  String get tabChat => 'Συνομιλία';

  @override
  String get tabPrs => 'PRs';

  @override
  String get tabCalendar => 'Ημερολόγιο';

  @override
  String get tabNews => 'Ειδήσεις';

  @override
  String tabWaitingCount(String label, int count) {
    return '$label, $count σε αναμονή';
  }

  @override
  String get updateAvailable => 'Ένα νέο Control Center είναι διαθέσιμο';

  @override
  String get appearance => 'Εμφάνιση';

  @override
  String get language => 'Γλώσσα';

  @override
  String get device => 'Συσκευή';

  @override
  String get themeSystem => 'Σύστημα';

  @override
  String get themeLight => 'Φωτεινό';

  @override
  String get themeDark => 'Σκοτεινό';

  @override
  String get languageSystem => 'Σύστημα';

  @override
  String get disconnectTapAgain =>
      'Πατήστε ξανά για να αποσυνδέσετε αυτή τη συσκευή από το Control Center';

  @override
  String get disconnectDevice => 'Αποσύνδεση αυτής της συσκευής';

  @override
  String get disconnect => 'Αποσύνδεση';

  @override
  String get chooseWorkspace => 'Επιλογή χώρου εργασίας';

  @override
  String get workspaces => 'Χώροι εργασίας';

  @override
  String get workspacesLoadFailed => 'Αποτυχία φόρτωσης χώρων εργασίας';

  @override
  String get noWorkspacesYet => 'Δεν υπάρχουν ακόμη χώροι εργασίας';

  @override
  String selectWorkspace(String name) {
    return 'Επιλογή $name';
  }

  @override
  String get inboxLoadFailed => 'Δεν ήταν δυνατή η φόρτωση των εισερχομένων';

  @override
  String get allCaughtUp => 'Είστε ενήμεροι';

  @override
  String get inboxNoForgeAccount =>
      'Δεν είναι συνδεδεμένος λογαριασμός forge στον διακομιστή, επομένως τα pull requests δεν μπορούν ακόμη να αποδοθούν σε εσάς.';

  @override
  String get inboxNothingWaiting =>
      'Τίποτα δεν είναι αποκλεισμένο και κανένα pull request δεν σας περιμένει.';

  @override
  String get blocked => 'Αποκλεισμένος';

  @override
  String get sectionNeedsYourReview => 'Χρειάζεται την ανασκόπησή σας';

  @override
  String get sectionReturnedToYou => 'Επιστράφηκε σε εσάς';

  @override
  String get sectionApprovedAndReady => 'Εγκεκριμένα και έτοιμα';

  @override
  String get sectionYourDrafts => 'Τα πρόχειρά σας';

  @override
  String get sectionWaitingForReviewers => 'Αναμονή κριτών';

  @override
  String get sectionMergingAndMerged => 'Συγχώνευση και πρόσφατα συγχωνευμένα';

  @override
  String get sectionWaitingForAuthor => 'Αναμονή συντάκτη';

  @override
  String waitingAgo(String ago) {
    return 'αναμονή $ago';
  }

  @override
  String get openConversation => 'Άνοιγμα της συνομιλίας';

  @override
  String get calendarLoadFailed => 'Δεν ήταν δυνατή η φόρτωση του ημερολογίου';

  @override
  String get nothingScheduled => 'Τίποτα προγραμματισμένο';

  @override
  String get calendarEmptyDescription =>
      'Τα γεγονότα από τα συνδεδεμένα ημερολόγιά σας εμφανίζονται εδώ.';

  @override
  String get agenda => 'Ατζέντα';

  @override
  String get syncCalendarsNow => 'Συγχρονισμός ημερολογίων τώρα';

  @override
  String get event => 'Γεγονός';

  @override
  String get eventNotFound => 'Το γεγονός δεν βρέθηκε';

  @override
  String get eventNotFoundDescription =>
      'Μπορεί να είναι εκτός του παραθύρου ατζέντας ή να αφαιρέθηκε στην πηγή.';

  @override
  String get joinMeeting => 'Συμμετοχή στη σύσκεψη';

  @override
  String get join => 'Συμμετοχή';

  @override
  String attendeesCount(int count) {
    return 'Παρευρισκόμενοι ($count)';
  }

  @override
  String get details => 'Λεπτομέρειες';

  @override
  String get allDay => 'Ολοήμερο';

  @override
  String get happeningNow => 'Συμβαίνει τώρα';

  @override
  String inDuration(String duration) {
    return 'Σε $duration';
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
  String get attendeeAccepted => 'αποδεκτό';

  @override
  String get attendeeDeclined => 'απορρίφθηκε';

  @override
  String get attendeeMaybe => 'ίσως';

  @override
  String get attendeeNoReply => 'χωρίς απάντηση';

  @override
  String get organizer => 'διοργανωτής';

  @override
  String get calendarNoAccounts =>
      'Δεν είναι συνδεδεμένο ημερολόγιο για αυτόν τον χώρο εργασίας. Συνδέστε ένα από την εφαρμογή υπολογιστή — η είσοδος αποθηκεύει το token στον διακομιστή.';

  @override
  String get calendarReauthNeeded =>
      'Ένας λογαριασμός ημερολογίου χρειάζεται επανασύνδεση — ό,τι βλέπετε παρακάτω μπορεί να είναι παλιό. Επανασυνδέστε τον από την εφαρμογή υπολογιστή.';

  @override
  String get spacesLoadFailed => 'Δεν ήταν δυνατή η φόρτωση των χώρων';

  @override
  String get noSpaces => 'Κανένας χώρος';

  @override
  String get spacesEmptyDescription =>
      'Οι χώροι σε αυτόν τον χώρο εργασίας εμφανίζονται εδώ.';

  @override
  String get thread => 'Νήμα';

  @override
  String get agentWorking => 'Ο πράκτορας εργάζεται';

  @override
  String get messagesLoadFailed => 'Δεν ήταν δυνατή η φόρτωση των μηνυμάτων';

  @override
  String get noMessagesYet => 'Δεν υπάρχουν ακόμη μηνύματα';

  @override
  String get noMessagesDescription =>
      'Στείλτε ένα μήνυμα για να ξεκινήσει η συνομιλία.';

  @override
  String get agentResponding => 'Ο πράκτορας απαντά';

  @override
  String get agentFinished => 'Ο πράκτορας ολοκλήρωσε';

  @override
  String attachmentsTooLarge(int count, String names) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$names είναι πολύ μεγάλα για αποστολή από εδώ.',
      one: '$names είναι πολύ μεγάλο για αποστολή από εδώ.',
    );
    return '$_temp0';
  }

  @override
  String attachmentsTooLargeRelay(int count, String names) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$names είναι πολύ μεγάλα για αποστολή μέσω του relay από εδώ.',
      one: '$names είναι πολύ μεγάλο για αποστολή μέσω του relay από εδώ.',
    );
    return '$_temp0';
  }

  @override
  String get attachmentUploadFailed =>
      'Δεν ήταν δυνατή η μεταφόρτωση του συνημμένου. Δοκιμάστε ξανά.';

  @override
  String attachmentsLeftOut(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count συνημμένα δεν μεταφορτώθηκαν και παραλείφθηκαν.',
      one: '1 συνημμένο δεν μεταφορτώθηκε και παραλείφθηκε.',
    );
    return '$_temp0';
  }

  @override
  String get teammate => 'Συνάδελφος';

  @override
  String get agent => 'Πράκτορας';

  @override
  String get attachFile => 'Επισύναψη αρχείου';

  @override
  String get messageHint => 'Μήνυμα';

  @override
  String removeAttachment(String name) {
    return 'Αφαίρεση $name';
  }

  @override
  String get articlesLoadFailed => 'Δεν ήταν δυνατή η φόρτωση των άρθρων';

  @override
  String get noArticles => 'Κανένα άρθρο';

  @override
  String get articlesEmptyDescription =>
      'Νέα άρθρα εμφανίζονται εδώ καθώς ενημερώνονται οι ροές.';

  @override
  String get unread => 'Μη αναγνωσμένα';

  @override
  String get allFeeds => 'Όλες οι ροές';

  @override
  String get save => 'Αποθήκευση';

  @override
  String get unsave => 'Αναίρεση αποθήκευσης';

  @override
  String get readFullArticle => 'Ανάγνωση πλήρους άρθρου';

  @override
  String get ticketsLoadFailed => 'Δεν ήταν δυνατή η φόρτωση των εισιτηρίων';

  @override
  String get noTickets => 'Κανένα εισιτήριο';

  @override
  String get ticketsEmptyDescription =>
      'Τα εισιτήρια σε αυτόν τον χώρο εργασίας εμφανίζονται εδώ.';

  @override
  String get all => 'Όλα';

  @override
  String get ticket => 'Εισιτήριο';

  @override
  String get ticketLoadFailed => 'Δεν ήταν δυνατή η φόρτωση του εισιτηρίου';

  @override
  String assignedTo(String name) {
    return 'Ανατέθηκε στον/στην $name';
  }

  @override
  String get openInBrowser => 'Άνοιγμα στο πρόγραμμα περιήγησης';

  @override
  String get status => 'Κατάσταση';

  @override
  String get assign => 'Ανάθεση';

  @override
  String get reassign => 'Επανάθεση';

  @override
  String get noAgents => 'Κανένας πράκτορας';

  @override
  String get noAgentsDescription =>
      'Αναθέστε έναν πράκτορα από αυτόν τον χώρο εργασίας.';

  @override
  String get statusOpen => 'Ανοιχτό';

  @override
  String get statusInProgress => 'Σε εξέλιξη';

  @override
  String get statusBlocked => 'Αποκλεισμένος';

  @override
  String get statusInReview => 'Σε ανασκόπηση';

  @override
  String get statusDone => 'Ολοκληρώθηκε';

  @override
  String get statusBacklog => 'Ανεκτέλεστα';

  @override
  String get lensNeedsMe => 'Με χρειάζεται';

  @override
  String get lensMine => 'Δικά μου';

  @override
  String get prsLoadFailed => 'Δεν ήταν δυνατή η φόρτωση των pull requests';

  @override
  String get noOpenPullRequests => 'Δεν υπάρχουν ανοιχτά pull requests';

  @override
  String get nothingWaitingOnReview =>
      'Τίποτα δεν περιμένει την ανασκόπησή σας';

  @override
  String get noOwnOpenPullRequests => 'Δεν έχετε ανοιχτά pull requests';

  @override
  String get nothingBlocked => 'Τίποτα δεν είναι αποκλεισμένο';

  @override
  String get prsEmptyDescription =>
      'Τα pull requests από τα repo αυτού του χώρου εργασίας εμφανίζονται εδώ.';

  @override
  String get refreshPullRequests => 'Ανανέωση pull requests';

  @override
  String get noForgeConnected =>
      'Δεν είναι συνδεδεμένο forge στον διακομιστή, επομένως δεν μπορούν να ανακτηθούν pull requests. Συνδέστε ένα από την εφαρμογή υπολογιστή.';

  @override
  String reposUnreadable(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count repo δεν ήταν αναγνώσιμα.',
      one: '1 repo δεν ήταν αναγνώσιμο.',
    );
    return '$_temp0';
  }

  @override
  String reposNotReadable(String names) {
    return 'Μη αναγνώσιμα: $names';
  }

  @override
  String get installationSuspendedTitle =>
      'Η εγκατάσταση του GitHub App έχει ανασταλεί';

  @override
  String installationSuspendedBody(String names) {
    return 'Εμφανίζονται τα τελευταία γνωστά δεδομένα για τα ⁨$names⁩. Συνεχίστε την εγκατάσταση στο GitHub ή συνδέστε token με πρόσβαση.';
  }

  @override
  String installationSuspendedNotice(String names) {
    return 'Η εγκατάσταση του GitHub App έχει ανασταλεί. Εμφανίζονται τα τελευταία γνωστά δεδομένα για τα ⁨$names⁩. Συνεχίστε την εγκατάσταση στο GitHub ή συνδέστε token με πρόσβαση.';
  }

  @override
  String get draft => 'Πρόχειρο';

  @override
  String get merged => 'Συγχωνεύθηκε';

  @override
  String get closed => 'Κλειστό';

  @override
  String get open => 'Ανοιχτό';

  @override
  String get approved => 'Εγκρίθηκε';

  @override
  String get changesRequested => 'Ζητήθηκαν αλλαγές';

  @override
  String get reviewRequired => 'Απαιτείται ανασκόπηση';

  @override
  String get checksPassing => 'Οι έλεγχοι περνούν';

  @override
  String get checksFailing => 'Οι έλεγχοι αποτυγχάνουν';

  @override
  String get checksRunning => 'Οι έλεγχοι εκτελούνται';

  @override
  String prSemanticLabel(String title, String status) {
    return '$title, $status';
  }

  @override
  String get pullRequest => 'Pull request';

  @override
  String get prLoadFailed => 'Δεν ήταν δυνατή η φόρτωση αυτού του pull request';

  @override
  String get openOnForge => 'Άνοιγμα στο forge';

  @override
  String get requestChangesNeedsComment =>
      'Προσθέστε ένα σχόλιο που εξηγεί τι πρέπει να αλλάξει.';

  @override
  String get conversation => 'Συνομιλία';

  @override
  String get files => 'Αρχεία';

  @override
  String get checks => 'Έλεγχοι';

  @override
  String labelWithCount(String label, int count) {
    return '$label ($count)';
  }

  @override
  String filesCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count αρχεία',
      one: '1 αρχείο',
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
  String get conflicts => 'Συγκρούσεις';

  @override
  String get reviewers => 'Κριτές';

  @override
  String get noDescriptionNoComments =>
      'Δεν υπάρχει ακόμη περιγραφή ούτε σχόλια.';

  @override
  String get noChangedFiles => 'Κανένα αλλαγμένο αρχείο.';

  @override
  String get noChecksReported => 'Δεν αναφέρθηκαν έλεγχοι για το head commit.';

  @override
  String get reviewCommentHint => 'Αφήστε ένα σχόλιο ανασκόπησης…';

  @override
  String get comment => 'Σχόλιο';

  @override
  String get commentPosted => 'Το σχόλιο δημοσιεύτηκε';

  @override
  String get request => 'Αίτημα';

  @override
  String get squashAndMerge => 'Squash και συγχώνευση';

  @override
  String noActionsAvailable(String status) {
    return '$status — δεν υπάρχουν διαθέσιμες ενέργειες.';
  }

  @override
  String get reviewApproved => 'ενέκρινε';

  @override
  String get reviewRequestedChanges => 'ζήτησε αλλαγές';

  @override
  String get reviewCommented => 'ανασκόπησε';

  @override
  String get reviewPending => 'εκκρεμεί';

  @override
  String get unknownAuthor => 'άγνωστος';

  @override
  String hideDiffFor(String file) {
    return 'Απόκρυψη του diff για το $file';
  }

  @override
  String showDiffFor(String file) {
    return 'Εμφάνιση του diff για το $file';
  }

  @override
  String get checkRunning => 'σε εκτέλεση';

  @override
  String get checkPassed => 'πέρασε';

  @override
  String get checkFailed => 'απέτυχε';

  @override
  String get checkCancelled => 'ακυρώθηκε';

  @override
  String get checkSkipped => 'παραλείφθηκε';

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
      'Δεν υπάρχει κειμενικό diff για αυτό το αρχείο — είναι δυαδικό ή πολύ μεγάλο για να επιστρέψει ένα το forge.';

  @override
  String showRemainingLines(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Εμφάνιση των υπόλοιπων $count γραμμών',
      one: 'Εμφάνιση της υπόλοιπης γραμμής',
    );
    return '$_temp0';
  }

  @override
  String unchangedLines(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count αμετάβλητες γραμμές',
      one: '1 αμετάβλητη γραμμή',
    );
    return '$_temp0';
  }

  @override
  String get jumpToLatest => 'Μετάβαση στα πιο πρόσφατα';

  @override
  String get streaming => 'Ροή';

  @override
  String get working => 'Εργάζεται';

  @override
  String get input => 'Είσοδος';

  @override
  String get output => 'Έξοδος';

  @override
  String get now => 'τώρα';

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
  String get today => 'Σήμερα';

  @override
  String get tomorrow => 'Αύριο';

  @override
  String get yesterday => 'Χθες';

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
